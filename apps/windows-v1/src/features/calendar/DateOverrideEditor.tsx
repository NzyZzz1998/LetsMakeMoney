import { useCallback, useEffect, useMemo, useReducer, useRef, useState } from "react";
import { Button, Feedback, IconButton, SegmentedControl } from "../../components";
import { recordSemanticEvent, saveDateOverride } from "../../model";
import { dashboardService, type LinkedOvertimeAction } from "../../services/dashboardService";
import { formatFullDate } from "../../utils/presentationFormatters";
import {
  isManualWeekendWork,
  resolveDateOvertimeDecision,
  suggestedOvertimeDraft,
  type LinkedOvertimeChoice,
} from "./dateOvertimeDecision";
import {
  formatOvertimeHours,
  parseOvertimeHours,
  type OvertimeBoundaryResolution,
  type OvertimeRecord,
} from "./overtimeModel";
import { overtimeService } from "./overtimeService";
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
  currentHourlyRateFen: number;
  onApplied(message: string): void;
  onClose(): void;
}

let transactionSequence = 0;

function nextTransactionId(date: string): string {
  transactionSequence += 1;
  return `date-override-${date}-${transactionSequence}`;
}

export function DateOverrideEditor({
  day,
  currentHourlyRateFen,
  onApplied,
  onClose,
}: DateOverrideEditorProps) {
  const [state, dispatch] = useReducer(
    reduceDateOverrideEditor,
    createDateOverrideEditorState(
      day.date,
      (day.override_kind ?? "automatic") as DateOverrideSelection,
    ),
  );
  const transactionId = useRef(nextTransactionId(day.date));
  const [linkedRecord, setLinkedRecord] = useState<OvertimeRecord | null>(null);
  const [boundary, setBoundary] = useState<OvertimeBoundaryResolution | null>(null);
  const [overtimeDraft, setOvertimeDraft] = useState("8");
  const [linkedChoice, setLinkedChoice] = useState<LinkedOvertimeChoice>(null);
  const [linkFeedback, setLinkFeedback] = useState<string | null>(null);
  const [linkLoading, setLinkLoading] = useState(overtimeService.isDesktop);

  const manualWeekendWork = isManualWeekendWork(state.draft, boundary);
  const parsedOvertime = useMemo(
    () => parseOvertimeHours(overtimeDraft, boundary?.snapshot.maximum_minutes),
    [boundary?.snapshot.maximum_minutes, overtimeDraft],
  );

  useEffect(() => {
    recordSemanticEvent(
      "calendar.override.opened",
      `transaction=${transactionId.current};date=${day.date};automatic=${day.automatic_kind};source=${day.automatic_source};current=${state.persisted}`,
    );
  }, [day.automatic_kind, day.automatic_source, day.date, state.persisted]);

  useEffect(() => {
    if (!overtimeService.isDesktop) return;
    let active = true;
    setLinkLoading(true);
    overtimeService.readDate(day.date)
      .then(result => {
        if (!active) return;
        if (result.status === "failed" || result.status === "corrupt") {
          setLinkFeedback(result.message);
          return;
        }
        const record = result.records.find(item =>
          item.origin === "manual_weekend_work" && item.linked_override_date === day.date,
        ) ?? null;
        setLinkedRecord(record);
        if (record) setOvertimeDraft(formatOvertimeHours(record.minutes));
      })
      .catch(error => {
        if (active) setLinkFeedback(`关联加班读取失败：${error instanceof Error ? error.message : String(error)}`);
      })
      .finally(() => {
        if (active) setLinkLoading(false);
      });
    return () => {
      active = false;
    };
  }, [day.date]);

  useEffect(() => {
    if (!overtimeService.isDesktop || state.draft !== "workday") {
      setBoundary(null);
      return;
    }
    let active = true;
    setLinkLoading(true);
    overtimeService.resolveBoundary(
      day.date,
      -new Date().getTimezoneOffset(),
      "workday",
    )
      .then(result => {
        if (!active) return;
        setBoundary(result);
        setLinkFeedback(null);
        const suggestion = suggestedOvertimeDraft(result, linkedRecord);
        if (suggestion !== null) setOvertimeDraft(suggestion);
      })
      .catch(error => {
        if (!active) return;
        setBoundary(null);
        setLinkFeedback(`无法计算联动加班上限：${error instanceof Error ? error.message : String(error)}`);
      })
      .finally(() => {
        if (active) setLinkLoading(false);
      });
    return () => {
      active = false;
    };
  }, [day.date, linkedRecord, state.draft]);

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
    const decision = resolveDateOvertimeDecision({
      dateChanged: shouldSubmitDateOverride(state),
      selection: state.draft,
      boundary,
      linkedRecord,
      overtimeDraft,
      linkedChoice,
    });
    if (decision.type === "unchanged") {
      dispatch({ type: "unchanged", message: decision.message });
      recordSemanticEvent(
        "calendar.override.unchanged",
        `transaction=${transactionId.current};date=${day.date};kind=${state.draft};source=client_guard`,
      );
      return;
    }
    if (decision.type === "error") {
      dispatch({ type: "failed", message: decision.message });
      return;
    }
    dispatch({ type: "saving" });
    const kind = state.draft === "automatic" ? null : state.draft;
    try {
      let result;
      if (dashboardService.isDesktop && decision.type === "upsert") {
        if (!boundary) throw new Error("尚未取得本次加班上限");
        result = await dashboardService.saveDateOvertimeTransaction(day.date, kind, {
          action: "upsert",
          request: {
            business_date: day.date,
            minutes: decision.minutes,
            hourly_rate_fen_snapshot: currentHourlyRateFen,
            origin: boundary.origin,
            boundary_snapshot: boundary.snapshot,
            linked_override_date: boundary.linked_override_date,
          },
        });
      } else if (dashboardService.isDesktop && decision.type === "linked") {
        const overtime: LinkedOvertimeAction = { action: decision.action };
        result = await dashboardService.saveDateOvertimeTransaction(day.date, kind, overtime);
      } else {
        result = await saveDateOverride(day.date, kind);
      }
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
          onChange={value => {
            setLinkedChoice(null);
            dispatch({ type: "changed", value: value as DateOverrideSelection });
          }}
          options={[
            { value: "automatic", label: "自动判断" },
            { value: "workday", label: "工作日" },
            { value: "paid_rest", label: "带薪休息", disabled: automaticIsRest },
            { value: "unpaid_rest", label: "不带薪休息", disabled: automaticIsRest },
          ]}
        />
        {linkLoading && <p className="date-editor__link-status" role="status">正在核对关联加班…</p>}
        {manualWeekendWork && boundary && (
          <section className="date-editor__overtime-link" aria-label="周末工作联动加班">
            <div>
              <strong>同时记录加班</strong>
              <p>自然周末设为工作日时默认 8 小时，并按下次真实开工时间限制上限。</p>
            </div>
            <label>
              <span>加班时长</span>
              <span className="overtime-editor__input-wrap">
                <input
                  type="text"
                  inputMode="decimal"
                  value={overtimeDraft}
                  onChange={event => setOvertimeDraft(event.target.value)}
                  disabled={state.feedback === "saving"}
                />
                <span>小时</span>
              </span>
            </label>
            <small>
              本次最多 {formatOvertimeHours(boundary.snapshot.maximum_minutes)} 小时；保存时换算为最近一分钟。
            </small>
            {!parsedOvertime.ok && <Feedback tone="error">{parsedOvertime.message}</Feedback>}
          </section>
        )}
        {linkedRecord && state.draft !== "workday" && (
          <section className="date-editor__linked-choice" aria-label="关联加班处理">
            <strong>该日期还有 {formatOvertimeHours(linkedRecord.minutes)} 小时关联加班</strong>
            <p>恢复自动判断或休息状态时，请明确处理这条记录。</p>
            <div>
              <Button
                variant={linkedChoice === "keep" ? "primary" : "secondary"}
                onClick={() => setLinkedChoice("keep")}
              >保留为独立加班</Button>
              <Button
                variant={linkedChoice === "delete" ? "primary" : "secondary"}
                onClick={() => setLinkedChoice("delete")}
              >删除关联加班</Button>
            </div>
          </section>
        )}
        {linkFeedback && <Feedback tone="error">{linkFeedback}</Feedback>}
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
