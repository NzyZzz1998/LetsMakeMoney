import {
  normalizeThemeMode,
  type ThemeMode,
} from "./theme";

export const CURRENT_CONFIG_VERSION = 8 as const;

export type RestMode = "single" | "double" | "alternating";
export type WeekType = "big" | "small" | null;
export type DateOverrideKind = "workday" | "paid_rest" | "unpaid_rest";
export type MiniEdgeDock = "none" | "left" | "right";

export interface AppConfig {
  config_version: typeof CURRENT_CONFIG_VERSION;
  theme_mode: ThemeMode;
  monthly_salary: number;
  rest_mode: RestMode;
  alternating_anchor_date: string | null;
  alternating_anchor_week_type: WeekType;
  work_hours_per_day: number;
  work_start_time: string;
  work_end_time: string;
  lunch_start_time: string;
  lunch_end_time: string;
  calendar_dataset_version: string;
  date_overrides: Array<{ date: string; kind: DateOverrideKind; note?: string }>;
  mini_window_position: { x: number; y: number } | null;
  mini_window_visible: boolean;
  mini_window_always_on_top: boolean;
  mini_edge_auto_hide: boolean;
  mini_edge_dock: MiniEdgeDock;
  minimize_to_tray: boolean;
  auto_start: boolean;
  check_updates_on_start: boolean;
  update_channel: "stable";
  log_level: "error" | "info" | "debug";
}

export const defaultConfig: AppConfig = {
  config_version: CURRENT_CONFIG_VERSION,
  theme_mode: "light",
  monthly_salary: 0,
  rest_mode: "double",
  alternating_anchor_date: null,
  alternating_anchor_week_type: null,
  work_hours_per_day: 8,
  work_start_time: "08:00",
  work_end_time: "18:00",
  lunch_start_time: "12:00",
  lunch_end_time: "14:00",
  calendar_dataset_version: "cn-2025-2026-v1",
  date_overrides: [],
  mini_window_position: null,
  mini_window_visible: true,
  mini_window_always_on_top: true,
  mini_edge_auto_hide: true,
  mini_edge_dock: "none",
  minimize_to_tray: true,
  auto_start: false,
  check_updates_on_start: true,
  update_channel: "stable",
  log_level: "info",
};

export function normalizeConfiguration(
  value: Partial<AppConfig> | null | undefined,
): AppConfig {
  const dock = value?.mini_edge_dock;
  const edgeAutoHide =
    typeof value?.mini_edge_auto_hide === "boolean"
      ? value.mini_edge_auto_hide
      : true;
  return {
    ...defaultConfig,
    ...value,
    config_version: CURRENT_CONFIG_VERSION,
    theme_mode: normalizeThemeMode(value?.theme_mode),
    mini_edge_auto_hide: edgeAutoHide,
    mini_edge_dock:
      edgeAutoHide && (dock === "left" || dock === "right")
        ? dock
        : "none",
  };
}

export function validateConfiguration(config: AppConfig) {
  const errors: Record<string, string> = {};
  if (!Number.isFinite(config.monthly_salary) || config.monthly_salary <= 0) {
    errors.monthly_salary = "请输入大于 0 的月薪";
  }
  if (config.rest_mode === "alternating" && !config.alternating_anchor_week_type) {
    errors.alternating_anchor_week_type = "请选择本周是大周还是小周";
  }
  if (!config.work_start_time) errors.work_start_time = "请选择上班时间";
  if (!config.lunch_start_time) errors.lunch_start_time = "请选择休息开始时间";
  return errors;
}

export function addHours(clock: string, hours: number) {
  const [hour, minute] = clock.split(":").map(Number);
  const total = Math.round(hour * 60 + minute + hours * 60);
  const normalized = ((total % 1440) + 1440) % 1440;
  return `${String(Math.floor(normalized / 60)).padStart(2, "0")}:${String(normalized % 60).padStart(2, "0")}`;
}
