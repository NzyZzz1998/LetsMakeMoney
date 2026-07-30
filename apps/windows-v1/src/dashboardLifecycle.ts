export interface DashboardLifecycleState {
  visible: boolean;
  timersRunning: boolean;
  configurationDirty: boolean;
}

export type DashboardLifecycleEvent =
  | { type: "hidden" }
  | { type: "shown" }
  | { type: "configuration_updated" }
  | { type: "unmounted" };

export type DashboardLifecycleEffect =
  | "stop_timers"
  | "reset_time_sample"
  | "start_timers"
  | "sync_window_shown"
  | "sync_configuration_updated";

export interface DashboardLifecycleTransition {
  state: DashboardLifecycleState;
  effects: DashboardLifecycleEffect[];
}

export function createDashboardLifecycle(): DashboardLifecycleState {
  return {
    visible: true,
    timersRunning: true,
    configurationDirty: false,
  };
}

export function transitionDashboardLifecycle(
  state: DashboardLifecycleState,
  event: DashboardLifecycleEvent,
): DashboardLifecycleTransition {
  if (event.type === "hidden") {
    if (!state.visible && !state.timersRunning) return { state, effects: [] };
    return {
      state: { ...state, visible: false, timersRunning: false },
      effects: state.timersRunning ? ["stop_timers"] : [],
    };
  }

  if (event.type === "shown") {
    if (state.visible && state.timersRunning) return { state, effects: [] };
    return {
      state: {
        visible: true,
        timersRunning: true,
        configurationDirty: false,
      },
      effects: ["reset_time_sample", "start_timers", "sync_window_shown"],
    };
  }

  if (event.type === "configuration_updated") {
    if (!state.visible) {
      return {
        state: { ...state, configurationDirty: true },
        effects: [],
      };
    }
    return {
      state,
      effects: ["sync_configuration_updated"],
    };
  }

  if (!state.timersRunning) {
    return {
      state: { ...state, visible: false },
      effects: [],
    };
  }
  return {
    state: { ...state, visible: false, timersRunning: false },
    effects: ["stop_timers"],
  };
}
