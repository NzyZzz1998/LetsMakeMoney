import fixtures from "./fixtures/v105-mini-interaction-fixtures.json";
import {
  createMiniEdgeAutoHideController,
  type MiniEdgeNativeStatus,
  type MiniEdgeTimerScheduler,
} from "../src/features/mini/miniEdgeAutoHide";

function assert(condition: unknown, message: string): asserts condition {
  if (!condition) throw new Error(message);
}

class FakeScheduler implements MiniEdgeTimerScheduler {
  private nextId = 1;
  private callbacks = new Map<number, () => void>();

  set(callback: () => void) {
    const id = this.nextId++;
    this.callbacks.set(id, callback);
    return id;
  }

  clear(id: number) {
    this.callbacks.delete(id);
  }

  pendingCount() {
    return this.callbacks.size;
  }

  firstId() {
    return [...this.callbacks.keys()][0] ?? null;
  }

  fire(id: number | null) {
    if (id === null) return;
    const callback = this.callbacks.get(id);
    this.callbacks.delete(id);
    callback?.();
  }
}

async function settle() {
  await Promise.resolve();
  await Promise.resolve();
}

function nativeStatus(
  dock: MiniEdgeNativeStatus["dock"],
  visibility: MiniEdgeNativeStatus["visibility"] = "expanded",
): MiniEdgeNativeStatus {
  return {
    auto_hide: true,
    dock,
    visibility,
    notice: null,
  };
}

function buildHarness(initialDock: MiniEdgeNativeStatus["dock"]) {
  const scheduler = new FakeScheduler();
  const calls: string[] = [];
  let status = nativeStatus(initialDock);
  const controller = createMiniEdgeAutoHideController({
    scheduler,
    retractDelayMs: 600,
    readStatus: async () => status,
    setRetracted: async (retracted, source) => {
      calls.push(`${retracted ? "retract" : "reveal"}:${source}`);
      status = nativeStatus(status.dock, retracted ? "retracted" : "expanded");
      return status;
    },
    completeDrag: async () => status,
  });
  return {
    controller,
    scheduler,
    calls,
    setStatus(next: MiniEdgeNativeStatus) {
      status = next;
    },
  };
}

assert(fixtures.schema_version === 1, "fixture schema drift");
assert(fixtures.milestone === "V105-M2", "fixture milestone drift");
assert(fixtures.states.length === 8, "the M2 interaction matrix must keep eight states");

for (const dock of ["left", "right"] as const) {
  const harness = buildHarness(dock);
  await harness.controller.initialize();
  assert(harness.scheduler.pendingCount() === 1, `${dock}: an idle docked Mini schedules one timer`);

  harness.controller.pointerEntered();
  await harness.controller.dragStarted();
  harness.setStatus(nativeStatus(dock));
  await harness.controller.dragCompleted();

  assert(harness.controller.snapshot().pointerInside, `${dock}: drag completion retains pointerInside`);
  assert(harness.controller.snapshot().dock === dock, `${dock}: native dock result is applied`);
  assert(
    harness.scheduler.pendingCount() === 0,
    `${dock}: the stale pointer blocks first retraction without pointerleave`,
  );

  harness.controller.pointerLeft();
  assert(harness.scheduler.pendingCount() === 1, `${dock}: pointerleave is currently required`);
  harness.scheduler.fire(harness.scheduler.firstId());
  await settle();
  assert(harness.controller.snapshot().phase === "retracted", `${dock}: pointerleave path retracts`);
  assert(harness.calls.at(-1) === "retract:pointer_leave", `${dock}: semantic retract source is retained`);
  harness.controller.dispose();
}

{
  const harness = buildHarness("left");
  await harness.controller.initialize();
  const staleTimer = harness.scheduler.firstId();
  harness.controller.setLock("menu_open", true);
  harness.scheduler.fire(staleTimer);
  await settle();
  assert(harness.calls.length === 0, "a late timer cannot bypass the menu lock");
  assert(harness.scheduler.pendingCount() === 0, "menu lock clears the timer");

  harness.controller.setLock("modal_open", true);
  harness.controller.setLock("menu_open", false);
  assert(harness.scheduler.pendingCount() === 0, "modal lock remains authoritative");
  harness.controller.setLock("modal_open", false);
  assert(harness.scheduler.pendingCount() === 1, "releasing the final lock schedules one timer");

  harness.controller.setLock("focus_inside", true);
  assert(harness.scheduler.pendingCount() === 0, "focus lock cancels privacy retraction");
  harness.controller.setLock("focus_inside", false);
  assert(harness.scheduler.pendingCount() === 1, "focus release restores one timer");
  harness.controller.dispose();
}

{
  const harness = buildHarness("right");
  await harness.controller.initialize();
  harness.controller.pointerEntered();
  await harness.controller.dragStarted();
  harness.setStatus(nativeStatus("none"));
  await harness.controller.dragCompleted();
  assert(harness.controller.snapshot().dock === "none", "dragging inward clears the dock");
  assert(harness.controller.snapshot().phase === "expanded", "floating Mini stays expanded");
  assert(harness.scheduler.pendingCount() === 0, "floating Mini is never eligible for retraction");
  harness.controller.dispose();
}

console.log(
  "M2 Mini characterization passed: current no-pointerleave failure is reproducible on both edges",
);
