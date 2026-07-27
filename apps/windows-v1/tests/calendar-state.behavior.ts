import {
  beginCalendarRequest,
  createCalendarState,
  reduceCalendarState,
  type CalendarMonthData,
} from "../src/calendarState";

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
assert(state.status === "stale", "a failed request with prior data must be explicitly stale");
assert(state.data?.month === "2026-08", "stale data must retain its real month identity");
assert(state.targetMonth === "2026-10", "stale state must retain the requested month");

let unsupported = createCalendarState();
unsupported = reduceCalendarState(unsupported, beginCalendarRequest(unsupported, "2027-01", 4));
unsupported = reduceCalendarState(unsupported, {
  type: "failed",
  requestId: 4,
  targetMonth: "2027-01",
  errorCode: "calendar_year_unsupported:2027",
});
assert(unsupported.status === "unsupported", "unsupported years need a dedicated state");

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
  },
});
assert(empty.status === "empty", "an empty successful response needs an explicit state");

console.log("calendar-state behavior: 4/4 passed");
