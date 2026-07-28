import { useCallback, useEffect, useMemo, useReducer, useRef, useState } from "react";
import { invoke } from "@tauri-apps/api/core";
import { listen } from "@tauri-apps/api/event";
import {
  defaultConfig,
  type AppConfig,
  type DateOverrideKind,
} from "./configModel";
import {
  createCalendarState,
  reduceCalendarState,
  type CalendarLoadStatus,
} from "./calendarState";
import {
  calculateLocalTick,
  needsAuthoritativeCorrection,
  shouldApplyAuthoritativeSnapshot,
  shouldRetryInitialSync,
  syncFailureDisposition,
  wallClockJumped,
  type TickAuthority,
} from "./authoritativeSync";
import type { BoundaryKind } from "./presentation";

export type DashboardState = "loading" | "ready" | "setup" | "error";
export type WorkPhase =
  | "working"
  | "lunch"
  | "before_work"
  | "after_work"
  | "rest_day"
  | "paid_rest"
  | "unpaid_rest";
export type CalendarDayKind = "workday" | "rest_day";

export interface CalendarDaySnapshot {
  date: string;
  kind: CalendarDayKind;
  source: string;
  automatic_kind: CalendarDayKind;
  automatic_source: string;
  override_kind: DateOverrideKind | null;
}

interface CalendarPayload {
  statutory_holidays: string[];
  adjusted_workdays: string[];
  date_overrides: AppConfig["date_overrides"];
}

interface CalendarDatasetResponse {
  year: number;
  dataset_version: string;
  source: {
    publisher: string;
    title: string;
    document_no: string;
    published_at: string;
    url: string;
  };
  calendar: Omit<CalendarPayload, "date_overrides"> & {
    date_overrides: AppConfig["date_overrides"];
  };
}

const calendarDatasetCache = new Map<number, Promise<CalendarDatasetResponse>>();

export interface DashboardSnapshot {
  state: DashboardState;
  phase: WorkPhase;
  workState: string;
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
  syncState: "synced" | "syncing" | "stale";
  algorithmVersion: string;
  effectiveSeconds: number;
  nextBoundarySeconds: number | null;
  nextBoundaryKind: BoundaryKind;
  workStartTime: string;
  lunchStartTime: string;
  lunchEndTime: string;
  workEndTime: string;
  nextWorkDate: string | null;
  calendarDays: CalendarDaySnapshot[];
  message?: string;
  errorCode?: string;
}

type SalarySlotKind = "workday" | "paid_rest" | "unpaid_rest";

interface SalarySlot {
  date: string;
  index: number;
  kind: SalarySlotKind;
  target_minor: number;
  payable_minor: number;
}

interface MonthSalaryResult {
  workdays: number;
  salary_slot_count: number;
  daily_salary_minor: number;
  hourly_salary_minor: number;
  payable_salary_minor: number;
  working_saturdays: string[];
  salary_slots: SalarySlot[];
}

export type WorkdayPreviewState = "loading" | "ready" | "needs_week_type" | "error";

export interface WorkdayPreview {
  state: WorkdayPreviewState;
  workdays: number | null;
}

function isTauri() {
  return "__TAURI_INTERNALS__" in window;
}

export function recordSemanticEvent(event: string, detail: string) {
  if (!isTauri()) return;
  void invoke("record_semantic_event", { event, detail }).catch(() => {
    // Logging must never replace or interrupt the user-visible result.
  });
}

function localDateKey(date: Date) {
  return `${date.getFullYear()}-${String(date.getMonth() + 1).padStart(2, "0")}-${String(date.getDate()).padStart(2, "0")}`;
}

function monthKey(date: Date) {
  return `${date.getFullYear()}-${String(date.getMonth() + 1).padStart(2, "0")}`;
}

function mondaySerial(date: Date) {
  const copy = new Date(date.getFullYear(), date.getMonth(), date.getDate());
  const weekday = copy.getDay() || 7;
  copy.setDate(copy.getDate() - weekday + 1);
  return Math.floor(copy.getTime() / 86_400_000);
}

