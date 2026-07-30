import { defaultConfig } from "../src/domain/configuration";
import { createAppRuntime, type DesktopBridge } from "../src/runtime/appRuntime";
import { createConfigurationService } from "../src/services/configurationService";
import { createDashboardService } from "../src/services/dashboardService";
import { createSupportService } from "../src/services/supportService";
import { createWindowService } from "../src/services/windowService";

function assert(condition: unknown, message: string): asserts condition {
  if (!condition) throw new Error(message);
}

const calls: Array<{ command: string; args?: Record<string, unknown> }> = [];
const emitted: Array<{ event: string; payload?: unknown }> = [];
const bridge: DesktopBridge = {
  invoke: async <T>(command: string, args?: Record<string, unknown>) => {
    calls.push({ command, args });
    const results: Record<string, unknown> = {
      read_configuration: { ...defaultConfig, monthly_salary: 12_000 },
      save_configuration: { status: "saved", message: "设置已保存" },
      window_drag_origin: { x: 12, y: 34, scale_factor: 1.25 },
      configuration_initialized: true,
      platform_capabilities: {
        webview2_available: true,
        tray_available: true,
        explorer_available: true,
      },
      open_data_directory: "C:/safe/data",
      diagnostic_summary: "diagnostic",
      evaluate_update_response: { status: "up_to_date", message: "已是最新版本" },
      save_date_override: {
        status: "saved",
        message: "日期调整已应用",
        draft_preserved: false,
      },
    };
    return results[command] as T;
  },
  emit: async (event, payload) => {
    emitted.push({ event, payload });
  },
  listen: async () => () => undefined,
};
const runtime = createAppRuntime(bridge);

let desktopLocalNotifications = 0;
const configuration = createConfigurationService(runtime, {
  events: {
    dispatchEvent() {
      desktopLocalNotifications += 1;
      return true;
    },
  },
});
const loaded = await configuration.read(defaultConfig);
assert(loaded.monthly_salary === 12_000, "configuration service reads the native configuration");
const saved = await configuration.save({ ...loaded, monthly_salary: 13_000 });
assert(saved.status === "saved", "configuration service preserves transactional save results");
await configuration.publishUpdated("settings");
assert(
  desktopLocalNotifications === 0,
  "desktop configuration updates must not duplicate the native broadcast locally",
);

let browserLocalNotifications = 0;
const browserConfiguration = createConfigurationService(createAppRuntime(), {
  events: {
    dispatchEvent() {
      browserLocalNotifications += 1;
      return true;
    },
  },
});
await browserConfiguration.publishUpdated("settings");
assert(
  browserLocalNotifications === 1,
  "browser preview configuration updates must use the local event fallback",
);

let failedDesktopLocalNotifications = 0;
const failedDesktopConfiguration = createConfigurationService(createAppRuntime({
  ...bridge,
  emit: async () => {
    throw new Error("native event unavailable");
  },
}), {
  events: {
    dispatchEvent() {
      failedDesktopLocalNotifications += 1;
      return true;
    },
  },
});
await failedDesktopConfiguration.publishUpdated("settings");
assert(
  failedDesktopLocalNotifications === 1,
  "a failed desktop broadcast must fall back to the current window event",
);

const windows = createWindowService(runtime);
await windows.show("settings");
await windows.hide("mini");
await windows.move("mini", 120, 240);
const origin = await windows.dragOrigin("workbench");
assert(origin.scale_factor === 1.25, "window service returns native DPI drag origin");
await windows.setMiniState("expanded");
assert(await windows.configurationInitialized(), "window service exposes initialization state");
await windows.exit();

const support = createSupportService(runtime);
const capabilities = await support.capabilities();
assert(capabilities.webview2_available, "support service exposes platform capabilities");
assert(await support.openDataDirectory() === "C:/safe/data", "support service opens the data path");
assert(await support.diagnosticSummary() === "diagnostic", "support service obtains diagnostics");
const update = await support.evaluateUpdate("1.0.3", "{}", null);
assert(update.status === "up_to_date", "support service delegates update evaluation");
await support.record("support.test", "result=success");

const dashboard = createDashboardService(runtime);
const schedule = {
  monthly_salary_minor: 1_000_000,
  rest_mode: "double",
  work_hours_per_day: 8,
  work_start_time: "08:00",
  work_end_time: "18:00",
  lunch_start_time: "12:00",
  lunch_end_time: "14:00",
};
const calendar = { statutory_holidays: [], adjusted_workdays: [], date_overrides: [] };
await dashboard.loadCalendarYear(2026);
await dashboard.calculateMonth("2026-07", schedule, calendar);
await dashboard.calculateToday({
  ownerDate: "2026-07-24",
  nowDate: "2026-07-24",
  nowTime: "10:00:00",
  schedule,
  monthSalary: {},
  calendar,
});
await dashboard.resolveOwnerDate("2026-07-24", "10:00:00", schedule);
await dashboard.resolveMonthDays("2026-07", schedule, calendar);
await dashboard.resolveNextWorkday("2026-07-24", schedule, calendar);
await dashboard.saveDateOverride("2026-07-24", "paid_rest");

const commandSequence = calls.map(call => call.command).join(",");
assert(
  commandSequence
    === "read_configuration,save_configuration,show_app_window,hide_app_window,"
      + "move_app_window,window_drag_origin,set_mini_window_state,"
      + "configuration_initialized,exit_application,platform_capabilities,"
      + "open_data_directory,diagnostic_summary,evaluate_update_response,"
      + "record_semantic_event,load_calendar_year,calculate_month_salary,"
      + "calculate_today_income,resolve_schedule_owner_date,resolve_calendar_month,"
      + "resolve_next_workday,save_date_override",
  "services must preserve the published Rust command contract",
);
assert(
  calls.find(call => call.command === "move_app_window")?.args?.x === 120,
  "window service must not alter physical coordinates",
);
assert(
  calls.find(call => call.command === "save_configuration")?.args?.draft !== undefined,
  "configuration save must keep the draft argument name",
);
assert(
  calls.find(call => call.command === "calculate_today_income")?.args?.request !== undefined,
  "today calculation must keep the request argument envelope",
);
assert(
  emitted.some(item => item.event === "lmm://configuration-updated"),
  "saved date overrides must notify every desktop window",
);
assert(
  (emitted.find(item =>
    item.event === "lmm://configuration-updated"
    && (item.payload as { source?: string })?.source === "date_override"
  )?.payload as {
    source?: string;
  })?.source === "date_override",
  "date override notifications must identify their source",
);
assert(
  emitted.filter(item =>
    item.event === "lmm://configuration-updated"
    && (item.payload as { source?: string })?.source === "settings"
  ).length === 1,
  "desktop settings updates must emit exactly one native notification",
);

console.log("desktop services behavior: 21/21 passed");
