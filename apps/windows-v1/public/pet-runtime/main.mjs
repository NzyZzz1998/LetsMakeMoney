import { DpiTransitionWatcher } from "./runtime/dpi-transition.mjs";
import { DpiSafetyPause } from "./runtime/dpi-safety-pause.mjs";
import { CompanionActionScheduler, createSeededRandom } from "./runtime/companion-scheduler.mjs";
import { resolveDirectionalFrame } from "./runtime/directional-frame.mjs";
import { FramePlayer, createBrowserScheduler } from "./runtime/frame-player.mjs";
import { DynamicHitCoordinator } from "./runtime/hit-coordinator.mjs";
import { alphaToRegionRuns } from "./runtime/hit-mask.mjs";
import { chooseNativeProbePoints, regionSignature } from "./runtime/hit-probe.mjs";
import { PetInputArbiter } from "./runtime/input-arbiter.mjs";
import { PetRuntimeMachine } from "./runtime/runtime-machine.mjs";
import { loadVNextPayload } from "./runtime/vnext-package-core.mjs";

const LOGICAL_WIDTH = 192;
const LOGICAL_HEIGHT = 208;
const ALPHA_THRESHOLD = 24;
const DPI_SETTLE_MS = 250;
const DPI_LATENCY_CLASSIFICATION_GRACE_MS = 750;
const PRODUCT_RUNTIME_READY_STATUS = "ready_for_product_runtime";
const FIRST_RETURN_SCHEDULER_SEED = 10701;
const FIRST_RETURN_ACTIONS = Object.freeze([
  "working_play_loop_a",
  "working_play_loop_b",
  "working_observe",
  "working_ack",
  "awake_rest_loop",
  "rest_ack",
  "sleeping_loop",
  "sleep_twitch",
  "sleep_ack",
  "run_prepare",
  "run_loop",
  "run_stop",
]);
const canvas = document.querySelector("#pet-canvas");
const context = canvas.getContext("2d", { alpha: true, willReadFrequently: true });
const analysisCanvas = document.createElement("canvas");
analysisCanvas.width = LOGICAL_WIDTH;
analysisCanvas.height = LOGICAL_HEIGHT;
const analysisContext = analysisCanvas.getContext("2d", { alpha: true, willReadFrequently: true });
const invoke = window.__LMM_PET_INVOKE__;
if (typeof invoke !== "function") {
  throw new Error("pet_runtime_invoke_bridge_missing");
}

let packageResult;
let bitmaps = new Map();
let player;
let machine;
let arbiter;
let hitCoordinator;
let dpiWatcher;
let companionScheduler;
let authoritativeRevision = 0;
let authoritativeBaseState = canvas.dataset.baseState || "awake_rest";
let fallbackActive = false;
let direction = "right";
let lastPointerScreen = null;
let timingCursor = null;
let moveQueue = Promise.resolve();
const frameTimings = [];
let frameSequence = 0;
const probedRegionSignatures = new Set();
let hitmaskSequence = 0;
let p0Failure = null;
let p0FailureDetails = null;
let lastHitMaskFrame = null;
let lastCommittedDirection = null;
let lastVerifiedDirection = null;
const sessionStartedAt = performance.now();

let firstFrameResolve;
const firstFrameReady = new Promise((resolve) => {
  firstFrameResolve = resolve;
});

function emitEvent(event) {
  void invoke("record_pet_event", { event: event.type, payload: event }).catch(() => {});
}

function browserLifecycleContext() {
  return {
    visibilityState: document.visibilityState,
    hasFocus: document.hasFocus(),
  };
}

function recordBrowserLifecycle(eventName) {
  emitEvent({
    type: "browser_lifecycle_observed",
    eventName,
    ...browserLifecycleContext(),
  });
}

document.addEventListener("visibilitychange", () => recordBrowserLifecycle("visibilitychange"));
document.addEventListener("freeze", () => recordBrowserLifecycle("freeze"));
document.addEventListener("resume", () => recordBrowserLifecycle("resume"));
window.addEventListener("focus", () => recordBrowserLifecycle("focus"));
window.addEventListener("blur", () => recordBrowserLifecycle("blur"));
window.addEventListener("pageshow", () => recordBrowserLifecycle("pageshow"));
window.addEventListener("pagehide", () => recordBrowserLifecycle("pagehide"));

