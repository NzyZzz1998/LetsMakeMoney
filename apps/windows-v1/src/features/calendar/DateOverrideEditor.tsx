import { useCallback, useEffect, useReducer, useRef } from "react";
import { Button, Feedback, IconButton, SegmentedControl } from "../../components";
import { recordSemanticEvent, saveDateOverride } from "../../model";
import { formatFullDate } from "../../utils/presentationFormatters";
import {
  createDateOverrideEditorState,
  reduceDateOverrideEditor,
  shouldSubmitDateOverride,
  type DateOverrideSelection,
} from "./dateOverrideState";

export interface DateOverrideDay {
  date: string;
  automatic_kind: "workday" | "rest_day";
  automatic_source: string;
  override_kind: DateOverrideSelection | null;
}

interface DateOverrideEditorProps {
  day: DateOverrideDay;
  onApplied(message: string): void;
  onClose(): void;
}

let transactionSequence = 0;

function nextTransactionId(date: string): string {
  transactionSequence += 1;
  return `date-override-${date}-${transactionSequence}`;
}

export function DateOverrideEditor({ day, onApplied, onClose }: DateOverrideEditorProps) {
  const [state, dispatch] = useReducer(
    reduceDateOverrideEditor,
    createDateOverrideEditorState(
      day.date,
      (day.override_kind ?? "automatic") as DateOverrideSelection,
    ),
  );
  const transactionId = useRef(nextTransactionId(day.date));

  useEffect(() => {
    recordSemanticEvent(
      "calendar.override.opened",
      `transaction=${transactionId.current};date=${day.date};automatic=${day.automatic_kind};source=${day.automatic_source};current=${state.persisted}`,
    );
  }, [day.automatic_kind, day.automatic_source, day.date, state.persisted]);

  const close = useCallback(() => {
    dispatch({ type: "cancelled" });
    recordSemanticEvent(
      "calendar.override.cancelled",
      `transaction=${transactionId.current};date=${day.date}`,
    );
    onClose();
  }, [day.date, onClose]);

  useEffect(() => {
    const handleKeyDown = (event: KeyboardEvent) => {
      if (event.key === "Escape") close();
    };
    window.addEventListener("keydown", handleKeyDown);
    return () => window.removeEventListener("keydown", handleKeyDown);
  }, [close]);

  const apply = async () => {
    if (!shouldSubmitDateOverride(state)) {
      dispatch({ type: "unchanged", message: "日期设置没有变化" });
      recordSemanticEvent(
        "calendar.override.unchanged",
        `transaction=${transactionId.current};date=${day.date};kind=${state.draft};source=client_guard`,
      );
      return;
    }
    dispatch({ type: "saving" });
    const kind = state.draft === "automatic" ? null : state.draft;
    try {
      const result = await saveDateOverride(day.date, kind);
      if (result.status === "failed") {
        dispatch({ type: "failed", message: result.message });
        recordSemanticEvent(
          "calendar.override.failed",
          `transaction=${transactionId.current};date=${day.date};kind=${state.draft};reason=${result.message}`,
        );
        return;
      }
      dispatch({ type: result.status, message: result.message });
      recordSemanticEvent(
        result.status === "unchanged"
          ? "calendar.override.unchanged"
          : state.draft === "automatic"
            ? "calendar.override.removed"
            : "calendar.override.applied",
        `transaction=${transactionId.current};date=${day.date};kind=${state.draft}`,
      );
      if (result.status === "saved") onApplied(result.message);
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error);
      dispatch({ type: "failed", message: `保存失败：${message}` });
      recordSemanticEvent(
        "calendar.override.failed",
        `transaction=${transactionId.current};date=${day.date};kind=${state.draft};reason=${message}`,
      );
    }
  };

  const automaticIsRest = day.automatic_kind === "rest_day";
  return (
    <div className="modal-backdrop" role="presentation">
      <section
        className="surface date-editor"
        role="dialog"
        aria-modal="true"
        aria-label={`调整 ${formatFullDate(day.date)}`}
      >
        <div className="date-editor__heading">
          <span className="eyebrow">手动调整</span>
          <h2>{formatFullDate(day.date)}</h2>
          <p>
            自动判断：{automaticIsRest ? "休息日" : "工作日"}。
            {automaticIsRest ? "自动休息日不能重复记为请假。" : "可区分带薪与不带薪休息。"}
          </p>
        </div>
        <SegmentedControl
          value={state.draft}
          onChange={value => dispatch({ type: "changed", value: value as DateOverrideSelection })}
          options={[
            { value: "automatic", label: "自动判断" },
            { value: "workday", label: "工作日" },
            { value: "paid_rest", label: "带薪休息", disabled: automaticIsRest },
            { value: "unpaid_rest", label: "不带薪休息", disabled: automaticIsRest },
          ]}
        />
        <div className="date-editor__actions">
          <Button variant="secondary" onClick={close}>取消</Button>
          <Button onClick={() => void apply()} disabled={state.feedback === "saving"}>
            {state.feedback === "saving" ? "正在应用…" : "应用"}
          </Button>
          <IconButton label="关闭日期调整" icon="close" onClick={close} />
        </div>
        {state.feedback !== "idle" && state.feedback !== "saving" && (
          <Feedback tone={state.feedback === "failed" ? "error" : "success"}>
            {state.message}
          </Feedback>
        )}
      </section>
    </div>
  );
}
