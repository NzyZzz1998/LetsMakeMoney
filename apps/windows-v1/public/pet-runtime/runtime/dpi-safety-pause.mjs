export class DpiSafetyPause {
  #active = false;
  #emit;
  #pauseAnimation;
  #resetInput;
  #resumeAnimation;

  constructor({ emit, pauseAnimation, resetInput, resumeAnimation }) {
    this.#emit = emit;
    this.#pauseAnimation = pauseAnimation;
    this.#resetInput = resetInput;
    this.#resumeAnimation = resumeAnimation;
  }

  get snapshot() {
    return { active: this.#active };
  }

  begin(reason) {
    if (this.#active) {
      return false;
    }
    this.#active = true;
    this.#resetInput();
    this.#pauseAnimation();
    this.#emit({ type: "dpi_safety_pause_started", reason });
    return true;
  }

  end(reason, { resume = true } = {}) {
    if (!this.#active) {
      return false;
    }
    this.#active = false;
    if (resume) {
      this.#resumeAnimation();
    }
    this.#emit({ type: "dpi_safety_pause_ended", reason, resumed: resume });
    return true;
  }
}
