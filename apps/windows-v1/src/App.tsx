import { useEffect, useMemo, useRef, useState } from "react";
import { invoke } from "@tauri-apps/api/core";
import {
  Button,
  Field,
  Feedback,
  IconButton,
  ProgressBar,
  SegmentedControl,
  Switch,
} from "./components";
import {
  formatDuration,
  formatMoney,
  dashboardErrorTitle,
  useCalendarOverrides,
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

type WindowKind = "mini" | "workbench" | "settings" | "wizard";

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
    await invoke("show_app_window", { label });
  } catch {
    window.location.search = `?window=${label}`;
  }
}

async function hideCurrentWindow() {
  try {
    await invoke("hide_app_window", { label: resolveWindowKind() });
  } catch {
    // Browser preview intentionally has no native window to hide.
  }
}

const DRAG_THRESHOLD_PX = 5;
const INTERACTIVE_DRAG_SELECTOR = "button, input, select, textarea, a, [role='switch'], [data-window-drag='false']";

type WindowDragOrigin = {
  x: number;
  y: number;
  scale_factor: number;
};

type WindowDragPointer = {
  id: number;
  startX: number;
  startY: number;
  currentX: number;
  currentY: number;
  origin: WindowDragOrigin | null;
  dragging: boolean;
  frame: number | null;
  captureTarget: HTMLElement;
};

function useWindowDrag({ allowInteractiveStart = false }: { allowInteractiveStart?: boolean } = {}) {
  const pointer = useRef<WindowDragPointer | null>(null);
  const dragged = useRef(false);

  const moveWindow = (current: NonNullable<typeof pointer.current>) => {
    if (!current.origin) return;
    const scale = current.origin.scale_factor;
    void invoke("move_app_window", {
      label: resolveWindowKind(),
      x: Math.round(current.origin.x + (current.currentX - current.startX) * scale),
      y: Math.round(current.origin.y + (current.currentY - current.startY) * scale),
    });
  };

  const scheduleMove = (current: NonNullable<typeof pointer.current>) => {
    if (current.frame !== null) return;
    current.frame = window.requestAnimationFrame(() => {
      current.frame = null;
      if (pointer.current === current && current.dragging) moveWindow(current);
    });
  };

  const cancel = (event?: React.PointerEvent<HTMLElement>, commit = false) => {
    const current = pointer.current;
    if (!current || (event && current.id !== event.pointerId)) return;
    if (event) {
      current.currentX = event.screenX;
      current.currentY = event.screenY;
    }
    if (commit && current.dragging) moveWindow(current);
    if (current.frame !== null) window.cancelAnimationFrame(current.frame);
    if (current.captureTarget.hasPointerCapture(current.id)) {
      current.captureTarget.releasePointerCapture(current.id);
    }
    pointer.current = null;
  };

  const handlers = {
    onPointerDownCapture(event: React.PointerEvent<HTMLElement>) {
      if (event.button !== 0 || !event.isPrimary) return;
      const target = event.target as HTMLElement;
      if (!allowInteractiveStart && target.closest(INTERACTIVE_DRAG_SELECTOR)) return;
      dragged.current = false;
      const captureTarget = event.currentTarget;
      const current: WindowDragPointer = {
        id: event.pointerId,
        startX: event.screenX,
        startY: event.screenY,
        currentX: event.screenX,
        currentY: event.screenY,
        origin: null,
        dragging: false,
        frame: null,
        captureTarget,
      };
      pointer.current = current;
      void invoke<WindowDragOrigin>("window_drag_origin", { label: resolveWindowKind() })
        .then(origin => {
          if (pointer.current !== current) return;
          current.origin = origin;
          if (current.dragging) scheduleMove(current);
        })
        .catch(() => cancel());
    },
    onPointerMoveCapture(event: React.PointerEvent<HTMLElement>) {
      const current = pointer.current;
      if (!current || current.id !== event.pointerId) return;
      if ((event.buttons & 1) === 0) {
        cancel(event);
        return;
      }
      current.currentX = event.screenX;
      current.currentY = event.screenY;
      const distance = Math.hypot(current.currentX - current.startX, current.currentY - current.startY);
      if (distance < DRAG_THRESHOLD_PX) return;
      if (!current.dragging) {
        current.dragging = true;
        dragged.current = true;
        current.captureTarget.setPointerCapture(current.id);
      }
      event.preventDefault();
      if (current.origin) scheduleMove(current);
    },
    onPointerUpCapture(event: React.PointerEvent<HTMLElement>) {
      cancel(event, true);
    },
    onPointerCancelCapture(event: React.PointerEvent<HTMLElement>) {
      cancel(event);
    },
  };

  return {
    handlers,
    consumeDraggedClick() {
      if (!dragged.current) return false;
      dragged.current = false;
      return true;
    },
  };
}