function fallbackWorkdays(config: AppConfig, now: Date) {
  const days = new Date(now.getFullYear(), now.getMonth() + 1, 0).getDate();
  const anchor = config.alternating_anchor_date
    ? new Date(`${config.alternating_anchor_date}T00:00:00`)
    : null;
  let workdays = 0;
  for (let day = 1; day <= days; day += 1) {
    const date = new Date(now.getFullYear(), now.getMonth(), day);
    const weekday = date.getDay() || 7;
    if (config.rest_mode === "double" && weekday <= 5) workdays += 1;
    if (config.rest_mode === "single" && weekday <= 6) workdays += 1;
    if (config.rest_mode === "alternating" && anchor && config.alternating_anchor_week_type) {
      const deltaWeeks = Math.floor((mondaySerial(date) - mondaySerial(anchor)) / 7);
      const anchorIsBig = config.alternating_anchor_week_type === "big";
      const isBig = Math.abs(deltaWeeks % 2) === 0 ? anchorIsBig : !anchorIsBig;
      if (weekday <= 5 || (weekday === 6 && isBig)) workdays += 1;
    }
  }
  return workdays;
}

function toSchedule(config: AppConfig) {
  return {
    monthly_salary_minor: Math.round(config.monthly_salary * 100),
    rest_mode: config.rest_mode,
    alternating_anchor_date: config.alternating_anchor_date,
    alternating_anchor_week_type: config.alternating_anchor_week_type,
    work_hours_per_day: config.work_hours_per_day,
    work_start_time: config.work_start_time,
    work_end_time: config.work_end_time,
    lunch_start_time: config.lunch_start_time,
    lunch_end_time: config.lunch_end_time,
  };
}

function withCalendarOverrides(
  calendar: Omit<CalendarPayload, "date_overrides">,
  config: AppConfig,
): CalendarPayload {
  return {
    statutory_holidays: calendar.statutory_holidays,
    adjusted_workdays: calendar.adjusted_workdays,
    date_overrides: config.date_overrides,
  };
}

async function loadCalendarForYear(year: number, config: AppConfig) {
  let pending = calendarDatasetCache.get(year);
  if (!pending) {
    pending = invoke<CalendarDatasetResponse>("load_calendar_year", { year });
    calendarDatasetCache.set(year, pending);
  }
  let dataset: CalendarDatasetResponse;
  try {
    dataset = await pending;
  } catch (error) {
    calendarDatasetCache.delete(year);
    throw error;
  }
  return {
    datasetVersion: dataset.dataset_version,
    calendar: withCalendarOverrides(dataset.calendar, config),
  };
}

export function useMonthWorkdayPreview(config: AppConfig): WorkdayPreview {
  const [preview, setPreview] = useState<WorkdayPreview>({
    state: "loading",
    workdays: null,
  });
  const previewKey = JSON.stringify({
    monthly_salary: config.monthly_salary,
    rest_mode: config.rest_mode,
    alternating_anchor_date: config.alternating_anchor_date,
    alternating_anchor_week_type: config.alternating_anchor_week_type,
    work_hours_per_day: config.work_hours_per_day,
    date_overrides: config.date_overrides,
  });

  useEffect(() => {
    if (config.rest_mode === "alternating" && !config.alternating_anchor_week_type) {
      setPreview({ state: "needs_week_type", workdays: null });
      return;
    }
    const now = new Date();
    if (!isTauri()) {
      setPreview({ state: "ready", workdays: fallbackWorkdays(config, now) });
      return;
    }
    let active = true;
    setPreview(current => ({ state: "loading", workdays: current.workdays }));
    void loadCalendarForYear(now.getFullYear(), config)
      .then(({ calendar }) => invoke<{ workdays: number }>("calculate_month_salary", {
        month: monthKey(now),
        schedule: toSchedule(config),
        calendar,
      }))
      .then(result => {
        if (active) setPreview({ state: "ready", workdays: result.workdays });
      })
      .catch(() => {
        if (active) setPreview({ state: "error", workdays: null });
      });
    return () => {
      active = false;
    };
  }, [previewKey]);

  return preview;
}

