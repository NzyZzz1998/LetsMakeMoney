import type { OvertimeReadStatus, OvertimeRecord } from "./overtimeModel";

export type OvertimeMonthStatus = "loading" | "ready" | "empty" | "stale" | "error" | "corrupt";

export interface OvertimeMonthData {
  month: string;
  records: OvertimeRecord[];
}

export interface OvertimeMonthState {
  status: OvertimeMonthStatus;
  requestId: number;
  targetMonth: string;
  data?: OvertimeMonthData;
  errorCode?: string | null;
  message: string;
}

export type OvertimeMonthAction =
  | { type: "requested"; requestId: number; targetMonth: string; cached?: OvertimeMonthData }
  | { type: "resolved"; requestId: number; targetMonth: string; data: OvertimeMonthData; message: string }
  | {
      type: "failed";
      requestId: number;
      targetMonth: string;
      failureStatus: Extract<OvertimeReadStatus, "failed" | "corrupt">;
      errorCode: string | null;
      message: string;
    };

export function createOvertimeMonthState(month: string): OvertimeMonthState {
  return {
    status: "loading",
    requestId: 0,
    targetMonth: month,
    message: "正在读取加班记录…",
  };
}

export function reduceOvertimeMonthState(
  state: OvertimeMonthState,
  action: OvertimeMonthAction,
): OvertimeMonthState {
  if (action.type === "requested") {
    return {
      status: "loading",
      requestId: action.requestId,
      targetMonth: action.targetMonth,
      data: action.cached,
      errorCode: null,
      message: "正在读取加班记录…",
    };
  }
  if (action.requestId !== state.requestId || action.targetMonth !== state.targetMonth) return state;
  if (action.type === "resolved") {
    return {
      status: action.data.records.length === 0 ? "empty" : "ready",
      requestId: action.requestId,
      targetMonth: action.targetMonth,
      data: action.data,
      errorCode: null,
      message: action.message,
    };
  }
  if (state.data?.month === action.targetMonth) {
    return {
      ...state,
      status: "stale",
      errorCode: action.errorCode,
      message: `${action.message}；暂时保留上次成功读取的加班记录。`,
    };
  }
  return {
    status: action.failureStatus === "corrupt" ? "corrupt" : "error",
    requestId: action.requestId,
    targetMonth: action.targetMonth,
    errorCode: action.errorCode,
    message: action.message,
  };
}
