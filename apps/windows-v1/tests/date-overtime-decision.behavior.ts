import {
  resolveDateOvertimeDecision,
  suggestedOvertimeDraft,
} from "../src/features/calendar/dateOvertimeDecision";
import type {
  OvertimeBoundaryResolution,
  OvertimeRecord,
} from "../src/features/calendar/overtimeModel";

function assert(condition: unknown, message: string): asserts condition {
  if (!condition) throw new Error(message);
}

const boundary: OvertimeBoundaryResolution = {
  snapshot: {
    basis: "planned_shift_gap",
    current_shift_end: "2026-08-08T18:00:00+08:00",
    next_actual_work_start: "2026-08-10T09:00:00+08:00",
    maximum_minutes: 360,
    calendar_source: "manual",
  },
  suggested_minutes: 360,
  origin: "manual_weekend_work",
  linked_override_date: "2026-08-08",
  day_source: "manual_override",
};
const linked: OvertimeRecord = {
  business_date: "2026-08-08",
  minutes: 300,
  hourly_rate_fen_snapshot: 6250,
  origin: "manual_weekend_work",
  boundary_snapshot: boundary.snapshot,
  linked_override_date: "2026-08-08",
  created_at: "2026-08-08T10:00:00Z",
  updated_at: "2026-08-08T10:00:00Z",
};

assert(suggestedOvertimeDraft(boundary, null) === "6", "the default 8h suggestion must be clipped to the dynamic maximum");
assert(suggestedOvertimeDraft(boundary, linked) === null, "an existing linked record must keep its saved draft");

const upsert = resolveDateOvertimeDecision({
  dateChanged: true,
  selection: "workday",
  boundary,
  linkedRecord: null,
  overtimeDraft: "6",
  linkedChoice: null,
});
assert(upsert.type === "upsert" && upsert.minutes === 360, "manual weekend work must atomically upsert overtime");

const overLimit = resolveDateOvertimeDecision({
  dateChanged: true,
  selection: "workday",
  boundary,
  linkedRecord: null,
  overtimeDraft: "6.01",
  linkedChoice: null,
});
assert(overLimit.type === "error", "the UI decision must enforce the native dynamic maximum");

const unchanged = resolveDateOvertimeDecision({
  dateChanged: false,
  selection: "workday",
  boundary,
  linkedRecord: linked,
  overtimeDraft: "5",
  linkedChoice: null,
});
assert(unchanged.type === "unchanged", "unchanged date and overtime values must not write");

const missingChoice = resolveDateOvertimeDecision({
  dateChanged: true,
  selection: "automatic",
  boundary: null,
  linkedRecord: linked,
  overtimeDraft: "5",
  linkedChoice: null,
});
assert(missingChoice.type === "error", "restoring a linked date must require an explicit keep/delete decision");

const keep = resolveDateOvertimeDecision({
  dateChanged: true,
  selection: "automatic",
  boundary: null,
  linkedRecord: linked,
  overtimeDraft: "5",
  linkedChoice: "keep",
});
assert(keep.type === "linked" && keep.action === "keep", "keep must detach the linked record through the transaction");

console.log("date overtime decision behavior: 7/7 passed");
