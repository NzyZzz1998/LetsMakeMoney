import type { DateOverrideKind } from "./configModel";

export type DateOverrideSelection = DateOverrideKind | "automatic";
export type DateOverrideFeedback = "idle" | "saving" | "saved" | "unchanged" | "failed";

export interface DateOverrideEditorState {
  date: string;
  persisted: DateOverrideSelection;
  draft: DateOverrideSelection;
  feedback: DateOverrideFeedback;
  message: string;
}

export type DateOverrideEditorAction =
  | { type: "changed"; value: DateOverrideSelection }
  | { type: "saving" }
  | { type: "saved"; message: string }
  | { type: "unchanged"; message: string }
  | { type: "failed"; message: string }
  | { type: "cancelled" };

export function createDateOverrideEditorState(
  date: string,
  persisted: DateOverrideSelection,
): DateOverrideEditorState {
  return {
    date,
    persisted,
    draft: persisted,
    feedback: "idle",
    message: "",
  };
}

export function reduceDateOverrideEditor(
  state: DateOverrideEditorState,
  action: DateOverrideEditorAction,
): DateOverrideEditorState {
  switch (action.type) {
    case "changed":
      return { ...state, draft: action.value, feedback: "idle", message: "" };
    case "saving":
      return { ...state, feedback: "saving", message: "" };
    case "saved":
      return {
        ...state,
        persisted: state.draft,
        feedback: "saved",
        message: action.message,
      };
    case "unchanged":
      return { ...state, feedback: "unchanged", message: action.message };
    case "failed":
      return { ...state, feedback: "failed", message: action.message };
    case "cancelled":
      return {
        ...state,
        draft: state.persisted,
        feedback: "idle",
        message: "",
      };
  }
}
