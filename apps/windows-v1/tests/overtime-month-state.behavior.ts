import {
  createOvertimeMonthState,
  reduceOvertimeMonthState,
  type OvertimeMonthData,
} from "../src/features/calendar/overtimeMonthState";
import type { OvertimeRecord } from "../src/features/calendar/overtimeModel";

function assert(condition: unknown, message: string): asserts condition {
  if (!condition) throw new Error(message);
}

const record: OvertimeRecord = {
  business_date: "2026-08-03",
  minutes: 90,
  hourly_rate_fen_snapshot: 6250,
  origin: "independent",
  boundary_snapshot: null,
  linked_override_date: null,
  created_at: "2026-08-03T11:30:00Z",
  updated_at: "2026-08-03T11:30:00Z",
};
const cached: OvertimeMonthData = { month: "2026-08", records: [record] };

let state = createOvertimeMonthState("2026-08");
state = reduceOvertimeMonthState(state, {
  type: "requested",
  requestId: 1,
  targetMonth: "2026-08",
});
state = reduceOvertimeMonthState(state, {
  type: "resolved",
  requestId: 1,
  targetMonth: "2026-08",
  data: cached,
  message: "已读取",
});
assert(state.status === "ready" && state.data?.records.length === 1, "records must resolve to ready");

state = reduceOvertimeMonthState(state, {
  type: "requested",
  requestId: 2,
  targetMonth: "2026-08",
  cached,
});
state = reduceOvertimeMonthState(state, {
  type: "failed",
  requestId: 2,
  targetMonth: "2026-08",
  failureStatus: "failed",
  errorCode: "read_failed",
  message: "读取失败",
});
assert(state.status === "stale", "same-month cached data must become stale after a read failure");
assert(state.data?.records[0]?.minutes === 90, "stale data must preserve the last valid records");

let failed = createOvertimeMonthState("2026-09");
failed = reduceOvertimeMonthState(failed, {
  type: "requested",
  requestId: 3,
  targetMonth: "2026-09",
});
failed = reduceOvertimeMonthState(failed, {
  type: "failed",
  requestId: 3,
  targetMonth: "2026-09",
  failureStatus: "failed",
  errorCode: "read_failed",
  message: "读取失败",
});
assert(failed.status === "error" && failed.data === undefined, "a first-load failure must not fabricate zero records");

let corrupt = createOvertimeMonthState("2026-10");
corrupt = reduceOvertimeMonthState(corrupt, {
  type: "requested",
  requestId: 4,
  targetMonth: "2026-10",
});
corrupt = reduceOvertimeMonthState(corrupt, {
  type: "failed",
  requestId: 4,
  targetMonth: "2026-10",
  failureStatus: "corrupt",
  errorCode: "store_corrupt",
  message: "数据损坏",
});
assert(corrupt.status === "corrupt", "corruption must remain distinguishable from ordinary read failure");

const late = reduceOvertimeMonthState(corrupt, {
  type: "resolved",
  requestId: 3,
  targetMonth: "2026-10",
  data: { month: "2026-10", records: [] },
  message: "迟到结果",
});
assert(late === corrupt, "late results must not replace the current request state");

let empty = createOvertimeMonthState("2026-11");
empty = reduceOvertimeMonthState(empty, {
  type: "requested",
  requestId: 5,
  targetMonth: "2026-11",
});
empty = reduceOvertimeMonthState(empty, {
  type: "resolved",
  requestId: 5,
  targetMonth: "2026-11",
  data: { month: "2026-11", records: [] },
  message: "没有记录",
});
assert(empty.status === "empty", "an authoritative empty month must be explicit");

console.log("overtime month state behavior: 7/7 passed");
