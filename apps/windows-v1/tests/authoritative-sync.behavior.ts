import {
  calculateLocalTick,
  needsAuthoritativeCorrection,
  shouldApplyAuthoritativeSnapshot,
  shouldRunAuthoritativeSync,
  syncFailureDisposition,
  wallClockJumped,
  type TickAuthority,
} from "../src/authoritativeSync";

function assert(condition: unknown, message: string): asserts condition {
  if (!condition) throw new Error(message);
}

const working: TickAuthority = {
  sequence: 8,
  capturedAtMs: 1_000,
  phase: "working",
  ownerDate: "2026-07-27",
  monthlySalaryMinor: 1_000_001,
  salarySlotIndex: 3,
  salarySlotCount: 23,
  effectiveSeconds: 28_800,
  completedSeconds: 3_600,
  todayMinor: 5_435,
  monthEarnedMinor: 92_392,
  nextBoundarySeconds: 600,
};

const advanced = calculateLocalTick(working, 4_000);
assert(advanced.completedSeconds === 3_603, "working state must advance by whole local seconds");
assert(advanced.todayMinor >= working.todayMinor, "working income must be monotonic");

const lunch = calculateLocalTick({ ...working, phase: "lunch" }, 4_000);
assert(lunch.todayMinor === working.todayMinor, "lunch must freeze local income");

const boundary = calculateLocalTick({ ...working, nextBoundarySeconds: 2 }, 10_000);
assert(boundary.reachedBoundary, "local tick must stop and request authority at a business boundary");
assert(boundary.completedSeconds === 3_602, "local tick must not interpolate past a boundary");

assert(shouldRunAuthoritativeSync(1_000, 31_000), "30 seconds must trigger one authority sync");
assert(!shouldRunAuthoritativeSync(1_000, 30_999), "authority sync must not run early");
assert(!needsAuthoritativeCorrection(1_001, 1_002), "one cent drift is tolerated");
assert(needsAuthoritativeCorrection(1_001, 1_003), "drift above one cent must be corrected");
assert(
  !shouldApplyAuthoritativeSnapshot(8, 7),
  "a late authority response must not replace the current sequence",
);
assert(
  syncFailureDisposition(1, true) === "stale",
  "the first boundary sync failure must preserve the latest trusted snapshot",
);
assert(
  syncFailureDisposition(2, true) === "blocked",
  "consecutive failures across a boundary must stop local projection",
);
assert(
  syncFailureDisposition(3, false) === "stale",
  "repeated failures before a boundary must not discard the trusted snapshot",
);
assert(
  !wallClockJumped(1_000, 10_000, 2_000, 11_000),
  "normal wall and monotonic time progression must not force a resync",
);
assert(
  wallClockJumped(1_000, 10_000, 8_000, 11_000),
  "a wall-clock jump must force an immediate authoritative resync",
);

console.log("authoritative sync behavior: 13/13 passed");