const dpiSafetyPause = new DpiSafetyPause({
  emit: emitEvent,
  pauseAnimation: () => player?.pause("dpi_safety_pause"),
  resetInput: () => arbiter?.reset("dpi_safety_pause"),
  resumeAnimation: () => player?.resume("dpi_scale_stabilized"),
});

function handleHitCoordinatorSafety(event) {
  if (
    event.type === "hitmask_latency_classification_started"
    || event.type === "hitmask_scale_transition_started"
  ) {
    dpiSafetyPause.begin(event.type);
  }
  if (event.type === "hitmask_scale_transition_stabilized") {
    dpiSafetyPause.end(event.type);
  }
  if (event.type === "hitmask_latency_classification_cancelled") {
    dpiSafetyPause.end(event.type, { resume: event.reason !== "window_suspended" });
  }
}

async function sha256(bytes) {
  const payload = bytes instanceof Uint8Array ? bytes : new Uint8Array(bytes);
  const digest = await crypto.subtle.digest("SHA-256", payload);
  return [...new Uint8Array(digest)]
    .map((value) => value.toString(16).padStart(2, "0"))
    .join("")
    .toUpperCase();
}

async function readFixtureFile(relativePath) {
  return new Uint8Array(await invoke("read_pet_package_file", { relativePath }));
}

async function loadPackage() {
  const runtimePaths = await invoke("list_pet_package_files");
  return loadVNextPayload({
    digest: sha256,
    expectedActions: FIRST_RETURN_ACTIONS,
    runtimePaths,
    readyStatus: PRODUCT_RUNTIME_READY_STATUS,
    readFile: readFixtureFile,
  });
}

async function decodeAtlases(result) {
  const decoded = new Map();
  for (const [atlasPath, bytes] of result.atlasBytesByPath) {
    const bitmap = await createImageBitmap(new Blob([bytes], { type: "image/webp" }));
    decoded.set(atlasPath, bitmap);
  }
  return decoded;
}

function drawFallbackShape(targetContext) {
  targetContext.clearRect(0, 0, LOGICAL_WIDTH, LOGICAL_HEIGHT);
  targetContext.fillStyle = "#1E9E8F";
  targetContext.beginPath();
  targetContext.ellipse(96, 142, 48, 42, 0, 0, Math.PI * 2);
  targetContext.fill();
  targetContext.fillStyle = "#F06449";
  targetContext.beginPath();
  targetContext.arc(96, 91, 35, 0, Math.PI * 2);
  targetContext.fill();
  targetContext.fillStyle = "#20242A";
  targetContext.fillRect(80, 86, 6, 6);
  targetContext.fillRect(106, 86, 6, 6);
}

function drawAnimationFrame(targetContext, presentation) {
  targetContext.clearRect(0, 0, LOGICAL_WIDTH, LOGICAL_HEIGHT);
  targetContext.save();
  if (presentation.mirrorX) {
    targetContext.translate(LOGICAL_WIDTH, 0);
    targetContext.scale(-1, 1);
  }
  const { bitmap, rect } = presentation;
  targetContext.drawImage(
    bitmap,
    rect.x,
    rect.y,
    rect.width,
    rect.height,
    0,
    0,
    LOGICAL_WIDTH,
    LOGICAL_HEIGHT,
  );
  targetContext.restore();
}

