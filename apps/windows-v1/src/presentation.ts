export type PresentationPhase =
  | "working"
  | "lunch"
  | "before_work"
  | "after_work"
  | "rest_day"
  | "paid_rest"
  | "unpaid_rest";

export type BoundaryKind =
  | "work_start"
  | "rest_start"
  | "work_resume"
  | "work_end"
  | null;

export interface BoundaryPresentationInput {
  phase: PresentationPhase;
  nextBoundaryKind: BoundaryKind;
  nextBoundarySeconds: number | null;
}

export interface BoundaryPresentation {
  stateLabel: string;
  countdownLabel: string | null;
  countdownSeconds: number | null;
  completeLabel: string | null;
}

export function boundaryPresentation(
  input: BoundaryPresentationInput,
): BoundaryPresentation {
  const countdownLabels: Record<Exclude<BoundaryKind, null>, string> = {
    work_start: "距离上班",
    rest_start: "距离休息",
    work_resume: "距离恢复工作",
    work_end: "距离下班",
  };
  const stateLabels: Record<PresentationPhase, string> = {
    before_work: "上班前",
    working: "工作中",
    lunch: "休息中",
    after_work: "今日工作已结束",
    rest_day: "休息日",
    paid_rest: "带薪休息",
    unpaid_rest: "不带薪休息",
  };
  const completeLabels: Partial<Record<PresentationPhase, string>> = {
    after_work: "今日工作已结束",
    rest_day: "今天没有工作安排",
    paid_rest: "今天为带薪休息",
    unpaid_rest: "今天为不带薪休息",
  };

  return {
    stateLabel: stateLabels[input.phase],
    countdownLabel: input.nextBoundaryKind
      ? countdownLabels[input.nextBoundaryKind]
      : null,
    countdownSeconds: input.nextBoundaryKind ? input.nextBoundarySeconds : null,
    completeLabel: completeLabels[input.phase] ?? null,
  };
}

export type TimelineRowKind = "work_start" | "rest_start" | "work_resume" | "work_end";
export type TimelineRowState = "completed" | "current" | "upcoming";

export interface TimelineSchedule {
  phase: PresentationPhase;
  nextBoundaryKind?: BoundaryKind;
  workStartTime: string;
  restStartTime: string;
  restEndTime: string;
  workEndTime: string;
}

export interface TimelineRow {
  kind: TimelineRowKind;
  time: string;
  title: string;
  detail: string;
  state: TimelineRowState;
}

function hasRest(schedule: TimelineSchedule) {
  return schedule.restStartTime !== schedule.restEndTime;
}

function isOvernight(schedule: TimelineSchedule) {
  return schedule.workEndTime <= schedule.workStartTime;
}

function displayClock(clock: string, schedule: TimelineSchedule) {
  return isOvernight(schedule) && clock < schedule.workStartTime
    ? `${clock} 次日`
    : clock;
}

function timelineState(
  phase: PresentationPhase,
  kind: TimelineRowKind,
  schedule: TimelineSchedule,
): TimelineRowState {
  if (["rest_day", "paid_rest", "unpaid_rest"].includes(phase)) return "upcoming";
  if (phase === "before_work") return kind === "work_start" ? "current" : "upcoming";
  if (phase === "after_work") return "completed";

  const orderedKinds = hasRest(schedule)
    ? ["work_start", "rest_start", "work_resume", "work_end"] as TimelineRowKind[]
    : ["work_start", "work_end"] as TimelineRowKind[];
  const boundaryKind = schedule.nextBoundaryKind;
  if (boundaryKind) {
    const boundaryIndex = orderedKinds.indexOf(boundaryKind);
    const rowIndex = orderedKinds.indexOf(kind);
    if (rowIndex < boundaryIndex) return "completed";
    if (rowIndex === boundaryIndex) return "current";
  }

  if (phase === "lunch" && kind === "work_resume") return "current";
  if (phase === "working" && kind === "work_start") return "completed";
  return "upcoming";
}

