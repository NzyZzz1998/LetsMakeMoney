import { useCallback, useEffect, useMemo, useState } from "react";
import { invoke } from "@tauri-apps/api/core";

export type DashboardState = "loading" | "ready" | "setup" | "error";

export interface DashboardSnapshot {
  state: DashboardState;
  workState: string;
  amount: number;
  dailySalary: number;
  hourlySalary: number;
  progress: number;
  completedSeconds: number;
  remainingSeconds: number;
  monthTotal: number;
  workdays: number;
  message?: string;
}

const baseSchedule = {
  monthly_salary_minor: 1_000_000,
  rest_mode: "double",
  alternating_anchor_date: null,
  alternating_anchor_week_type: null,
  work_hours_per_day: 8,
  work_start_time: "08:00",
  work_end_time: "18:00",
  lunch_start_time: "12:00",
  lunch_end_time: "14:00",
};

const calendar = {
  statutory_holidays: [],
  adjusted_workdays: [],
  date_overrides: [],
};

function isTauri() {
  return "__TAURI_INTERNALS__" in window;
}

function fallbackSnapshot(now: Date): DashboardSnapshot {
  const start = 8 * 3600;
  const lunchStart = 12 * 3600;
  const lunchEnd = 14 * 3600;
  const end = 18 * 3600;
  const second = now.getHours() * 3600 + now.getMinutes() * 60 + now.getSeconds();
  const first = Math.max(0, Math.min(second, lunchStart) - start);
  const secondSegment = Math.max(0, Math.min(second, end) - lunchEnd);
  const completed = Math.max(0, Math.min(8 * 3600, first + secondSegment));
  const progress = completed / (8 * 3600);
  const workState = second < start ? "上班前" : second < lunchStart ? "工作中" : second < lunchEnd ? "午休中" : second < end ? "工作中" : "已下班";
  return {
    state: "ready",
    workState,
    amount: 500 * progress,
    dailySalary: 500,
    hourlySalary: 62.5,
    progress: Math.round(progress * 100),
    completedSeconds: completed,
    remainingSeconds: Math.max(0, 8 * 3600 - completed),
    monthTotal: 3842,
    workdays: 20,
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
      const month = await invoke<{
        workdays: number;
        daily_salary_minor: number;
        hourly_salary_minor: number;
      }>("calculate_month_salary", {
        month: `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, "0")}`,
        schedule: baseSchedule,
        calendar,
      });
      const today = await invoke<{
        state: string;
        completed_work_seconds: number;
        earned_minor: number;
        progress: number;
      }>("calculate_today_income", {
        request: {
          owner_date: `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, "0")}-${String(now.getDate()).padStart(2, "0")}`,
          now_date: `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, "0")}-${String(now.getDate()).padStart(2, "0")}`,
          now_time: `${String(now.getHours()).padStart(2, "0")}:${String(now.getMinutes()).padStart(2, "0")}`,
          schedule: baseSchedule,
          daily_salary_minor: month.daily_salary_minor,
          calendar,
        },
      });
      setSnapshot({
        state: "ready",
        workState: {
          working: "工作中",
          lunch: "午休中",
          before_work: "上班前",
          after_work: "已下班",
          rest_day: "休息日",
        }[today.state] ?? today.state,
        amount: today.earned_minor / 100,
        dailySalary: month.daily_salary_minor / 100,
        hourlySalary: month.hourly_salary_minor / 100,
        progress: Math.round(today.progress * 100),
        completedSeconds: today.completed_work_seconds,
        remainingSeconds: Math.max(0, 8 * 3600 - today.completed_work_seconds),
        monthTotal: 3842,
        workdays: month.workdays,
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
