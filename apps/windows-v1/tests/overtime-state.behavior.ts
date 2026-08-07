import {
  approximateOvertimeAmountYuan,
  createOvertimeEditorState,
  formatOvertimeHours,
  overtimeDraftIsUnchanged,
  parseOvertimeHours,
  reduceOvertimeEditor,
  type OvertimeRecord,
} from "../src/features/calendar/overtimeModel";

function assert(condition: unknown, message: string): asserts condition {
  if (!condition) throw new Error(message);
}

const oneAndQuarter = parseOvertimeHours("1.25");
assert(oneAndQuarter.ok && oneAndQuarter.minutes === 75, "1.25 hours must become 75 minutes");
assert(parseOvertimeHours("0.01").minutes === 1, "fractional hours must round to the nearest minute");
assert(parseOvertimeHours("24").minutes === 1440, "24 hours must be accepted");
assert(!parseOvertimeHours("24.01").ok, "values above 24 hours must be rejected");
assert(!parseOvertimeHours("1.234").ok, "more than two decimal places must be rejected");
assert(!parseOvertimeHours("-1").ok, "negative overtime must be rejected");
assert(formatOvertimeHours(90) === "1.5", "stored minutes must render without meaningless zeroes");

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
let state = createOvertimeEditorState();
state = reduceOvertimeEditor(state, { type: "loaded", record, message: "已读取" });
assert(overtimeDraftIsUnchanged(state, 90), "an unchanged persisted duration must not be written");
state = reduceOvertimeEditor(state, { type: "changed", value: "2" });
state = reduceOvertimeEditor(state, { type: "saving" });
state = reduceOvertimeEditor(state, { type: "failed", message: "写入失败" });
assert(state.draftHours === "2", "save failure must retain the user's draft");
assert(state.persisted?.minutes === 90, "save failure must retain the persisted record");
state = reduceOvertimeEditor(state, { type: "corrupt", message: "数据损坏" });
assert(state.recoveryAvailable, "corruption must expose explicit recovery");
state = reduceOvertimeEditor(state, { type: "recovered", message: "已恢复" });
assert(state.persisted === null && state.draftHours === "0", "recovery must start from an explicit empty store");
assert(approximateOvertimeAmountYuan(90, 6250) === 93.75, "rate snapshot math must use fen and minutes");

console.log("overtime state behavior: 13/13 passed");
