const BASE_ACTIONS = Object.freeze({
  working: "working_loop",
  awake_rest: "awake_rest_loop",
  sleeping: "sleeping_loop",
});

const ACK_ACTIONS = Object.freeze({
  working: "working_ack",
  awake_rest: "rest_ack",
  sleeping: "sleep_ack",
});

export class PetRuntimeMachine {
  #play;
  #stop;
  #emit;
  #requestAuthoritativeSnapshot;
  #baseState = "awake_rest";
  #actionLayer = "base_loop";
  #inputState = "idle";
  #windowState = "visible";
  #activeAction = null;
  #authoritativeRevision = 0;
  #waitingForFreshSnapshot = false;
  #baseActions;
  #ackActions;

  constructor({
    play,
    stop,
    emit,
    requestAuthoritativeSnapshot,
    baseActions = BASE_ACTIONS,
    ackActions = ACK_ACTIONS,
  }) {
    this.#play = play;
    this.#stop = stop;
    this.#emit = emit;
    this.#requestAuthoritativeSnapshot = requestAuthoritativeSnapshot;
    this.#baseActions = Object.freeze({ ...baseActions });
    this.#ackActions = Object.freeze({ ...ackActions });
  }

  get snapshot() {
    return {
      baseState: this.#baseState,
      actionLayer: this.#actionLayer,
      inputState: this.#inputState,
      windowState: this.#windowState,
      activeAction: this.#activeAction === null ? null : { ...this.#activeAction },
      authoritativeRevision: this.#authoritativeRevision,
    };
  }

  applyAuthoritativeBaseState(baseState, revision) {
    if (!Object.hasOwn(this.#baseActions, baseState) || revision <= this.#authoritativeRevision) {
      return false;
    }
    this.#baseState = baseState;
    this.#authoritativeRevision = revision;
    this.#emit({ type: "base_state_changed", baseState, revision });

    if (this.#waitingForFreshSnapshot) {
      this.#waitingForFreshSnapshot = false;
      this.#windowState = "visible";
      this.#inputState = "idle";
      this.#requestBaseLoop();
    } else if (this.#inputState === "idle" && this.#windowState === "visible") {
      this.#requestBaseLoop();
    }
    return true;
  }

  handleInput(event) {
    if (this.#windowState !== "visible") {
      return false;
    }
    switch (event.type) {
      case "click":
        if (this.#inputState !== "idle") {
          return false;
        }
        this.#actionLayer = "ack";
        this.#requestAction(this.#ackActions[this.#baseState]);
        return true;
      case "drag_started":
        this.#inputState = "dragging";
        this.#actionLayer = "drag_transition";
        this.#requestAction("run_prepare");
        return true;
      case "drag_direction":
        if (this.#inputState !== "dragging") {
          return false;
        }
        this.#emit({ type: "drag_direction_changed", direction: event.direction });
        return true;
      case "drag_released":
        if (this.#inputState !== "dragging") {
          return false;
        }
        this.#actionLayer = "drag_transition";
        this.#requestAction("run_stop");
        return true;
      default:
        return false;
    }
  }

  requestScheduledAction({ actionId, baseState, layer }) {
    if (
      this.#windowState !== "visible"
      || this.#inputState !== "idle"
      || this.#actionLayer !== "base_loop"
      || this.#baseState !== baseState
      || !["base_loop", "ambient"].includes(layer)
      || typeof actionId !== "string"
      || actionId.length === 0
    ) {
      return false;
    }
    this.#actionLayer = layer;
    this.#requestAction(actionId);
    return true;
  }

  animationFinished(instanceId) {
    if (this.#activeAction?.instanceId !== instanceId) {
      this.#emit({
        type: "late_animation_finished_ignored",
        instanceId,
        currentInstanceId: this.#activeAction?.instanceId ?? null,
      });
      return false;
    }

    const actionId = this.#activeAction.actionId;
    this.#emit({ type: "animation_finished", actionId, instanceId });
    if (actionId === "run_prepare") {
      this.#actionLayer = "drag_loop";
      this.#requestAction("run_loop");
    } else if (actionId === "run_stop") {
      this.#inputState = "idle";
      this.#requestBaseLoop();
    } else {
      this.#requestBaseLoop();
    }
    return true;
  }

  animationTimedOut(instanceId) {
    if (this.#activeAction?.instanceId !== instanceId) {
      return false;
    }
    this.#emit({ type: "animation_timed_out", ...this.#activeAction });
    this.#inputState = "idle";
    this.#requestBaseLoop();
    return true;
  }

  hide(reason = "window_hidden") {
    this.#stop(reason);
    this.#activeAction = null;
    this.#inputState = "idle";
    this.#windowState = "hidden";
    this.#waitingForFreshSnapshot = false;
    this.#emit({ type: "window_hidden", reason });
  }

  show() {
    if (this.#windowState !== "hidden") {
      return false;
    }
    this.#waitingForFreshSnapshot = true;
    this.#requestAuthoritativeSnapshot();
    this.#emit({ type: "authoritative_snapshot_requested", afterRevision: this.#authoritativeRevision });
    return true;
  }

  degrade(reason) {
    this.#stop(reason);
    this.#activeAction = null;
    this.#inputState = "idle";
    this.#windowState = "degraded";
    this.#emit({ type: "safe_static_fallback_requested", reason });
  }

  #requestBaseLoop() {
    this.#actionLayer = "base_loop";
    this.#requestAction(this.#baseActions[this.#baseState]);
  }

  #requestAction(actionId) {
    const instanceId = this.#play(actionId);
    this.#activeAction = { actionId, instanceId };
    this.#emit({
      type: "action_started",
      actionId,
      instanceId,
      layer: this.#actionLayer,
      baseState: this.#baseState,
    });
  }
}
