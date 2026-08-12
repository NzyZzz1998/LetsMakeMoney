import { isPermanentRectangleFallback } from "./hit-mask.mjs";

export class DynamicHitCoordinator {
  #apply;
  #classificationGraceMs;
  #commit;
  #emit;
  #degrade;
  #queue = Promise.resolve();
  #normalDrainActive = false;
  #pendingNormalFrame = null;
  #pendingLatencyClassification = null;
  #scheduler;
  #suspended = false;
  #generation = 0;
  #stableScale = null;
  #transition = null;

  constructor({
    apply,
    classificationGraceMs = 100,
    commit = () => {},
    emit,
    degrade,
    scheduler = defaultScheduler(),
  }) {
    if (!Number.isFinite(classificationGraceMs) || classificationGraceMs < 0) {
      throw new RangeError("classificationGraceMs must be a non-negative number.");
    }
    this.#apply = apply;
    this.#classificationGraceMs = classificationGraceMs;
    this.#commit = commit;
    this.#emit = emit;
    this.#degrade = degrade;
    this.#scheduler = scheduler;
  }

  get snapshot() {
    return {
      generation: this.#generation,
      latencyClassificationGraceMs: this.#classificationGraceMs,
      normalDrainActive: this.#normalDrainActive,
      pendingNormalFrameId: this.#pendingNormalFrame?.frame.frameId ?? null,
      pendingLatencyClassification: this.#pendingLatencyClassification !== null,
      pendingLatencyFrameId: this.#pendingLatencyClassification?.frameId ?? null,
      stableScale: this.#stableScale,
      transitionActive: this.#transition !== null,
      transitionTargetScale: this.#transition?.toScale ?? null,
    };
  }

