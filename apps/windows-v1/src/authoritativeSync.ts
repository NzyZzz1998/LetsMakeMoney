export type TickPhase =
  | "working"
  | "lunch"
  | "before_work"
  | "after_work"
  | "rest_day"
  | "paid_rest"
  | "unpaid_rest";

export interface TickAuthority {
  sequence: number;
  capturedAtMs: number;
  phase: TickPhase;
  ownerDate: string;
  monthlySalaryMinor: number;
  salarySlotIndex: number | null;
  salarySlotCount: number;
  effectiveSeconds: number;
  completedSeconds: number;
  todayMinor: number;
  monthEarnedMinor: number;
  nextBoundarySeconds: number | null;
}

export interface TickResult {
  completedSeconds: number;
  todayMinor: number;
  monthEarnedMinor: number;
  reachedBoundary: boolean;
}

function roundPositiveRatio(numerator: number, denominator: number) {
  if (!Number.isSafeInteger(numerator) || !Number.isSafeInteger(denominator) || denominator <= 0) {
    throw new Error("salary.local_tick_unsafe_integer");
  }
  const numeratorBig = BigInt(numerator);
  const denominatorBig = BigInt(denominator);
  return Number((numeratorBig + denominatorBig / 2n) / denominatorBig);
}

function cumulativeMinor(
  monthlySalaryMinor: number,
  salarySlotCount: number,
  completedSlots: number,
) {
  const numerator = BigInt(monthlySalaryMinor) * BigInt(completedSlots);
  const denominator = BigInt(salarySlotCount);
  return Number((numerator + denominator / 2n) / denominator);
}

export function calculateLocalTick(authority: TickAuthority, nowMs: number): TickResult {
  if (
    authority.phase !== "working"
    || authority.salarySlotIndex === null
    || authority.salarySlotCount <= 0
    || authority.effectiveSeconds <= 0
  ) {
    return {
      completedSeconds: authority.completedSeconds,
      todayMinor: authority.todayMinor,
      monthEarnedMinor: authority.monthEarnedMinor,
      reachedBoundary: false,
    };
  }

  const elapsedSeconds = Math.max(0, Math.floor((nowMs - authority.capturedAtMs) / 1000));
  const boundarySeconds = authority.nextBoundarySeconds ?? Number.POSITIVE_INFINITY;
  const appliedSeconds = Math.min(elapsedSeconds, boundarySeconds);
  const completedSeconds = Math.min(
    authority.effectiveSeconds,
    authority.completedSeconds + appliedSeconds,
  );
  const previousCumulative = cumulativeMinor(
    authority.monthlySalaryMinor,
    authority.salarySlotCount,
    authority.salarySlotIndex - 1,
  );
  const numerator = BigInt(authority.monthlySalaryMinor) * BigInt(
    (authority.salarySlotIndex - 1) * authority.effectiveSeconds + completedSeconds,
  );
  const denominator = BigInt(authority.salarySlotCount) * BigInt(authority.effectiveSeconds);
  const todayMinor = Number((numerator + denominator / 2n) / denominator) - previousCumulative;
  const priorMonthMinor = authority.monthEarnedMinor - authority.todayMinor;

  return {
    completedSeconds,
    todayMinor,
    monthEarnedMinor: priorMonthMinor + todayMinor,
    reachedBoundary: elapsedSeconds >= boundarySeconds,
  };
}

export function shouldRunAuthoritativeSync(
  lastSuccessAtMs: number,
  nowMs: number,
  intervalMs = 30_000,
) {
  return nowMs - lastSuccessAtMs >= intervalMs;
}

export function shouldApplyAuthoritativeSnapshot(
  currentSequence: number,
  incomingSequence: number,
) {
  return incomingSequence >= currentSequence;
}

export function needsAuthoritativeCorrection(
  localMinor: number,
  authoritativeMinor: number,
  toleranceMinor = 1,
) {
  return Math.abs(localMinor - authoritativeMinor) > toleranceMinor;
}

export function syncFailureDisposition(
  consecutiveFailures: number,
  boundaryPending: boolean,
) {
  return boundaryPending && consecutiveFailures >= 2 ? "blocked" : "stale";
}

export function wallClockJumped(
  previousWallMs: number,
  previousMonotonicMs: number,
  currentWallMs: number,
  currentMonotonicMs: number,
  toleranceMs = 2_000,
) {
  const wallElapsed = currentWallMs - previousWallMs;
  const monotonicElapsed = currentMonotonicMs - previousMonotonicMs;
  return Math.abs(wallElapsed - monotonicElapsed) > toleranceMs;
}
