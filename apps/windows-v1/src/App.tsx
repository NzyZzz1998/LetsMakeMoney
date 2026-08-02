import { useCallback, useEffect, useMemo, useReducer, useRef, useState } from "react";
import {
  Button,
  AppIcon,
  Field,
  Feedback,
  IconButton,
  ProgressBar,
  SegmentedControl,
  Switch,
} from "./components";
import { WindowFrame } from "./components/WindowFrame";
import { MiniWindow } from "./features/mini/MiniWindow";
import {
  formatDuration,
  formatMoney,
  dashboardErrorTitle,
  recordSemanticEvent,
  saveDateOverride,
  useCalendarMonth,
  useDashboard,
  useMonthWorkdayPreview,
} from "./model";
import {
  addHours,
  useConfigDraft,
  type RestMode,
  type WeekType,
} from "./configModel";
import {
  createDateOverrideEditorState,
  reduceDateOverrideEditor,
  type DateOverrideSelection,
} from "./dateOverrideState";
import {
  boundaryPresentation,
  calendarBusinessState,
  calendarCellContract,
  calendarCoveragePresentation,
  timelineRows,
  workbenchHeading,
} from "./presentation";
import {
  formatLocalDate,
  systemTime,
} from "./runtime/timeService";
import {
  windowService,
  type WindowKind,
} from "./services/windowService";
import {
  supportService,
  type PlatformCapabilities,
} from "./services/supportService";
import {
  calendarLeadingBlankCount,
  clockDifferenceSeconds,
  formatFullDate,
  formatLunchDuration,
  formatReadableDuration,
  formatShortDate,
  parseLunchDuration,
  shiftMonthKey,
} from "./utils/presentationFormatters";

const WINDOW_LABELS: Record<WindowKind, string> = {
  mini: "迷你收入视图",
  workbench: "今日工作台",
  settings: "设置",
  wizard: "首次配置",
};

function resolveWindowKind(): WindowKind {
  const query = new URLSearchParams(window.location.search).get("window");
  if (query && query in WINDOW_LABELS) return query as WindowKind;
  return "mini";
}

async function showWindow(label: WindowKind) {
  try {
    await windowService.show(label);
  } catch {
    window.location.search = `?window=${label}`;
  }
}

async function hideCurrentWindow() {
  try {
    await windowService.hide(resolveWindowKind());
  } catch {
    // Browser preview intentionally has no native window to hide.
  }
}

function useNativeCloseRequest(requestClose: () => void) {
  useEffect(() => {
    window.addEventListener("lmm:window-close-requested", requestClose);
    return () => window.removeEventListener("lmm:window-close-requested", requestClose);
  }, [requestClose]);
}

function SyncNotice({ state }: { state: "synced" | "syncing" | "stale" }) {
  if (state === "synced") return null;
  return (
    <div className={`sync-notice sync-notice--${state}`} role="status">
      {state === "stale" ? "正在重新同步，当前显示最近一次可信结果。" : "正在同步最新结果…"}
    </div>
  );
}

function CalendarCoverageNotice({
  coverage,
}: {
  coverage: ReturnType<typeof useDashboard>["snapshot"]["calendarCoverage"];
}) {
  const content = calendarCoveragePresentation(coverage);
  if (!content.isVisible || content.tone === null) return null;
  return (
    <div className={`calendar-coverage calendar-coverage--${content.tone}`} role="status">
      <strong>{content.title}</strong>
      <span>{content.detail}</span>
    </div>
  );
}

function WorkbenchWindow() {
  const [tab, setTab] = useState("today");
  const dashboard = useDashboard();
  return (
    <WindowFrame kind="workbench" title="LetsMakeMoney" className="workbench-window">
      <div className="workbench-layout">
        <nav className="side-nav" aria-label="工作台导航">
          <button className={tab === "today" ? "is-active" : ""} onClick={() => setTab("today")}>
            <AppIcon name="coins" />今日
          </button>
          <button className={tab === "calendar" ? "is-active" : ""} onClick={() => setTab("calendar")}>
            <AppIcon name="calendar" />日历
          </button>
          <button onClick={() => showWindow("settings")}>
            <AppIcon name="settings" />设置
          </button>
        </nav>
        <section className="workbench-content">
          {tab === "today" ? <TodayView {...dashboard} /> : <CalendarView snapshot={dashboard.snapshot} />}
        </section>
      </div>
    </WindowFrame>
  );
}