  applyFrame(frame) {
    if (this.#transition !== null) {
      if (frame.scale !== this.#transition.toScale) {
        this.#emit({
          type: "hitmask_transition_frame_discarded",
          frameId: frame.frameId,
          frameScale: frame.scale,
          generation: this.#transition.generation,
          targetScale: this.#transition.toScale,
        });
        return Promise.resolve({ status: "discarded_scale_mismatch" });
      }
      this.#transition.latestFrame = frame;
      this.#transition.latestRevision += 1;
      this.#emit({
        type: "hitmask_transition_frame_coalesced",
        frameId: frame.frameId,
        generation: this.#transition.generation,
        revision: this.#transition.latestRevision,
        scale: frame.scale,
      });
      return Promise.resolve({ status: "coalesced" });
    }

    if (this.#suspended) {
      return Promise.resolve({ status: "suspended" });
    }

    const generation = this.#generation;
    const entry = pendingFrame(frame, generation);
    if (!this.#normalDrainActive) {
      this.#normalDrainActive = true;
      this.#queue = this.#queue.then(() => this.#drainNormalFrames(entry));
      return entry.promise;
    }

    if (this.#pendingNormalFrame !== null) {
      const replaced = this.#pendingNormalFrame;
      replaced.resolve({ status: "coalesced_by_backpressure" });
      this.#emit({
        type: "hitmask_normal_frame_coalesced",
        frameId: replaced.frame.frameId,
        generation: replaced.generation,
        replacementFrameId: frame.frameId,
        scale: replaced.frame.scale,
      });
    }
    this.#pendingNormalFrame = entry;
    return entry.promise;
  }

  async #drainNormalFrames(firstEntry) {
    let current = firstEntry;
    let result = { status: "idle" };
    try {
      while (current !== null) {
        result = await this.#applyForGeneration(current.frame, {
          generation: current.generation,
          transitionAttempt: 0,
        });
        current.resolve(result);
        current = this.#pendingNormalFrame;
        this.#pendingNormalFrame = null;
      }
      return result;
    } finally {
      this.#normalDrainActive = false;
    }
  }

  beginScaleTransition({ fromScale, toScale }) {
    if (!validScale(fromScale) || !validScale(toScale)) {
      throw new RangeError("DPI transition scales must be finite positive numbers.");
    }
    this.#discardPendingNormalFrame(
      "scale_transition",
      { status: "discarded_by_scale_transition" },
    );
    this.#generation += 1;
    const previous = this.#transition;
    this.#transition = {
      fromScale,
      generation: this.#generation,
      latestFrame: null,
      latestRevision: 0,
      toScale,
    };
    this.#emit({
      type: "hitmask_scale_transition_started",
      fromScale,
      generation: this.#generation,
      replacedGeneration: previous?.generation ?? null,
      toScale,
    });
    this.#claimPendingLatencyClassification({
      fromScale,
      generation: this.#generation,
      toScale,
    });
    return this.#generation;
  }

  completeScaleTransition({ scale }) {
    const transition = this.#transition;
    if (transition === null) {
      return this.#queue;
    }
    if (scale !== transition.toScale) {
      this.#emit({
        type: "hitmask_scale_transition_completion_ignored",
        actualScale: scale,
        expectedScale: transition.toScale,
        generation: transition.generation,
      });
      return this.#queue;
    }

    const generation = transition.generation;
    this.#queue = this.#queue.then(async () => {
      if (!this.#isCurrentTransition(generation)) {
        return { status: "stale_transition" };
      }
      if (this.#transition.latestFrame === null) {
        this.#emit({
          type: "hitmask_scale_transition_waiting_for_frame",
          generation,
          scale,
        });
        return { status: "waiting_for_frame" };
      }

      let transitionAttempt = 1;
      let coalescedPasses = 0;
      while (this.#isCurrentTransition(generation)) {
        const current = this.#transition;
        const frame = current.latestFrame;
        const revision = current.latestRevision;
        const result = await this.#applyForGeneration(frame, {
          generation,
          transitionAttempt,
        });
        if (result.status === "retry_required") {
          transitionAttempt = 2;
          continue;
        }
        if (result.status !== "applied") {
          return result;
        }
        if (current.latestRevision !== revision && coalescedPasses < 3) {
          coalescedPasses += 1;
          continue;
        }
        this.#stableScale = scale;
        this.#transition = null;
        this.#emit({
          type: "hitmask_scale_transition_stabilized",
          attempts: transitionAttempt,
          frameId: frame.frameId,
          generation,
          scale,
        });
        return { status: "stabilized" };
      }
      return { status: "stale_transition" };
    });
    return this.#queue;
  }

  async #applyForGeneration(frame, { generation, transitionAttempt }) {
    if (this.#suspended) {
      return { status: "suspended" };
    }
    if (generation !== this.#generation) {
      this.#emit({
        type: "hitmask_apply_discarded_stale",
        frameId: frame.frameId,
        frameGeneration: generation,
        generation: this.#generation,
        phase: "before_native_apply",
      });
      return { status: "stale" };
    }
    if (isPermanentRectangleFallback(frame.rects, frame.logicalWidth, frame.logicalHeight)) {
      const details = diagnostics(frame, generation, { latencyMs: 0 }, transitionAttempt, false);
      this.#emit({
        type: "hitmask_update_failed",
        frameId: frame.frameId,
        reason: "permanent_rectangle_fallback",
        ...details,
      });
      this.#degrade("permanent_rectangle_fallback", details);
      return { status: "degraded" };
    }
    try {
      const result = await this.#apply(frame);
      if (generation !== this.#generation) {
        this.#emit({
          type: "hitmask_apply_discarded_stale",
          frameId: frame.frameId,
          frameGeneration: generation,
          generation: this.#generation,
          latencyMs: result.latencyMs,
          phase: "after_native_apply",
          scale: frame.scale,
        });
        return { status: "stale" };
      }
      if (
        Number.isFinite(result.dispatchWaitUs)
        && result.dispatchWaitUs > frame.durationMs * 1_000
      ) {
        this.#emit({
          type: "hitmask_window_thread_dispatch_delayed",
          ...diagnostics(frame, generation, result, transitionAttempt, false),
          dispatchWaitMs: result.dispatchWaitUs / 1_000,
        });
      }
      this.#commit(frame);
      this.#emit({
        type: "hitmask_applied",
        frameId: frame.frameId,
        latencyMs: result.latencyMs,
        scale: frame.scale,
      });
      if (result.latencyMs > frame.durationMs) {
        if (transitionAttempt === 0) {
          const baseDetails = diagnostics(
            frame,
            generation,
            result,
            transitionAttempt,
            false,
          );
          const classification = await this.#classifyNormalLatency(baseDetails);
          if (classification.status === "dpi_transition") {
            this.#emit({
              type: "hitmask_apply_discarded_stale",
              frameId: frame.frameId,
              frameGeneration: generation,
              generation: this.#generation,
              latencyMs: result.latencyMs,
              phase: "dpi_transition_classification",
              scale: frame.scale,
            });
            return { status: "stale" };
          }
          if (classification.status === "cancelled" || this.#suspended) {
            return { status: "suspended" };
          }
          if (generation !== this.#generation) {
            this.#emit({
              type: "hitmask_apply_discarded_stale",
              frameId: frame.frameId,
              frameGeneration: generation,
              generation: this.#generation,
              latencyMs: result.latencyMs,
              phase: "after_latency_classification",
              scale: frame.scale,
            });
            return { status: "stale" };
          }
          const details = {
            ...baseDetails,
            classificationGraceMs: this.#classificationGraceMs,
          };
          this.#emit({ type: "hitmask_latency_exceeded_frame_duration", ...details });
          this.#degrade("hitmask_latency_exceeded_frame_duration", details);
          return { status: "degraded" };
        }
        const recoverable = transitionAttempt === 1;
        const details = diagnostics(
          frame,
          generation,
          result,
          transitionAttempt,
          recoverable,
        );
        this.#emit({ type: "hitmask_latency_exceeded_frame_duration", ...details });
        if (recoverable) {
          return { status: "retry_required" };
        }
        this.#degrade("hitmask_latency_exceeded_frame_duration", details);
        return { status: "degraded" };
      }
      if (transitionAttempt === 0 && this.#stableScale === null) {
        this.#stableScale = frame.scale;
      }
      return { status: "applied" };
    } catch (error) {
      if (generation !== this.#generation) {
        this.#emit({
          type: "hitmask_apply_discarded_stale",
          frameId: frame.frameId,
          frameGeneration: generation,
          generation: this.#generation,
          phase: "native_apply_error",
          reason: errorMessage(error),
        });
        return { status: "stale" };
      }
      const details = {
        frameDurationMs: frame.durationMs,
        frameId: frame.frameId,
        generation,
        scale: frame.scale,
        transitionAttempt,
      };
      this.#emit({
        type: "hitmask_update_failed",
        reason: errorMessage(error),
        ...details,
      });
      this.#degrade("native_hitmask_apply_failed", details);
      return { status: "degraded" };
    }
  }

  #isCurrentTransition(generation) {
    return this.#transition?.generation === generation && this.#generation === generation;
  }

  #classifyNormalLatency(details) {
    if (this.#pendingLatencyClassification !== null) {
      throw new Error("Only one native hit-mask latency classification may be pending.");
    }
    return new Promise((resolve) => {
      const pending = {
        frameId: details.frameId,
        generation: details.generation,
        resolve,
        scale: details.scale,
        timerId: null,
      };
      pending.timerId = this.#scheduler.setTimeout(() => {
        if (this.#pendingLatencyClassification !== pending) {
          return;
        }
        this.#pendingLatencyClassification = null;
        this.#emit({
          type: "hitmask_latency_classification_expired",
          classificationGraceMs: this.#classificationGraceMs,
          frameId: pending.frameId,
          generation: pending.generation,
          scale: pending.scale,
        });
        resolve({ status: "expired" });
      }, this.#classificationGraceMs);
      this.#pendingLatencyClassification = pending;
      this.#emit({
        type: "hitmask_latency_classification_started",
        classificationGraceMs: this.#classificationGraceMs,
        ...details,
      });
    });
  }

  #claimPendingLatencyClassification({ fromScale, generation, toScale }) {
    const pending = this.#pendingLatencyClassification;
    if (
      pending === null
      || pending.generation !== generation - 1
      || pending.scale !== fromScale
      || fromScale === toScale
    ) {
      return false;
    }
    this.#scheduler.clearTimeout(pending.timerId);
    this.#pendingLatencyClassification = null;
    this.#emit({
      type: "hitmask_latency_claimed_by_dpi_transition",
      frameId: pending.frameId,
      frameGeneration: pending.generation,
      fromScale,
      generation,
      toScale,
    });
    pending.resolve({ status: "dpi_transition" });
    return true;
  }

  #cancelPendingLatencyClassification(reason) {
    const pending = this.#pendingLatencyClassification;
    if (pending === null) {
      return false;
    }
    this.#scheduler.clearTimeout(pending.timerId);
    this.#pendingLatencyClassification = null;
    this.#emit({
      type: "hitmask_latency_classification_cancelled",
      frameId: pending.frameId,
      generation: pending.generation,
      reason,
      scale: pending.scale,
    });
    pending.resolve({ status: "cancelled" });
    return true;
  }

  suspend() {
    this.#suspended = true;
    this.#discardPendingNormalFrame("window_suspended", { status: "suspended" });
    this.#generation += 1;
    this.#transition = null;
    this.#cancelPendingLatencyClassification("window_suspended");
  }

  resume() {
    this.#suspended = false;
  }

  flush() {
    return this.#queue;
  }

  #discardPendingNormalFrame(reason, result) {
    const pending = this.#pendingNormalFrame;
    if (pending === null) {
      return false;
    }
    this.#pendingNormalFrame = null;
    pending.resolve(result);
    this.#emit({
      type: "hitmask_normal_frame_discarded",
      frameId: pending.frame.frameId,
      generation: pending.generation,
      reason,
      scale: pending.frame.scale,
    });
    return true;
  }
}

