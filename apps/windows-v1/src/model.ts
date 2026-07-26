import { useCallback, useEffect, useMemo, useState } from "react";
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
    } catch (error) {
      setSnapshot(current => ({
        ...current,
        state: "error",
        message: error instanceof Error ? error.message : String(error),
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
  const [overrides, setOverrides] = useState<Record<number, "work" | "rest">>({});
  const setOverride = useCallback((day: number, kind: "work" | "rest" | "default") => {
    setOverrides(current => {
      const next = { ...current };
      if (kind === "default") delete next[day];
      else next[day] = kind;
      return next;
    });
  }, []);
  return useMemo(() => ({ overrides, setOverride }), [overrides, setOverride]);
}
