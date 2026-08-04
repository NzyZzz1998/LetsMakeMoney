import type { DateOverrideSelection } from "./dateOverrideState";
import {
  parseOvertimeHours,
  type OvertimeBoundaryResolution,
  type OvertimeRecord,
} from "./overtimeModel";

export type LinkedOvertimeChoice = "keep" | "delete" | null;

export type DateOvertimeDecision =
  | { type: "plain" }
  | { type: "unchanged"; message: string }
  | { type: "error"; message: string }
  | { type: "linked"; action: Exclude<LinkedOvertimeChoice, null> }
  | { type: "upsert"; minutes: number };

interface ResolveDateOvertimeDecisionInput {
  dateChanged: boolean;
  selection: DateOverrideSelection;
  boundary: OvertimeBoundaryResolution | null;
  linkedRecord: OvertimeRecord | null;
  overtimeDraft: string;
  linkedChoice: LinkedOvertimeChoice;
}

export function isManualWeekendWork(
  selection: DateOverrideSelection,
  boundary: OvertimeBoundaryResolution | null,
): boolean {
  return selection === "workday" && boundary?.origin === "manual_weekend_work";
}

export function suggestedOvertimeDraft(
  boundary: OvertimeBoundaryResolution,
  linkedRecord: OvertimeRecord | null,
): string | null {
  if (linkedRecord || boundary.origin !== "manual_weekend_work") return null;
  if (boundary.suggested_minutes === null) return null;
  return (boundary.suggested_minutes / 60)
    .toFixed(2)
    .replace(/\.00$/, "")
    .replace(/(\.\d)0$/, "$1");
}

export function resolveDateOvertimeDecision({
  dateChanged,
  selection,
  boundary,
  linkedRecord,
  overtimeDraft,
  linkedChoice,
}: ResolveDateOvertimeDecisionInput): DateOvertimeDecision {
  if (isManualWeekendWork(selection, boundary)) {
    if (!boundary) return { type: "error", message: "尚未取得本次加班上限" };
    const parsed = parseOvertimeHours(overtimeDraft, boundary.snapshot.maximum_minutes);
    if (!parsed.ok || parsed.minutes === null || parsed.minutes === 0) {
      return {
        type: "error",
        message: parsed.message || "请输入大于 0 的加班时长",
      };
    }
    if (!dateChanged && linkedRecord?.minutes === parsed.minutes) {
      return { type: "unchanged", message: "日期与关联加班没有变化" };
    }
    return { type: "upsert", minutes: parsed.minutes };
  }

  if (linkedRecord && selection !== "workday") {
    if (linkedChoice === null) {
      return { type: "error", message: "请选择保留或删除关联加班记录" };
    }
    return { type: "linked", action: linkedChoice };
  }

  return dateChanged
    ? { type: "plain" }
    : { type: "unchanged", message: "日期设置没有变化" };
}
