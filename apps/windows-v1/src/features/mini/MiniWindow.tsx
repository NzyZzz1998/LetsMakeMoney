import { useEffect } from "react";

import { ProgressBar } from "../../components";
import { WINDOW_SURFACE_ATTRIBUTES } from "../../components/windowSurfaceContract";
import { useWindowDrag } from "../../hooks/useWindowDrag";
import {
  dashboardErrorTitle,
  formatDuration,
  formatMoney,
  useDashboard,
} from "../../model";
import { boundaryPresentation } from "../../presentation";
import {
  windowService,
  type WindowKind,
} from "../../services/windowService";
import { formatShortDate } from "../../utils/presentationFormatters";
import { useMiniEdgeAutoHide } from "./useMiniEdgeAutoHide";
import { privacyTabPresentation } from "./privacyTabPresentation";

interface MiniWindowProps {
  onOpenWindow(label: WindowKind): void;
}

export function MiniWindow({ onOpenWindow }: MiniWindowProps) {
  const { snapshot, refresh } = useDashboard();
  const edge = useMiniEdgeAutoHide();
  const drag = useWindowDrag("mini", {
    allowInteractiveStart: true,
    onDragStart: edge.dragStarted,
    onDragEnd: edge.dragCompleted,
  });
  const miniState = snapshot.state === "error" ? "error" : "normal";
  const activateClick = (action: () => void) => {
    if (!drag.consumeDraggedClick()) action();
  };

  useEffect(() => {
    void windowService.setMiniState(miniState).catch(() => {
      // Browser preview and older native shells keep their current dimensions.
    });
  }, [miniState]);

  const privacy = privacyTabPresentation({
    state: snapshot.state,
    phase: snapshot.phase,
    nextBoundaryKind: snapshot.nextBoundaryKind,
    nextBoundarySeconds: snapshot.nextBoundarySeconds,
  });

  const revealFromPrivacyControl = () => {
    if (drag.consumeDraggedClick()) return;
    void Promise.resolve(edge.reveal("privacy_activate")).then(() => {
      window.requestAnimationFrame(() => {
        document.querySelector<HTMLElement>("[data-mini-primary-action]")?.focus();
      });
    });
  };

  if (edge.snapshot.phase === "retracted") {
    return (
      <main
        className={`mini-window mini-window--privacy-tab mini-window--dock-${edge.snapshot.dock}`}
        data-window="mini"
        {...WINDOW_SURFACE_ATTRIBUTES}
        {...edge.handlers}
        {...drag.handlers}
        data-privacy-surface="true"
      >
        <button
          className="mini-window__privacy-hit"
          type="button"
          data-window-drag="false"
          aria-label={privacy.ariaLabel}
          onClick={revealFromPrivacyControl}
        >
          <span aria-hidden="true" data-privacy-copy="true">{privacy.visibleText}</span>
        </button>
      </main>
    );
  }

  if (snapshot.state === "loading") {
    return (
      <main
        className="mini-window mini-window--state"
        data-window="mini"
        {...WINDOW_SURFACE_ATTRIBUTES}
        {...edge.handlers}
        {...drag.handlers}
      >
        <span className="spinner" />
        <strong>正在计算今天的收入</strong>
        {edge.feedback && <span className="mini-window__edge-feedback" role="status">{edge.feedback}</span>}
      </main>
    );
  }

  if (snapshot.state === "error") {
    return (
      <main
        className="mini-window mini-window--state mini-window--error"
        data-window="mini"
        {...WINDOW_SURFACE_ATTRIBUTES}
        {...edge.handlers}
        {...drag.handlers}
      >
        <div className="mini-window__error-copy">
          <strong>{dashboardErrorTitle(snapshot.errorCode)}</strong>
          <span>{snapshot.message}</span>
        </div>
        <div className="mini-window__error-actions">
          <button
            type="button"
            data-window-drag="false"
            data-mini-primary-action="true"
            onClick={() => activateClick(() => onOpenWindow("settings"))}
          >
            检查设置
          </button>
          <button
            type="button"
            data-window-drag="false"
            onClick={() => activateClick(refresh)}
          >
            重试
          </button>
        </div>
        {edge.feedback && <span className="mini-window__edge-feedback" role="status">{edge.feedback}</span>}
      </main>
    );
  }

  const isRestDay = snapshot.phase === "rest_day";
  const isPaidRest = snapshot.phase === "paid_rest";
  const isUnpaidRest = snapshot.phase === "unpaid_rest";
  const isRestLike = isRestDay || isPaidRest || isUnpaidRest;
  const stage = boundaryPresentation({
    phase: snapshot.phase,
    nextBoundaryKind: snapshot.nextBoundaryKind,
    nextBoundarySeconds: snapshot.nextBoundarySeconds,
  });

  return (
    <main
      className={`mini-window ${isRestLike ? "mini-window--rest" : ""}`}
      data-window="mini"
      {...WINDOW_SURFACE_ATTRIBUTES}
      {...edge.handlers}
      {...drag.handlers}
    >
      <button
        className="mini-window__primary"
        type="button"
        data-mini-primary-action="true"
        onClick={() => activateClick(() => onOpenWindow("workbench"))}
        aria-label="打开今日工作台"
      >
        <span className="mini-window__status">
          <span className="status-dot" />
          {stage.stateLabel}
        </span>
        {isRestDay ? (
          <>
            <span className="mini-window__label">今天没有工作安排</span>
            <strong className="mini-window__amount mini-window__amount--rest">安心休息</strong>
            <span className="mini-window__rest-line" aria-hidden="true" />
            <span className="mini-window__meta">
              {snapshot.nextWorkDate
                ? `下一个工作日 ${formatShortDate(snapshot.nextWorkDate)} ${snapshot.workStartTime}`
                : "下一个工作日尚未确定"}
            </span>
          </>
        ) : isPaidRest ? (
          <>
            <span className="mini-window__label">今日带薪金额</span>
            <strong className="mini-window__amount">{formatMoney(snapshot.amount)}</strong>
            <span className="mini-window__rest-line" aria-hidden="true" />
            <span className="mini-window__meta">今天不计算有效工时</span>
          </>
        ) : isUnpaidRest ? (
          <>
            <span className="mini-window__label">今天不计算收入</span>
            <strong className="mini-window__amount mini-window__amount--rest">不带薪休息</strong>
            <span className="mini-window__rest-line" aria-hidden="true" />
            <span className="mini-window__meta">
              本月预计应发 {formatMoney(snapshot.expectedMonthlyPay)}
            </span>
          </>
        ) : (
          <>
            <span className="mini-window__label">今日已赚</span>
            <strong className="mini-window__amount">{formatMoney(snapshot.amount)}</strong>
            <ProgressBar value={snapshot.progress} label="工作进度" compact />
            <span className="mini-window__meta">
              {stage.completeLabel
                ?? (stage.countdownLabel && stage.countdownSeconds !== null
                  ? `${stage.countdownLabel} ${formatDuration(stage.countdownSeconds)}`
                  : snapshot.workState)}
            </span>
          </>
        )}
        {snapshot.syncState === "stale" && (
          <span className="mini-window__sync">正在重新同步</span>
        )}
      </button>
      {edge.feedback && <span className="mini-window__edge-feedback" role="status">{edge.feedback}</span>}
    </main>
  );
}