function presentPreparedFrame(request) {
  const { presentation } = request;
  if (presentation?.kind === "animation") {
    drawAnimationFrame(context, presentation);
  } else if (presentation?.kind === "fallback") {
    drawFallbackShape(context);
  } else {
    throw new Error("prepared_frame_presentation_missing");
  }
  const committedAtMs = performance.now();
  const directionChanged = presentation.kind === "animation"
    && presentation.direction !== lastCommittedDirection;
  if (directionChanged) {
    lastCommittedDirection = presentation.direction;
  }
  if (committedAtMs - sessionStartedAt < 60_000 || frameSequence % 120 === 0 || directionChanged) {
    emitEvent({
      type: "frame_visual_committed",
      direction: presentation.direction ?? null,
      frameId: request.frameId,
      hitRegionSignature: regionSignature(request.rects),
      kind: presentation.kind,
      requestToCommitMs: committedAtMs - presentation.requestedAtMs,
      scale: request.scale,
    });
  }
  if (firstFrameResolve) {
    firstFrameResolve();
    firstFrameResolve = null;
  }
}

function timingForFrame(event, actualAtMs) {
  frameSequence += 1;
  if (timingCursor?.instanceId !== event.instanceId) {
    timingCursor = { instanceId: event.instanceId, expectedAtMs: actualAtMs };
  }
  const row = {
    actionId: event.actionId,
    instanceId: event.instanceId,
    frameId: event.frame.id,
    frameIndex: event.frameIndex,
    durationMs: event.frame.durationMs,
    expectedAtMs: timingCursor.expectedAtMs,
    actualAtMs,
    driftMs: actualAtMs - timingCursor.expectedAtMs,
  };
  timingCursor.expectedAtMs += event.frame.durationMs;
  frameTimings.push(row);
  if (frameTimings.length > 20_000) {
    frameTimings.shift();
  }
  if (performance.now() - sessionStartedAt < 60_000 || frameSequence % 120 === 0) {
    emitEvent({ type: "frame_timing_sample", sequence: frameSequence, ...row });
  }
  return row;
}

async function verifyAppliedNativeRegion(request) {
  const signature = `${request.scale}:${regionSignature(request.rects)}`;
  if (probedRegionSignatures.has(signature)) {
    return;
  }
  probedRegionSignatures.add(signature);
  const probe = chooseNativeProbePoints({
    rects: request.rects,
    logicalWidth: request.logicalWidth,
    logicalHeight: request.logicalHeight,
    scale: request.scale,
  });
  const actual = await invoke("probe_pet_hit_region", { points: probe.points });
  emitEvent({
    type: "hitmask_classifier_probe",
    frameId: request.frameId,
    signature,
    points: probe.points,
    expected: probe.expected,
    actual,
  });
  if (actual.length !== probe.expected.length || actual.some((value, index) => value !== probe.expected[index])) {
    throw new Error("P0_NATIVE_HIT_PROBE_MISMATCH");
  }
}

function prepareHitMaskRequest({ frameId, durationMs, presentation }) {
  let rects;
  let resolvedPresentation = presentation;
  if (presentation.kind === "animation") {
    if (!Array.isArray(presentation.hitMaskRuns) || presentation.hitMaskRuns.length === 0) {
      throw new Error("packaged_hitmask_missing");
    }
    const directionalFrame = resolveDirectionalFrame({
      direction: presentation.direction,
      hitMaskRuns: presentation.hitMaskRuns,
      logicalWidth: LOGICAL_WIDTH,
    });
    rects = directionalFrame.rects;
    resolvedPresentation = {
      ...presentation,
      mirrorX: directionalFrame.mirrorX,
    };
  } else if (presentation.kind === "fallback") {
    drawFallbackShape(analysisContext);
    const pixels = analysisContext.getImageData(0, 0, LOGICAL_WIDTH, LOGICAL_HEIGHT).data;
    rects = alphaToRegionRuns(
      pixels,
      LOGICAL_WIDTH,
      LOGICAL_HEIGHT,
      ALPHA_THRESHOLD,
    );
  } else {
    throw new Error("unknown_prepared_frame_kind");
  }
  if (rects.length === 0) {
    throw new Error("empty_hitmask");
  }
  const scale = window.devicePixelRatio;
  dpiWatcher?.observe(scale, { reason: "animation_frame" });
  return {
    frameId,
    durationMs,
    logicalWidth: LOGICAL_WIDTH,
    logicalHeight: LOGICAL_HEIGHT,
    scale,
    rects,
    presentation: resolvedPresentation,
  };
}

