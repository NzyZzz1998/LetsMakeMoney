import {
  beginCalendarRequest,
  createCalendarState,
  reduceCalendarState,
  type CalendarMonthData,
} from "../src/calendarState";
import {
  classifyCalendarLoadFailure,
  createEstimatedCoverage,
  createOfficialCoverage,
} from "../src/calendarCoverage";

function assert(condition: unknown, message: string): asserts condition {
  if (!condition) throw new Error(message);
}

const august: CalendarMonthData = {
  month: "2026-08",
  days: [{
    date: "2026-08-03",
    kind: "workday",
    source: "rest_mode",
    automatic_kind: "workday",
    automatic_source: "rest_mode",
    override_kind: null,
  }],
  datasetVersion: "cn-2025-2026-v1",
  coverage: createOfficialCoverage(2026, "cn-2025-2026-v1", {
    publisher: "国务院办公厅",
    title: "2026 年部分节假日安排",
    document_no: "fixture",
    published_at: "2025-11-01",
    url: "https://www.gov.cn/fixture",
  }),
};

let state = createCalendarState(august);
state = reduceCalendarState(state, beginCalendarRequest(state, "2026-09", 1));
state = reduceCalendarState(state, beginCalendarRequest(state, "2026-10", 2));
state = reduceCalendarState(state, {
  type: "resolved",
  requestId: 1,
  targetMonth: "2026-09",
  data: { ...august, month: "2026-09" },
});
assert(state.targetMonth === "2026-10", "late response must not replace the active target");
assert(state.status === "loading", "late response must leave the active request loading");

state = reduceCalendarState(state, {
  type: "failed",
  requestId: 2,
  targetMonth: "2026-10",
  errorCode: "calendar_hash_mismatch:2026",
});
assert(state.status === "error", "data from another month must never be exposed as stale");
assert(state.data === undefined, "cross-month failures must not expose a different month");
assert(state.targetMonth === "2026-10", "stale state must retain the requested month");

let sameMonth = createCalendarState(august);
sameMonth = reduceCalendarState(sameMonth, beginCalendarRequest(sameMonth, "2026-08", 3));
sameMonth = reduceCalendarState(sameMonth, {
  type: "failed",
  requestId: 3,
  targetMonth: "2026-08",
  errorCode: "calendar_hash_mismatch:2026",
});
assert(sameMonth.status === "stale", "same-month failures must preserve trusted data");
assert(sameMonth.data?.month === "2026-08", "stale data must match the requested month");
assert(sameMonth.data?.coverage.mode === "stale", "stale data needs explicit coverage");
assert(!sameMonth.data?.coverage.can_adjust_date, "stale calendar must be read-only");

let empty = createCalendarState();
empty = reduceCalendarState(empty, beginCalendarRequest(empty, "2026-11", 5));
empty = reduceCalendarState(empty, {
  type: "resolved",
  requestId: 5,
  targetMonth: "2026-11",
  data: {
    month: "2026-11",
    days: [],
    datasetVersion: "cn-2025-2026-v1",
    coverage: august.coverage,
  },
});
assert(empty.status === "empty", "an empty successful response needs an explicit state");

const estimated = createEstimatedCoverage(2027, "double");
assert(estimated.mode === "estimated", "unsupported years must resolve as estimated data");
assert(!estimated.official, "estimated coverage must never claim official status");
assert(estimated.can_adjust_date, "estimated dates remain adjustable");
assert(
  classifyCalendarLoadFailure("calendar_year_unsupported:2027", 2027) === "unsupported",
  "the exact unsupported-year error is eligible for estimation",
);
assert(
  classifyCalendarLoadFailure("calendar_year_unsupported:2028", 2027) === "integrity_error",
  "a mismatched unsupported-year error must not be estimated",
);
assert(
  classifyCalendarLoadFailure("calendar_hash_mismatch:2027", 2027) === "integrity_error",
  "hash failures must remain integrity errors",
);

console.log("calendar-state behavior: 11/11 passed");
