import {
  calculateMonthlySummary,
  elapsedPlannedMinutesForOwnerDate,
  formatWorkMinutes,
  type MonthlySummaryDay,
  type MonthlySummarySchedule,
} from "../src/features/calendar/monthlySummary";
import type { OvertimeRecord } from "../src/features/calendar/overtimeModel";

function assert(condition: unknown, message: string): asserts condition {
  if (!condition) throw new Error(message);
}

const daySchedule: MonthlySummarySchedule = {
  workStartTime: "09:00",
  restStartTime: "12:00",
  restEndTime: "13:00",
  workEndTime: "18:00",
  effectiveMinutes: 480,
};
const overnightSchedule: MonthlySummarySchedule = {
  workStartTime: "22:00",
  restStartTime: "02:00",
  restEndTime: "02:30",
  workEndTime: "06:00",
  effectiveMinutes: 450,
};
const days: MonthlySummaryDay[] = [
  { date: "2026-08-01", kind: "rest_day" },
  { date: "2026-08-03", kind: "workday" },
  { date: "2026-08-04", kind: "workday" },
  { date: "2026-08-05", kind: "workday" },
];
const overtimeRecords: OvertimeRecord[] = [
  {
    business_date: "2026-08-03",
    minutes: 90,
    hourly_rate_fen_snapshot: 6250,
    origin: "independent",
    boundary_snapshot: null,
    linked_override_date: null,
    created_at: "2026-08-03T11:30:00Z",
    updated_at: "2026-08-03T11:30:00Z",
  },
  {
    business_date: "2026-08-04",
    minutes: 30,
    hourly_rate_fen_snapshot: 6250,
    origin: "independent",
    boundary_snapshot: null,
    linked_override_date: null,
    created_at: "2026-08-04T11:30:00Z",
    updated_at: "2026-08-04T11:30:00Z",
  },
];

assert(
  elapsedPlannedMinutesForOwnerDate("2026-08-04", "2026-08-04", 14 * 60 + 30, daySchedule) === 270,
  "day shifts must exclude the rest interval from naturally elapsed work",
);
assert(
  elapsedPlannedMinutesForOwnerDate("2026-08-03", "2026-08-04", 3 * 60, overnightSchedule) === 270,
  "overnight shifts must measure elapsed work against the owner date",
);
assert(
  elapsedPlannedMinutesForOwnerDate(
    "2026-08-04",
    "2026-08-04",
    12 * 60,
    { ...daySchedule, restStartTime: "12:00", restEndTime: "12:00", effectiveMinutes: 540 },
  ) === 180,
  "zero-rest schedules must remain continuous",
);

const current = calculateMonthlySummary({
  month: "2026-08",
  days,
  ownerDate: "2026-08-04",
  currentLocalDate: "2026-08-04",
  currentMinuteOfDay: 14 * 60 + 30,
  schedule: daySchedule,
  overtimeRecords,
});
assert(current.plannedMinutes === 1440, "planned work must include every resolved workday");
assert(current.elapsedPlannedMinutes === 750, "current month must include past workdays and current elapsed work");
assert(current.overtimeMinutes === 120, "monthly overtime must sum persisted minute records");

const past = calculateMonthlySummary({
  month: "2026-07",
  days: [
    { date: "2026-07-30", kind: "workday" },
    { date: "2026-07-31", kind: "workday" },
  ],
  ownerDate: "2026-08-04",
  currentLocalDate: "2026-08-04",
  currentMinuteOfDay: 0,
  schedule: daySchedule,
  overtimeRecords: [],
});
assert(past.plannedMinutes === 960 && past.elapsedPlannedMinutes === 960, "past months must be fully elapsed");

const future = calculateMonthlySummary({
  month: "2026-09",
  days: [{ date: "2026-09-01", kind: "workday" }],
  ownerDate: "2026-08-04",
  currentLocalDate: "2026-08-04",
  currentMinuteOfDay: 0,
  schedule: daySchedule,
  overtimeRecords: [],
});
assert(future.plannedMinutes === 480 && future.elapsedPlannedMinutes === 0, "future months must not accrue elapsed work");
assert(formatWorkMinutes(0) === "0 分钟", "zero must not be presented as actual hours");
assert(formatWorkMinutes(125) === "2 小时 5 分钟", "minute formatting must preserve the remainder");

console.log("monthly summary behavior: 10/10 passed");
