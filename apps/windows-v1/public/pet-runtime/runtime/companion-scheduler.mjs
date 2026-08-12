function sourceStates(action) {
  return Array.isArray(action.sourceState) ? action.sourceState : [action.sourceState];
}

function actionCandidates(actions, baseState, semanticRole) {
  return [...actions.values()].filter(
    (action) => action.semanticRole === semanticRole && sourceStates(action).includes(baseState),
  );
}

export function createSeededRandom(seed) {
  let value = seed >>> 0;
  return () => {
    value = (Math.imul(value, 1664525) + 1013904223) >>> 0;
    return value / 0x1_0000_0000;
  };
}

export class CompanionActionScheduler {
  #actions;
  #scheduler;
  #random;
  #emit;
  #getRuntimeSnapshot;
  #requestAction;
  #timerId = null;
  #baseState = null;
  #ambientDueAt = new Map();
  #lastBaseActionId = null;
  #consecutiveBaseCount = 0;

  constructor({ actions, scheduler, random = Math.random, emit, getRuntimeSnapshot, requestAction }) {
    this.#actions = actions;
    this.#scheduler = scheduler;
    this.#random = random;
    this.#emit = emit;
    this.#getRuntimeSnapshot = getRuntimeSnapshot;
    this.#requestAction = requestAction;
  }

  get snapshot() {
    return {
      baseState: this.#baseState,
      pendingTimerCount: this.#timerId === null ? 0 : 1,
      lastBaseActionId: this.#lastBaseActionId,
      consecutiveBaseCount: this.#consecutiveBaseCount,
      ambientDueAt: Object.fromEntries(this.#ambientDueAt),
    };
  }

  handleRuntimeEvent(event) {
    if (event.type === "base_state_changed") {
      this.#clearTimer();
      this.#baseState = event.baseState;
      this.#lastBaseActionId = null;
      this.#consecutiveBaseCount = 0;
      for (const action of actionCandidates(this.#actions, event.baseState, "ambient")) {
        this.#ambientDueAt.set(action.id, this.#scheduler.now() + action.cooldownMs);
      }
      return;
    }

    if (event.type === "window_hidden" || event.type === "safe_static_fallback_requested") {
      this.#clearTimer();
      return;
    }

    if (event.type !== "action_started") {
      return;
    }

    this.#clearTimer();
    if (event.layer !== "base_loop") {
      return;
    }
    const action = this.#actions.get(event.actionId);
    if (!action || action.semanticRole !== "base_loop") {
      return;
    }
    this.#baseState = event.baseState;
    if (this.#lastBaseActionId === action.id) {
      this.#consecutiveBaseCount += 1;
    } else {
      this.#lastBaseActionId = action.id;
      this.#consecutiveBaseCount = 1;
    }
    const expectedInstanceId = event.instanceId;
    this.#timerId = this.#scheduler.setTimeout(
      () => this.#onCycleBoundary(expectedInstanceId),
      action.nominalRuntimeMs,
    );
  }

  #onCycleBoundary(expectedInstanceId) {
    this.#timerId = null;
    const runtime = this.#getRuntimeSnapshot();
    if (
      runtime.windowState !== "visible"
      || runtime.inputState !== "idle"
      || runtime.actionLayer !== "base_loop"
      || runtime.baseState !== this.#baseState
      || runtime.activeAction?.instanceId !== expectedInstanceId
    ) {
      this.#emit({ type: "companion_schedule_skipped", reason: "runtime_not_idle_base" });
      return;
    }

    const now = this.#scheduler.now();
    const dueAmbient = actionCandidates(this.#actions, this.#baseState, "ambient")
      .filter((action) => now >= (this.#ambientDueAt.get(action.id) ?? now + action.cooldownMs))
      .sort((left, right) => left.id.localeCompare(right.id))[0];
    if (dueAmbient) {
      this.#ambientDueAt.set(dueAmbient.id, now + dueAmbient.cooldownMs);
      this.#request({
        actionId: dueAmbient.id,
        baseState: this.#baseState,
        layer: "ambient",
        reason: "ambient_cooldown_due",
      });
      return;
    }

    const nextBase = this.#chooseBaseAction();
    if (!nextBase) {
      this.#emit({ type: "companion_schedule_skipped", reason: "base_variant_missing" });
      return;
    }
    this.#request({
      actionId: nextBase.id,
      baseState: this.#baseState,
      layer: "base_loop",
      reason: "base_cycle_complete",
    });
  }

  #chooseBaseAction() {
    const candidates = actionCandidates(this.#actions, this.#baseState, "base_loop");
    if (candidates.length === 0) {
      return null;
    }
    let eligible = candidates.filter(
      (action) => action.id !== this.#lastBaseActionId
        || this.#consecutiveBaseCount < action.maxConsecutive,
    );
    if (eligible.length === 0) {
      eligible = candidates.filter((action) => action.id !== this.#lastBaseActionId);
    }
    if (eligible.length === 0) {
      eligible = candidates;
    }
    const totalWeight = eligible.reduce((total, action) => total + action.weight, 0);
    let cursor = this.#random() * totalWeight;
    for (const action of eligible) {
      cursor -= action.weight;
      if (cursor <= 0) {
        return action;
      }
    }
    return eligible.at(-1);
  }

  #request(request) {
    const accepted = this.#requestAction(request);
    this.#emit({
      type: accepted ? "companion_action_scheduled" : "companion_action_rejected",
      ...request,
    });
  }

  #clearTimer() {
    if (this.#timerId !== null) {
      this.#scheduler.clearTimeout(this.#timerId);
      this.#timerId = null;
    }
  }
}
