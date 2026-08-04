import { useEffect, useReducer, useRef, useState } from "react";
import { recordSemanticEvent } from "../../model";
import { createDeferredDisposer } from "../../runtime/appRuntime";
import { overtimeService } from "./overtimeService";
import {
  createOvertimeMonthState,
  reduceOvertimeMonthState,
  type OvertimeMonthData,
} from "./overtimeMonthState";

export function useOvertimeMonth(month: string) {
  const [state, dispatch] = useReducer(
    reduceOvertimeMonthState,
    month,
    createOvertimeMonthState,
  );
  const [revision, setRevision] = useState(0);
  const requestId = useRef(0);
  const cache = useRef(new Map<string, OvertimeMonthData>());

  useEffect(() => {
    const activeRequestId = requestId.current + 1;
    requestId.current = activeRequestId;
    dispatch({
      type: "requested",
      requestId: activeRequestId,
      targetMonth: month,
      cached: cache.current.get(month),
    });
    const load = async () => {
      if (!overtimeService.isDesktop) {
        dispatch({
          type: "resolved",
          requestId: activeRequestId,
          targetMonth: month,
          data: { month, records: [] },
          message: "浏览器预览未连接本机加班记录",
        });
        return;
      }
      try {
        const result = await overtimeService.readMonth(month);
        if (requestId.current !== activeRequestId) return;
        if (result.status === "failed" || result.status === "corrupt") {
          dispatch({
            type: "failed",
            requestId: activeRequestId,
            targetMonth: month,
            failureStatus: result.status,
            errorCode: result.error_code,
            message: result.message,
          });
          recordSemanticEvent(
            "overtime.month.failed",
            `month=${month};status=${result.status};reason=${result.error_code ?? "unknown"}`,
          );
          return;
        }
        const data = { month, records: result.records };
        cache.current.set(month, data);
        dispatch({
          type: "resolved",
          requestId: activeRequestId,
          targetMonth: month,
          data,
          message: result.message,
        });
        recordSemanticEvent(
          "overtime.month.loaded",
          `month=${month};status=${result.status};records=${result.records.length}`,
        );
      } catch (error) {
        if (requestId.current !== activeRequestId) return;
        const message = error instanceof Error ? error.message : String(error);
        dispatch({
          type: "failed",
          requestId: activeRequestId,
          targetMonth: month,
          failureStatus: "failed",
          errorCode: "overtime_month_read_failed",
          message: `无法读取加班记录：${message}`,
        });
      }
    };
    void load();
  }, [month, revision]);

  useEffect(() => {
    if (!overtimeService.isDesktop) return;
    const disposer = createDeferredDisposer();
    void overtimeService.listenUpdated(() => setRevision(value => value + 1))
      .then(unlisten => disposer.attach(unlisten))
      .catch(() => undefined);
    return () => disposer.dispose();
  }, []);

  return {
    state: state.status,
    records: state.data?.month === month ? state.data.records : [],
    message: state.message,
    errorCode: state.errorCode,
    retry: () => setRevision(value => value + 1),
  };
}
