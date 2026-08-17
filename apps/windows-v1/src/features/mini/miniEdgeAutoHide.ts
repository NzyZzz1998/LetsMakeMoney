import type { MiniEdgeDock } from "../../domain/configuration";
import type {
  MiniEdgeStatus as WindowMiniEdgeStatus,
  MiniEdgeVisibility,
} from "../../services/windowService";

export const MINI_EDGE_RETRACT_DELAY_MS = 600;
export const MINI_EDGE_TRANSITION_MS = 180;

export type MiniEdgeNativeStatus = WindowMiniEdgeStatus;
export type MiniEdgePhase =
  | "expanded"
  | "retract_pending"
  | "retracted";
export type MiniEdgeInteractionLock =
  | "dragging"
  | "focus_inside"
  | "menu_open"
  | "modal_open";

export interface MiniEdgeSnapshot {
  autoHide: boolean;
  dock: MiniEdgeDock;
  phase: MiniEdgePhase;
  pointerInside: boolean;
  locks: Record<MiniEdgeInteractionLock, boolean>;
}

export interface MiniEdgeTimerScheduler {
  set(callback: () => void, delayMs: number): number;
  clear(id: number): void;
}

interface ControllerDependencies {
  scheduler?: MiniEdgeTimerScheduler;
  retractDelayMs?: number;
  readStatus(): Promise<MiniEdgeNativeStatus>;
  setRetracted(
    retracted: boolean,
    source: string,
  ): Promise<MiniEdgeNativeStatus>;
  completeDrag(): Promise<MiniEdgeNativeStatus>;
  onChange?(snapshot: MiniEdgeSnapshot): void;
  onError?(error: unknown): void;
  onEvent?(event: string, detail: string): void;
}

export interface MiniEdgeAutoHideController {
  snapshot(): MiniEdgeSnapshot;
  initialize(): Promise<void>;
  refresh(): Promise<void>;
  pointerEntered(): void;
  pointerLeft(): void;
  setLock(lock: MiniEdgeInteractionLock, active: boolean): void;
  dragStarted(): Promise<void>;
  dragCompleted(): Promise<void>;
  reveal(source: string): Promise<void>;
  dispose(): void;
}

function browserScheduler(): MiniEdgeTimerScheduler {
  return {
    set: (callback, delayMs) => window.setTimeout(callback, delayMs),
    clear: id => window.clearTimeout(id),
  };
}

function emptyLocks(): Record<MiniEdgeInteractionLock, boolean> {
  return {
    dragging: false,
    focus_inside: false,
    menu_open: false,
    modal_open: false,
  };
}

