export class DpiTransitionWatcher {
  #currentScale;
  #emit;
  #generation = 0;
  #onBegin;
  #onSettle;
  #scheduler;
  #settleMs;
  #timerId = null;
  #transitionActive = false;

  constructor({ initialScale, scheduler, settleMs, onBegin, onSettle, emit }) {
    if (!validScale(initialScale)) {
      throw new RangeError("initialScale must be a finite positive number.");
    }
    if (!Number.isFinite(settleMs) || settleMs < 0) {
      throw new RangeError("settleMs must be a non-negative number.");
    }
    this.#currentScale = initialScale;
    this.#scheduler = scheduler;
    this.#settleMs = settleMs;
    this.#onBegin = onBegin;
    this.#onSettle = onSettle;
    this.#emit = emit;
  }

  get snapshot() {
    return {
      currentScale: this.#currentScale,
      generation: this.#generation,
      pendingTimer: this.#timerId !== null,
      transitionActive: this.#transitionActive,
    };
  }

  observe(nextScale, { extendSettle = false, reason = "observed" } = {}) {
    if (!validScale(nextScale)) {
      throw new RangeError("observed DPI scale must be a finite positive number.");
    }
    const changed = nextScale !== this.#currentScale;
    if (changed) {
      const event = {
        fromScale: this.#currentScale,
        generation: this.#generation + 1,
        reason,
        toScale: nextScale,
      };
      this.#currentScale = nextScale;
      this.#generation = event.generation;
      this.#transitionActive = true;
      this.#onBegin(event);
      this.#emit({ type: "dpi_transition_observed", ...event });
      this.#scheduleSettlement();
      return true;
    }
    if (this.#transitionActive && extendSettle) {
      this.#emit({
        type: "dpi_transition_settle_extended",
        generation: this.#generation,
        reason,
        scale: this.#currentScale,
      });
      this.#scheduleSettlement();
    }
    return false;
  }

  cancel(reason = "cancelled") {
    if (this.#timerId !== null) {
      this.#scheduler.clearTimeout(this.#timerId);
      this.#timerId = null;
    }
    if (!this.#transitionActive) {
      return false;
    }
    this.#transitionActive = false;
    this.#generation += 1;
    this.#emit({
      type: "dpi_transition_cancelled",
      generation: this.#generation,
      reason,
      scale: this.#currentScale,
    });
    return true;
  }

  #scheduleSettlement() {
    if (this.#timerId !== null) {
      this.#scheduler.clearTimeout(this.#timerId);
    }
    const generation = this.#generation;
    this.#timerId = this.#scheduler.setTimeout(() => {
      if (!this.#transitionActive || generation !== this.#generation) {
        return;
      }
      this.#timerId = null;
      this.#transitionActive = false;
      const event = { generation, scale: this.#currentScale };
      this.#emit({ type: "dpi_transition_settle_started", ...event });
      try {
        const result = this.#onSettle(event);
        Promise.resolve(result).catch((error) => {
          this.#emit({
            type: "dpi_transition_settle_failed",
            generation,
            reason: errorMessage(error),
            scale: this.#currentScale,
          });
        });
      } catch (error) {
        this.#emit({
          type: "dpi_transition_settle_failed",
          generation,
          reason: errorMessage(error),
          scale: this.#currentScale,
        });
      }
    }, this.#settleMs);
  }
}

function validScale(scale) {
  return Number.isFinite(scale) && scale > 0;
}

function errorMessage(error) {
  return error instanceof Error ? error.message : String(error);
}
