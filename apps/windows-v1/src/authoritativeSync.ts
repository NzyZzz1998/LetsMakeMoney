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
  nextBoundarySeconds: number | null;
  reachedBoundary: boolean;
}

export interface TimeEnvironmentSample {
  wallMs: number;
  monotonicMs: number;
  timezoneId: string;
  timezoneOffsetMinutes: number;
}

export type TimeEnvironmentChange =
  | "none"
  | "sleep_resume"
  | "wall_clock"
  | "timezone";

export function createTimeEnvironmentSample(
  wallMs = Date.now(),
  monotonicMs = performance.now(),
  timezoneId = Intl.DateTimeFormat().resolvedOptions().timeZone,
  timezoneOffsetMinutes = new Date(wallMs).getTimezoneOffset(),
): TimeEnvironmentSample {
  return {
    wallMs,
    monotonicMs,
    timezoneId,
    timezoneOffsetMinutes,
  };
}

export function classifyTimeEnvironmentChange(
  previous: TimeEnvironmentSample,
  current: TimeEnvironmentSample,
  wallToleranceMs = 2_000,
  suspensionThresholdMs = 5_000,
): TimeEnvironmentChange {
  if (
    previous.timezoneId !== current.timezoneId
    || previous.timezoneOffsetMinutes !== current.timezoneOffsetMinutes
  ) {
    return "timezone";
  }
  const wallElapsed = current.wallMs - previous.wallMs;
  const monotonicElapsed = current.monotonicMs - previous.monotonicMs;
  if (Math.abs(wallElapsed - monotonicElapsed) > wallToleranceMs) {
    return "wall_clock";
  }
  if (Math.max(wallElapsed, monotonicElapsed) > suspensionThresholdMs) {
    return "sleep_resume";
  }
  return "none";
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
  const elapsedSeconds = Math.max(0, Math.floor((nowMs - authority.capturedAtMs) / 1000));
  const nextBoundarySeconds = authority.nextBoundarySeconds === null
    ? null
    : Math.max(0, authority.nextBoundarySeconds - elapsedSeconds);
  const reachedBoundary =
    authority.nextBoundarySeconds !== null
    && elapsedSeconds >= authority.nextBoundarySeconds;

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
      nextBoundarySeconds,
      reachedBoundary,
    };
  }

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
    nextBoundarySeconds,
    reachedBoundary,
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

export function shouldRetryInitialSync(
  hasAuthority: boolean,
  errorCode: string,
  consecutiveFailures: number,
  maxAttempts = 2,
) {
  return (
    !hasAuthority
    && errorCode === "calculation_unavailable"
    && consecutiveFailures <= maxAttempts
  );
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
