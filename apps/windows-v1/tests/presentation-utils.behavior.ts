import {
  calendarLeadingBlankCount,
  clockDifferenceSeconds,
  formatFullDate,
  formatLunchDuration,
  formatReadableDuration,
  formatShortDate,
  parseLocalDate,
  parseLunchDuration,
  shiftMonthKey,
} from "../src/utils/presentationFormatters";
import { calendarBusinessState } from "../src/presentation";

function equal<T>(actual: T, expected: T, message: string) {
  if (actual !== expected) {
    throw new Error(`${message}: expected ${String(expected)}, got ${String(actual)}`);
  }
}

const localDate = parseLocalDate("2026-07-30");
equal(localDate.getFullYear(), 2026, "local date year");
equal(localDate.getMonth(), 6, "local date month");
equal(localDate.getDate(), 30, "local date day");
equal(formatFullDate("2026-07-30").includes("7月30日"), true, "full date label");
equal(formatShortDate("2026-07-30").includes("7"), true, "short date label");
equal(formatReadableDuration(3 * 3600 + 22 * 60), "3 小时 22 分钟", "mixed duration");
equal(formatReadableDuration(3600), "1 小时", "whole hour duration");
equal(formatReadableDuration(22 * 60), "22 分钟", "minute duration");
equal(clockDifferenceSeconds("23:00", "07:30"), 30_600, "overnight clock difference");
equal(parseLunchDuration("1,5"), 1.5, "localized decimal duration");
equal(parseLunchDuration("-1"), null, "negative duration");
equal(formatLunchDuration(1.255), "1.25", "stable lunch duration");
equal(calendarLeadingBlankCount("2026-07"), 3, "calendar grid leading blanks");
equal(shiftMonthKey("2026-01", -1), "2025-12", "calendar previous year boundary");
equal(shiftMonthKey("2026-12", 1), "2027-01", "calendar next year boundary");
equal(
  calendarBusinessState({
    kind: "workday",
    source: "automatic",
    automatic_source: "adjusted_workday",
    override_kind: null,
  }),
  "adjusted_workday",
  "adjusted workday mapping",
);
equal(
  calendarBusinessState({
    kind: "rest_day",
    source: "manual",
    automatic_source: "rest_day",
    override_kind: "paid_rest",
  }),
  "paid_rest",
  "manual paid rest mapping",
);

console.log("presentation utilities behavior: 18/18 passed");
