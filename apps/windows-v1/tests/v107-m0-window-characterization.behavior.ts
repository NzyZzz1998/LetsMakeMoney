import fixtures from "./fixtures/v107-m0-window-characterization.json";
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

assert(fixtures.schema_version === 1, "M0 fixture schema drift");
assert(fixtures.milestone === "V107-M0", "M0 fixture milestone drift");
assert(fixtures.first_launch_topmost.length === 4, "topmost matrix must retain four entries");
assert(
  fixtures.mini_workbench_entry_states.map(item => item.state).join(",")
    === "expanded,privacy_retracted,hidden_by_user,not_present",
  "Mini/Workbench restoration matrix drift",
);
assert(fixtures.auto_hide_states.length === 6, "auto-hide state matrix drift");
assert(fixtures.drag_contract.current === "move_clamped_each_frame", "current drag red light drift");
assert(fixtures.drag_contract.target === "move_free_finalize_recover", "target drag contract drift");
assert(fixtures.drag_contract.privacy_tab_is_not_lost_window, "privacy tab must not be treated as lost");

const scheduler = new FakeScheduler();
let status: MiniEdgeNativeStatus = {
  auto_hide: true,
  dock: "none",
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
controller.setLock("focus_inside", true);
await controller.dragStarted();
status = { ...status, dock: "right" };
await controller.dragCompleted();
assert(!controller.snapshot().pointerInside, "drag completion must discard stale pointer intent");
assert(!controller.snapshot().locks.focus_inside, "drag completion must discard stale focus ownership");
assert(scheduler.pendingCount() === 1, "first docking must schedule retraction without pointerleave");

controller.setLock("menu_open", true);
controller.setLock("modal_open", true);
assert(scheduler.pendingCount() === 0, "menu/modal locks must cancel privacy retraction");
controller.setLock("menu_open", false);
assert(scheduler.pendingCount() === 0, "modal lock remains authoritative");
controller.setLock("modal_open", false);
assert(scheduler.pendingCount() === 1, "releasing final lock restores one timer");
controller.dispose();

console.log("v1.0.7 M0 window characterization passed");
