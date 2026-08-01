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

  fire(id: number) {
    const callback = this.callbacks.get(id);
    this.callbacks.delete(id);
    callback?.();
  }

  firstId() {
    return [...this.callbacks.keys()][0] ?? null;
  }
}

const scheduler = new FakeScheduler();
const nativeCalls: string[] = [];
let status: MiniEdgeNativeStatus = {
  auto_hide: true,
  dock: "right",
  visibility: "expanded",
  notice: null,
};

const controller = createMiniEdgeAutoHideController({
  scheduler,
  retractDelayMs: 600,
  readStatus: async () => status,
  setRetracted: async (retracted, source) => {
    nativeCalls.push(`${retracted ? "retract" : "reveal"}:${source}`);
    status = { ...status, visibility: retracted ? "retracted" : "expanded" };
    return status;
  },
  completeDrag: async () => status,
});

await controller.initialize();
assert(controller.snapshot().phase === "retract_pending", "a restored dock schedules privacy");
assert(scheduler.pendingCount() === 1, "only one retract timer exists after initialization");

controller.pointerLeft();
assert(scheduler.pendingCount() === 1, "repeated pointer leave replaces rather than duplicates timer");
const staleTimer = scheduler.firstId();
controller.pointerEntered();
assert(scheduler.pendingCount() === 0, "pointer entry cancels the pending timer");
if (staleTimer !== null) scheduler.fire(staleTimer);
await Promise.resolve();
assert(nativeCalls.length === 0, "a late canceled timer cannot retract the window");

controller.pointerLeft();
const activeTimer = scheduler.firstId();
assert(activeTimer !== null, "pointer leave schedules a new timer");
if (activeTimer !== null) scheduler.fire(activeTimer);
await Promise.resolve();
await Promise.resolve();
assert(controller.snapshot().phase === "retracted", "the active timer retracts after 600ms");
assert(nativeCalls.at(-1) === "retract:pointer_leave", "retraction records a semantic trigger");

controller.setLock("focus_inside", true);
await Promise.resolve();
await Promise.resolve();
assert(controller.snapshot().phase === "retracted", "ordinary focus must not reveal a retracted Mini");
assert(nativeCalls.at(-1) === "retract:pointer_leave", "ordinary focus does not call native reveal");
assert(!controller.snapshot().locks.focus_inside, "ordinary focus cannot strand a lock on the privacy tab");

controller.setLock("focus_inside", false);
assert(scheduler.pendingCount() === 0, "a retracted Mini never schedules a second retract timer");
await controller.reveal("window_shown");
assert(controller.snapshot().phase === "expanded", "an explicit shown event reveals the Mini");
assert(nativeCalls.at(-1) === "reveal:window_shown", "explicit reveal retains its semantic source");
controller.setLock("menu_open", true);
controller.pointerLeft();
assert(scheduler.pendingCount() === 0, "an open menu blocks privacy retraction");
controller.setLock("menu_open", false);
assert(scheduler.pendingCount() === 1, "releasing the final lock restores one timer");

await controller.dragStarted();
assert(controller.snapshot().locks.dragging, "drag start owns an interaction lock");
assert(scheduler.pendingCount() === 0, "drag start cancels the timer");
status = {
  auto_hide: true,
  dock: "none",
  visibility: "expanded",
  notice: null,
};
await controller.dragCompleted();
assert(controller.snapshot().dock === "none", "dragging inward can return to floating");
assert(controller.snapshot().phase === "expanded", "floating Mini remains fully visible");

status = {
  auto_hide: true,
  dock: "left",
  visibility: "expanded",
  notice: null,
};
controller.pointerEntered();
await controller.dragStarted();
await controller.dragCompleted();
assert(!controller.snapshot().pointerInside, "drag completion discards stale pre-drag pointer intent");
assert(scheduler.pendingCount() === 1, "first edge docking schedules retract without pointerleave");
const dragTimer = scheduler.firstId();
assert(dragTimer !== null, "drag completion exposes one cancellable timer");
if (dragTimer !== null) scheduler.fire(dragTimer);
await Promise.resolve();
await Promise.resolve();
const callsAfterDragRetract = nativeCalls.length;
controller.pointerEntered();
await Promise.resolve();
assert(
  controller.snapshot().phase === "retracted" && nativeCalls.length === callsAfterDragRetract,
  "the stationary post-drag pointer cannot immediately reveal the moved privacy tab",
);
controller.pointerLeft();
controller.pointerEntered();
await Promise.resolve();
await Promise.resolve();
assert(controller.snapshot().phase === "expanded", "a fresh leave-enter sequence reveals the privacy tab");

status = {
  auto_hide: false,
  dock: "none",
  visibility: "expanded",
  notice: null,
};
await controller.refresh();
assert(!controller.snapshot().autoHide, "a cross-window preference refresh disables privacy");
assert(
  controller.snapshot().dock === "none"
    && controller.snapshot().phase === "expanded",
  "disabling privacy exits the retracted surface and restores full Mini content",
);
assert(scheduler.pendingCount() === 0, "disabled privacy cannot leave a retract timer behind");

controller.dispose();
assert(scheduler.pendingCount() === 0, "dispose clears any remaining timer");

let fallbackReported = false;
const fallbackController = createMiniEdgeAutoHideController({
  scheduler: new FakeScheduler(),
  readStatus: async () => ({
    auto_hide: true,
    dock: "none",
    visibility: "expanded",
    notice: "fallback",
  }),
  setRetracted: async () => {
    throw new Error("unexpected native transition");
  },
  completeDrag: async () => {
    throw new Error("unexpected drag completion");
  },
  onError: () => {
    fallbackReported = true;
  },
});
await fallbackController.initialize();
assert(fallbackReported, "native monitor fallback produces non-blocking user feedback");
assert(
  fallbackController.snapshot().dock === "none"
    && fallbackController.snapshot().phase === "expanded",
  "native monitor fallback remains fully visible and clears the dock",
);
fallbackController.dispose();

const lateScheduler = new FakeScheduler();
let resolveLateRetract: ((status: MiniEdgeNativeStatus) => void) | null = null;
const lateController = createMiniEdgeAutoHideController({
  scheduler: lateScheduler,
  retractDelayMs: 600,
  readStatus: async () => ({
    auto_hide: true,
    dock: "right",
    visibility: "expanded",
    notice: null,
  }),
  setRetracted: async retracted => {
    if (!retracted) {
      return {
        auto_hide: true,
        dock: "right",
        visibility: "expanded",
        notice: null,
      };
    }
    return await new Promise<MiniEdgeNativeStatus>(resolve => {
      resolveLateRetract = resolve;
    });
  },
  completeDrag: async () => ({
    auto_hide: true,
    dock: "right",
    visibility: "expanded",
    notice: null,
  }),
});
await lateController.initialize();
const lateTimer = lateScheduler.firstId();
assert(lateTimer !== null, "the late-result fixture schedules one retract timer");
if (lateTimer !== null) lateScheduler.fire(lateTimer);
await Promise.resolve();
assert(lateController.snapshot().phase === "retracted", "the native retract starts optimistically");
lateController.pointerEntered();
await Promise.resolve();
await Promise.resolve();
assert(lateController.snapshot().phase === "expanded", "pointer entry reveals during an in-flight retract");
resolveLateRetract?.({
  auto_hide: true,
  dock: "right",
  visibility: "retracted",
  notice: null,
});
await Promise.resolve();
await Promise.resolve();
assert(
  lateController.snapshot().phase === "expanded",
  "a stale native retract result cannot overwrite the newer reveal",
);
lateController.dispose();

console.log("mini edge auto-hide behavior: 37/37 passed");
