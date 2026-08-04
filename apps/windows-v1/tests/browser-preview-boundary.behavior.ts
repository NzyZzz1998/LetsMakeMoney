import { createAppRuntime } from "../src/runtime/appRuntime";
import { createDashboardService } from "../src/services/dashboardService";
import { createOvertimeService } from "../src/features/calendar/overtimeService";
import { createVersionService } from "../src/services/versionService";

function assert(condition: unknown, message: string): asserts condition {
  if (!condition) throw new Error(message);
}

async function rejectsWith(action: () => Promise<unknown>, expected: string) {
  try {
    await action();
  } catch (error) {
    assert(String(error).includes(expected), `expected ${expected}, received ${String(error)}`);
    return;
  }
  throw new Error(`expected rejection containing ${expected}`);
}

const runtime = createAppRuntime();
const dashboard = createDashboardService(runtime);
const overtime = createOvertimeService(runtime);
const version = createVersionService(runtime, async () => "1.0.8");

assert(!runtime.isDesktop, "a browser preview must never identify as the desktop runtime");
assert(!dashboard.isDesktop, "dashboard preview must expose its non-desktop boundary");
assert(!overtime.isDesktop, "overtime preview must expose its non-desktop boundary");
assert(await version.read() === "dev-preview", "browser preview must use a non-release identity");

await rejectsWith(
  () => dashboard.saveDateOverride("2026-08-04", "workday"),
  "desktop_runtime_unavailable:save_date_override",
);
await rejectsWith(
  () => overtime.save({
    businessDate: "2026-08-04",
    minutes: 60,
    hourlyRateFenSnapshot: 6250,
    origin: "standalone",
    boundarySnapshot: {
      basis: "rest_day_manual",
      current_shift_end: null,
      next_actual_work_start: null,
      maximum_minutes: 1440,
      calendar_source: "manual",
    },
    linkedOverrideDate: null,
  }),
  "desktop_runtime_unavailable:save_overtime_record",
);

console.log("browser preview boundary: 6/6 passed");
