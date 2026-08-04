import type { DateOverrideKind } from "../domain/configuration";
import type {
  OvertimeBoundarySnapshot,
  OvertimeOrigin,
} from "../features/calendar/overtimeModel";
import {
  appRuntime,
  type AppRuntime,
} from "../runtime/appRuntime";

type CommandObject = object;

export interface TodayCalculationInput {
  ownerDate: string;
  nowDate: string;
  nowTime: string;
  schedule: CommandObject;
  monthSalary: CommandObject;
  calendar: CommandObject;
}

export interface DateOverrideSaveResult {
  status: "saved" | "unchanged" | "failed";
  message: string;
  draft_preserved: boolean;
}

export type LinkedOvertimeAction =
  | { action: "keep" }
  | { action: "delete" }
  | {
      action: "upsert";
      request: {
        business_date: string;
        minutes: number;
        hourly_rate_fen_snapshot: number;
        origin: OvertimeOrigin;
        boundary_snapshot: OvertimeBoundarySnapshot;
        linked_override_date: string | null;
      };
    };

export interface DateOvertimeTransactionResult extends DateOverrideSaveResult {
  overtime_changed: boolean;
}

export interface DashboardService {
  readonly isDesktop: boolean;
  loadCalendarYear<T>(year: number): Promise<T>;
  calculateMonth<T>(
    month: string,
    schedule: CommandObject,
    calendar: CommandObject,
  ): Promise<T>;
  calculateToday<T>(input: TodayCalculationInput): Promise<T>;
  resolveOwnerDate(
    nowDate: string,
    nowTime: string,
    schedule: CommandObject,
  ): Promise<string>;
  resolveMonthDays<T>(
    month: string,
    schedule: CommandObject,
    calendar: CommandObject,
  ): Promise<T>;
  resolveNextWorkday(
    afterDate: string,
    schedule: CommandObject,
    calendar: CommandObject,
  ): Promise<string | null>;
  saveDateOverride(
    date: string,
    kind: DateOverrideKind | null,
  ): Promise<DateOverrideSaveResult>;
  saveDateOvertimeTransaction(
    date: string,
    kind: DateOverrideKind | null,
    overtime: LinkedOvertimeAction,
  ): Promise<DateOvertimeTransactionResult>;
  listenConfigurationUpdated(handler: () => void): Promise<() => void>;
}

export function createDashboardService(runtime: AppRuntime): DashboardService {
  return {
    isDesktop: runtime.isDesktop,
    loadCalendarYear: year => runtime.invoke("load_calendar_year", { year }),
    calculateMonth: (month, schedule, calendar) =>
      runtime.invoke("calculate_month_salary", { month, schedule, calendar }),
    calculateToday: input =>
      runtime.invoke("calculate_today_income", {
        request: {
          owner_date: input.ownerDate,
          now_date: input.nowDate,
          now_time: input.nowTime,
          schedule: input.schedule,
          month_salary: input.monthSalary,
          calendar: input.calendar,
        },
      }),
    resolveOwnerDate: (nowDate, nowTime, schedule) =>
      runtime.invoke("resolve_schedule_owner_date", { nowDate, nowTime, schedule }),
    resolveMonthDays: (month, schedule, calendar) =>
      runtime.invoke("resolve_calendar_month", { month, schedule, calendar }),
    resolveNextWorkday: (afterDate, schedule, calendar) =>
      runtime.invoke("resolve_next_workday", { afterDate, schedule, calendar }),
    async saveDateOverride(date, kind) {
      const result = await runtime.invoke<DateOverrideSaveResult>(
        "save_date_override",
        { date, kind },
      );
      if (result.status === "saved") {
        await runtime.emit("lmm://configuration-updated", {
          source: "date_override",
        });
      }
      return result;
    },
    saveDateOvertimeTransaction: (date, kind, overtime) =>
      runtime.invoke("save_date_overtime_transaction", {
        request: { date, kind, overtime },
      }),
    listenConfigurationUpdated: handler =>
      runtime.listen("lmm://configuration-updated", handler),
  };
}

export const dashboardService = createDashboardService(appRuntime);