export function createMiniEdgeAutoHideController(
  dependencies: ControllerDependencies,
): MiniEdgeAutoHideController {
  const scheduler = dependencies.scheduler ?? browserScheduler();
  const delay = dependencies.retractDelayMs ?? MINI_EDGE_RETRACT_DELAY_MS;
  let state: MiniEdgeSnapshot = {
    autoHide: true,
    dock: "none",
    phase: "expanded",
    pointerInside: false,
    locks: emptyLocks(),
  };
  let timer: number | null = null;
  let generation = 0;
  let dragOperationGeneration = 0;
  let disposed = false;
  let pointerEntryArmed = true;

  const publish = () => {
    dependencies.onChange?.({
      ...state,
      locks: { ...state.locks },
    });
  };

  const emit = (event: string, source: string) => {
    dependencies.onEvent?.(
      event,
      `side=${state.dock} phase=${state.phase} source=${source} generation=${generation}`,
    );
  };

  const clearTimer = (source: string) => {
    generation += 1;
    if (timer !== null) {
      scheduler.clear(timer);
      timer = null;
      emit("mini.edge.retract.cancelled", source);
    }
  };

  const hasLock = () => Object.values(state.locks).some(Boolean);
  const eligible = () =>
    !disposed
    && state.autoHide
    && state.dock !== "none"
    && state.phase !== "retracted"
    && !state.pointerInside
    && !hasLock();

  const applyNative = (status: MiniEdgeNativeStatus) => {
    clearTimer("native_status");
    state = {
      ...state,
      autoHide: status.auto_hide,
      dock: status.dock,
      phase: status.visibility,
    };
    publish();
    if (status.notice === "fallback") {
      emit("mini.edge.fallback", "native_status");
      dependencies.onError?.(new Error("mini_edge_fallback"));
    }
  };

  const scheduleRetract = (source: string) => {
    clearTimer(source);
    if (!eligible()) {
      if (state.phase === "retract_pending") {
        state = { ...state, phase: "expanded" };
        publish();
      }
      return;
    }
    const expectedGeneration = generation;
    state = { ...state, phase: "retract_pending" };
    publish();
    emit("mini.edge.retract.scheduled", source);
    let scheduledTimer = 0;
    scheduledTimer = scheduler.set(() => {
      if (timer === scheduledTimer) timer = null;
      if (
        disposed
        || expectedGeneration !== generation
        || !eligible()
      ) {
        return;
      }
      generation += 1;
      const transitionGeneration = generation;
      state = { ...state, phase: "retracted" };
      publish();
      void dependencies
        .setRetracted(true, source)
        .then(status => {
          if (disposed || transitionGeneration !== generation) return;
          applyNative(status);
          emit("mini.edge.retract.completed", source);
        })
        .catch(error => {
          if (disposed || transitionGeneration !== generation) return;
          state = { ...state, phase: "expanded" };
          publish();
          emit("mini.edge.fallback", source);
          dependencies.onError?.(error);
        });
    }, delay);
    timer = scheduledTimer;
  };

  const reveal = async (source: string) => {
    clearTimer(source);
    const expectedGeneration = generation;
    emit("mini.edge.reveal.requested", source);
    if (state.phase === "expanded" || state.phase === "retract_pending") {
      if (state.phase !== "expanded") {
        state = { ...state, phase: "expanded" };
        publish();
      }
      emit("mini.edge.reveal.completed", source);
      return;
    }
    state = { ...state, phase: "expanded" };
    publish();
    try {
      const status = await dependencies.setRetracted(false, source);
      if (disposed || expectedGeneration !== generation) return;
      applyNative(status);
      emit("mini.edge.reveal.completed", source);
    } catch (error) {
      if (disposed || expectedGeneration !== generation) return;
      emit("mini.edge.fallback", source);
      dependencies.onError?.(error);
    }
  };

  const refresh = async () => {
    const expectedGeneration = generation;
    try {
      const status = await dependencies.readStatus();
      if (disposed || expectedGeneration !== generation) return;
      applyNative(status);
      if (status.visibility === "expanded") scheduleRetract("refresh");
    } catch (error) {
      if (!disposed) dependencies.onError?.(error);
    }
  };

  const setLock = (lock: MiniEdgeInteractionLock, active: boolean) => {
    if (lock === "focus_inside" && active && state.phase === "retracted") return;
    if (state.locks[lock] === active) return;
    state = {
      ...state,
      locks: { ...state.locks, [lock]: active },
    };
    publish();
    if (active) {
      clearTimer(lock);
      if (state.phase === "retract_pending") {
        state = { ...state, phase: "expanded" };
        publish();
      }
    } else {
      scheduleRetract("lock_released");
    }
  };

  return {
    snapshot: () => ({
      ...state,
      locks: { ...state.locks },
    }),
    initialize: refresh,
    refresh,
    pointerEntered() {
      if (state.locks.dragging) return;
      if (!pointerEntryArmed) return;
      pointerEntryArmed = false;
      state = { ...state, pointerInside: true };
      publish();
      void reveal("pointer_enter");
    },
    pointerLeft() {
      pointerEntryArmed = true;
      state = { ...state, pointerInside: false };
      publish();
      scheduleRetract("pointer_leave");
    },
    setLock,
    async dragStarted() {
      dragOperationGeneration += 1;
      setLock("dragging", true);
      await reveal("drag_start");
    },
    async dragCompleted() {
      clearTimer("drag_complete");
      const expectedDragOperation = dragOperationGeneration;
      try {
        const status = await dependencies.completeDrag();
        if (disposed || expectedDragOperation !== dragOperationGeneration) return;
        state = {
          ...state,
          locks: { ...state.locks, dragging: false },
        };
        const docked = status.auto_hide && status.dock !== "none";
        if (docked) {
          pointerEntryArmed = false;
          // Pointer capture leaves the dragged WebView focused after release.
          // Once native docking succeeds, that focus belongs to the completed
          // drag and must not block the first privacy retraction.
          state = {
            ...state,
            pointerInside: false,
            locks: { ...state.locks, focus_inside: false },
          };
        }
        applyNative(status);
        if (status.visibility === "expanded") scheduleRetract("drag_complete");
      } catch (error) {
        state = {
          ...state,
          locks: { ...state.locks, dragging: false },
          phase: "expanded",
        };
        publish();
        emit("mini.edge.fallback", "drag_complete");
        dependencies.onError?.(error);
      }
    },
    reveal,
    dispose() {
      disposed = true;
      clearTimer("dispose");
    },
  };
}
