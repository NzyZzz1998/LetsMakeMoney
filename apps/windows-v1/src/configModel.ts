import { useCallback, useEffect, useMemo, useRef, useState } from "react";
import { invoke } from "@tauri-apps/api/core";

export type RestMode = "single" | "double" | "alternating";
export type WeekType = "big" | "small" | null;
export type DateOverrideKind = "workday" | "paid_rest" | "unpaid_rest";

export interface AppConfig {
  config_version: 7;
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
  minimize_to_tray: boolean;
  auto_start: boolean;
  check_updates_on_start: boolean;
  update_channel: "stable";
  log_level: "error" | "info" | "debug";
}

export const defaultConfig: AppConfig = {
  config_version: 7,
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
  minimize_to_tray: true,
  auto_start: false,
  check_updates_on_start: true,
  update_channel: "stable",
  log_level: "info",
};

export type SaveFeedback = "idle" | "saved" | "unchanged" | "failed";

function isTauri() {
  return "__TAURI_INTERNALS__" in window;
}

function validate(config: AppConfig) {
  const errors: Record<string, string> = {};
  if (!Number.isFinite(config.monthly_salary) || config.monthly_salary <= 0) {
    errors.monthly_salary = "请输入大于 0 的月薪";
  }
  if (config.rest_mode === "alternating" && !config.alternating_anchor_week_type) {
    errors.alternating_anchor_week_type = "请选择本周是大周还是小周";
  }
  if (!config.work_start_time) errors.work_start_time = "请选择上班时间";
  if (!config.lunch_start_time) errors.lunch_start_time = "请选择午休开始时间";
  return errors;
}

export function addHours(clock: string, hours: number) {
  const [hour, minute] = clock.split(":").map(Number);
  const total = Math.round(hour * 60 + minute + hours * 60);
  const normalized = ((total % 1440) + 1440) % 1440;
  return `${String(Math.floor(normalized / 60)).padStart(2, "0")}:${String(normalized % 60).padStart(2, "0")}`;
}

export function useConfigDraft(seed?: Partial<AppConfig>) {
  const seedKey = JSON.stringify(seed ?? {});
  const seeded = useMemo(() => ({ ...defaultConfig, ...seed }), [seedKey]);
  const [persisted, setPersisted] = useState<AppConfig>(seeded);
  const [draft, setDraft] = useState<AppConfig>(seeded);
  const [loading, setLoading] = useState(true);
  const [feedback, setFeedback] = useState<SaveFeedback>("idle");
  const [message, setMessage] = useState("");
  const dirtyRef = useRef(false);

  const reload = useCallback(async (preserveDirty = true) => {
    if (preserveDirty && dirtyRef.current) return;
    try {
      const loaded = isTauri()
        ? await invoke<AppConfig>("read_configuration")
        : JSON.parse(localStorage.getItem("lmm.config") ?? "null") ?? seeded;
      setPersisted(loaded);
      setDraft(loaded);
      setFeedback("idle");
      setMessage("");
    } catch {
      setPersisted(seeded);
      setDraft(seeded);
    } finally {
      setLoading(false);
    }
  }, [seeded]);

  useEffect(() => {
    void reload(false);
  }, [reload]);

  const errors = useMemo(() => validate(draft), [draft]);
  const dirty = useMemo(() => JSON.stringify(draft) !== JSON.stringify(persisted), [draft, persisted]);
  useEffect(() => {
    dirtyRef.current = dirty;
  }, [dirty]);

  useEffect(() => {
    const refresh = () => void reload(true);
    window.addEventListener("focus", refresh);
    return () => {
      window.removeEventListener("focus", refresh);
    };
  }, [reload]);

  const update = useCallback(<K extends keyof AppConfig>(key: K, value: AppConfig[K]) => {
    setDraft(current => ({ ...current, [key]: value }));
    setFeedback("idle");
    setMessage("");
  }, []);

  const save = useCallback(async () => {
    const validation = validate(draft);
    if (Object.keys(validation).length) {
      setFeedback("failed");
      setMessage(Object.values(validation)[0]);
      return false;
    }
    if (!dirty) {
      setFeedback("unchanged");
      setMessage("没有需要保存的更改");
      return true;
    }
    try {
      if (!isTauri() && sessionStorage.getItem("lmm.simulateSaveFailure") === "true") {
        throw new Error("配置目录不可写");
      }
      const result = isTauri()
        ? await invoke<{ status: "saved" | "unchanged" | "failed"; message: string }>("save_configuration", { draft })
        : { status: "saved" as const, message: "设置已保存" };
      if (result.status === "failed") throw new Error(result.message);
      if (!isTauri()) localStorage.setItem("lmm.config", JSON.stringify(draft));
      setPersisted(draft);
      setFeedback(result.status === "unchanged" ? "unchanged" : "saved");
      setMessage(result.message);
      return true;
    } catch (error) {
      setFeedback("failed");
      setMessage(`保存失败：${error instanceof Error ? error.message : String(error)}`);
      return false;
    }
  }, [dirty, draft]);

  const reset = useCallback(() => {
    setDraft(defaultConfig);
    setFeedback("idle");
    setMessage("");
  }, []);

  const cancel = useCallback(() => {
    setDraft(persisted);
    setFeedback("idle");
    setMessage("");
  }, [persisted]);

  return { draft, persisted, loading, dirty, errors, feedback, message, update, save, reset, cancel, reload };
}