function fallbackCalendarDays(now: Date): CalendarDaySnapshot[] {
  const daysInMonth = new Date(now.getFullYear(), now.getMonth() + 1, 0).getDate();
  return Array.from({ length: daysInMonth }, (_, index) => {
    const date = new Date(now.getFullYear(), now.getMonth(), index + 1);
    const weekend = date.getDay() === 0 || date.getDay() === 6;
    return {
      date: localDateKey(date),
      kind: weekend ? "rest_day" : "workday",
      source: "rest_mode",
      automatic_kind: weekend ? "rest_day" : "workday",
      automatic_source: "rest_mode",
      override_kind: null,
    };
  });
}

function fallbackSnapshot(now: Date): DashboardSnapshot {
  const calendarDays = fallbackCalendarDays(now);
  const ownerDate = localDateKey(now);
  const isRestDay = calendarDays.find(day => day.date === ownerDate)?.kind === "rest_day";
  const start = 8 * 3600;
  const lunchStart = 12 * 3600;
  const lunchEnd = 14 * 3600;
  const end = 18 * 3600;
  const second = now.getHours() * 3600 + now.getMinutes() * 60 + now.getSeconds();
  const first = Math.max(0, Math.min(second, lunchStart) - start);
  const secondSegment = Math.max(0, Math.min(second, end) - lunchEnd);
  const completed = isRestDay ? 0 : Math.max(0, Math.min(8 * 3600, first + secondSegment));
  const progress = completed / (8 * 3600);
  const phase: WorkPhase = isRestDay
    ? "rest_day"
    : second < start
      ? "before_work"
      : second < lunchStart
        ? "working"
        : second < lunchEnd
          ? "lunch"
          : second < end
            ? "working"
            : "after_work";
  const workState = {
    working: "工作中",
    lunch: "休息中",
    before_work: "上班前",
    after_work: "已下班",
    rest_day: "休息日",
  }[phase];
  const nextWorkDate = calendarDays.find(day => day.date > ownerDate && day.kind === "workday")?.date ?? null;
  const priorWorkdays = calendarDays.filter(day => day.date < ownerDate && day.kind === "workday").length;
  const [nextBoundarySeconds, nextBoundaryKind]: [number | null, BoundaryKind] = isRestDay
    ? [null, null]
    : phase === "before_work"
      ? [Math.max(0, start - second), "work_start"]
      : phase === "working" && second < lunchStart
        ? [Math.max(0, lunchStart - second), "rest_start"]
        : phase === "lunch"
          ? [Math.max(0, lunchEnd - second), "work_resume"]
          : phase === "working"
            ? [Math.max(0, end - second), "work_end"]
            : [null, null];
  return {
    state: "ready",
    phase,
    workState,
    ownerDate,
    amount: isRestDay ? 0 : 500 * progress,
    dailySalary: 500,
    hourlySalary: 62.5,
    progress: Math.round(progress * 100),
    completedSeconds: completed,
    remainingSeconds: isRestDay ? 0 : Math.max(0, 8 * 3600 - completed),
    monthTotal: priorWorkdays * 500 + (isRestDay ? 0 : 500 * progress),
    expectedMonthlyPay: 10_000,
    workdays: calendarDays.filter(day => day.kind === "workday").length,
    salarySlotCount: calendarDays.filter(day => day.kind === "workday").length,
    syncState: "synced",
    algorithmVersion: "browser-preview",
    effectiveSeconds: 8 * 3600,
    nextBoundarySeconds,
    nextBoundaryKind,
    workStartTime: "08:00",
    lunchStartTime: "12:00",
    lunchEndTime: "14:00",
    workEndTime: "18:00",
    nextWorkDate,
    calendarDays,
  };
}

