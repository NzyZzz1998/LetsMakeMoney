export const OVERTIME_SCHEMA_VERSION = 2;

export type OvertimeOrigin = "independent" | "manual_weekend_work";
export type OvertimeBoundaryBasis = "planned_shift_gap" | "rest_day_cap";
export type OvertimeCalendarSource = "official" | "estimated" | "manual";

export interface OvertimeBoundarySnapshot {
  basis: OvertimeBoundaryBasis;
  current_shift_end: string | null;
  next_actual_work_start: string | null;
  maximum_minutes: number;
  calendar_source: OvertimeCalendarSource;
}

export interface OvertimeBoundaryResolution {
  snapshot: OvertimeBoundarySnapshot;
  suggested_minutes: number | null;
  origin: OvertimeOrigin;
  linked_override_date: string | null;
  day_source: string;
}

export interface OvertimeRecord {
  business_date: string;
  minutes: number;
  hourly_rate_fen_snapshot: number;
  origin: OvertimeOrigin;
  boundary_snapshot: OvertimeBoundarySnapshot | null;
  linked_override_date: string | null;
  created_at: string;
  updated_at: string;
}

export type OvertimeReadStatus = "ready" | "empty" | "corrupt" | "failed";
export type OvertimeMutationStatus =
  | "saved"
  | "unchanged"
  | "deleted"
  | "recovered"
  | "failed"
  | "corrupt";

export interface OvertimeReadResponse {
  status: OvertimeReadStatus;
  schema_version: number;
  records: OvertimeRecord[];
  error_code: string | null;
  message: string;
  recovery_available: boolean;
}

export interface OvertimeMutationResponse {
  status: OvertimeMutationStatus;
  schema_version: number;
  record: OvertimeRecord | null;
  error_code: string | null;
  message: string;
  recovery_available: boolean;
}

export type OvertimeEditorStatus =
  | "loading"
  | "empty"
  | "editing"
  | "saving"
  | "saved"
  | "deleting"
  | "failed"
  | "corrupt";

export interface OvertimeEditorState {
  status: OvertimeEditorStatus;
  persisted: OvertimeRecord | null;
  draftHours: string;
  message: string;
  errorCode: string | null;
  recoveryAvailable: boolean;
}

export type OvertimeEditorAction =
  | { type: "loading" }
  | { type: "loaded"; record: OvertimeRecord | null; message: string }
  | { type: "changed"; value: string }
  | { type: "saving" }
  | { type: "saved"; record: OvertimeRecord; message: string }
  | { type: "unchanged"; message: string }
  | { type: "deleting" }
  | { type: "deleted"; message: string }
  | { type: "failed"; message: string; errorCode?: string | null }
  | { type: "corrupt"; message: string; errorCode?: string | null }
  | { type: "recovered"; message: string };

export interface ParsedOvertimeHours {
  ok: boolean;
  minutes: number | null;
  normalizedHours: string;
  message: string;
}

export function formatOvertimeHours(minutes: number): string {
  const hours = minutes / 60;
  return hours.toFixed(2).replace(/\.00$/, "").replace(/(\.\d)0$/, "$1");
}

export function parseOvertimeHours(value: string, maximumMinutes = 24 * 60): ParsedOvertimeHours {
  const normalized = value.trim();
  if (!/^\d{1,2}(?:\.\d{1,2})?$/.test(normalized)) {
    return { ok: false, minutes: null, normalizedHours: normalized, message: "请输入有效小时数，最多两位小数" };
  }
  const hours = Number(normalized);
  const minutes = Math.round(hours * 60);
  if (!Number.isFinite(hours) || hours < 0 || minutes > maximumMinutes) {
    return {
      ok: false,
      minutes: null,
      normalizedHours: normalized,
      message: `加班时长不能超过 ${formatOvertimeHours(maximumMinutes)} 小时`,
    };
  }
  return {
    ok: true,
    minutes,
    normalizedHours: formatOvertimeHours(minutes),
    message: minutes === 0 ? "0 小时将删除现有记录" : `将保存为 ${minutes} 分钟`,
  };
}

export function approximateOvertimeAmountYuan(minutes: number, hourlyRateFen: number): number {
  return Math.round((minutes * hourlyRateFen) / 60) / 100;
}

export function createOvertimeEditorState(): OvertimeEditorState {
  return {
    status: "loading",
    persisted: null,
    draftHours: "0",
    message: "正在读取加班记录…",
    errorCode: null,
    recoveryAvailable: false,
  };
}

export function reduceOvertimeEditor(
  state: OvertimeEditorState,
  action: OvertimeEditorAction,
): OvertimeEditorState {
  switch (action.type) {
    case "loading":
      return { ...state, status: "loading", message: "正在读取加班记录…", errorCode: null };
    case "loaded":
      return {
        status: action.record ? "editing" : "empty",
        persisted: action.record,
        draftHours: action.record ? formatOvertimeHours(action.record.minutes) : "0",
        message: action.message,
        errorCode: null,
        recoveryAvailable: false,
      };
    case "changed":
      return { ...state, status: "editing", draftHours: action.value, message: "", errorCode: null };
    case "saving":
      return { ...state, status: "saving", message: "正在保存…", errorCode: null };
    case "saved":
      return {
        ...state,
        status: "saved",
        persisted: action.record,
        draftHours: formatOvertimeHours(action.record.minutes),
        message: action.message,
        errorCode: null,
        recoveryAvailable: false,
      };
    case "unchanged":
      return { ...state, status: state.persisted ? "editing" : "empty", message: action.message, errorCode: null };
    case "deleting":
      return { ...state, status: "deleting", message: "正在删除…", errorCode: null };
    case "deleted":
      return {
        ...state,
        status: "empty",
        persisted: null,
        draftHours: "0",
        message: action.message,
        errorCode: null,
        recoveryAvailable: false,
      };
    case "failed":
      return {
        ...state,
        status: "failed",
        message: action.message,
        errorCode: action.errorCode ?? null,
      };
    case "corrupt":
      return {
        ...state,
        status: "corrupt",
        message: action.message,
        errorCode: action.errorCode ?? "overtime_store_corrupt",
        recoveryAvailable: true,
      };
    case "recovered":
      return {
        status: "empty",
        persisted: null,
        draftHours: "0",
        message: action.message,
        errorCode: null,
        recoveryAvailable: false,
      };
  }
}

export function overtimeDraftIsUnchanged(state: OvertimeEditorState, minutes: number): boolean {
  return state.persisted ? state.persisted.minutes === minutes : minutes === 0;
}
