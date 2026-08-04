import type { OvertimeRecord } from "./overtimeModel";

export interface MonthlySummaryDay {
  date: string;
  kind: "workday" | "rest_day";
}

export interface MonthlySummarySchedule {
  workStartTime: string;
  restStartTime: string;
  restEndTime: string;
  workEndTime: string;
  effectiveMinutes: number;
}

export interface MonthlySummaryInput {
  month: string;
  days: MonthlySummaryDay[];
  ownerDate: string;
  currentLocalDate: string;
  currentMinuteOfDay: number;
  schedule: MonthlySummarySchedule;
  overtimeRecords: OvertimeRecord[];
}

export interface MonthlySummaryResult {
  plannedMinutes: number;
  elapsedPlannedMinutes: number;
  overtimeMinutes: number;
}

function parseClockMinutes(value: string): number | null {
  const match = /^(\d{2}):(\d{2})$/.exec(value);
  if (!match) return null;
  const hours = Number(match[1]);
  const minutes = Number(match[2]);
  if (hours > 23 || minutes > 59) return null;
  return hours * 60 + minutes;
}

function dateSerial(value: string): number | null {
  const match = /^(\d{4})-(\d{2})-(\d{2})$/.exec(value);
  if (!match) return null;
  const year = Number(match[1]);
  const month = Number(match[2]);
  const day = Number(match[3]);
  const timestamp = Date.UTC(year, month - 1, day);
  const parsed = new Date(timestamp);
  if (
    parsed.getUTCFullYear() !== year
    || parsed.getUTCMonth() !== month - 1
    || parsed.getUTCDate() !== day
  ) return null;
  return Math.floor(timestamp / 86_400_000);
}

function intervalElapsed(now: number, start: number, end: number): number {
  return Math.max(0, Math.min(now, end) - start);
}

export function elapsedPlannedMinutesForOwnerDate(
  ownerDate: string,
  currentLocalDate: string,
  currentMinuteOfDay: number,
  schedule: MonthlySummarySchedule,
): number {
  const start = parseClockMinutes(schedule.workStartTime);
  let end = parseClockMinutes(schedule.workEndTime);
  let restStart = parseClockMinutes(schedule.restStartTime);
  let restEnd = parseClockMinutes(schedule.restEndTime);
  const ownerSerial = dateSerial(ownerDate);
  const currentSerial = dateSerial(currentLocalDate);
  if (
    start === null
    || end === null
    || restStart === null
    || restEnd === null
    || ownerSerial === null
    || currentSerial === null
    || !Number.isFinite(currentMinuteOfDay)
  ) return 0;

  const overnight = end <= start;
  if (overnight) {
    end += 24 * 60;
    if (restStart < start) restStart += 24 * 60;
    if (restEnd <= start) restEnd += 24 * 60;
  }
  if (restEnd < restStart || restStart < start || restEnd > end) return 0;

  const now = (currentSerial - ownerSerial) * 24 * 60 + currentMinuteOfDay;
  const elapsed = restEnd === restStart
    ? intervalElapsed(now, start, end)
    : intervalElapsed(now, start, restStart) + intervalElapsed(now, restEnd, end);
  return Math.min(Math.max(0, Math.round(schedule.effectiveMinutes)), elapsed);
}

export function calculateMonthlySummary(input: MonthlySummaryInput): MonthlySummaryResult {
  const monthDays = input.days.filter(day => day.date.startsWith(`${input.month}-`));
  const workdays = monthDays.filter(day => day.kind === "workday");
  const effectiveMinutes = Math.max(0, Math.round(input.schedule.effectiveMinutes));
  const plannedMinutes = workdays.length * effectiveMinutes;
  const ownerMonth = input.ownerDate.slice(0, 7);

  let elapsedPlannedMinutes = 0;
  if (input.month < ownerMonth) {
    elapsedPlannedMinutes = plannedMinutes;
  } else if (input.month === ownerMonth) {
    for (const day of workdays) {
      if (day.date < input.ownerDate) {
        elapsedPlannedMinutes += effectiveMinutes;
      } else if (day.date === input.ownerDate) {
        elapsedPlannedMinutes += elapsedPlannedMinutesForOwnerDate(
          input.ownerDate,
          input.currentLocalDate,
          input.currentMinuteOfDay,
          input.schedule,
        );
      }
    }
  }

  const overtimeMinutes = input.overtimeRecords
    .filter(record => record.business_date.startsWith(`${input.month}-`))
    .reduce((total, record) => total + Math.max(0, record.minutes), 0);

  return { plannedMinutes, elapsedPlannedMinutes, overtimeMinutes };
}

export function formatWorkMinutes(minutes: number): string {
  const safeMinutes = Math.max(0, Math.round(minutes));
  if (safeMinutes === 0) return "0 分钟";
  const hours = Math.floor(safeMinutes / 60);
  const remainder = safeMinutes % 60;
  if (hours === 0) return `${remainder} 分钟`;
  if (remainder === 0) return `${hours} 小时`;
  return `${hours} 小时 ${remainder} 分钟`;
}