export function useDashboard() {
  const [snapshot, setSnapshot] = useState<DashboardSnapshot>({
    ...fallbackSnapshot(new Date()),
    state: "loading",
  });
  const lastErrorCode = useRef<string | null>(null);
  const requestSequence = useRef(0);
  const appliedSequence = useRef(0);
  const authority = useRef<TickAuthority | null>(null);
  const boundarySyncPending = useRef(false);
  const consecutiveSyncFailures = useRef(0);
  const lastOwnerDate = useRef<string | null>(null);
  const clockSample = useRef({ wall: Date.now(), monotonic: performance.now() });
  const initialRetryTimer = useRef<number | null>(null);

  const refreshAuthority = useCallback(async function refreshAuthorityRequest(reason: string) {
    const sequence = ++requestSequence.current;
    const now = new Date();
    if (!isTauri()) {
      setSnapshot(fallbackSnapshot(now));
      return;
    }
    setSnapshot(current => current.state === "ready"
      ? {
          ...current,
          syncState: current.syncState === "stale" ? "stale" : "syncing",
        }
      : current);
    recordSemanticEvent(
      "earnings.authoritative_sync.requested",
      `sequence=${sequence} reason=${reason}`,
    );
    try {
      const config = await invoke<AppConfig>("read_configuration");
      const schedule = toSchedule(config);
      const nowDate = localDateKey(now);
      const nowTime = `${String(now.getHours()).padStart(2, "0")}:${String(now.getMinutes()).padStart(2, "0")}:${String(now.getSeconds()).padStart(2, "0")}`;
      const ownerDate = await invoke<string>("resolve_schedule_owner_date", {
        nowDate,
        nowTime,
        schedule,
      });
      if (ownerDate !== lastOwnerDate.current) {
        recordSemanticEvent(
          "schedule.owner_date.resolved",
          `owner_date=${ownerDate} overnight=${schedule.work_end_time <= schedule.work_start_time}`,
        );
        lastOwnerDate.current = ownerDate;
      }
      const ownerYear = Number(ownerDate.slice(0, 4));
      const currentMonth = ownerDate.slice(0, 7);
      const { calendar } = await loadCalendarForYear(ownerYear, config);
      const month = await invoke<MonthSalaryResult>("calculate_month_salary", {
        month: currentMonth,
        schedule,
        calendar,
      });
      const calendarDays = await invoke<CalendarDaySnapshot[]>("resolve_calendar_month", {
        month: currentMonth,
        schedule,
        calendar,
      });
      const today = await invoke<{
        state: string;
        schedule_owner_date: string;
        algorithm_version: string;
        monthly_salary_minor: number;
        effective_work_seconds: number;
        completed_work_seconds: number;
        earned_minor: number;
        daily_target_minor: number;
        hourly_salary_minor: number;
        month_earned_minor: number;
        payable_salary_minor: number;
        salary_slot_index: number | null;
        salary_slot_count: number;
        next_boundary_seconds: number | null;
        next_boundary_kind: BoundaryKind;
        progress: number;
      }>("calculate_today_income", {
        request: {
          owner_date: ownerDate,
          now_date: nowDate,
          now_time: nowTime,
          schedule,
          month_salary: month,
          calendar,
        },
      });
      const phase = today.state as WorkPhase;
      const nextWorkDate = ["rest_day", "paid_rest", "unpaid_rest"].includes(phase)
        ? await invoke<string | null>("resolve_next_workday", {
            afterDate: ownerDate,
            schedule,
            calendar,
          })
        : null;
      if (!shouldApplyAuthoritativeSnapshot(requestSequence.current, sequence)) {
        recordSemanticEvent(
          "earnings.authoritative_sync.ignored",
          `sequence=${sequence} current=${appliedSequence.current}`,
        );
        return;
      }
      const nextSnapshot: DashboardSnapshot = {
        state: "ready",
        phase,
        workState: {
          working: "工作中",
          lunch: "休息中",
          before_work: "上班前",
          after_work: "已下班",
          rest_day: "休息日",
          paid_rest: "带薪休息",
          unpaid_rest: "不带薪休息",
        }[today.state] ?? today.state,
        ownerDate: today.schedule_owner_date,
        amount: today.earned_minor / 100,
        dailySalary: today.daily_target_minor / 100,
        hourlySalary: today.hourly_salary_minor / 100,
        progress: Math.round(today.progress * 100),
        completedSeconds: today.completed_work_seconds,
        remainingSeconds: ["rest_day", "paid_rest", "unpaid_rest"].includes(phase)
          ? 0
          : Math.max(0, today.effective_work_seconds - today.completed_work_seconds),
        monthTotal: today.month_earned_minor / 100,
        expectedMonthlyPay: today.payable_salary_minor / 100,
        workdays: month.workdays,
        salarySlotCount: month.salary_slot_count,
        syncState: "synced",
        algorithmVersion: today.algorithm_version,
        effectiveSeconds: today.effective_work_seconds,
        nextBoundarySeconds: today.next_boundary_seconds,
        nextBoundaryKind: today.next_boundary_kind,
        workStartTime: config.work_start_time,
        lunchStartTime: config.lunch_start_time,
        lunchEndTime: config.lunch_end_time,
        workEndTime: config.work_end_time,
        nextWorkDate,
        calendarDays,
      };
      const nextAuthority: TickAuthority = {
        sequence,
        capturedAtMs: Math.floor(now.getTime() / 1000) * 1000,
        phase,
        ownerDate: today.schedule_owner_date,
        monthlySalaryMinor: today.monthly_salary_minor,
        salarySlotIndex: today.salary_slot_index,
        salarySlotCount: today.salary_slot_count,
        effectiveSeconds: today.effective_work_seconds,
        completedSeconds: today.completed_work_seconds,
        todayMinor: today.earned_minor,
        monthEarnedMinor: today.month_earned_minor,
        nextBoundarySeconds: today.next_boundary_seconds,
      };
      appliedSequence.current = sequence;
      authority.current = nextAuthority;
      boundarySyncPending.current = false;
      setSnapshot(current => {
        if (current.state === "ready") {
          const correctionReasons = [
            needsAuthoritativeCorrection(
              Math.round(current.amount * 100),
              today.earned_minor,
            ) ? "amount" : null,
            current.ownerDate !== nextSnapshot.ownerDate ? "owner_date" : null,
            current.phase !== nextSnapshot.phase ? "phase" : null,
          ].filter(Boolean);
          if (correctionReasons.length > 0) {
          recordSemanticEvent(
            "earnings.authoritative_sync.drift_corrected",
              `sequence=${sequence} reasons=${correctionReasons.join(",")} drift_minor=${Math.abs(Math.round(current.amount * 100) - today.earned_minor)}`,
          );
          }
        }
        return nextSnapshot;
      });
      recordSemanticEvent(
        "earnings.authoritative_sync.completed",
        `sequence=${sequence} owner_date=${today.schedule_owner_date} phase=${today.state}`,
      );
      if (initialRetryTimer.current !== null) {
        window.clearTimeout(initialRetryTimer.current);
        initialRetryTimer.current = null;
      }
      lastErrorCode.current = null;
      consecutiveSyncFailures.current = 0;
    } catch (error) {
      if (!shouldApplyAuthoritativeSnapshot(requestSequence.current, sequence)) return;
      const { code, message } = describeDashboardError(error);
      consecutiveSyncFailures.current += 1;
      if (
        shouldRetryInitialSync(
          authority.current !== null,
          code,
          consecutiveSyncFailures.current,
        )
      ) {
        recordSemanticEvent(
          "earnings.authoritative_sync.retry_scheduled",
          `sequence=${sequence} reason=${code} attempt=${consecutiveSyncFailures.current}`,
        );
        if (initialRetryTimer.current !== null) {
          window.clearTimeout(initialRetryTimer.current);
        }
        initialRetryTimer.current = window.setTimeout(() => {
          initialRetryTimer.current = null;
          void refreshAuthorityRequest("startup_retry");
        }, 500);
        return;
      }
      if (lastErrorCode.current !== code) {
        lastErrorCode.current = code;
        recordSemanticEvent(
          "earnings.authoritative_sync.failed",
          `sequence=${sequence} reason=${code}`,
        );
      }
      setSnapshot(current => {
        const crossedBoundaryWithoutAuthority =
          current.state === "ready"
          && syncFailureDisposition(
            consecutiveSyncFailures.current,
            boundarySyncPending.current,
          ) === "blocked";
        if (crossedBoundaryWithoutAuthority) {
          recordSemanticEvent(
            "earnings.local_tick.paused",
            `owner_date=${current.ownerDate} reason=boundary_sync_failed`,
          );
          return {
            ...current,
            state: "error" as const,
            syncState: "stale" as const,
            message: "时间边界后的结果尚未同步成功，请重试。",
            errorCode: code,
          };
        }
        return {
          ...current,
          ...(current.state === "ready"
            ? {
                syncState: "stale" as const,
                message: "正在重新同步，当前显示最近一次可信结果。",
                errorCode: code,
              }
            : {
                state: "error" as const,
                message,
                errorCode: code,
              }),
        };
      });
    }
  }, []);

  useEffect(() => {
    void refreshAuthority("startup");
    const localTimer = window.setInterval(() => {
      if (document.visibilityState === "hidden") return;
      const wallNow = Date.now();
      const monotonicNow = performance.now();
      if (wallClockJumped(
        clockSample.current.wall,
        clockSample.current.monotonic,
        wallNow,
        monotonicNow,
      )) {
        clockSample.current = { wall: wallNow, monotonic: monotonicNow };
        recordSemanticEvent("schedule.wall_clock_changed", "action=authoritative_sync");
        void refreshAuthority("wall_clock_changed");
        return;
      }
      clockSample.current = { wall: wallNow, monotonic: monotonicNow };
      const currentAuthority = authority.current;
      if (!currentAuthority) return;
      const tick = calculateLocalTick(currentAuthority, wallNow);
      setSnapshot(current => {
        if (
          current.state !== "ready"
          || current.ownerDate !== currentAuthority.ownerDate
          || current.phase !== currentAuthority.phase
        ) {
          return current;
        }
        return {
          ...current,
          amount: tick.todayMinor / 100,
          monthTotal: tick.monthEarnedMinor / 100,
          completedSeconds: tick.completedSeconds,
          nextBoundarySeconds: tick.nextBoundarySeconds,
          remainingSeconds: Math.max(0, current.effectiveSeconds - tick.completedSeconds),
          progress: current.effectiveSeconds > 0
            ? Math.round((tick.completedSeconds / current.effectiveSeconds) * 100)
            : 0,
        };
      });
      if (tick.reachedBoundary && !boundarySyncPending.current) {
        boundarySyncPending.current = true;
        recordSemanticEvent(
          "earnings.boundary.recalculated",
          `owner_date=${currentAuthority.ownerDate} phase=${currentAuthority.phase}`,
        );
        void refreshAuthority("business_boundary");
      }
    }, 1000);
    const authorityTimer = window.setInterval(() => {
      if (document.visibilityState !== "hidden") {
        void refreshAuthority("interval_30s");
      }
    }, 30_000);
    const handleConfigurationUpdate = () => void refreshAuthority("configuration_updated");
    const handleFocus = () => void refreshAuthority("window_focus");
    const handleVisibility = () => {
      if (document.visibilityState === "visible") {
        clockSample.current = { wall: Date.now(), monotonic: performance.now() };
        void refreshAuthority("window_visible");
      }
    };
    window.addEventListener("lmm:configuration-updated", handleConfigurationUpdate);
    window.addEventListener("focus", handleFocus);
    document.addEventListener("visibilitychange", handleVisibility);
    let unlistenConfiguration: (() => void) | null = null;
    if (isTauri()) {
      void listen("lmm://configuration-updated", handleConfigurationUpdate).then(unlisten => {
        unlistenConfiguration = unlisten;
      });
    }
    return () => {
      window.clearInterval(localTimer);
      window.clearInterval(authorityTimer);
      if (initialRetryTimer.current !== null) {
        window.clearTimeout(initialRetryTimer.current);
        initialRetryTimer.current = null;
      }
      window.removeEventListener("lmm:configuration-updated", handleConfigurationUpdate);
      window.removeEventListener("focus", handleFocus);
      document.removeEventListener("visibilitychange", handleVisibility);
      unlistenConfiguration?.();
    };
  }, [refreshAuthority]);

  const refresh = useCallback(() => {
    void refreshAuthority("manual");
  }, [refreshAuthority]);

  return { snapshot, refresh };
}