function WindowFrame({
  kind,
  title,
  children,
  className = "",
  onClose = hideCurrentWindow,
}: {
  kind: WindowKind;
  title: string;
  children: React.ReactNode;
  className?: string;
  onClose?: () => void;
}) {
  const drag = useWindowDrag();

  return (
    <main
      className={`window-frame ${className}`}
      data-window={kind}
      {...drag.handlers}
    >
      <header className="titlebar">
        <div className="titlebar__identity">
          <span className="coin-mark" aria-hidden="true">¥</span>
          <strong>{title}</strong>
        </div>
        <IconButton label={`关闭${title}`} icon="×" data-window-drag="false" onClick={onClose} />
      </header>
      {children}
    </main>
  );
}

function MiniWindow() {
  const { snapshot, refresh } = useDashboard();
  const drag = useWindowDrag({ allowInteractiveStart: true });
  if (snapshot.state === "loading") {
    return <main className="mini-window mini-window--state" data-window="mini" {...drag.handlers}><span className="spinner" /><strong>正在计算今天的收入</strong></main>;
  }
  if (snapshot.state === "error") {
    return (
      <main className="mini-window mini-window--state mini-window--error" data-window="mini" {...drag.handlers}>
        <div className="mini-window__error-copy">
          <strong>{dashboardErrorTitle(snapshot.errorCode)}</strong>
          <span>{snapshot.message}</span>
        </div>
        <div className="mini-window__error-actions">
          <button type="button" data-window-drag="false" onClick={() => showWindow("settings")}>检查设置</button>
          <button type="button" data-window-drag="false" onClick={refresh}>重试</button>
        </div>
      </main>
    );
  }
  const isRestDay = snapshot.phase === "rest_day";
  return (
    <main className={`mini-window ${isRestDay ? "mini-window--rest" : ""}`} data-window="mini" {...drag.handlers}>
      <div
        className="mini-window__drag"
        aria-label="拖动迷你收入视图"
      >
        <span aria-hidden="true" />
      </div>
      <button
        className="mini-window__primary"
        type="button"
        onClick={() => {
          if (!drag.consumeDraggedClick()) void showWindow("workbench");
        }}
        aria-label="打开今日工作台"
      >
        <span className="mini-window__status">
          <span className="status-dot" />
          {snapshot.workState}
        </span>
        {isRestDay ? (
          <>
            <span className="mini-window__label">今天没有工作安排</span>
            <strong className="mini-window__amount mini-window__amount--rest">安心休息</strong>
            <span className="mini-window__rest-line" aria-hidden="true" />
            <span className="mini-window__meta">
              {snapshot.nextWorkDate ? `下一个工作日 ${formatShortDate(snapshot.nextWorkDate)} ${snapshot.workStartTime}` : "下一个工作日尚未确定"}
            </span>
          </>
        ) : (
          <>
            <span className="mini-window__label">今日已赚</span>
            <strong className="mini-window__amount">{formatMoney(snapshot.amount)}</strong>
            <ProgressBar value={snapshot.progress} label="工作进度" compact />
            <span className="mini-window__meta">剩余有效工时 {formatDuration(snapshot.remainingSeconds)}</span>
          </>
        )}
      </button>
    </main>
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
            <span aria-hidden="true">¥</span>今日
          </button>
          <button className={tab === "calendar" ? "is-active" : ""} onClick={() => setTab("calendar")}>
            <span className="nav-calendar-mark" aria-hidden="true">日</span>日历
          </button>
          <button onClick={() => showWindow("settings")}>
            <span aria-hidden="true">⚙</span>设置
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
  const hasLunch = snapshot.lunchStartTime !== snapshot.lunchEndTime;
  const lunchCompleted = hasLunch && (snapshot.phase === "after_work"
    || (snapshot.phase === "working" && snapshot.completedSeconds > clockDifferenceSeconds(snapshot.workStartTime, snapshot.lunchStartTime)));
  return (
    <div className="page-stack" aria-label="今日">
      <div className="page-heading">
        <div>
          <span className="eyebrow">{formatFullDate(snapshot.ownerDate)} · 工作日</span>
          <h1>今天的收入进度</h1>
        </div>
        <span className="status-pill status-pill--success">{snapshot.workState}</span>
      </div>
      <section className="amount-hero">
        <span>今日已赚</span>
        <strong className="long-number">{formatMoney(snapshot.amount)}</strong>
        <p>日薪 {formatMoney(snapshot.dailySalary)} · 时薪 {formatMoney(snapshot.hourlySalary)}</p>
        <ProgressBar value={snapshot.progress} label="工作进度" />
      </section>
      <div className="content-grid">
        <section className="surface schedule">
          <div className="section-heading">
            <div><span className="eyebrow">时间线</span><h2>今日安排</h2></div>
            <Button variant="ghost" onClick={() => showWindow("settings")}>调整今天</Button>
          </div>
          <ol>
            <li className={snapshot.completedSeconds > 0 || snapshot.phase === "after_work" ? "is-done" : snapshot.phase === "before_work" ? "is-current" : ""}>
              <time>{snapshot.workStartTime}</time>
              <strong>开始工作</strong>
              <span>{snapshot.completedSeconds > 0 ? `已完成 ${formatReadableDuration(snapshot.completedSeconds)}` : `将在 ${snapshot.workStartTime} 开始`}</span>
            </li>
            {hasLunch && (
              <li className={snapshot.phase === "lunch" ? "is-current" : lunchCompleted ? "is-done" : ""}>
                <time>{snapshot.lunchStartTime}</time>
                <strong>午休</strong>
                <span>{snapshot.lunchStartTime}–{snapshot.lunchEndTime}</span>
              </li>
            )}
            <li className={snapshot.phase === "after_work" ? "is-done" : ""}>
              <time>{snapshot.workEndTime}</time>
              <strong>结束工作</strong>
              <span>{snapshot.phase === "after_work" ? "今日工作已完成" : `预计 ${snapshot.workEndTime} 下班`}</span>
            </li>
          </ol>
        </section>
        <section className="surface stats">
          <div><span>本月累计</span><strong>{formatMoney(snapshot.monthTotal)}</strong></div>
          <div><span>本月工作日</span><strong>{snapshot.workdays} 天</strong></div>
          <div><span>剩余有效工时</span><strong>{formatDuration(snapshot.remainingSeconds)}</strong></div>
        </section>
      </div>
    </div>
  );
}

function CalendarView({ snapshot }: { snapshot: ReturnType<typeof useDashboard>["snapshot"] }) {
  const owner = parseLocalDate(snapshot.ownerDate);
  const [visibleMonth, setVisibleMonth] = useState(() => `${owner.getFullYear()}-${String(owner.getMonth() + 1).padStart(2, "0")}`);
  const calendarMonth = useCalendarMonth(visibleMonth, snapshot.calendarDays);
  const [visibleYear, visibleMonthNumber] = visibleMonth.split("-").map(Number);
  const days = calendarMonth.days;
  const monthLabel = `${visibleYear} 年 ${visibleMonthNumber} 月`;
  const leadingBlanks = Array.from({ length: new Date(visibleYear, visibleMonthNumber - 1, 1).getDay() });
  const { overrides, setOverride } = useCalendarOverrides();
  const [selectedDate, setSelectedDate] = useState<string | null>(null);
  const moveMonth = (offset: number) => {
    const next = new Date(visibleYear, visibleMonthNumber - 1 + offset, 1);
    setVisibleMonth(`${next.getFullYear()}-${String(next.getMonth() + 1).padStart(2, "0")}`);
    setSelectedDate(null);
  };
  return (
    <div className="page-stack" aria-label="日历">
      <div className="page-heading">
        <div><span className="eyebrow">{monthLabel}</span><h1>收入日历</h1></div>
        <Button variant="secondary" onClick={() => showWindow("settings")}>调整日期</Button>
      </div>
      <section className="surface calendar">
        <div className="calendar__toolbar" aria-label="切换月份">
          <IconButton label="查看上个月" icon="‹" onClick={() => moveMonth(-1)} />
          <strong>{monthLabel}</strong>
          <IconButton label="查看下个月" icon="›" onClick={() => moveMonth(1)} />
        </div>
        <div className="calendar__weekdays">{["日","一","二","三","四","五","六"].map(day => <span key={day}>{day}</span>)}</div>
        <div className="calendar__grid">
          {leadingBlanks.map((_, index) => <span key={`blank-${index}`} />)}
          {days.map(daySnapshot => {
            const day = Number(daySnapshot.date.slice(-2));
            const override = overrides[daySnapshot.date];
            const className = [
              daySnapshot.date === snapshot.ownerDate ? "is-today" : "",
              override === "work" ? "is-manual-work" : "",
              override === "rest" || (!override && daySnapshot.kind === "rest_day") ? "is-rest" : "",
              daySnapshot.source === "manual_override" ? "is-manual" : "",
            ].filter(Boolean).join(" ");
            return (
              <button
                key={daySnapshot.date}
                aria-current={daySnapshot.date === snapshot.ownerDate ? "date" : undefined}
                aria-label={`${visibleMonthNumber}月${day}日，${daySnapshot.kind === "rest_day" ? "休息日" : "工作日"}${daySnapshot.date === snapshot.ownerDate ? "，今天" : ""}`}
                className={className}
                onClick={() => setSelectedDate(daySnapshot.date)}
              >
                {day}
              </button>
            );
          })}
        </div>
        <div className="calendar__legend">
          <span><i className="legend-dot legend-dot--work" />工作日</span>
          <span><i className="legend-dot legend-dot--rest" />休息日</span>
          <span><i className="legend-ring" />今天</span>
          <span><i className="legend-dot legend-dot--manual" />手动调整</span>
        </div>
      </section>
      {selectedDate !== null && (
        <section className="surface date-editor" role="dialog" aria-label={`调整 ${visibleMonthNumber} 月 ${Number(selectedDate.slice(-2))} 日`}>
          <div><span className="eyebrow">手动调整</span><h2>{visibleMonthNumber} 月 {Number(selectedDate.slice(-2))} 日</h2><p>本次调整只影响这一天。</p></div>
          <SegmentedControl
            value={overrides[selectedDate] ?? "default"}
            onChange={value => setOverride(selectedDate, value as "work" | "rest" | "default")}
            options={[{ value: "default", label: "跟随规则" }, { value: "work", label: "工作日" }, { value: "rest", label: "休息日" }]}
          />
          <IconButton label="关闭日期调整" icon="×" onClick={() => setSelectedDate(null)} />
        </section>
      )}
    </div>
  );
}

function parseLocalDate(value: string) {
  const [year, month, day] = value.split("-").map(Number);
  return new Date(year, month - 1, day);
}

function formatFullDate(value: string) {
  return new Intl.DateTimeFormat("zh-CN", { month: "long", day: "numeric", weekday: "long" }).format(parseLocalDate(value));
}

function formatShortDate(value: string) {
  return new Intl.DateTimeFormat("zh-CN", { month: "numeric", day: "numeric" }).format(parseLocalDate(value));
}

function formatReadableDuration(seconds: number) {
  const hours = Math.floor(seconds / 3600);
  const minutes = Math.floor((seconds % 3600) / 60);
  if (hours && minutes) return `${hours} 小时 ${minutes} 分钟`;
  if (hours) return `${hours} 小时`;
  return `${minutes} 分钟`;
}

function clockDifferenceSeconds(start: string, end: string) {
  const [startHour, startMinute] = start.split(":").map(Number);
  const [endHour, endMinute] = end.split(":").map(Number);
  const startMinutes = startHour * 60 + startMinute;
  const endMinutes = endHour * 60 + endMinute;
  return (((endMinutes - startMinutes) % 1440) + 1440) % 1440 * 60;
}

function parseLunchDuration(value: string) {
  if (!value.trim()) return null;
  const parsed = Number(value.replace(",", "."));
  return Number.isFinite(parsed) && parsed >= 0 ? parsed : null;
}

function formatLunchDuration(value: number) {
  return String(Math.round(value * 100) / 100);
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
  useEffect(() => {
    invoke<boolean>("configuration_initialized")
      .then(value => setFirstRun(!value))
      .catch(() => setFirstRun(false));
  }, []);
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
    };
    window.addEventListener("lmm:window-shown", resetWizard);
    return () => window.removeEventListener("lmm:window-shown", resetWizard);
  }, [config.draft.lunch_end_time, config.draft.lunch_start_time]);
  const requestClose = () => setConfirmClose(true);
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
  return (
    <WindowFrame kind="wizard" title="开始配置" className="wizard-window" onClose={requestClose}>
      <div className="wizard-layout">
        <aside className="wizard-rail">
          <span className="eyebrow">首次配置</span>
          <h2>三分钟完成</h2>
          <p>只询问计算收入真正需要的信息。</p>
          <ol>
            {["收入与休息", "工作与午休", "确认配置"].map((label, index) => (
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
                        config.update("alternating_anchor_date", new Date().toISOString().slice(0, 10));
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
                <p>默认每天工作 8 小时，午休不计入有效工时。</p>
                <div className="form-grid">
                  <Field label="上班时间" value={config.draft.work_start_time} type="time" onChange={event => updateStart(event.target.value)} />
                  <Field label="午休开始" value={config.draft.lunch_start_time} type="time" onChange={event => updateLunchStart(event.target.value)} />
                  <Field
                    label="午休时长"
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
                    ? "无午休"
                    : `午休 ${config.draft.lunch_start_time}–${config.draft.lunch_end_time}`}
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
                  <div><dt>午休</dt><dd>{config.draft.lunch_start_time === config.draft.lunch_end_time ? "无午休" : `${config.draft.lunch_start_time}–${config.draft.lunch_end_time}`}</dd></div>
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
            config.cancel();
            if (firstRun) void invoke("exit_application");
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
  const requestClose = () => config.dirty ? setConfirmClose(true) : void hideCurrentWindow();
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
    ["window", "窗口与启动"],
    ["support", "数据与支持"],
  ];
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
      <section><h2>工作与午休</h2><div className="form-grid"><Field label="上班时间" value={config.draft.work_start_time} type="time" onChange={event => config.update("work_start_time", event.target.value)} /><Field label="下班时间" value={config.draft.work_end_time} type="time" onChange={event => config.update("work_end_time", event.target.value)} /><Field label="午休开始" value={config.draft.lunch_start_time} type="time" onChange={event => config.update("lunch_start_time", event.target.value)} /><Field label="午休结束" value={config.draft.lunch_end_time} type="time" onChange={event => config.update("lunch_end_time", event.target.value)} /></div></section>
    </div>
  );
}