async function applyPreparedFrame(request) {
  lastHitMaskFrame = request;
  const result = await hitCoordinator.applyFrame(request);
  if (
    result.status === "coalesced"
    && dpiWatcher !== undefined
    && !dpiWatcher.snapshot.transitionActive
    && hitCoordinator.snapshot.transitionActive
  ) {
    await hitCoordinator.completeScaleTransition({ scale: request.scale });
  }
}

async function renderFrame(event) {
  const actualAtMs = performance.now();
  timingForFrame(event, actualAtMs);
  const bitmap = bitmaps.get(event.frame.atlasPath);
  if (!bitmap) {
    await renderFallback("atlas_bitmap_missing");
    return;
  }
  const request = prepareHitMaskRequest({
    frameId: event.frame.id,
    durationMs: event.frame.durationMs,
    presentation: {
      bitmap,
      direction,
      hitMaskRuns: event.frame.hitMaskRuns,
      kind: "animation",
      rect: event.frame.rect,
      requestedAtMs: actualAtMs,
    },
  });
  await applyPreparedFrame(request);
}

async function renderFallback(reason) {
  if (fallbackActive) {
    return;
  }
  fallbackActive = true;
  emitEvent({ type: "pet_package_fallback_loaded", reason });
  try {
    const request = prepareHitMaskRequest({
      frameId: `safe-fallback-${reason}`,
      durationMs: 1_000,
      presentation: {
        kind: "fallback",
        requestedAtMs: performance.now(),
      },
    });
    await applyPreparedFrame(request);
  } finally {
    fallbackActive = false;
  }
}