const DASHBOARD_ERROR_CODES = [
  "invalid_monthly_salary",
  "invalid_salary_denominator",
  "salary.zero_slots",
  "salary.owner_slot_missing",
  "schedule.owner_date_mismatch",
  "invalid_work_hours",
  "invalid_time",
  "invalid_lunch_interval",
  "invalid_work_interval",
  "alternating_anchor_date_required",
  "alternating_week_type_required",
] as const;

function describeDashboardError(error: unknown) {
  const raw = error instanceof Error ? error.message : String(error);
  const code = DASHBOARD_ERROR_CODES.find(candidate => raw.includes(candidate)) ?? "calculation_unavailable";
  if (code === "invalid_monthly_salary" || code === "invalid_salary_denominator") {
    return { code, message: "请检查月薪和休息模式后重试。" };
  }
  if (code === "alternating_anchor_date_required" || code === "alternating_week_type_required") {
    return { code, message: "大小周需要明确选择本周是大周还是小周。" };
  }
  if (code !== "calculation_unavailable") {
    return { code, message: "请检查上班、下班和休息时间后重试。" };
  }
  return { code, message: "请稍后重试；若仍失败，请检查设置。" };
}

export function dashboardErrorTitle(errorCode?: string) {
  if (errorCode === "invalid_monthly_salary" || errorCode === "invalid_salary_denominator") {
    return "收入配置有误";
  }
  if (errorCode === "alternating_anchor_date_required" || errorCode === "alternating_week_type_required") {
    return "大小周尚未配置完整";
  }
  if (errorCode && errorCode !== "calculation_unavailable") {
    return "工作时间配置有误";
  }
  return "暂时无法计算";
}