function CalendarSettings() {
  return <div className="settings-groups"><section><h2>日历口径</h2><label className="setting-row"><span><strong>节假日数据</strong><small>用于识别法定节假日和调休工作日</small></span><select><option>中国大陆 2026</option></select></label><label className="setting-row"><span><strong>允许手动调整</strong><small>单独修改某一天，不改变长期规则</small></span><Switch defaultChecked label="允许手动调整" /></label></section></div>;
}

function WindowSettings({ config }: { config: ReturnType<typeof useConfigDraft> }) {
  return <div className="settings-groups"><section><h2>迷你收入视图</h2><label className="setting-row"><span><strong>启动时显示</strong><small>随应用启动显示迷你收入视图</small></span><Switch checked={config.draft.mini_window_visible} onChange={value => config.update("mini_window_visible", value)} label="启动时显示" /></label><label className="setting-row"><span><strong>始终置顶</strong><small>保持在其他普通窗口上方</small></span><Switch checked={config.draft.mini_window_always_on_top} onChange={value => config.update("mini_window_always_on_top", value)} label="始终置顶" /></label></section><section><h2>系统</h2><label className="setting-row"><span><strong>开机启动</strong><small>登录 Windows 后启动应用</small></span><Switch checked={config.draft.auto_start} onChange={value => config.update("auto_start", value)} label="开机启动" /></label></section></div>;
}

