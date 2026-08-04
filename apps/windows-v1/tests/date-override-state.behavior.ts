import {
  createDateOverrideEditorState,
  reduceDateOverrideEditor,
  shouldSubmitDateOverride,
} from "../src/dateOverrideState";

function assert(condition: unknown, message: string): asserts condition {
  if (!condition) throw new Error(message);
}

let state = createDateOverrideEditorState("2026-07-24", "automatic");
assert(!shouldSubmitDateOverride(state), "unchanged date overrides must not invoke the backend");
state = reduceDateOverrideEditor(state, { type: "changed", value: "paid_rest" });
assert(shouldSubmitDateOverride(state), "changed date overrides must become submittable");
state = reduceDateOverrideEditor(state, { type: "cancelled" });
assert(state.draft === "automatic", "cancel must discard the unsaved draft");

state = reduceDateOverrideEditor(state, { type: "changed", value: "unpaid_rest" });
state = reduceDateOverrideEditor(state, { type: "saving" });
state = reduceDateOverrideEditor(state, { type: "failed", message: "保存失败" });
assert(state.draft === "unpaid_rest", "failure must preserve the user's draft");
assert(state.persisted === "automatic", "failure must not mutate persisted state");
assert(state.feedback === "failed", "failure must remain visible");

state = reduceDateOverrideEditor(state, { type: "saved", message: "已应用" });
assert(state.persisted === "unpaid_rest", "success must promote the draft");
assert(state.feedback === "saved", "success feedback must be explicit");

state = reduceDateOverrideEditor(state, { type: "unchanged", message: "没有变化" });
assert(state.feedback === "unchanged", "unchanged must be distinguishable from saved");

console.log("date-override state behavior: 6/6 passed");