export function formatMoney(value: number) {
  return new Intl.NumberFormat("zh-CN", {
    style: "currency",
    currency: "CNY",
    minimumFractionDigits: 2,
  }).format(value);
}

export function formatDuration(seconds: number) {
  const hours = Math.floor(seconds / 3600);
  const minutes = Math.floor((seconds % 3600) / 60);
  const remaining = Math.floor(seconds % 60);
  return `${String(hours).padStart(2, "0")}:${String(minutes).padStart(2, "0")}:${String(remaining).padStart(2, "0")}`;
}

export function useCalendarMonth(month: string, currentMonthDays: CalendarDaySnapshot[]) {
  const initialMonth = currentMonthDays[0]?.date.slice(0, 7);
  const lastValidMonth = useRef(initialMonth);
  const [calendarState, dispatch] = useReducer(
    reduceCalendarState,
    createCalendarState(
      initialMonth
        ? {
            month: initialMonth,
            days: currentMonthDays,
            datasetVersion: "dashboard",
          }
        : undefined,
    ),
  );
  const requestId = useRef(0);
  const [retryRevision, setRetryRevision] = useState(0);

  useEffect(() => {
    const activeRequestId = requestId.current + 1;
    requestId.current = activeRequestId;
    dispatch({ type: "requested", requestId: activeRequestId, targetMonth: month });
    const load = async () => {
      try {
        if (!isTauri()) {
          const [year, monthNumber] = month.split("-").map(Number);
          const result = fallbackCalendarDays(new Date(year, monthNumber - 1, 1));
          if (requestId.current !== activeRequestId) return;
          lastValidMonth.current = month;
          dispatch({
            type: "resolved",
            requestId: activeRequestId,
            targetMonth: month,
            data: { month, days: result, datasetVersion: "browser-preview" },
          });
          return;
        }
        const config = await invoke<AppConfig>("read_configuration");
        const year = Number(month.slice(0, 4));
        const { calendar, datasetVersion } = await loadCalendarForYear(year, config);
        const result = await invoke<CalendarDaySnapshot[]>("resolve_calendar_month", {
          month,
          schedule: toSchedule(config),
          calendar,
        });
        if (requestId.current !== activeRequestId) {
          recordSemanticEvent(
            "calendar.request.ignored",
            `target_month=${month};reason=late_result`,
          );
          return;
        }
        lastValidMonth.current = month;
        dispatch({
          type: "resolved",
          requestId: activeRequestId,
          targetMonth: month,
          data: { month, days: result, datasetVersion },
        });
      } catch (error) {
        if (requestId.current !== activeRequestId) {
          recordSemanticEvent(
            "calendar.request.ignored",
            `target_month=${month};reason=late_failure`,
          );
          return;
        }
        const errorCode = calendarErrorCode(error);
        if (lastValidMonth.current) {
          recordSemanticEvent(
            "calendar.dataset.stale",
            `target_month=${month};displayed_month=${lastValidMonth.current};reason=${errorCode}`,
          );
        }
        dispatch({
          type: "failed",
          requestId: activeRequestId,
          targetMonth: month,
          errorCode,
        });
      }
    };
    void load();
  }, [month, retryRevision]);

  const canDisplayData =
    calendarState.status === "ready"
    || calendarState.status === "empty"
    || calendarState.status === "stale";
  return {
    days: canDisplayData ? calendarState.data?.days ?? [] : [],
    state: calendarState.status as CalendarLoadStatus,
    dataMonth: canDisplayData ? calendarState.data?.month : undefined,
    datasetVersion: canDisplayData ? calendarState.data?.datasetVersion : undefined,
    errorCode: calendarState.errorCode,
    retry: () => setRetryRevision(value => value + 1),
  };
}

