export class WindowMoveCoordinator {
  #move;
  #onError;
  #inFlight = false;
  #pendingX = 0;
  #pendingY = 0;

  constructor({ move, onError = () => undefined }) {
    this.#move = move;
    this.#onError = onError;
  }

  enqueue(deltaX, deltaY) {
    if (!Number.isFinite(deltaX) || !Number.isFinite(deltaY)) {
      return false;
    }
    if (deltaX === 0 && deltaY === 0) {
      return false;
    }

    this.#pendingX += deltaX;
    this.#pendingY += deltaY;
    this.#drain();
    return true;
  }

  cancelPending() {
    const discarded = { deltaX: this.#pendingX, deltaY: this.#pendingY };
    this.#pendingX = 0;
    this.#pendingY = 0;
    return discarded;
  }

  async #drain() {
    if (this.#inFlight || (this.#pendingX === 0 && this.#pendingY === 0)) {
      return;
    }

    const deltaX = this.#pendingX;
    const deltaY = this.#pendingY;
    this.#pendingX = 0;
    this.#pendingY = 0;
    this.#inFlight = true;

    try {
      await this.#move(deltaX, deltaY);
    } catch (error) {
      this.#onError(error);
    } finally {
      this.#inFlight = false;
      this.#drain();
    }
  }
}
