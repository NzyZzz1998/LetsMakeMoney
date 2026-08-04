import {
  formatTimeValue,
  moveTimePart,
  parseTimeValue,
  shouldTimeFieldOpenUp,
} from "../src/components/timeFieldModel";

function assert(condition: unknown, message: string): asserts condition {
  if (!condition) throw new Error(message);
}

assert(parseTimeValue("09:30").hour === 9, "valid hours must parse");
assert(parseTimeValue("09:30").minute === 30, "valid minutes must parse");
assert(parseTimeValue("invalid").hour === 9, "invalid values must use the safe default");
assert(formatTimeValue(9, 5) === "09:05", "time values must be zero padded");
assert(moveTimePart(23, "ArrowDown", 23) === 0, "hour navigation must wrap forward");
assert(moveTimePart(0, "ArrowUp", 23) === 23, "hour navigation must wrap backward");
assert(moveTimePart(30, "Home", 59) === 0, "Home must select the first value");
assert(moveTimePart(30, "End", 59) === 59, "End must select the last value");
assert(
  shouldTimeFieldOpenUp({ triggerTop: 420, triggerBottom: 456, popoverHeight: 220, viewportHeight: 500 }),
  "near-bottom controls must open upward",
);
assert(
  !shouldTimeFieldOpenUp({ triggerTop: 80, triggerBottom: 116, popoverHeight: 220, viewportHeight: 500 }),
  "controls with room below must open downward",
);

console.log("time field behavior: 10/10 passed");