function createRuntime(actions) {
  player = new FramePlayer({
    scheduler: createBrowserScheduler(),
    onFrame: (event) => {
      void renderFrame(event).catch((error) => {
        machine?.degrade(error instanceof Error ? error.message : String(error));
        void renderFallback("frame_render_failed");
      });
    },
    onFinished: (event) => {
      emitEvent({ type: "animation_finished", ...event });
      machine.animationFinished(event.instanceId);
    },
    onTimedOut: (event) => {
      emitEvent({ type: "pet_action_timed_out", ...event });
      machine.animationTimedOut(event.instanceId);
    },
    onIgnoredFinished: (event) => emitEvent({ type: "pet_action_late_finished_ignored", ...event }),
  });

  hitCoordinator = new DynamicHitCoordinator({
    apply: async (request) => {
      const { presentation, ...nativeRequest } = request;
      const invokeStartedAt = performance.now();
      const nativeResult = await invoke("apply_pet_hit_region", { request: nativeRequest });
      const invokeElapsedMs = performance.now() - invokeStartedAt;
      const result = {
        ...nativeResult,
        invokeElapsedMs,
        ipcOverheadMs: Math.max(0, invokeElapsedMs - nativeResult.latencyMs),
      };
      if (
        Number.isFinite(result.nativeScaleFactor)
        && result.nativeScaleFactor > 0
        && result.nativeScaleFactor !== nativeRequest.scale
      ) {
        emitEvent({
          type: "native_hit_region_scale_changed",
          frameId: nativeRequest.frameId,
          nativeScale: result.nativeScaleFactor,
          requestScale: nativeRequest.scale,
        });
        dpiWatcher?.observe(result.nativeScaleFactor, { reason: "native_hit_region" });
        return result;
      }
      await verifyAppliedNativeRegion(nativeRequest);
      if (
        presentation?.kind === "animation"
        && presentation.direction !== lastVerifiedDirection
      ) {
        lastVerifiedDirection = presentation.direction;
        emitEvent({
          type: "directional_hitmask_verified",
          direction: presentation.direction,
          frameId: nativeRequest.frameId,
          hitRegionSignature: regionSignature(nativeRequest.rects),
        });
      }
      return result;
    },
    commit: (request) => presentPreparedFrame(request),
    emit: (event) => {
      handleHitCoordinatorSafety(event);
      hitmaskSequence += 1;
      if (event.type !== "hitmask_applied" || performance.now() - sessionStartedAt < 60_000 || hitmaskSequence % 120 === 0) {
        emitEvent(event);
      }
    },
    degrade: (reason, details = {}) => {
      if (p0Failure !== null) {
        return;
      }
      p0Failure = reason;
      p0FailureDetails = { ...details };
      dpiSafetyPause.end("p0_runtime_stopped", { resume: false });
      machine?.degrade(reason);
      arbiter?.reset("p0_hitmask_failure");
      emitEvent({ type: "p0_runtime_stopped", reason, details: p0FailureDetails });
      void invoke("pet_runtime_failed", { reason }).catch(() => {});
    },
    classificationGraceMs: DPI_LATENCY_CLASSIFICATION_GRACE_MS,
    scheduler: createBrowserScheduler(),
  });

  dpiWatcher = new DpiTransitionWatcher({
    initialScale: window.devicePixelRatio,
    scheduler: createBrowserScheduler(),
    settleMs: DPI_SETTLE_MS,
    emit: emitEvent,
    onBegin: (event) => hitCoordinator.beginScaleTransition(event),
    onSettle: async ({ scale }) => {
      if (lastHitMaskFrame !== null) {
        await hitCoordinator.applyFrame({ ...lastHitMaskFrame, scale });
      }
      await hitCoordinator.completeScaleTransition({ scale });
    },
  });

  machine = new PetRuntimeMachine({
    baseActions: {
      working: "working_play_loop_a",
      awake_rest: "awake_rest_loop",
      sleeping: "sleeping_loop",
    },
    ackActions: {
      working: "working_ack",
      awake_rest: "rest_ack",
      sleeping: "sleep_ack",
    },
    play: (actionId) => {
      const action = actions.get(actionId);
      if (!action) {
        throw new Error(`fixture_action_missing:${actionId}`);
      }
      return player.play(action);
    },
    stop: (reason) => player.stop(reason),
    emit: (event) => {
      emitEvent(event);
      companionScheduler?.handleRuntimeEvent(event);
    },
    requestAuthoritativeSnapshot: () => {
      queueMicrotask(() => {
        authoritativeRevision += 1;
        machine.applyAuthoritativeBaseState(authoritativeBaseState, authoritativeRevision);
      });
    },
  });

  companionScheduler = new CompanionActionScheduler({
    actions,
    scheduler: createBrowserScheduler(),
    random: createSeededRandom(FIRST_RETURN_SCHEDULER_SEED),
    emit: emitEvent,
    getRuntimeSnapshot: () => machine.snapshot,
    requestAction: (request) => machine.requestScheduledAction(request),
  });

  arbiter = new PetInputArbiter({
    scheduler: createBrowserScheduler(),
    holdMs: 500,
    clickMoveThresholdPx: 6,
    directionDeadZonePx: 4,
    emit: (event) => {
      emitEvent({ ...event, type: `pet_input_${event.type}` });
      if (event.type === "drag_direction") {
        direction = event.direction;
      }
      machine.handleInput(event);
    },
  });
}

function queueWindowMove(deltaX, deltaY) {
  if (deltaX === 0 && deltaY === 0) {
    return;
  }
  moveQueue = moveQueue
    .then(() => invoke("move_pet_window", { deltaXCss: deltaX, deltaYCss: deltaY }))
    .catch((error) => emitEvent({ type: "pet_window_move_failed", reason: String(error) }));
}

canvas.addEventListener("pointerdown", (event) => {
  if (dpiSafetyPause.snapshot.active) {
    event.preventDefault();
    return;
  }
  lastPointerScreen = { x: event.screenX, y: event.screenY };
  const accepted = arbiter.pointerDown({
    pointerId: event.pointerId,
    x: event.screenX,
    y: event.screenY,
    button: event.button,
  });
  if (accepted) {
    try {
      canvas.setPointerCapture(event.pointerId);
    } catch (error) {
      emitEvent({ type: "pet_input_capture_failed", reason: String(error) });
      arbiter.pointerCancel({ pointerId: event.pointerId, reason: "pointer_capture_failed" });
    }
  }
  event.preventDefault();
});

