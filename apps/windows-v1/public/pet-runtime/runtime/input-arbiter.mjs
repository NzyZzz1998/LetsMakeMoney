function distanceBetween(start, point) {
  return Math.hypot(point.x - start.x, point.y - start.y);
}

export class PetInputArbiter {
  #scheduler;
  #holdMs;
  #clickMoveThresholdPx;
  #directionDeadZonePx;
  #emit;
  #pending = null;
  #drag = null;
  #lockToken = null;
  #nextLockToken = 1;

  constructor({ scheduler, holdMs, clickMoveThresholdPx, directionDeadZonePx, emit }) {
    this.#scheduler = scheduler;
    this.#holdMs = holdMs;
    this.#clickMoveThresholdPx = clickMoveThresholdPx;
    this.#directionDeadZonePx = directionDeadZonePx;
    this.#emit = emit;
  }

  get state() {
    if (this.#lockToken !== null) {
      return "locked";
    }
    if (this.#drag !== null) {
      return "dragging";
    }
    return this.#pending === null ? "idle" : "press_pending";
  }

  pointerDown({ pointerId, x, y, button }) {
    if (button !== 0 || this.#lockToken !== null || this.#pending !== null || this.#drag !== null) {
      return false;
    }

    const startedAt = this.#scheduler.now();
    const pending = {
      pointerId,
      x,
      y,
      startedAt,
      timerId: null,
    };
    pending.timerId = this.#scheduler.setTimeout(() => {
      if (this.#pending !== pending || this.#lockToken !== null) {
        return;
      }
      this.#pending = null;
      this.#drag = {
        pointerId,
        x,
        y,
        lastX: x,
        lastY: y,
        directionAnchorX: x,
        startedAt,
        direction: null,
      };
      this.#emit({
        type: "drag_started",
        pointerId,
        durationMs: this.#scheduler.now() - startedAt,
        x,
        y,
      });
    }, this.#holdMs);
    this.#pending = pending;
    this.#emit({ type: "press_pending", pointerId, x, y, startedAt });
    return true;
  }

  pointerMove({ pointerId, x, y }) {
    if (this.#pending?.pointerId === pointerId) {
      const distance = distanceBetween(this.#pending, { x, y });
      if (distance > this.#clickMoveThresholdPx) {
        this.#cancelPending("move_threshold", distance);
      }
      return;
    }

    if (this.#drag?.pointerId !== pointerId) {
      return;
    }
    const deltaMoveX = x - this.#drag.lastX;
    const deltaMoveY = y - this.#drag.lastY;
    this.#drag.lastX = x;
    this.#drag.lastY = y;
    if (deltaMoveX !== 0 || deltaMoveY !== 0) {
      this.#emit({
        type: "drag_move",
        pointerId,
        deltaX: deltaMoveX,
        deltaY: deltaMoveY,
        x,
        y,
      });
    }
    const directionDeltaX = x - this.#drag.directionAnchorX;
    if (Math.abs(directionDeltaX) < this.#directionDeadZonePx) {
      return;
    }
    this.#drag.directionAnchorX = x;
    const direction = directionDeltaX > 0 ? "right" : "left";
    if (direction !== this.#drag.direction) {
      this.#drag.direction = direction;
      this.#emit({ type: "drag_direction", pointerId, direction, deltaX: directionDeltaX, x, y });
    }
  }

  pointerUp({ pointerId, x, y }) {
    if (this.#pending?.pointerId === pointerId) {
      const pending = this.#pending;
      this.#scheduler.clearTimeout(pending.timerId);
      this.#pending = null;
      this.#emit({
        type: "click",
        pointerId,
        durationMs: this.#scheduler.now() - pending.startedAt,
        distance: distanceBetween(pending, { x, y }),
        x,
        y,
      });
      return;
    }

    if (this.#drag?.pointerId === pointerId) {
      const drag = this.#drag;
      this.#drag = null;
      this.#emit({
        type: "drag_released",
        pointerId,
        durationMs: this.#scheduler.now() - drag.startedAt,
        x,
        y,
      });
    }
  }

  pointerCancel({ pointerId, reason = "pointer_cancel" }) {
    if (this.#pending?.pointerId === pointerId) {
      this.#cancelPending(reason, 0);
      return;
    }
    if (this.#drag?.pointerId === pointerId) {
      const drag = this.#drag;
      this.#drag = null;
      this.#emit({
        type: "drag_released",
        pointerId,
        durationMs: this.#scheduler.now() - drag.startedAt,
        cancelled: true,
        reason,
      });
    }
  }

  lock(source) {
    if (this.#pending !== null) {
      this.#cancelPending("input_locked", 0);
    }
    if (this.#drag !== null) {
      this.pointerCancel({ pointerId: this.#drag.pointerId, reason: "input_locked" });
    }
    const token = `lock-${this.#nextLockToken++}`;
    this.#lockToken = token;
    this.#emit({ type: "input_locked", token, source });
    return token;
  }

  unlock(token) {
    if (token !== this.#lockToken) {
      this.#emit({ type: "unlock_ignored", token, activeToken: this.#lockToken });
      return false;
    }
    this.#lockToken = null;
    this.#emit({ type: "input_unlocked", token });
    return true;
  }

  reset(reason = "hard_interrupt") {
    if (this.#pending !== null) {
      this.#cancelPending(reason, 0);
    }
    if (this.#drag !== null) {
      this.pointerCancel({ pointerId: this.#drag.pointerId, reason });
    }
    this.#lockToken = null;
  }

  #cancelPending(reason, distance) {
    const pending = this.#pending;
    if (pending === null) {
      return;
    }
    this.#scheduler.clearTimeout(pending.timerId);
    this.#pending = null;
    this.#emit({
      type: "press_cancelled",
      pointerId: pending.pointerId,
      durationMs: this.#scheduler.now() - pending.startedAt,
      distance,
      reason,
    });
  }
}