export interface DateOverrideSaveResult {
  status: "saved" | "unchanged" | "failed";
  message: string;
  draft_preserved: boolean;
}

export async function saveDateOverride(
  date: string,
  kind: DateOverrideKind | null,
): Promise<DateOverrideSaveResult> {
  if (isTauri()) {
    return invoke<DateOverrideSaveResult>("save_date_override", { date, kind });
  }
  const config: AppConfig = JSON.parse(
    localStorage.getItem("lmm.config") ?? JSON.stringify(defaultConfig),
  );
  const next = {
    ...config,
    date_overrides: config.date_overrides
      .filter(entry => entry.date !== date)
      .concat(kind ? [{ date, kind, note: "" }] : [])
      .sort((left, right) => left.date.localeCompare(right.date)),
  };
  if (JSON.stringify(config) === JSON.stringify(next)) {
    return {
      status: "unchanged",
      message: "没有需要保存的更改",
      draft_preserved: true,
    };
  }
  localStorage.setItem("lmm.config", JSON.stringify(next));
  return {
    status: "saved",
    message: kind ? "日期调整已应用" : "已恢复自动判断",
    draft_preserved: false,
  };
}

function calendarErrorCode(error: unknown) {
  const raw = error instanceof Error ? error.message : String(error);
  const known = [
    "calendar_year_unsupported:",
    "calendar_manifest_invalid",
    "calendar_hash_mismatch:",
    "calendar_dataset_invalid:",
  ].find(code => raw.includes(code));
  if (!known) return "calendar_load_failed";
  if (known.endsWith(":")) {
    const suffix = raw.slice(raw.indexOf(known) + known.length).match(/^\d{4}/)?.[0];
    return `${known}${suffix ?? "unknown"}`;
  }
  return known;
}