function TodayView({ snapshot, refresh }: ReturnType<typeof useDashboard>) {
  if (snapshot.state === "loading") return <PageState title="正在整理今天" detail="收入、安排和日历正在同步。" />;
  if (snapshot.state === "error") {
    return (
      <PageState
        title={dashboardErrorTitle(snapshot.errorCode)}
        detail={snapshot.message ?? "请稍后重试。"}
        action={(
          <div className="page-state__actions">
            <Button variant="secondary" onClick={() => showWindow("settings")}>检查设置</Button>
            <Button onClick={refresh}>重新计算</Button>
          </div>
        )}
      />
    );
  }
  if (snapshot.phase === "rest_day") {
    return (
      <div className="page-stack" aria-label="今日休息">
        <SyncNotice state={snapshot.syncState} />
        <CalendarCoverageNotice coverage={snapshot.calendarCoverage} />
        <div className="page-heading">
          <div>
            <span className="eyebrow">{formatFullDate(snapshot.ownerDate)} · 休息日</span>
            <h1>今天安心休息</h1>
          </div>
          <span className="status-pill status-pill--rest">休息日</span>
        </div>
        <section className="rest-hero">
          <span className="rest-hero__symbol" aria-hidden="true">☕</span>
          <div>
            <h2>今天没有工作安排</h2>
            <p>休息日不计算有效工时、工作进度和今日收入。</p>
          </div>
        </section>
        <div className="content-grid">
          <section className="surface rest-schedule">
            <div className="section-heading">
              <div><span className="eyebrow">今日状态</span><h2>休息日</h2></div>
              <Button variant="ghost" onClick={() => showWindow("settings")}>调整今天</Button>
            </div>
            <div className="rest-schedule__body">
              <strong>今天无需打卡或记录工时</strong>
              <span>
                {snapshot.nextWorkDate
                  ? `下一个工作日是 ${formatFullDate(snapshot.nextWorkDate)}，${snapshot.workStartTime} 开始工作。`
                  : "暂未找到下一个工作日，请检查休息模式和日期调整。"}
              </span>
            </div>
          </section>
          <section className="surface stats">
            <div><span>本月累计</span><strong>{formatMoney(snapshot.monthTotal)}</strong></div>
            <div><span>本月工作日</span><strong>{snapshot.workdays} 天</strong></div>
            <div><span>下一工作日</span><strong>{snapshot.nextWorkDate ? formatShortDate(snapshot.nextWorkDate) : "待确定"}</strong></div>
          </section>
        </div>
      </div>
    );
  }
  if (snapshot.phase === "paid_rest" || snapshot.phase === "unpaid_rest") {
    const paid = snapshot.phase === "paid_rest";
    return (
      <div className="page-stack" aria-label={paid ? "今日带薪休息" : "今日不带薪休息"}>
        <SyncNotice state={snapshot.syncState} />
        <CalendarCoverageNotice coverage={snapshot.calendarCoverage} />
        <div className="page-heading">
          <div>
            <span className="eyebrow">{formatFullDate(snapshot.ownerDate)} · {paid ? "带薪休息" : "不带薪休息"}</span>
            <h1>{paid ? "今天带薪休息" : "今天不带薪休息"}</h1>
          </div>
          <span className={`status-pill ${paid ? "status-pill--success" : "status-pill--rest"}`}>
            {snapshot.workState}
          </span>
        </div>
        <section className="rest-hero">
          <span className="rest-hero__symbol" aria-hidden="true">{paid ? "¥" : "—"}</span>
          <div>
            <h2>{paid ? `今日带薪金额 ${formatMoney(snapshot.amount)}` : "今天不计算收入"}</h2>
            <p>
              {paid
                ? "当天工资分配金额已计入本月累计，不计算有效工时和工作进度。"
                : `当天工资分配金额已从本月预计应发中扣除，预计应发 ${formatMoney(snapshot.expectedMonthlyPay)}。`}
            </p>
          </div>
        </section>
        <div className="content-grid">
          <section className="surface rest-schedule">
            <div className="section-heading">
              <div><span className="eyebrow">今日状态</span><h2>{paid ? "带薪休息" : "不带薪休息"}</h2></div>
              <Button variant="ghost" onClick={() => showWindow("settings")}>调整今天</Button>
            </div>
            <div className="rest-schedule__body">
              <strong>今天无需记录有效工时</strong>
              <span>
                {snapshot.nextWorkDate
                  ? `下一个工作日是 ${formatFullDate(snapshot.nextWorkDate)}，${snapshot.workStartTime} 开始工作。`
                  : "暂未找到下一个工作日，请检查休息模式和日期调整。"}
              </span>
            </div>
          </section>
          <section className="surface stats">
            <div><span>本月累计</span><strong>{formatMoney(snapshot.monthTotal)}</strong></div>
            <div><span>本月预计应发</span><strong>{formatMoney(snapshot.expectedMonthlyPay)}</strong></div>
            <div><span>预计工作日</span><strong>{snapshot.workdays} 天</strong></div>
          </section>
        </div>
      </div>
    );
  }
  const todayKey = formatLocalDate(systemTime.now());
  const heading = workbenchHeading(snapshot.ownerDate, todayKey);
  const stage = boundaryPresentation({
    phase: snapshot.phase,
    nextBoundaryKind: snapshot.nextBoundaryKind,
    nextBoundarySeconds: snapshot.nextBoundarySeconds,
  });
  const scheduleRows = timelineRows({
    phase: snapshot.phase,
    nextBoundaryKind: snapshot.nextBoundaryKind,
    workStartTime: snapshot.workStartTime,
    restStartTime: snapshot.lunchStartTime,
    restEndTime: snapshot.lunchEndTime,
    workEndTime: snapshot.workEndTime,
  });
  const ownerDay = snapshot.calendarDays.find(day => day.date === snapshot.ownerDate);
  const ownerKindLabel = ownerDay?.source === "adjusted_workday"
    ? "官方调休工作日"
    : ownerDay?.source === "manual_workday"
      ? "手动工作日"
      : "工作日";
  return (
    <div className="page-stack" aria-label="今日">
      <SyncNotice state={snapshot.syncState} />
      <CalendarCoverageNotice coverage={snapshot.calendarCoverage} />
      <div className="page-heading">
        <div>
          <span className="eyebrow">{formatFullDate(snapshot.ownerDate)} · {ownerKindLabel}</span>
          <h1>{heading.title}</h1>
          {snapshot.ownerDate !== todayKey && <p>{heading.subtitle}</p>}
        </div>
        <span className="status-pill status-pill--success">{stage.stateLabel}</span>
      </div>
      <section className="amount-hero">
        <span>今日已赚</span>
        <strong className="long-number">{formatMoney(snapshot.amount)}</strong>
        <p>日薪 {formatMoney(snapshot.dailySalary)} · 时薪 {formatMoney(snapshot.hourlySalary)}</p>
        <ProgressBar value={snapshot.progress} label="工作进度" />
        <div className="boundary-summary" role="status">
          <span>{stage.completeLabel ?? stage.countdownLabel ?? snapshot.workState}</span>
          {stage.countdownSeconds !== null && <strong>{formatDuration(stage.countdownSeconds)}</strong>}
        </div>
      </section>
      <div className="content-grid">
        <section className="surface schedule">
          <div className="section-heading">
            <div><span className="eyebrow">时间线</span><h2>今日安排</h2></div>
            <Button variant="ghost" onClick={() => showWindow("settings")}>调整今天</Button>
          </div>
          <ol>
            {scheduleRows.map(row => {
              const detail = row.kind === "work_start" && snapshot.completedSeconds > 0
                ? `已完成 ${formatReadableDuration(snapshot.completedSeconds)}`
                : row.kind === "work_end" && snapshot.phase === "after_work"
                  ? "本次工作已完成"
                  : row.detail;
              return (
                <li key={row.kind} className={`is-${row.state}`}>
                  <time className="schedule__time">{row.time}</time>
                  <span className="schedule__axis" aria-hidden="true"><i /></span>
                  <div className="schedule__content">
                    <strong>{row.title}</strong>
                    <span>{detail}</span>
                  </div>
                </li>
              );
            })}
          </ol>
        </section>
        <section className="surface stats">
          <div><span>本月累计</span><strong>{formatMoney(snapshot.monthTotal)}</strong></div>
          <div><span>本月工作日</span><strong>{snapshot.workdays} 天</strong></div>
          <div>
            <span>{stage.completeLabel ?? stage.countdownLabel ?? "当前状态"}</span>
            <strong>{stage.countdownSeconds !== null ? formatDuration(stage.countdownSeconds) : "—"}</strong>
          </div>
        </section>
      </div>
    </div>
  );
}

