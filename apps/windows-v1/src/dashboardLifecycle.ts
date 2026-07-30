export interface DashboardLifecycleState {
  visible: boolean;
  timersRunning: boolean;
  configurationDirty: boolean;
  mounted: boolean;
  generation: number;
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
    mounted: true,
    generation: 0,
  };
}

export function shouldApplyDashboardRequest(
  state: DashboardLifecycleState,
  requestGeneration: number,
  latestSequence: number,
  incomingSequence: number,
) {
  return (
    state.mounted
    && state.visible
    && state.generation === requestGeneration
    && incomingSequence >= latestSequence
  );
}

export function transitionDashboardLifecycle(
  state: DashboardLifecycleState,
  event: DashboardLifecycleEvent,
): DashboardLifecycleTransition {
  if (event.type === "hidden") {
    if (!state.visible && !state.timersRunning) return { state, effects: [] };
    return {
      state: {
        ...state,
        visible: false,
        timersRunning: false,
        generation: state.generation + 1,
      },
      effects: state.timersRunning ? ["stop_timers"] : [],
    };
  }

  if (event.type === "shown") {
    if (!state.mounted) return { state, effects: [] };
    if (state.visible && state.timersRunning) return { state, effects: [] };
    return {
      state: {
        visible: true,
        timersRunning: true,
        configurationDirty: false,
        mounted: true,
        generation: state.generation + 1,
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

  if (!state.mounted) {
    return { state, effects: [] };
  }
  if (!state.timersRunning) {
    return {
      state: {
        ...state,
        visible: false,
        mounted: false,
        generation: state.generation + 1,
      },
      effects: [],
    };
  }
  return {
    state: {
      ...state,
      visible: false,
      timersRunning: false,
      mounted: false,
      generation: state.generation + 1,
    },
    effects: ["stop_timers"],
  };
}
