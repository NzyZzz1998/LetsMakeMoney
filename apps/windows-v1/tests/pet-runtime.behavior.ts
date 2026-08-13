import assert from "node:assert/strict";

import { PetInputArbiter } from "../public/pet-runtime/runtime/input-arbiter.mjs";
import { PetRuntimeMachine } from "../public/pet-runtime/runtime/runtime-machine.mjs";

class FakeScheduler {
  current = 0;
  nextId = 1;
  tasks = new Map<number, { at: number; callback: () => void }>();

  setTimeout(callback: () => void, delay: number) {
    const id = this.nextId++;
    this.tasks.set(id, { at: this.current + delay, callback });
    return id;
  }

  clearTimeout(id: number) {
    this.tasks.delete(id);
  }

  now() {
    return this.current;
  }

  advanceBy(delay: number) {
    this.current += delay;
    for (const [id, task] of [...this.tasks.entries()]
      .filter(([, task]) => task.at <= this.current)
      .sort((left, right) => left[1].at - right[1].at)) {
      this.tasks.delete(id);
      task.callback();
    }
  }
}

function runtimeHarness() {
  const requests: Array<{ actionId: string; instanceId: string }> = [];
  const events: Array<{ type: string }> = [];
  let nextInstance = 1;
  const machine = new PetRuntimeMachine({
    baseActions: {
      working: "working_play_loop_a",
      awake_rest: "awake_rest_loop",
      sleeping: "sleeping_loop",
    },
    ackActions: {
      working: "working_ack",
      awake_rest: "rest_ack",
      sleeping: "sleep_ack",
    },
    play: (actionId: string) => {
      const request = { actionId, instanceId: `instance-${nextInstance++}` };
      requests.push(request);
      return request.instanceId;
    },
    stop: () => undefined,
    emit: (event: { type: string }) => events.push(event),
    requestAuthoritativeSnapshot: () => undefined,
  });
  return { events, machine, requests };
}

{
  const { machine, requests } = runtimeHarness();
  machine.applyAuthoritativeBaseState("working", 1);
  assert.equal(requests.at(-1)?.actionId, "working_play_loop_a");
  machine.handleInput({ type: "click" });
  assert.equal(requests.at(-1)?.actionId, "working_ack");

  machine.applyAuthoritativeBaseState("awake_rest", 2);
  machine.handleInput({ type: "click" });
  assert.equal(requests.at(-1)?.actionId, "rest_ack");

  machine.applyAuthoritativeBaseState("sleeping", 3);
  machine.handleInput({ type: "click" });
  assert.equal(requests.at(-1)?.actionId, "sleep_ack");
}

{
  const { events, machine, requests } = runtimeHarness();
  machine.applyAuthoritativeBaseState("working", 1);
  machine.handleInput({ type: "drag_started", pointerId: 7 });
  const prepare = requests.at(-1)!;
  assert.equal(prepare.actionId, "run_prepare");
  machine.animationFinished(prepare.instanceId);
  assert.equal(requests.at(-1)?.actionId, "run_loop");
  machine.applyAuthoritativeBaseState("sleeping", 2);
  machine.handleInput({ type: "drag_released", pointerId: 7 });
  const stop = requests.at(-1)!;
  assert.equal(stop.actionId, "run_stop");
  machine.animationFinished(stop.instanceId);
  assert.equal(requests.at(-1)?.actionId, "sleeping_loop");
  assert.equal(events.some((event) => event.type === "base_state_changed"), true);
}

{
  const scheduler = new FakeScheduler();
  const events: Array<{ type: string; direction?: string }> = [];
  const arbiter = new PetInputArbiter({
    scheduler,
    holdMs: 500,
    clickMoveThresholdPx: 6,
    directionDeadZonePx: 4,
    emit: (event: { type: string; direction?: string }) => events.push(event),
  });
  arbiter.pointerDown({ pointerId: 9, x: 100, y: 50, button: 0 });
  scheduler.advanceBy(500);
  arbiter.pointerMove({ pointerId: 9, x: 60, y: 50 });
  arbiter.pointerMove({ pointerId: 9, x: 70, y: 50 });
  arbiter.pointerUp({ pointerId: 9, x: 70, y: 50 });
  assert.deepEqual(
    events
      .filter((event) => event.type === "drag_direction")
      .map((event) => event.direction),
    ["left", "right"],
  );
  assert.equal(events.at(-1)?.type, "drag_released");
}

{
  const scheduler = new FakeScheduler();
  const events: Array<{ type: string; cancelled?: boolean; reason?: string }> = [];
  const arbiter = new PetInputArbiter({
    scheduler,
    holdMs: 500,
    clickMoveThresholdPx: 6,
    directionDeadZonePx: 4,
    emit: (event: { type: string; cancelled?: boolean; reason?: string }) => events.push(event),
  });
  arbiter.pointerDown({ pointerId: 11, x: 80, y: 60, button: 0 });
  scheduler.advanceBy(500);
  arbiter.reset("window_blur");
  assert.equal(arbiter.state, "idle");
  assert.deepEqual(events.at(-1), {
    type: "drag_released",
    pointerId: 11,
    durationMs: 500,
    cancelled: true,
    reason: "window_blur",
  });
  assert.equal(arbiter.pointerDown({ pointerId: 12, x: 80, y: 60, button: 0 }), true);
  scheduler.advanceBy(100);
  arbiter.pointerUp({ pointerId: 12, x: 80, y: 60 });
  assert.equal(events.at(-1)?.type, "click");
}

console.log("pet runtime behavior passed (4/4)");