function CalendarView({ snapshot }: { snapshot: ReturnType<typeof useDashboard>["snapshot"] }) {
  const todayKey = formatLocalDate(systemTime.now());
  const [visibleMonth, setVisibleMonth] = useState(() => snapshot.ownerDate.slice(0, 7));
  const calendarMonth = useCalendarMonth(
    visibleMonth,
    snapshot.calendarDays,
    snapshot.calendarCoverage,
  );
  const [visibleYear, visibleMonthNumber] = visibleMonth.split("-").map(Number);
  const displayMonth = calendarMonth.dataMonth ?? visibleMonth;
  const [displayYear, displayMonthNumber] = displayMonth.split("-").map(Number);
  const days = calendarMonth.days;
  const monthLabel = `${visibleYear} 年 ${visibleMonthNumber} 月`;
  const displayMonthLabel = `${displayYear} 年 ${displayMonthNumber} 月`;
  const leadingBlanks = Array.from({ length: calendarLeadingBlankCount(displayMonth) });
  const [selectedDate, setSelectedDate] = useState<string | null>(null);
  const [overrideFeedback, setOverrideFeedback] = useState<string | null>(null);
  const moveMonth = (offset: number) => {
    setVisibleMonth(shiftMonthKey(visibleMonth, offset));
    setSelectedDate(null);
    setOverrideFeedback(null);
  };
  return (
    <div className="page-stack" aria-label="日历">
      <SyncNotice state={snapshot.syncState} />
      <div className="page-heading">
        <div><span className="eyebrow">{monthLabel}</span><h1>收入日历</h1></div>
        <Button
          variant="secondary"
          onClick={() => setSelectedDate(
            days.find(day => day.date === snapshot.ownerDate)?.date ?? days[0]?.date ?? null,
          )}
          disabled={
            !days.length
            || calendarMonth.state === "stale"
            || calendarMonth.coverage?.can_adjust_date === false
          }
        >
          调整日期
        </Button>
      </div>
      {overrideFeedback && <Feedback tone="success">{overrideFeedback}</Feedback>}
      <section className="surface calendar">
        <div className="calendar__toolbar" aria-label="切换月份">
          <IconButton label="查看上个月" icon="chevron-left" onClick={() => moveMonth(-1)} />
          <strong>{monthLabel}</strong>
          <IconButton label="查看下个月" icon="chevron-right" onClick={() => moveMonth(1)} />
        </div>
        {calendarMonth.state === "loading" && (
          <div className="calendar__status" role="status">正在读取 {monthLabel} 的日历…</div>
        )}
        {calendarMonth.coverage && <CalendarCoverageNotice coverage={calendarMonth.coverage} />}
        {calendarMonth.state === "error" && (
          <div className="calendar__status calendar__status--warning" role="alert">
            <span>日历暂时无法加载，未展示可能错误的日期。</span>
            <Button variant="secondary" onClick={calendarMonth.retry}>重试</Button>
          </div>
        )}
        {calendarMonth.state === "empty" && (
          <div className="calendar__status calendar__status--warning" role="status">
            <span>{monthLabel} 没有可用日期数据。</span>
            <Button variant="secondary" onClick={calendarMonth.retry}>重试</Button>
          </div>
        )}
        {calendarMonth.state === "stale" && (
          <div className="calendar__status calendar__status--warning" role="alert">
            <span>{monthLabel} 加载失败，暂时保留 {displayMonthLabel} 的上次有效数据。</span>
            <Button variant="secondary" onClick={calendarMonth.retry}>重试</Button>
          </div>
        )}
        {(calendarMonth.state === "ready" || calendarMonth.state === "stale") && (
          <>
            <div className="calendar__weekdays">{["日","一","二","三","四","五","六"].map(day => <span key={day}>{day}</span>)}</div>
            <div className="calendar__grid">
              {leadingBlanks.map((_, index) => <span key={`blank-${index}`} />)}
              {days.map(daySnapshot => {
                const day = Number(daySnapshot.date.slice(-2));
                const isToday = daySnapshot.date === todayKey;
                const isSelected = daySnapshot.date === selectedDate;
                const businessState = calendarBusinessState(daySnapshot);
                const contract = calendarCellContract({
                  businessState,
                  isToday,
                  isSelected,
                  isStale: calendarMonth.state === "stale",
                  isDisabled: calendarMonth.state === "stale",
                });
                return (
                  <button
                    key={daySnapshot.date}
                    aria-current={isToday ? "date" : undefined}
                    aria-pressed={isSelected}
                    aria-label={`${displayMonthNumber}月${day}日，${contract.ariaLabel}`}
                    className={contract.classNames.join(" ")}
                    disabled={
                      calendarMonth.state === "stale"
                      || calendarMonth.coverage?.can_adjust_date === false
                    }
                    onClick={() => setSelectedDate(daySnapshot.date)}
                  >
                    {contract.todayCue && (
                      <span className="calendar-day__today" aria-hidden="true">{contract.todayCue}</span>
                    )}
                    <span className="calendar-day__number">{day}</span>
                    <span className="calendar-day__marker" aria-hidden="true" />
                  </button>
                );
              })}
            </div>
            <div className="calendar__legend">
              <span><i className="legend-dot legend-dot--work" />工作日</span>
              <span><i className="legend-dot legend-dot--rest" />休息日</span>
              <span><i className="legend-dot legend-dot--adjusted" />官方调休</span>
              <span><i className="legend-dot legend-dot--manual" />手动工作</span>
              <span><i className="legend-dot legend-dot--paid" />带薪休息</span>
              <span><i className="legend-dot legend-dot--unpaid" />不带薪休息</span>
              <span><i className="legend-today">今</i>今天</span>
              <span><i className="legend-selected" />已选日期</span>
            </div>
          </>
        )}
      </section>
      {selectedDate !== null
        && calendarMonth.coverage?.can_adjust_date !== false
        && calendarMonth.days.find(day => day.date === selectedDate) && (
        <DateOverrideEditor
          key={selectedDate}
          day={calendarMonth.days.find(day => day.date === selectedDate)!}
          onApplied={message => {
            setOverrideFeedback(message);
            setSelectedDate(null);
            calendarMonth.retry();
          }}
          onClose={() => setSelectedDate(null)}
        />
      )}
    </div>
  );
}

