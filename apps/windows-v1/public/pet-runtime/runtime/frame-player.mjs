function validateAction(action) {
  if (!action || !Array.isArray(action.frames) || action.frames.length === 0) {
    throw new TypeError("action must declare at least one frame");
  }
  if (!['loop', 'oneshot'].includes(action.playbackKind)) {
    throw new TypeError("action playbackKind must be loop or oneshot");
  }
  for (const frame of action.frames) {
    if (!Number.isInteger(frame.durationMs) || frame.durationMs <= 0) {
      throw new RangeError("every frame durationMs must be a positive integer");
    }
  }
}

export function createBrowserScheduler() {
  return {
    now: () => performance.now(),
    setTimeout: (callback, delayMs) => window.setTimeout(callback, delayMs),
    clearTimeout: (timerId) => window.clearTimeout(timerId),
  };
}

export class FramePlayer {
  #scheduler;
  #onFrame;
  #onFinished;
  #onTimedOut;
  #onIgnoredFinished;
  #active = null;
  #nextInstance = 1;

  constructor({ scheduler, onFrame, onFinished, onTimedOut = () => {}, onIgnoredFinished = () => {} }) {
    this.#scheduler = scheduler;
    this.#onFrame = onFrame;
    this.#onFinished = onFinished;
    this.#onTimedOut = onTimedOut;
    this.#onIgnoredFinished = onIgnoredFinished;
  }

  get activeInstanceId() {
    return this.#active?.instanceId ?? null;
  }

  get pendingTimerCount() {
    return this.#active?.timerId == null ? 0 : 1;
  }

  play(action) {
    validateAction(action);
    this.stop("replaced");

    const now = this.#scheduler.now();
    const instanceId = `action-${this.#nextInstance++}`;
    this.#active = {
      action,
      instanceId,
      frameIndex: 0,
      startedAt: now,
      frameStartedAt: now,
      frameDueAt: now + action.frames[0].durationMs,
      remainingMs: action.frames[0].durationMs,
      pausedAt: null,
      totalPausedMs: 0,
      timerId: null,
      maxRuntimeMs:
        action.playbackKind === "oneshot" && Number.isFinite(action.maxRuntimeMs)
          ? action.maxRuntimeMs
          : Infinity,
    };
    this.#emitFrame(this.#active);
    this.#schedule(this.#active);
    return instanceId;
  }

  pause(reason = "paused") {
    const active = this.#active;
    if (active === null || active.pausedAt !== null) {
      return false;
    }
    const now = this.#scheduler.now();
    active.remainingMs = Math.max(0, active.frameDueAt - now);
    active.pausedAt = now;
    active.pauseReason = reason;
    if (active.timerId !== null) {
      this.#scheduler.clearTimeout(active.timerId);
      active.timerId = null;
    }
    return true;
  }

  resume(reason = "resumed") {
    const active = this.#active;
    if (active === null || active.pausedAt === null) {
      return false;
    }
    const now = this.#scheduler.now();
    const pausedDurationMs = now - active.pausedAt;
    active.totalPausedMs += pausedDurationMs;
    active.pausedAt = null;
    active.resumeReason = reason;
    active.frameStartedAt += pausedDurationMs;
    active.frameDueAt += pausedDurationMs;
    this.#schedule(active);
    return true;
  }

  stop(reason = "stopped") {
    const active = this.#active;
    if (active === null) {
      return false;
    }
    if (active.timerId !== null) {
      this.#scheduler.clearTimeout(active.timerId);
    }
    active.stopReason = reason;
    this.#active = null;
    return true;
  }

  acceptFinished(instanceId) {
    const active = this.#active;
    if (active === null || active.instanceId !== instanceId) {
      this.#onIgnoredFinished({
        instanceId,
        currentInstanceId: active?.instanceId ?? null,
      });
      return false;
    }
    this.#finish(active);
    return true;
  }

  #schedule(active) {
    if (this.#active !== active || active.pausedAt !== null) {
      return;
    }
    const now = this.#scheduler.now();
    const runtimeDueAt = active.startedAt + active.totalPausedMs + active.maxRuntimeMs;
    const timerKind = runtimeDueAt <= active.frameDueAt ? "timeout" : "frame";
    const targetAt = Math.min(active.frameDueAt, runtimeDueAt);
    const scheduledDelayMs = Math.max(0, targetAt - now);
    active.remainingMs = Math.max(0, active.frameDueAt - now);
    const instanceId = active.instanceId;
    active.timerId = this.#scheduler.setTimeout(() => {
      if (this.#active !== active || active.instanceId !== instanceId || active.pausedAt !== null) {
        return;
      }
      active.timerId = null;
      if (this.#activeElapsed(active) >= active.maxRuntimeMs) {
        this.#timeOut(active);
      } else if (timerKind === "frame") {
        this.#advance(active);
      }
    }, scheduledDelayMs);
  }

  #advance(active) {
    const lastFrame = active.frameIndex === active.action.frames.length - 1;
    if (lastFrame && active.action.playbackKind === "oneshot") {
      this.#finish(active);
      return;
    }

    active.frameIndex = lastFrame ? 0 : active.frameIndex + 1;
    active.frameStartedAt = active.frameDueAt;
    const frame = active.action.frames[active.frameIndex];
    active.frameDueAt += frame.durationMs;
    this.#emitFrame(active);
    this.#schedule(active);
  }

  #finish(active) {
    if (this.#active !== active) {
      return;
    }
    if (active.timerId !== null) {
      this.#scheduler.clearTimeout(active.timerId);
    }
    const elapsedMs = this.#activeElapsed(active);
    this.#active = null;
    this.#onFinished({
      actionId: active.action.id,
      instanceId: active.instanceId,
      elapsedMs,
    });
  }

  #timeOut(active) {
    if (this.#active !== active) {
      return;
    }
    this.#active = null;
    this.#onTimedOut({
      actionId: active.action.id,
      instanceId: active.instanceId,
      elapsedMs: this.#activeElapsed(active),
      frameIndex: active.frameIndex,
    });
  }

  #activeElapsed(active) {
    const inProgressPause = active.pausedAt === null ? 0 : this.#scheduler.now() - active.pausedAt;
    return this.#scheduler.now() - active.startedAt - active.totalPausedMs - inProgressPause;
  }

  #emitFrame(active) {
    this.#onFrame({
      actionId: active.action.id,
      instanceId: active.instanceId,
      frameIndex: active.frameIndex,
      frame: active.action.frames[active.frameIndex],
      plannedAtMs: active.frameStartedAt,
    });
  }
}
