export type DashboardState = "loading" | "ready" | "setup" | "error";
export type WorkPhase =
  | "working"
  | "lunch"
  | "before_work"
  | "after_work"
  | "rest_day"
  | "paid_rest"
  | "unpaid_rest";

export interface DashboardProjection {
  state: "ready";
  phase: WorkPhase;
  ownerDate: string;
  amount: number;
  dailySalary: number;
  hourlySalary: number;
  progress: number;
  completedSeconds: number;
  remainingSeconds: number;
  monthTotal: number;
  expectedMonthlyPay: number;
  workdays: number;
  salarySlotCount: number;
  syncState: "synced";
  algorithmVersion: string;
  effectiveSeconds: number;
}

interface BrowserProjectionInput {
  phase: WorkPhase;
  ownerDate: string;
  amount: number;
  dailySalary: number;
  hourlySalary: number;
  progressPercent: number;
  completedSeconds: number;
  effectiveSeconds: number;
  monthTotal: number;
  expectedMonthlyPay: number;
  workdays: number;
  salarySlotCount: number;
  algorithmVersion: string;
}

interface TauriProjectionInput {
  phase: WorkPhase;
  ownerDate: string;
  earnedMinor: number;
  dailyTargetMinor: number;
  hourlySalaryMinor: number;
  progressRatio: number;
  completedSeconds: number;
  effectiveSeconds: number;
  monthEarnedMinor: number;
  payableSalaryMinor: number;
  workdays: number;
  salarySlotCount: number;
  algorithmVersion: string;
}

const REST_PHASES: WorkPhase[] = ["rest_day", "paid_rest", "unpaid_rest"];

function createProjection(
  input: Omit<DashboardProjection, "state" | "syncState" | "remainingSeconds">,
): DashboardProjection {
  return {
    state: "ready",
    syncState: "synced",
    ...input,
    remainingSeconds: REST_PHASES.includes(input.phase)
      ? 0
      : Math.max(0, input.effectiveSeconds - input.completedSeconds),
  };
}

export function createBrowserDashboardProjection(
  input: BrowserProjectionInput,
): DashboardProjection {
  return createProjection({
    phase: input.phase,
    ownerDate: input.ownerDate,
    amount: input.amount,
    dailySalary: input.dailySalary,
    hourlySalary: input.hourlySalary,
    progress: Math.round(input.progressPercent),
    completedSeconds: input.completedSeconds,
    monthTotal: input.monthTotal,
    expectedMonthlyPay: input.expectedMonthlyPay,
    workdays: input.workdays,
    salarySlotCount: input.salarySlotCount,
    algorithmVersion: input.algorithmVersion,
    effectiveSeconds: input.effectiveSeconds,
  });
}

export function createTauriDashboardProjection(
  input: TauriProjectionInput,
): DashboardProjection {
  return createProjection({
    phase: input.phase,
    ownerDate: input.ownerDate,
    amount: input.earnedMinor / 100,
    dailySalary: input.dailyTargetMinor / 100,
    hourlySalary: input.hourlySalaryMinor / 100,
    progress: Math.round(input.progressRatio * 100),
    completedSeconds: input.completedSeconds,
    monthTotal: input.monthEarnedMinor / 100,
    expectedMonthlyPay: input.payableSalaryMinor / 100,
    workdays: input.workdays,
    salarySlotCount: input.salarySlotCount,
    algorithmVersion: input.algorithmVersion,
    effectiveSeconds: input.effectiveSeconds,
  });
}

interface DashboardSyncState {
  state: DashboardState;
  syncState: "synced" | "syncing" | "stale";
  message?: string;
  errorCode?: string;
}

interface DashboardSyncFailure {
  code: string;
  message: string;
  blocked: boolean;
}

export function applyDashboardSyncFailure<T extends DashboardSyncState>(
  current: T,
  failure: DashboardSyncFailure,
): T {
  if (current.state === "ready" && failure.blocked) {
    return {
      ...current,
      state: "error",
      syncState: "stale",
      message: "时间边界后的结果尚未同步成功，请重试。",
      errorCode: failure.code,
    };
  }
  if (current.state === "ready") {
    return {
      ...current,
      syncState: "stale",
      message: "正在重新同步，当前显示最近一次可信结果。",
      errorCode: failure.code,
    };
  }
  return {
    ...current,
    state: "error",
    message: failure.message,
    errorCode: failure.code,
  };
}
