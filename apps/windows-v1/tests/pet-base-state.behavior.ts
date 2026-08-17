import { resolvePetBaseState } from "../src/features/pet/petBaseState";

function assert(condition: unknown, message: string): asserts condition {
  if (!condition) throw new Error(message);
}

assert(
  resolvePetBaseState({ state: "ready", phase: "working" }, new Date("2026-08-12T01:00:00")) === "working",
  "an overnight working phase must override the sleeping window",
);
assert(
  resolvePetBaseState({ state: "ready", phase: "lunch" }, new Date("2026-08-12T01:00:00")) === "awake_rest",
  "an explicit rest phase must remain awake_rest even at night",
);
assert(
  resolvePetBaseState({ state: "ready", phase: "after_work" }, new Date("2026-08-12T23:15:00")) === "sleeping",
  "inactive late-night time must map to sleeping",
);
assert(
  resolvePetBaseState({ state: "ready", phase: "before_work" }, new Date("2026-08-12T07:29:00")) === "sleeping",
  "inactive early-morning time must map to sleeping",
);
assert(
  resolvePetBaseState({ state: "ready", phase: "rest_day" }, new Date("2026-08-12T12:00:00")) === "awake_rest",
  "daytime rest days must map to awake_rest",
);
assert(
  resolvePetBaseState({ state: "loading", phase: "working" }, new Date("2026-08-12T12:00:00")) === "awake_rest",
  "untrusted dashboard states must fail closed to awake_rest",
);

console.log("pet base state behavior: 6/6 passed");