export function timelineRows(schedule: TimelineSchedule): TimelineRow[] {
  const rows: Array<Omit<TimelineRow, "state">> = [
    {
      kind: "work_start",
      time: displayClock(schedule.workStartTime, schedule),
      title: "开始工作",
      detail: `计划 ${displayClock(schedule.workStartTime, schedule)} 开始`,
    },
  ];
  if (hasRest(schedule)) {
    rows.push(
      {
        kind: "rest_start",
        time: displayClock(schedule.restStartTime, schedule),
        title: "开始休息",
        detail: `${displayClock(schedule.restStartTime, schedule)}–${displayClock(schedule.restEndTime, schedule)}`,
      },
      {
        kind: "work_resume",
        time: displayClock(schedule.restEndTime, schedule),
        title: "恢复工作",
        detail: `计划 ${displayClock(schedule.restEndTime, schedule)} 恢复`,
      },
    );
  }
  rows.push({
    kind: "work_end",
    time: displayClock(schedule.workEndTime, schedule),
    title: "结束工作",
    detail: `计划 ${displayClock(schedule.workEndTime, schedule)} 下班`,
  });
  return rows.map(row => ({
    ...row,
    state: timelineState(schedule.phase, row.kind, schedule),
  }));
}

export function workbenchHeading(ownerDate: string, localDate: string) {
  if (ownerDate === localDate) {
    return { title: "今日收入进度", subtitle: ownerDate };
  }
  return {
    title: "本次夜班收入进度",
    subtitle: `归属日期 ${ownerDate}`,
  };
}

export type CalendarBusinessState =
  | "workday"
  | "rest_day"
  | "adjusted_workday"
  | "manual_workday"
  | "paid_rest"
  | "unpaid_rest";

export function calendarBusinessState(day: {
  kind: "workday" | "rest_day";
  source: string;
  automatic_source: string;
  override_kind: "workday" | "paid_rest" | "unpaid_rest" | null;
}): CalendarBusinessState {
  if (day.override_kind === "workday") return "manual_workday";
  if (day.override_kind === "paid_rest") return "paid_rest";
  if (day.override_kind === "unpaid_rest") return "unpaid_rest";
  if (day.source === "adjusted_workday" || day.automatic_source === "adjusted_workday") {
    return "adjusted_workday";
  }
  return day.kind === "rest_day" ? "rest_day" : "workday";
}

export interface CalendarCellPresentation {
  businessState: CalendarBusinessState;
  isToday: boolean;
  isSelected: boolean;
  isStale?: boolean;
  isDisabled?: boolean;
}

export interface CalendarCoveragePresentation {
  isVisible: boolean;
  title: string;
  detail: string;
  tone: "estimated" | "stale" | "error" | null;
}

export function calendarCoveragePresentation(input: {
  mode: "official" | "estimated" | "stale" | "integrity_error";
  year: number;
}): CalendarCoveragePresentation {
  if (input.mode === "official") {
    return {
      isVisible: false,
      title: "",
      detail: "",
      tone: null,
    };
  }
  if (input.mode === "estimated") {
    return {
      isVisible: true,
      title: "当前年份使用估算日历",
      detail: `${input.year} 年按你的休息模式推算，不代表法定放假安排`,
      tone: "estimated",
    };
  }
  if (input.mode === "stale") {
    return {
      isVisible: true,
      title: "日历数据可能已过期",
      detail: "当前继续显示上次有效数据，日期调整暂不可用",
      tone: "stale",
    };
  }
  return {
    isVisible: true,
    title: "日历暂时无法加载",
    detail: "数据完整性校验未通过，未使用估算结果替代",
    tone: "error",
  };
}

export function calendarCellContract(input: CalendarCellPresentation) {
  const labels: Record<CalendarBusinessState, string> = {
    workday: "工作日",
    rest_day: "休息日",
    adjusted_workday: "官方调休工作日",
    manual_workday: "手动工作日",
    paid_rest: "带薪休息",
    unpaid_rest: "不带薪休息",
  };
  return {
    classNames: [
      `calendar-day--${input.businessState}`,
      input.isToday ? "is-today" : "",
      input.isSelected ? "is-selected" : "",
      input.isStale ? "is-stale" : "",
      input.isDisabled ? "is-disabled" : "",
    ].filter(Boolean),
    todayCue: input.isToday ? "今" : null,
    ariaLabel: [
      labels[input.businessState],
      input.isToday ? "今天" : "",
      input.isSelected ? "当前选中" : "",
      input.isStale ? "数据可能不是最新" : "",
      input.isDisabled ? "不可用" : "",
    ].filter(Boolean).join("，"),
  };
}
