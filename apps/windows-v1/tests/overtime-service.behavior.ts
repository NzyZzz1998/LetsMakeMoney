import { createOvertimeService } from "../src/features/calendar/overtimeService";
import { createAppRuntime, type DesktopBridge } from "../src/runtime/appRuntime";

function assert(condition: unknown, message: string): asserts condition {
  if (!condition) throw new Error(message);
}

const calls: Array<{ command: string; args?: Record<string, unknown> }> = [];
const events: string[] = [];
const bridge: DesktopBridge = {
  invoke: async <T>(command: string, args?: Record<string, unknown>) => {
    calls.push({ command, args });
    if (command.startsWith("read_overtime")) {
      return { status: "empty", schema_version: 1, records: [], error_code: null, message: "已读取", recovery_available: false } as T;
    }
    const status = command === "delete_overtime_record" ? "deleted" : command === "recover_overtime_records" ? "recovered" : "saved";
    return { status, schema_version: 1, record: status === "saved" ? {
      business_date: "2026-08-03",
      minutes: 90,
      hourly_rate_fen_snapshot: 6250,
      created_at: "2026-08-03T11:30:00Z",
      updated_at: "2026-08-03T11:30:00Z",
    } : null, error_code: null, message: "完成", recovery_available: false } as T;
  },
  emit: async event => { events.push(event); },
  listen: async () => () => undefined,
};

const service = createOvertimeService(createAppRuntime(bridge));
await service.readDate("2026-08-03");
await service.readMonth("2026-08");
await service.save({ businessDate: "2026-08-03", minutes: 90, hourlyRateFenSnapshot: 6250 });
await service.delete("2026-08-03");
await service.recover();

assert(
  calls.map(call => call.command).join(",")
    === "read_overtime_record,read_overtime_month,save_overtime_record,delete_overtime_record,recover_overtime_records",
  "overtime service must preserve all five Rust command names",
);
const saveRequest = calls.find(call => call.command === "save_overtime_record")?.args?.request as Record<string, unknown>;
assert(saveRequest.business_date === "2026-08-03", "save request must use the business date field");
assert(saveRequest.hourly_rate_fen_snapshot === 6250, "save request must carry the immutable rate snapshot");
assert(!("hourly_rate_minor" in saveRequest), "legacy rate field names must not leak into IPC");
assert(events.length === 3 && events.every(event => event === "lmm://overtime-updated"), "mutations must notify every app window exactly once");

console.log("overtime service behavior: 5/5 passed");