function DateOverrideEditor({
  day,
  onApplied,
  onClose,
}: {
  day: ReturnType<typeof useCalendarMonth>["days"][number];
  onApplied(message: string): void;
  onClose(): void;
}) {
  const [state, dispatch] = useReducer(
    reduceDateOverrideEditor,
    createDateOverrideEditorState(
      day.date,
      (day.override_kind ?? "automatic") as DateOverrideSelection,
    ),
  );
  useEffect(() => {
    recordSemanticEvent(
      "calendar.override.opened",
      `date=${day.date};automatic=${day.automatic_kind};current=${state.persisted}`,
    );
  }, [day.date]);
  const close = () => {
    dispatch({ type: "cancelled" });
    recordSemanticEvent("calendar.override.cancelled", `date=${day.date}`);
    onClose();
  };
  useEffect(() => {
    const handleKeyDown = (event: KeyboardEvent) => {
      if (event.key === "Escape") {
        close();
      }
    };
    window.addEventListener("keydown", handleKeyDown);
    return () => window.removeEventListener("keydown", handleKeyDown);
  }, [day.date]);
  const apply = async () => {
    dispatch({ type: "saving" });
    const kind = state.draft === "automatic" ? null : state.draft;
    try {
      const result = await saveDateOverride(day.date, kind);
      if (result.status === "failed") {
        dispatch({ type: "failed", message: result.message });
        recordSemanticEvent(
          "calendar.override.failed",
          `date=${day.date};kind=${state.draft};reason=${result.message}`,
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
        `date=${day.date};kind=${state.draft}`,
      );
      onApplied(result.message);
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error);
      dispatch({ type: "failed", message: `保存失败：${message}` });
      recordSemanticEvent(
        "calendar.override.failed",
        `date=${day.date};kind=${state.draft};reason=${message}`,
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
          <Button
            onClick={() => void apply()}
            disabled={state.feedback === "saving"}
          >
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

function PageState({ title, detail, action }: { title: string; detail: string; action?: React.ReactNode }) {
  return <div className="page-state" role="status"><span className="state-symbol" aria-hidden="true">¥</span><h1>{title}</h1><p>{detail}</p>{action}</div>;
}

function WizardWindow() {
  const [step, setStep] = useState(1);
  const config = useConfigDraft();
  const workdayPreview = useMonthWorkdayPreview(config.draft);
  const [lunchDurationInput, setLunchDurationInput] = useState("2");
  const lunchDurationEdited = useRef(false);
  const lunchDuration = parseLunchDuration(lunchDurationInput) ?? 0;
  const [confirmClose, setConfirmClose] = useState(false);
  const [firstRun, setFirstRun] = useState(false);
  const firstRunRequest = useRef(0);
  const refreshFirstRun = useCallback(async () => {
    const request = ++firstRunRequest.current;
    try {
      const initialized = await windowService.configurationInitialized();
      if (request === firstRunRequest.current) setFirstRun(!initialized);
    } catch {
      if (request === firstRunRequest.current) setFirstRun(false);
    }
  }, []);
  useEffect(() => {
    void refreshFirstRun();
  }, [refreshFirstRun]);
  useEffect(() => {
    if (!config.loading && !lunchDurationEdited.current) {
      setLunchDurationInput(formatLunchDuration(
        clockDifferenceSeconds(config.draft.lunch_start_time, config.draft.lunch_end_time) / 3600,
      ));
    }
  }, [config.loading, config.draft.lunch_end_time, config.draft.lunch_start_time]);
  useEffect(() => {
    const resetWizard = () => {
      setStep(1);
      setConfirmClose(false);
      lunchDurationEdited.current = false;
      setLunchDurationInput(formatLunchDuration(
        clockDifferenceSeconds(config.draft.lunch_start_time, config.draft.lunch_end_time) / 3600,
      ));
      void refreshFirstRun();
    };
    window.addEventListener("lmm:window-shown", resetWizard);
    return () => window.removeEventListener("lmm:window-shown", resetWizard);
  }, [config.draft.lunch_end_time, config.draft.lunch_start_time, refreshFirstRun]);
  const requestClose = useCallback(() => setConfirmClose(true), []);
  useNativeCloseRequest(requestClose);
  const updateRestMode = (mode: RestMode) => {
    config.update("rest_mode", mode);
    if (mode !== "alternating") config.update("alternating_anchor_week_type", null);
  };
  const updateStart = (value: string) => {
    config.update("work_start_time", value);
    config.update("work_end_time", addHours(value, config.draft.work_hours_per_day + lunchDuration));
  };
  const updateLunchStart = (value: string) => {
    config.update("lunch_start_time", value);
    config.update("lunch_end_time", addHours(value, lunchDuration));
  };
  const updateLunchDuration = (rawValue: string) => {
    const value = rawValue.replace(",", ".");
    if (!/^\d*(?:\.\d{0,2})?$/.test(value)) return;
    setLunchDurationInput(value);
    lunchDurationEdited.current = true;
    const parsed = parseLunchDuration(value);
    if (parsed === null) return;
    config.update("lunch_end_time", addHours(config.draft.lunch_start_time, parsed));
    config.update("work_end_time", addHours(config.draft.work_start_time, config.draft.work_hours_per_day + parsed));
  };
  const commitLunchDuration = () => {
    const value = parseLunchDuration(lunchDurationInput) ?? 0;
    setLunchDurationInput(formatLunchDuration(value));
    config.update("lunch_end_time", addHours(config.draft.lunch_start_time, value));
    config.update("work_end_time", addHours(config.draft.work_start_time, config.draft.work_hours_per_day + value));
  };
  if (config.loading) {
    return (
      <WindowFrame kind="wizard" title="开始配置" className="wizard-window" onClose={requestClose}>
        <PageState title="正在读取本地配置" detail="确认现有设置后即可继续配置。" />
      </WindowFrame>
    );
  }
  if (config.hydrationError) {
    return (
      <WindowFrame kind="wizard" title="开始配置" className="wizard-window" onClose={requestClose}>
        <PageState
          title="暂时无法读取配置"
          detail="当前输入不会被保存。请确认数据目录可用后重试。"
          action={<Button onClick={() => void config.reload(false)}>重试</Button>}
        />
      </WindowFrame>
    );
  }
  return (
    <WindowFrame kind="wizard" title="开始配置" className="wizard-window" onClose={requestClose}>
      <div className="wizard-layout">
        <aside className="wizard-rail">
          <span className="eyebrow">首次配置</span>
          <h2>三分钟完成</h2>
          <p>只询问计算收入真正需要的信息。</p>
          <ol>
            {["收入与休息", "工作与休息", "确认配置"].map((label, index) => (
              <li key={label} className={step === index + 1 ? "is-active" : step > index + 1 ? "is-done" : ""}>
                <span>{step > index + 1 ? "✓" : index + 1}</span>{label}
              </li>
            ))}
          </ol>
          <small>✓ 配置只保存在本机</small>
        </aside>
        <section className="wizard-content">
          <div className="wizard-body">
            {step === 1 && (
              <>
                <span className="eyebrow">第 1 步，共 3 步</span>
                <h1>先告诉我你的月薪</h1>
                <p>用于计算日薪、时薪和今天实时赚到的金额。</p>
                <Field
                  label="月薪"
                  value={config.draft.monthly_salary || ""}
                  suffix="元"
                  inputMode="decimal"
                  error={config.errors.monthly_salary}
                  onChange={event => config.update("monthly_salary", Number(event.target.value.replaceAll(",", "")) || 0)}
                />
                <fieldset className="choice-field">
                  <legend>休息模式</legend>
                  <div className="choice-grid">
                    {[
                      ["double", "双休", "周六、周日休息"],
                      ["single", "单休", "每周休息一天"],
                      ["alternating", "大小周", "由你指定本周"],
                    ].map(([value, title, detail]) => (
                      <button key={value} type="button" className={config.draft.rest_mode === value ? "is-selected" : ""} onClick={() => updateRestMode(value as RestMode)}>
                        <strong>{title}</strong><span>{detail}</span>
                      </button>
                    ))}
                  </div>
                </fieldset>
                {config.draft.rest_mode === "alternating" && (
                  <fieldset className="choice-field choice-field--inline">
                    <legend>本周是哪一周？</legend>
                    <SegmentedControl
                      value={config.draft.alternating_anchor_week_type ?? ""}
                      onChange={value => {
                        config.update("alternating_anchor_week_type", value as WeekType);
                        config.update(
                          "alternating_anchor_date",
                          formatLocalDate(systemTime.now()),
                        );
                      }}
                      options={[{ value: "big", label: "大周" }, { value: "small", label: "小周" }]}
                    />
                    {!config.draft.alternating_anchor_week_type && <small className="field-hint">请选择后再继续，我们不会替你决定。</small>}
                  </fieldset>
                )}
                {workdayPreview.state === "ready" && (
                  <Feedback tone="success">预计本月工作日 {workdayPreview.workdays} 天</Feedback>
                )}
                {workdayPreview.state === "loading" && (
                  <Feedback tone="success">正在计算本月工作日…</Feedback>
                )}
                {workdayPreview.state === "needs_week_type" && (
                  <Feedback tone="success">选择本周类型后显示预计工作日</Feedback>
                )}
                {workdayPreview.state === "error" && (
                  <Feedback tone="error">暂时无法计算工作日，请检查当前配置</Feedback>
                )}
              </>
            )}
            {step === 2 && (
              <>
                <span className="eyebrow">第 2 步，共 3 步</span>
                <h1>你的工作时间</h1>
                <p>默认每天工作 8 小时，休息时间不计入有效工时。</p>
                <div className="form-grid">
                  <Field label="上班时间" value={config.draft.work_start_time} type="time" onChange={event => updateStart(event.target.value)} />
                  <Field label="休息开始" value={config.draft.lunch_start_time} type="time" onChange={event => updateLunchStart(event.target.value)} />
                  <Field
                    label="休息时长"
                    value={lunchDurationInput}
                    suffix="小时"
                    inputMode="decimal"
                    pattern="[0-9]*[.,]?[0-9]{0,2}"
                    onChange={event => updateLunchDuration(event.target.value)}
                    onBlur={commitLunchDuration}
                  />
                  <Field label="推算下班时间" value={config.draft.work_end_time} type="time" readOnly />
                </div>
                <Feedback tone="success">
                  有效工时 {config.draft.work_hours_per_day} 小时 · {config.draft.lunch_start_time === config.draft.lunch_end_time
                    ? "无休息时段"
                    : `休息 ${config.draft.lunch_start_time}–${config.draft.lunch_end_time}`}
                </Feedback>
              </>
            )}
            {step === 3 && (
              <>
                <span className="eyebrow">第 3 步，共 3 步</span>
                <h1>确认配置</h1>
                <p>以后可以在设置中修改，已有收入记录不会被重算。</p>
                <dl className="summary-list">
                  <div><dt>月薪</dt><dd>{formatMoney(config.draft.monthly_salary)}</dd></div>
                  <div><dt>休息模式</dt><dd>{config.draft.rest_mode === "single" ? "单休" : config.draft.rest_mode === "alternating" ? `大小周 · 本周${config.draft.alternating_anchor_week_type === "small" ? "小周" : "大周"}` : "双休"}</dd></div>
                  <div><dt>工作时间</dt><dd>{config.draft.work_start_time}–{config.draft.work_end_time}</dd></div>
                  <div><dt>休息</dt><dd>{config.draft.lunch_start_time === config.draft.lunch_end_time ? "无休息时段" : `${config.draft.lunch_start_time}–${config.draft.lunch_end_time}`}</dd></div>
                </dl>
                {config.feedback === "failed" && <Feedback tone="error">{config.message}</Feedback>}
              </>
            )}
          </div>
          <footer className="actionbar">
            <Button variant="secondary" onClick={requestClose}>取消</Button>
            <div>
              <Button variant="secondary" disabled={step === 1} onClick={() => setStep(value => Math.max(1, value - 1))}>上一步</Button>
              <Button
                disabled={
                  step === 1 &&
                  (Boolean(config.errors.monthly_salary) ||
                    (config.draft.rest_mode === "alternating" && !config.draft.alternating_anchor_week_type))
                }
                onClick={async () => {
                  if (step < 3) setStep(value => value + 1);
                  else if (await config.save()) {
                    firstRunRequest.current += 1;
                    setFirstRun(false);
                    await showWindow("mini");
                    await hideCurrentWindow();
                  }
                }}
              >
                {step === 3 ? "完成" : "下一步"}
              </Button>
            </div>
          </footer>
        </section>
      </div>
      {confirmClose && (
        <ConfirmDialog
          title={firstRun ? "退出首次配置？" : "放弃本次配置？"}
          detail={firstRun ? "完成配置后才能开始使用。你可以继续配置，或退出应用。" : "尚未保存的输入会被丢弃。"}
          confirmLabel={firstRun ? "退出应用" : "放弃配置"}
          onCancel={() => setConfirmClose(false)}
          onConfirm={() => {
            setConfirmClose(false);
            config.cancel();
            if (firstRun) void windowService.exit();
            else void hideCurrentWindow();
          }}
        />
      )}
    </WindowFrame>
  );
}

function SettingsWindow() {
  const [section, setSection] = useState("income");
  const config = useConfigDraft({ monthly_salary: 10_000 });
  const [confirmClose, setConfirmClose] = useState(false);
  const [confirmReset, setConfirmReset] = useState(false);
  const requestClose = useCallback(
    () => config.dirty ? setConfirmClose(true) : void hideCurrentWindow(),
    [config.dirty],
  );
  useNativeCloseRequest(requestClose);
  const saveAndFocus = async () => {
    const saved = await config.save();
    if (!saved) {
      requestAnimationFrame(() => {
        document.querySelector<HTMLElement>("[aria-invalid='true']")?.focus();
      });
    }
  };
  const sections = [
    ["income", "收入与作息"],
    ["calendar", "日历"],
    ["appearance", "外观"],
    ["window", "窗口与启动"],
    ["support", "数据与支持"],
  ];
  if (config.loading) {
    return (
      <WindowFrame kind="settings" title="设置" className="settings-window" onClose={requestClose}>
        <PageState title="正在读取本地配置" detail="设置将在读取完成后开放编辑。" />
      </WindowFrame>
    );
  }
  if (config.hydrationError) {
    return (
      <WindowFrame kind="settings" title="设置" className="settings-window" onClose={requestClose}>
        <PageState
          title="暂时无法读取配置"
          detail="为保护现有配置，读取失败期间不会保存默认值。"
          action={<Button onClick={() => void config.reload(false)}>重试</Button>}
        />
      </WindowFrame>
    );
  }
  return (
    <WindowFrame kind="settings" title="设置" className="settings-window" onClose={requestClose}>
      <div className="settings-layout">
        <nav className="settings-nav" aria-label="设置分类">
          <span className="eyebrow">偏好设置</span>
          {sections.map(([value, label]) => <button key={value} className={section === value ? "is-active" : ""} onClick={() => setSection(value)}>{label}</button>)}
        </nav>
        <section className="settings-content">
          <div className="settings-scroll">
            <div className="page-heading page-heading--compact">
              <div><h1>{sections.find(([value]) => value === section)?.[1]}</h1><p>{section === "income" ? "统一管理工资、休息模式与工作时间。" : "调整当前设备上的本地偏好。"}</p></div>
              {config.feedback === "saved" && <span className="status-pill status-pill--success">已保存</span>}
            </div>
            {section === "income" && <IncomeSettings config={config} />}
            {section === "calendar" && <CalendarSettings />}
            {section === "appearance" && <AppearanceSettings config={config} />}
            {section === "window" && <WindowSettings config={config} />}
            {section === "support" && <SupportSettings />}
          </div>
          <footer className="actionbar">
            <span className={`actionbar__status ${config.feedback === "failed" ? "is-error" : ""}`}>
              {config.message || (config.dirty ? "有尚未保存的更改" : "没有未保存的更改")}
            </span>
            <div><Button variant="secondary" onClick={() => setConfirmReset(true)}>恢复默认</Button><Button onClick={saveAndFocus}>保存</Button></div>
          </footer>
        </section>
      </div>
      {confirmClose && (
        <ConfirmDialog
          title="放弃未保存的更改？"
          detail="当前输入尚未保存，关闭后将恢复原配置。"
          confirmLabel="放弃更改"
          onCancel={() => setConfirmClose(false)}
          onConfirm={() => {
            setConfirmClose(false);
            config.cancel();
            void hideCurrentWindow();
          }}
        />
      )}
      {confirmReset && (
        <ConfirmDialog
          title="恢复默认设置？"
          detail="工资、作息和窗口偏好将先恢复为默认草稿；点击保存后才会生效。"
          confirmLabel="恢复默认"
          tone="warning"
          onCancel={() => setConfirmReset(false)}
          onConfirm={() => {
            config.reset();
            setConfirmReset(false);
          }}
        />
      )}
    </WindowFrame>
  );
}

function IncomeSettings({ config }: { config: ReturnType<typeof useConfigDraft> }) {
  return (
    <div className="settings-groups">
      <section><h2>基础收入</h2><Field label="月薪" value={config.draft.monthly_salary || ""} suffix="元" error={config.errors.monthly_salary} onChange={event => config.update("monthly_salary", Number(event.target.value.replaceAll(",", "")) || 0)} /><label className="setting-row"><span><strong>休息模式</strong><small>决定每月工作日口径</small></span><select value={config.draft.rest_mode} onChange={event => config.update("rest_mode", event.target.value as RestMode)}><option value="double">双休</option><option value="single">单休</option><option value="alternating">大小周</option></select></label>{config.draft.rest_mode === "alternating" && <label className="setting-row"><span><strong>本周类型</strong><small>必须由你明确选择</small></span><select value={config.draft.alternating_anchor_week_type ?? ""} onChange={event => config.update("alternating_anchor_week_type", (event.target.value || null) as WeekType)}><option value="">请选择</option><option value="big">大周</option><option value="small">小周</option></select></label>}</section>
      <section><h2>工作与休息</h2><div className="form-grid"><Field label="上班时间" value={config.draft.work_start_time} type="time" onChange={event => config.update("work_start_time", event.target.value)} /><Field label="下班时间" value={config.draft.work_end_time} type="time" onChange={event => config.update("work_end_time", event.target.value)} /><Field label="休息开始" value={config.draft.lunch_start_time} type="time" onChange={event => config.update("lunch_start_time", event.target.value)} /><Field label="休息结束" value={config.draft.lunch_end_time} type="time" onChange={event => config.update("lunch_end_time", event.target.value)} /></div></section>
    </div>
  );
}

function AppearanceSettings({ config }: { config: ReturnType<typeof useConfigDraft> }) {
  return (
    <div className="settings-groups">
      <section>
        <h2>界面主题</h2>
        <p className="section-description">选择只保存在当前设备上的浅色或深色外观。更改会立即预览，保存后对所有窗口生效。</p>
        <div className="theme-options" role="radiogroup" aria-label="界面主题">
          <button
            type="button"
            role="radio"
            aria-checked={config.draft.theme_mode === "light"}
            className={config.draft.theme_mode === "light" ? "is-selected" : ""}
            onClick={() => config.update("theme_mode", "light")}
          >
            <AppIcon name="sun" size={22} />
            <span><strong>浅色模式</strong><small>默认，适合明亮桌面环境</small></span>
          </button>
          <button
            type="button"
            role="radio"
            aria-checked={config.draft.theme_mode === "dark"}
            className={config.draft.theme_mode === "dark" ? "is-selected" : ""}
            onClick={() => config.update("theme_mode", "dark")}
          >
            <AppIcon name="moon" size={22} />
            <span><strong>深色模式</strong><small>降低暗光环境下的视觉刺激</small></span>
          </button>
        </div>
      </section>
    </div>
  );
}

function CalendarSettings() {
  return (
    <div className="settings-groups">
      <section>
        <h2>日历口径</h2>
        <div className="setting-row">
          <span>
            <strong>离线节假日数据</strong>
            <small>用于识别法定节假日和调休工作日</small>
          </span>
          <strong>中国大陆 2025-2026</strong>
        </div>
        <div className="setting-row">
          <span>
            <strong>日期判断优先级</strong>
            <small>单日调整请前往收入日历</small>
          </span>
          <strong>手动调整 &gt; 官方日历 &gt; 休息模式</strong>
        </div>
      </section>
    </div>
  );
}

function WindowSettings({ config }: { config: ReturnType<typeof useConfigDraft> }) {
  const setEdgeAutoHide = (value: boolean) => {
    config.update("mini_edge_auto_hide", value);
    if (!value) config.update("mini_edge_dock", "none");
  };
  return <div className="settings-groups"><section><h2>迷你收入视图</h2><label className="setting-row"><span><strong>启动时显示</strong><small>随应用启动显示迷你收入视图</small></span><Switch checked={config.draft.mini_window_visible} onChange={value => config.update("mini_window_visible", value)} label="启动时显示" /></label><label className="setting-row"><span><strong>始终置顶</strong><small>保持在其他普通窗口上方</small></span><Switch checked={config.draft.mini_window_always_on_top} onChange={value => config.update("mini_window_always_on_top", value)} label="始终置顶" /></label><label className="setting-row"><span><strong>贴边自动隐藏</strong><small>靠近屏幕左右边缘后收起，悬停时展开</small></span><Switch checked={config.draft.mini_edge_auto_hide} onChange={setEdgeAutoHide} label="贴边自动隐藏" /></label></section><section><h2>系统</h2><label className="setting-row"><span><strong>开机启动</strong><small>登录 Windows 后启动应用</small></span><Switch checked={config.draft.auto_start} onChange={value => config.update("auto_start", value)} label="开机启动" /></label></section></div>;
}

function ConfirmDialog({ title, detail, confirmLabel, tone = "danger", onCancel, onConfirm }: { title: string; detail: string; confirmLabel: string; tone?: "danger" | "warning"; onCancel(): void; onConfirm(): void }) {
  return <div className="modal-backdrop" role="presentation"><section className="confirm-dialog" role="alertdialog" aria-modal="true" aria-labelledby="confirm-title"><span className="state-symbol" aria-hidden="true">!</span><h2 id="confirm-title">{title}</h2><p>{detail}</p><div><Button variant="secondary" autoFocus onClick={onCancel}>继续编辑</Button><Button variant={tone === "danger" ? "danger" : "primary"} onClick={onConfirm}>{confirmLabel}</Button></div></section></div>;
}

function SupportSettings() {
  const [feedback, setFeedback] = useState<{ tone: "success" | "warning" | "error"; message: string } | null>(null);
  const [checking, setChecking] = useState(false);
  const [platform, setPlatform] = useState<PlatformCapabilities | null>(null);

  useEffect(() => {
    void supportService.capabilities()
      .then(setPlatform)
      .catch(() => setPlatform(null));
  }, []);

  const record = async (event: string, detail: string) => {
    try {
      await supportService.record(event, detail);
    } catch {
      // Browser preview has no native logger.
    }
  };

  const openData = async () => {
    try {
      await supportService.openDataDirectory();
      setFeedback({ tone: "success", message: "数据目录已打开。" });
    } catch (error) {
      setFeedback({ tone: "error", message: `无法打开数据目录：${String(error)}` });
    }
  };

  const copyDiagnostics = async () => {
    try {
      const summary = await supportService.diagnosticSummary();
      await navigator.clipboard.writeText(summary);
      await record("support.diagnostic_copied", "result=success");
      setFeedback({ tone: "success", message: "诊断摘要已复制，内容不包含用户名和本机路径。" });
    } catch (error) {
      await record("support.diagnostic_copy_failed", `reason=${String(error)}`);
      setFeedback({ tone: "error", message: `复制失败：${String(error)}` });
    }
  };

  const checkUpdates = async () => {
    setChecking(true);
    try {
      const response = await fetch("https://api.github.com/repos/NzyZzz1998/LetsMakeMoney/releases/latest", {
        headers: { Accept: "application/vnd.github+json" },
      });
      if (!response.ok) throw new Error(`HTTP ${response.status}`);
      const body = await response.text();
      const result = await supportService.evaluateUpdate("1.0.5", body, null);
      await record("update.checked", `status=${result.status}`);
      setFeedback({ tone: result.status === "unavailable" ? "warning" : "success", message: result.message });
    } catch (error) {
      const result = await supportService
        .evaluateUpdate("1.0.5", null, String(error))
        .catch(() => ({ status: "unavailable" as const, message: `暂时无法检查更新：${String(error)}` }));
      await record("update.check_failed", `reason=${String(error)}`);
      setFeedback({ tone: "warning", message: `${result.message} 当前版本可继续正常使用。` });
    } finally {
      setChecking(false);
    }
  };

  return (
    <div className="settings-groups">
      <section>
        <h2>数据与诊断</h2>
        <div className="button-list">
          <Button variant="secondary" onClick={openData}>打开数据目录</Button>
          <Button variant="secondary" onClick={copyDiagnostics}>复制诊断摘要</Button>
          <Button variant="secondary" disabled={checking} onClick={checkUpdates}>{checking ? "正在检查…" : "检查更新"}</Button>
        </div>
        {feedback && <Feedback tone={feedback.tone}>{feedback.message}</Feedback>}
      </section>
      <section>
        <h2>关于</h2>
        <dl className="summary-list">
          <div><dt>版本</dt><dd>1.0.5</dd></div>
          <div><dt>数据</dt><dd>仅保存在本机</dd></div>
          <div><dt>运行环境</dt><dd>Windows · WebView2</dd></div>
          {platform && <div><dt>原生能力</dt><dd>{platform.tray_available && platform.explorer_available ? "可用" : "部分不可用，主功能不受影响"}</dd></div>}
        </dl>
      </section>
    </div>
  );
}

export function App() {
  const kind = useMemo(resolveWindowKind, []);

  useEffect(() => {
    document.documentElement.dataset.window = kind;
    document.title = WINDOW_LABELS[kind];
  }, [kind]);

  if (kind === "workbench") return <WorkbenchWindow />;
  if (kind === "settings") return <SettingsWindow />;
  if (kind === "wizard") return <WizardWindow />;
  return <MiniWindow onOpenWindow={label => { void showWindow(label); }} />;
}
