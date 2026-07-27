import { useCallback, useEffect, useMemo, useRef, useState } from "react";
import { invoke } from "@tauri-apps/api/core";
import { defaultConfig, type AppConfig } from "./configModel";

export type DashboardState = "loading" | "ready" | "setup" | "error";
export type WorkPhase = "working" | "lunch" | "before_work" | "after_work" | "rest_day";
export type CalendarDayKind = "workday" | "rest_day";

export interface CalendarDaySnapshot {
  date: string;
  kind: CalendarDayKind;
  source: string;
}

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
  workdays: number;
  effectiveSeconds: number;
  workStartTime: string;
  lunchStartTime: string;
  lunchEndTime: string;
  workEndTime: string;
  nextWorkDate: string | null;
  calendarDays: CalendarDaySnapshot[];
  message?: string;
  errorCode?: string;
}

export type WorkdayPreviewState = "loading" | "ready" | "needs_week_type" | "error";

export interface WorkdayPreview {
  state: WorkdayPreviewState;
  workdays: number | null;
}

function isTauri() {
  return "__TAURI_INTERNALS__" in window;
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

function toCalendar(config: AppConfig) {
  return {
    statutory_holidays: [] as string[],
    adjusted_workdays: [] as string[],
    date_overrides: config.date_overrides,
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
    void invoke<{ workdays: number }>("calculate_month_salary", {
      month: monthKey(now),
      schedule: toSchedule(config),
      calendar: toCalendar(config),
    })
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
    lunch: "午休中",
    before_work: "上班前",
    after_work: "已下班",
    rest_day: "休息日",
  }[phase];
  const nextWorkDate = calendarDays.find(day => day.date > ownerDate && day.kind === "workday")?.date ?? null;
  const priorWorkdays = calendarDays.filter(day => day.date < ownerDate && day.kind === "workday").length;
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
    workdays: calendarDays.filter(day => day.kind === "workday").length,
    effectiveSeconds: 8 * 3600,
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

  const refresh = useCallback(async () => {
    const now = new Date();
    if (!isTauri()) {
      setSnapshot(fallbackSnapshot(now));
      return;
    }
    try {
      const config = await invoke<AppConfig>("read_configuration");
      const schedule = toSchedule(config);
      const calendar = toCalendar(config);
      const ownerDate = localDateKey(now);
      const currentMonth = monthKey(now);
      const month = await invoke<{
        workdays: number;
        daily_salary_minor: number;
        hourly_salary_minor: number;
      }>("calculate_month_salary", {
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
        effective_work_seconds: number;
        completed_work_seconds: number;
        earned_minor: number;
        progress: number;
      }>("calculate_today_income", {
        request: {
          owner_date: ownerDate,
          now_date: ownerDate,
          now_time: `${String(now.getHours()).padStart(2, "0")}:${String(now.getMinutes()).padStart(2, "0")}`,
          schedule,
          daily_salary_minor: month.daily_salary_minor,
          calendar,
        },
      });
      const phase = today.state as WorkPhase;
      const nextWorkDate = phase === "rest_day"
        ? await invoke<string | null>("resolve_next_workday", {
            afterDate: ownerDate,
            schedule,
            calendar,
          })
        : null;
      const priorWorkdays = calendarDays.filter(day => day.date < ownerDate && day.kind === "workday").length;
      setSnapshot({
        state: "ready",
        phase,
        workState: {
          working: "工作中",
          lunch: "午休中",
          before_work: "上班前",
          after_work: "已下班",
          rest_day: "休息日",
        }[today.state] ?? today.state,
        ownerDate: today.schedule_owner_date,
        amount: today.earned_minor / 100,
        dailySalary: month.daily_salary_minor / 100,
        hourlySalary: month.hourly_salary_minor / 100,
        progress: Math.round(today.progress * 100),
        completedSeconds: today.completed_work_seconds,
        remainingSeconds: phase === "rest_day"
          ? 0
          : Math.max(0, today.effective_work_seconds - today.completed_work_seconds),
        monthTotal: priorWorkdays * (month.daily_salary_minor / 100) + today.earned_minor / 100,
        workdays: month.workdays,
        effectiveSeconds: today.effective_work_seconds,
        workStartTime: config.work_start_time,
        lunchStartTime: config.lunch_start_time,
        lunchEndTime: config.lunch_end_time,
        workEndTime: config.work_end_time,
        nextWorkDate,
        calendarDays,
      });
      lastErrorCode.current = null;
    } catch (error) {
      const { code, message } = describeDashboardError(error);
      if (lastErrorCode.current !== code) {
        lastErrorCode.current = code;
        void invoke("record_semantic_event", {
          event: "salary.calculate.invalid",
          detail: `reason=${code}`,
        }).catch(() => {
          // Browser preview and a degraded native bridge intentionally have no logger.
        });
      }
      setSnapshot(current => ({
        ...current,
        state: "error",
        message,
        errorCode: code,
      }));
    }
  }, []);

  useEffect(() => {
    void refresh();
    const timer = window.setInterval(refresh, 1000);
    return () => window.clearInterval(timer);
  }, [refresh]);

  return { snapshot, refresh };
}

const DASHBOARD_ERROR_CODES = [
  "invalid_monthly_salary",
  "invalid_salary_denominator",
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
    return { code, message: "请检查上班、下班和午休时间后重试。" };
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

export function useCalendarOverrides() {
  const [overrides, setOverrides] = useState<Record<string, "work" | "rest">>({});
  const setOverride = useCallback((date: string, kind: "work" | "rest" | "default") => {
    setOverrides(current => {
      const next = { ...current };
      if (kind === "default") delete next[date];
      else next[date] = kind;
      return next;
    });
  }, []);
  return useMemo(() => ({ overrides, setOverride }), [overrides, setOverride]);
}

export function useCalendarMonth(month: string, currentMonthDays: CalendarDaySnapshot[]) {
  const [days, setDays] = useState<CalendarDaySnapshot[]>(currentMonthDays);
  const [state, setState] = useState<"loading" | "ready" | "error">("ready");

  useEffect(() => {
    let active = true;
    const load = async () => {
      setState("loading");
      try {
        if (!isTauri()) {
          const [year, monthNumber] = month.split("-").map(Number);
          const result = fallbackCalendarDays(new Date(year, monthNumber - 1, 1));
          if (active) {
            setDays(result);
            setState("ready");
          }
          return;
        }
        const config = await invoke<AppConfig>("read_configuration");
        const result = await invoke<CalendarDaySnapshot[]>("resolve_calendar_month", {
          month,
          schedule: toSchedule(config),
          calendar: toCalendar(config),
        });
        if (active) {
          setDays(result);
          setState("ready");
        }
      } catch {
        if (active) setState("error");
      }
    };
    void load();
    return () => {
      active = false;
    };
  }, [month]);

  return { days, state };
}
