import { useCallback, useEffect, useMemo, useReducer, useState } from "react";
import { Button, Feedback, IconButton } from "../../components";
import { formatMoney, recordSemanticEvent } from "../../model";
import {
  approximateOvertimeAmountYuan,
  createOvertimeEditorState,
  overtimeDraftIsUnchanged,
  parseOvertimeHours,
  reduceOvertimeEditor,
} from "./overtimeModel";
import { overtimeService } from "./overtimeService";

interface OvertimeEditorProps {
  businessDate: string;
  currentHourlyRateFen: number;
  onApplied(message: string): void;
  onClose(): void;
}

export function OvertimeEditor({
  businessDate,
  currentHourlyRateFen,
  onApplied,
  onClose,
}: OvertimeEditorProps) {
  const [state, dispatch] = useReducer(reduceOvertimeEditor, undefined, createOvertimeEditorState);
  const [confirmDelete, setConfirmDelete] = useState(false);
  const parsed = useMemo(() => parseOvertimeHours(state.draftHours), [state.draftHours]);
  const busy = state.status === "saving" || state.status === "deleting";

  const load = useCallback(async () => {
    dispatch({ type: "loading" });
    try {
      const result = await overtimeService.readDate(businessDate);
      if (result.status === "corrupt") {
        dispatch({ type: "corrupt", message: result.message, errorCode: result.error_code });
        return;
      }
      if (result.status === "failed") {
        dispatch({ type: "failed", message: result.message, errorCode: result.error_code });
        return;
      }
      dispatch({ type: "loaded", record: result.records[0] ?? null, message: result.message });
      recordSemanticEvent(
        "overtime.editor.loaded",
        `date=${businessDate};status=${result.status};schema=${result.schema_version}`,
      );
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error);
      dispatch({ type: "failed", message: `无法读取加班记录：${message}`, errorCode: "overtime_read_failed" });
    }
  }, [businessDate]);

  useEffect(() => {
    void load();
  }, [load]);

  const close = useCallback(() => {
    if (busy) return;
    recordSemanticEvent("overtime.editor.cancelled", `date=${businessDate}`);
    onClose();
  }, [businessDate, busy, onClose]);

  useEffect(() => {
    const handleKeyDown = (event: KeyboardEvent) => {
      if (event.key === "Escape") close();
    };
    window.addEventListener("keydown", handleKeyDown);
    return () => window.removeEventListener("keydown", handleKeyDown);
  }, [close]);

  const remove = async () => {
    dispatch({ type: "deleting" });
    try {
      const result = await overtimeService.delete(businessDate);
      if (result.status === "corrupt") {
        dispatch({ type: "corrupt", message: result.message, errorCode: result.error_code });
        return;
      }
      if (result.status === "failed") {
        dispatch({ type: "failed", message: result.message, errorCode: result.error_code });
        return;
      }
      dispatch({ type: "deleted", message: result.message });
      recordSemanticEvent("overtime.record.deleted", `date=${businessDate};minutes=0`);
      onApplied(result.message);
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error);
      dispatch({ type: "failed", message: `删除失败：${message}`, errorCode: "overtime_delete_failed" });
    }
  };

  const save = async () => {
    if (!parsed.ok || parsed.minutes === null) {
      dispatch({ type: "failed", message: parsed.message, errorCode: "overtime_input_invalid" });
      return;
    }
    if (parsed.minutes === 0 && state.persisted) {
      setConfirmDelete(true);
      return;
    }
    if (overtimeDraftIsUnchanged(state, parsed.minutes)) {
      dispatch({ type: "unchanged", message: "加班记录没有变化" });
      return;
    }
    dispatch({ type: "saving" });
    try {
      const result = await overtimeService.save({
        businessDate,
        minutes: parsed.minutes,
        hourlyRateFenSnapshot: currentHourlyRateFen,
      });
      if (result.status === "corrupt") {
        dispatch({ type: "corrupt", message: result.message, errorCode: result.error_code });
        return;
      }
      if (result.status === "failed" || !result.record) {
        dispatch({ type: "failed", message: result.message, errorCode: result.error_code });
        return;
      }
      if (result.status === "unchanged") {
        dispatch({ type: "unchanged", message: result.message });
        return;
      }
      dispatch({ type: "saved", record: result.record, message: result.message });
      recordSemanticEvent(
        "overtime.record.saved",
        `date=${businessDate};minutes=${result.record.minutes};schema=${result.schema_version}`,
      );
      onApplied(result.message);
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error);
      dispatch({ type: "failed", message: `保存失败：${message}`, errorCode: "overtime_save_failed" });
    }
  };

  const recover = async () => {
    dispatch({ type: "saving" });
    try {
      const result = await overtimeService.recover();
      if (result.status !== "recovered") {
        if (result.status === "corrupt") {
          dispatch({ type: "corrupt", message: result.message, errorCode: result.error_code });
        } else {
          dispatch({ type: "failed", message: result.message, errorCode: result.error_code });
        }
        return;
      }
      dispatch({ type: "recovered", message: result.message });
      recordSemanticEvent("overtime.store.recovered", `date=${businessDate};schema=${result.schema_version}`);
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error);
      dispatch({ type: "failed", message: `恢复失败：${message}`, errorCode: "overtime_recovery_failed" });
    }
  };

  const effectiveRateFen = state.persisted?.hourly_rate_fen_snapshot ?? currentHourlyRateFen;
  const approximateAmount = parsed.ok && parsed.minutes !== null
    ? approximateOvertimeAmountYuan(parsed.minutes, effectiveRateFen)
    : null;

  return (
    <div className="modal-backdrop" role="presentation">
      <section className="surface overtime-editor" role="dialog" aria-modal="true" aria-label={`记录 ${businessDate} 加班`}>
        <div className="overtime-editor__heading">
          <div>
            <span className="eyebrow">按日记录</span>
            <h2>记录加班</h2>
            <p>{businessDate} · 所有日期类型均可记录</p>
          </div>
          <IconButton label="关闭加班记录" icon="close" onClick={close} disabled={busy} />
        </div>

        {state.status === "loading" && <div className="overtime-editor__state" role="status">正在读取加班记录…</div>}
        {state.status === "corrupt" && (
          <div className="overtime-editor__state overtime-editor__state--danger" role="alert">
            <strong>加班数据无法安全读取</strong>
            <span>{state.message}</span>
            <Button onClick={() => void recover()}>备份损坏文件并恢复空白数据</Button>
          </div>
        )}
        {state.status !== "loading" && state.status !== "corrupt" && (
          <>
            <label className="overtime-editor__field">
              <span>加班时长</span>
              <span className="overtime-editor__input-wrap">
                <input
                  type="text"
                  inputMode="decimal"
                  value={state.draftHours}
                  onChange={event => {
                    setConfirmDelete(false);
                    dispatch({ type: "changed", value: event.target.value });
                  }}
                  disabled={busy}
                  aria-describedby="overtime-hours-hint"
                />
                <span>小时</span>
              </span>
            </label>
            <p id="overtime-hours-hint" className="overtime-editor__hint">
              请输入 0–24 小时，最多两位小数；保存时换算为最近一分钟。
            </p>
            {approximateAmount !== null && parsed.minutes !== null && parsed.minutes > 0 && (
              <div className="overtime-editor__summary">
                <span>{state.persisted ? "按首次录入费率" : "按当前权威时薪"}</span>
                <strong>本次约 {formatMoney(approximateAmount)}</strong>
                <small>仅用于解释本条记录，不计入 Dashboard 或月度收入。</small>
              </div>
            )}
            {confirmDelete && (
              <div className="overtime-editor__confirm" role="alert">
                <span>确认删除 {businessDate} 的加班记录？原费率快照也会一并移除。</span>
                <Button variant="secondary" onClick={() => setConfirmDelete(false)}>保留记录</Button>
                <Button onClick={() => void remove()}>确认删除</Button>
              </div>
            )}
            {state.status === "failed" && <Feedback tone="error">{state.message}</Feedback>}
            {state.message && !["failed", "loading"].includes(state.status) && (
              <Feedback tone="success">{state.message}</Feedback>
            )}
            <div className="overtime-editor__actions">
              {state.persisted && !confirmDelete && (
                <Button variant="ghost" onClick={() => setConfirmDelete(true)} disabled={busy}>删除记录</Button>
              )}
              <Button variant="secondary" onClick={close} disabled={busy}>取消</Button>
              <Button onClick={() => void save()} disabled={busy || !parsed.ok}>
                {state.status === "saving" ? "正在保存…" : state.status === "deleting" ? "正在删除…" : "保存"}
              </Button>
              {state.status === "failed" && (
                <Button variant="ghost" onClick={() => void load()} disabled={busy}>重新读取</Button>
              )}
            </div>
          </>
        )}
      </section>
    </div>
  );
}