function pendingFrame(frame, generation) {
  let resolve;
  const promise = new Promise((next) => {
    resolve = next;
  });
  return { frame, generation, promise, resolve };
}

function errorMessage(error) {
  return error instanceof Error ? error.message : String(error);
}

function diagnostics(frame, generation, result, transitionAttempt, recoverable) {
  return {
    frameId: frame.frameId,
    frameDurationMs: frame.durationMs,
    generation,
    latencyMs: result.latencyMs,
    recoverable,
    scale: frame.scale,
    transitionAttempt,
    ...timingDetails(result),
  };
}

function timingDetails(result) {
  const fields = [
    "invokeElapsedMs",
    "ipcOverheadMs",
    "dispatchWaitUs",
    "nativeOperationUs",
    "prepareUs",
    "windowHandleUs",
    "bridgeUpdateUs",
    "subclassInstallUs",
    "regionBuildUs",
    "setWindowRegionUs",
    "dpiQueryUs",
  ];
  return Object.fromEntries(
    fields
      .filter((field) => Number.isFinite(result[field]))
      .map((field) => [field, result[field]]),
  );
}

function validScale(scale) {
  return Number.isFinite(scale) && scale > 0;
}

function defaultScheduler() {
  return {
    clearTimeout: (timerId) => globalThis.clearTimeout(timerId),
    setTimeout: (callback, delayMs) => globalThis.setTimeout(callback, delayMs),
  };
}
