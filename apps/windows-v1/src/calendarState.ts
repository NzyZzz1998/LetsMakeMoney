export type CalendarLoadStatus =
  | "loading"
  | "ready"
  | "empty"
  | "stale"
  | "error"
  | "unsupported";

export interface CalendarStateDay {
  date: string;
  kind: "workday" | "rest_day";
  source: string;
  automatic_kind: "workday" | "rest_day";
  automatic_source: string;
  override_kind: DateOverrideKind | null;
}

export interface CalendarMonthData {
  month: string;
  days: CalendarStateDay[];
  datasetVersion: string;
}

export interface CalendarLoadState {
  status: CalendarLoadStatus;
  requestId: number;
  targetMonth: string;
  data?: CalendarMonthData;
  errorCode?: string;
}

export type CalendarStateAction =
  | {
      type: "requested";
      requestId: number;
      targetMonth: string;
    }
  | {
      type: "resolved";
      requestId: number;
      targetMonth: string;
      data: CalendarMonthData;
    }
  | {
      type: "failed";
      requestId: number;
      targetMonth: string;
      errorCode: string;
    };

export function createCalendarState(data?: CalendarMonthData): CalendarLoadState {
  return {
    status: data ? (data.days.length === 0 ? "empty" : "ready") : "loading",
    requestId: 0,
    targetMonth: data?.month ?? "",
    data,
  };
}

export function beginCalendarRequest(
  _state: CalendarLoadState,
  targetMonth: string,
  requestId: number,
): CalendarStateAction {
  return { type: "requested", requestId, targetMonth };
}

export function reduceCalendarState(
  state: CalendarLoadState,
  action: CalendarStateAction,
): CalendarLoadState {
  if (action.type === "requested") {
    return {
      ...state,
      status: "loading",
      requestId: action.requestId,
      targetMonth: action.targetMonth,
      errorCode: undefined,
    };
  }

  if (action.requestId !== state.requestId || action.targetMonth !== state.targetMonth) {
    return state;
  }

  if (action.type === "resolved") {
    return {
      status: action.data.days.length === 0 ? "empty" : "ready",
      requestId: action.requestId,
      targetMonth: action.targetMonth,
      data: action.data,
      errorCode: undefined,
    };
  }

  const unsupported = action.errorCode.startsWith("calendar_year_unsupported:");
  return {
    ...state,
    status: unsupported ? "unsupported" : state.data ? "stale" : "error",
    errorCode: action.errorCode,
  };
}
import type { DateOverrideKind } from "./configModel";
