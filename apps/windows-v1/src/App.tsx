import { useEffect, useMemo, useState } from "react";
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
  useCalendarOverrides,
  useDashboard,
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
  return (
    <main className={`window-frame ${className}`} data-window={kind}>
      <header className="titlebar" data-tauri-drag-region>
        <div className="titlebar__identity">
          <span className="coin-mark" aria-hidden="true">¥</span>
          <strong>{title}</strong>
        </div>
        <IconButton label={`关闭${title}`} icon="×" onClick={onClose} />
      </header>
      {children}
    </main>
  );
}

function MiniWindow() {
  const { snapshot, refresh } = useDashboard();
  if (snapshot.state === "loading") {
    return <main className="mini-window mini-window--state" data-window="mini"><span className="spinner" /><strong>正在计算今天的收入</strong></main>;
  }
  if (snapshot.state === "error") {
    return <main className="mini-window mini-window--state" data-window="mini"><strong>暂时无法计算</strong><button type="button" onClick={refresh}>重试</button></main>;
  }
  return (
    <main className="mini-window" data-window="mini">
      <div className="mini-window__drag" data-tauri-drag-region aria-label="拖动迷你收入视图" />
      <button
        className="mini-window__primary"
        type="button"
        onClick={() => showWindow("workbench")}
        aria-label="打开今日工作台"
      >
        <span className="mini-window__status">
          <span className="status-dot" />
          {snapshot.workState}
        </span>
        <span className="mini-window__label">今日已赚</span>
        <strong className="mini-window__amount">{formatMoney(snapshot.amount)}</strong>
        <ProgressBar value={snapshot.progress} label="工作进度" compact />
        <span className="mini-window__meta">剩余有效工时 {formatDuration(snapshot.remainingSeconds)}</span>
      </button>
      <IconButton
        label="更多操作"
        icon="•••"
        onClick={() => showWindow("settings")}
        className="mini-window__more"
      />
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
            <span aria-hidden="true">▦</span>日历
          </button>
          <button onClick={() => showWindow("settings")}>
            <span aria-hidden="true">⚙</span>设置
          </button>
        </nav>
        <section className="workbench-content">
          {tab === "today" ? <TodayView {...dashboard} /> : <CalendarView />}
        </section>
      </div>
    </WindowFrame>
  );
}

function TodayView({ snapshot, refresh }: ReturnType<typeof useDashboard>) {
  if (snapshot.state === "loading") return <PageState title="正在整理今天" detail="收入、安排和日历正在同步。" />;
  if (snapshot.state === "error") return <PageState title="暂时无法计算" detail={snapshot.message ?? "请稍后重试。"} action={<Button onClick={refresh}>重新计算</Button>} />;
  return (
    <div className="page-stack" aria-label="今日">
      <div className="page-heading">
        <div>
          <span className="eyebrow">7 月 24 日 · 工作日</span>
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
            <li className="is-done"><time>08:00</time><strong>开始工作</strong><span>已完成 3 小时 22 分钟</span></li>
            <li className="is-current"><time>12:00</time><strong>午休</strong><span>12:00–14:00</span></li>
            <li><time>18:00</time><strong>结束工作</strong><span>预计今日收入 ¥ 500.00</span></li>
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

function CalendarView() {
  const days = Array.from({ length: 31 }, (_, index) => index + 1);
  const { overrides, setOverride } = useCalendarOverrides();
  const [selectedDay, setSelectedDay] = useState<number | null>(null);
  return (
    <div className="page-stack" aria-label="日历">
      <div className="page-heading">
        <div><span className="eyebrow">2026 年 7 月</span><h1>收入日历</h1></div>
        <Button variant="secondary" onClick={() => showWindow("settings")}>调整日期</Button>
      </div>
      <section className="surface calendar">
        <div className="calendar__weekdays">{["日","一","二","三","四","五","六"].map(day => <span key={day}>{day}</span>)}</div>
        <div className="calendar__grid">
          <span />
          <span />
          <span />
          {days.map(day => {
            const override = overrides[day];
            const className = [
              day === 24 ? "is-today" : "",
              override === "work" ? "is-manual-work" : "",
              override === "rest" ? "is-rest" : !override && (day % 7 === 4 || day % 7 === 5) ? "is-rest" : "",
            ].filter(Boolean).join(" ");
            return <button key={day} aria-label={`7月${day}日${override ? "，已手动调整" : ""}`} className={className} onClick={() => setSelectedDay(day)}>{day}</button>;
          })}
        </div>
        <div className="calendar__legend"><span><i className="legend-dot legend-dot--work" />工作日</span><span><i className="legend-dot legend-dot--rest" />休息日</span><span><i className="legend-dot legend-dot--manual" />手动调整</span></div>
      </section>
      {selectedDay !== null && (
        <section className="surface date-editor" role="dialog" aria-label={`调整 7 月 ${selectedDay} 日`}>
          <div><span className="eyebrow">手动调整</span><h2>7 月 {selectedDay} 日</h2><p>本次调整只影响这一天。</p></div>
          <SegmentedControl
            value={overrides[selectedDay] ?? "default"}
            onChange={value => setOverride(selectedDay, value as "work" | "rest" | "default")}
            options={[{ value: "default", label: "跟随规则" }, { value: "work", label: "工作日" }, { value: "rest", label: "休息日" }]}
          />
          <IconButton label="关闭日期调整" icon="×" onClick={() => setSelectedDay(null)} />
        </section>
      )}
    </div>
  );
}

function PageState({ title, detail, action }: { title: string; detail: string; action?: React.ReactNode }) {
  return <div className="page-state" role="status"><span className="state-symbol" aria-hidden="true">¥</span><h1>{title}</h1><p>{detail}</p>{action}</div>;
}

function WizardWindow() {
  const [step, setStep] = useState(1);
  const config = useConfigDraft();
  const [lunchDuration, setLunchDuration] = useState(2);
  const [confirmClose, setConfirmClose] = useState(false);
  const [firstRun, setFirstRun] = useState(false);
  useEffect(() => {
    invoke<boolean>("configuration_initialized")
      .then(value => setFirstRun(!value))
      .catch(() => setFirstRun(false));
  }, []);
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
  const updateLunchDuration = (value: number) => {
    setLunchDuration(value);
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
                <Feedback tone="success">预计本月工作日 23 天</Feedback>
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
                  <Field label="午休时长" value={lunchDuration} suffix="小时" inputMode="decimal" onChange={event => updateLunchDuration(Math.max(0, Number(event.target.value) || 0))} />
                  <Field label="推算下班时间" value={config.draft.work_end_time} type="time" readOnly />
                </div>
                <Feedback tone="success">有效工时 {config.draft.work_hours_per_day} 小时 · 午休 {config.draft.lunch_start_time}–{config.draft.lunch_end_time}</Feedback>
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
                  <div><dt>午休</dt><dd>{config.draft.lunch_start_time}–{config.draft.lunch_end_time}</dd></div>
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
