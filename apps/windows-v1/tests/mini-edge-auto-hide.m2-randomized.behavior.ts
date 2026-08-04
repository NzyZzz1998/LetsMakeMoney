import {
  createMiniEdgeAutoHideController,
  type MiniEdgeNativeStatus,
  type MiniEdgeTimerScheduler,
} from "../src/features/mini/miniEdgeAutoHide";

const BASE_SEED = 0x1070_0002;
const SEQUENCE_COUNT = 10_000;
const STEPS_PER_SEQUENCE = 10;

function assert(condition: unknown, message: string): asserts condition {
  if (!condition) throw new Error(message);
}

class DeterministicScheduler implements MiniEdgeTimerScheduler {
  private nextId = 1;
  private active = new Map<number, () => void>();
  private stale: Array<() => void> = [];

  set(callback: () => void) {
    const id = this.nextId++;
    this.active.set(id, callback);
    return id;
  }

  clear(id: number) {
    const callback = this.active.get(id);
    if (callback) this.stale.push(callback);
    this.active.delete(id);
  }

  pendingCount() {
    return this.active.size;
  }

  fireActive() {
    const entry = this.active.entries().next().value as [number, () => void] | undefined;
    if (!entry) return;
    this.active.delete(entry[0]);
    entry[1]();
  }

  fireStale() {
    this.stale.shift()?.();
  }
}

function lcg(seed: number) {
  let state = seed >>> 0;
  return () => {
    state = (Math.imul(state, 1_664_525) + 1_013_904_223) >>> 0;
    return state;
  };
}

function status(
  dock: MiniEdgeNativeStatus["dock"],
  autoHide = true,
  visibility: MiniEdgeNativeStatus["visibility"] = "expanded",
): MiniEdgeNativeStatus {
  return {
    auto_hide: autoHide,
    dock,
    visibility: dock === "none" ? "expanded" : visibility,
    notice: null,
  };
}

async function settle() {
  await Promise.resolve();
  await Promise.resolve();
}

for (let sequence = 0; sequence < SEQUENCE_COUNT; sequence += 1) {
  const seed = (BASE_SEED + sequence) >>> 0;
  const random = lcg(seed);
  const scheduler = new DeterministicScheduler();
  let native = status((random() & 1) === 0 ? "left" : "right");
  let nativeCalls = 0;
  let dragging = false;
  const controller = createMiniEdgeAutoHideController({
    scheduler,
    retractDelayMs: 600,
    readStatus: async () => native,
    setRetracted: async retracted => {
      nativeCalls += 1;
      native = status(native.dock, native.auto_hide, retracted ? "retracted" : "expanded");
      return native;
    },
    completeDrag: async () => native,
  });

  await controller.initialize();
  for (let step = 0; step < STEPS_PER_SEQUENCE; step += 1) {
    const action = random() % 12;
    try {
      if (action === 0) controller.pointerEntered();
      else if (action === 1) controller.pointerLeft();
      else if (action >= 2 && action <= 4) {
        const lock = action === 2 ? "focus_inside" : action === 3 ? "menu_open" : "modal_open";
        controller.setLock(lock, (random() & 1) === 1);
      } else if (action === 5 && !dragging) {
        dragging = true;
        await controller.dragStarted();
      } else if (action === 6 && dragging) {
        const dockChoice = random() % 3;
        native = status(dockChoice === 0 ? "none" : dockChoice === 1 ? "left" : "right");
        await controller.dragCompleted();
        dragging = false;
      } else if (action === 7) scheduler.fireActive();
      else if (action === 8) scheduler.fireStale();
      else if (action === 9) await controller.reveal("randomized_sequence");
      else if (action === 10) {
        const autoHide = (random() & 1) === 1;
        native = status(autoHide ? ((random() & 1) === 0 ? "left" : "right") : "none", autoHide);
        await controller.refresh();
      } else if (action === 11 && dragging) {
        native = status((random() & 1) === 0 ? "left" : "right");
        await controller.dragCompleted();
        dragging = false;
      }
      await settle();

      const snapshot = controller.snapshot();
      const context = `seed=${seed} sequence=${sequence} step=${step} action=${action}`;
      assert(scheduler.pendingCount() <= 1, `${context}: duplicate retract timers`);
      if (snapshot.dock === "none" || !snapshot.autoHide || snapshot.phase === "retracted") {
        assert(scheduler.pendingCount() === 0, `${context}: ineligible state retained a timer`);
      }
      if (snapshot.pointerInside || Object.values(snapshot.locks).some(Boolean)) {
        assert(scheduler.pendingCount() === 0, `${context}: interaction lock retained a timer`);
      }
      if (snapshot.dock === "none") {
        assert(snapshot.phase === "expanded", `${context}: floating Mini was not expanded`);
      }
      assert(nativeCalls <= step + 3, `${context}: transition loop detected`);
    } catch (error) {
      throw new Error(
        `M2 randomized failure seed=${seed} sequence=${sequence} step=${step} action=${action}: ${String(error)}`,
      );
    }
  }
  controller.dispose();
  assert(scheduler.pendingCount() === 0, `seed=${seed}: dispose left a timer`);
}

console.log(
  `M2 randomized behavior passed: ${SEQUENCE_COUNT} deterministic sequences, base_seed=${BASE_SEED}`,
);
