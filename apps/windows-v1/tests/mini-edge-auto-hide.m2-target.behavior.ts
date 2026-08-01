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
}

const scheduler = new FakeScheduler();
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
  setRetracted: async retracted => {
    status = { ...status, visibility: retracted ? "retracted" : "expanded" };
    return status;
  },
  completeDrag: async () => status,
});

await controller.initialize();
controller.pointerEntered();
await controller.dragStarted();
await controller.dragCompleted();

assert(
  scheduler.pendingCount() === 1,
  "M2_RED_NO_POINTERLEAVE_RETRACT: drag release at a docked edge must schedule privacy retraction without waiting for pointerleave",
);

controller.dispose();
console.log("M2 target behavior passed");