function ConfirmDialog({ title, detail, confirmLabel, tone = "danger", onCancel, onConfirm }: { title: string; detail: string; confirmLabel: string; tone?: "danger" | "warning"; onCancel(): void; onConfirm(): void }) {
  return <div className="modal-backdrop" role="presentation"><section className="confirm-dialog" role="alertdialog" aria-modal="true" aria-labelledby="confirm-title"><span className="state-symbol" aria-hidden="true">!</span><h2 id="confirm-title">{title}</h2><p>{detail}</p><div><Button variant="secondary" autoFocus onClick={onCancel}>继续编辑</Button><Button variant={tone === "danger" ? "danger" : "primary"} onClick={onConfirm}>{confirmLabel}</Button></div></section></div>;
}

function SupportSettings() {
  const [feedback, setFeedback] = useState<{ tone: "success" | "warning" | "error"; message: string } | null>(null);
  const [checking, setChecking] = useState(false);
  const [platform, setPlatform] = useState<{ webview2_available: boolean; tray_available: boolean; explorer_available: boolean } | null>(null);

  useEffect(() => {
    void invoke<{ webview2_available: boolean; tray_available: boolean; explorer_available: boolean }>("platform_capabilities")
      .then(setPlatform)
      .catch(() => setPlatform(null));
  }, []);

  const record = async (event: string, detail: string) => {
    try {
      await invoke("record_semantic_event", { event, detail });
    } catch {
      // Browser preview has no native logger.
    }
  };

  const openData = async () => {
    try {
      await invoke<string>("open_data_directory");
      setFeedback({ tone: "success", message: "数据目录已打开。" });
    } catch (error) {
      setFeedback({ tone: "error", message: `无法打开数据目录：${String(error)}` });
    }
  };

  const copyDiagnostics = async () => {
    try {
      const summary = await invoke<string>("diagnostic_summary");
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
      const result = await invoke<{ status: "up_to_date" | "available" | "unavailable"; message: string }>(
        "evaluate_update_response",
        { currentVersion: "1.0.0", responseBody: body, failureReason: null },
      );
      await record("update.checked", `status=${result.status}`);
      setFeedback({ tone: result.status === "unavailable" ? "warning" : "success", message: result.message });
    } catch (error) {
      const result = await invoke<{ message: string }>("evaluate_update_response", {
        currentVersion: "1.0.0",
        responseBody: null,
        failureReason: String(error),
      }).catch(() => ({ message: `暂时无法检查更新：${String(error)}` }));
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
          <div><dt>版本</dt><dd>1.0.0</dd></div>
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
  return <MiniWindow />;
}