canvas.addEventListener("pointermove", (event) => {
  arbiter.pointerMove({ pointerId: event.pointerId, x: event.screenX, y: event.screenY });
  if (arbiter.state === "dragging" && lastPointerScreen) {
    queueWindowMove(event.screenX - lastPointerScreen.x, event.screenY - lastPointerScreen.y);
  }
  lastPointerScreen = { x: event.screenX, y: event.screenY };
});

canvas.addEventListener("pointerup", (event) => {
  arbiter.pointerUp({ pointerId: event.pointerId, x: event.screenX, y: event.screenY });
  if (canvas.hasPointerCapture(event.pointerId)) {
    canvas.releasePointerCapture(event.pointerId);
  }
  lastPointerScreen = null;
});

canvas.addEventListener("pointercancel", (event) => {
  arbiter.pointerCancel({ pointerId: event.pointerId });
  if (canvas.hasPointerCapture(event.pointerId)) {
    canvas.releasePointerCapture(event.pointerId);
  }
  lastPointerScreen = null;
});

canvas.addEventListener("contextmenu", (event) => {
  event.preventDefault();
  if (dpiSafetyPause.snapshot.active) {
    return;
  }
  const token = arbiter.lock("context-menu");
  window.setTimeout(() => arbiter.unlock(token), 250);
});

window.addEventListener("lmm:window-hidden", (event) => {
  dpiWatcher?.cancel("window_hidden");
  hitCoordinator?.suspend();
  dpiSafetyPause.end("window_hidden", { resume: false });
  arbiter?.reset("window_hidden");
  machine?.hide(event.detail?.source ?? "window_hidden");
});

window.addEventListener("lmm:window-shown", () => {
  hitCoordinator?.resume();
  dpiWatcher?.observe(window.devicePixelRatio, { reason: "window_shown" });
  machine?.show();
});

window.addEventListener("lmm:pet-base-state", (event) => {
  const detail = event.detail ?? {};
  if (!["working", "awake_rest", "sleeping"].includes(detail.baseState)) {
    emitEvent({ type: "pet_base_state_rejected", requested: detail.baseState ?? null });
    return;
  }
  authoritativeBaseState = detail.baseState;
  authoritativeRevision = Math.max(authoritativeRevision + 1, Number(detail.revision) || 0);
  machine?.applyAuthoritativeBaseState(authoritativeBaseState, authoritativeRevision);
});

window.addEventListener("resize", () => {
  dpiWatcher?.observe(window.devicePixelRatio, {
    extendSettle: true,
    reason: "window_resize",
  });
});

async function startProductRuntime() {
  try {
    packageResult = await loadPackage();
    if (packageResult.status !== PRODUCT_RUNTIME_READY_STATUS) {
      throw new Error(packageResult.reason || "pet_package_not_ready");
    }
    createRuntime(packageResult.actions);
    bitmaps = await decodeAtlases(packageResult);
    authoritativeRevision = 1;
    machine.applyAuthoritativeBaseState(authoritativeBaseState, authoritativeRevision);
    await firstFrameReady;
    if (p0Failure !== null) {
      throw new Error(`pet_runtime_blocked_by_p0:${p0Failure}`);
    }
    await invoke("pet_runtime_ready", {
      manifestSha256: packageResult.manifestSha256,
      packageTreeSha256: packageResult.packageTreeSha256,
    });
    emitEvent({
      type: "pet_product_runtime_created",
      packageStatus: packageResult.status,
      manifestSha256: packageResult.manifestSha256 ?? null,
      packageTreeSha256: packageResult.packageTreeSha256 ?? null,
      devicePixelRatio: window.devicePixelRatio,
    });
  } catch (error) {
    const reason = error instanceof Error ? error.message : String(error);
    emitEvent({ type: "pet_product_runtime_failed", reason });
    await invoke("pet_runtime_failed", { reason }).catch(() => {});
  }
}

void startProductRuntime();
