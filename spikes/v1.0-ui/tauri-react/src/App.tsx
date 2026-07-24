import { useEffect, useState } from "react";
import {
  hideToTray,
  saveSettings,
  setWindowMode,
  type WindowMode
} from "./tauri";

type Feedback = {
  tone: "neutral" | "success" | "error";
  message: string;
};

const savedBaseline = "10,000";

function App() {
  const [mode, setMode] = useState<WindowMode>("mini");
  const [salary, setSalary] = useState(savedBaseline);
  const [failure, setFailure] = useState(false);
  const [feedback, setFeedback] = useState<Feedback>({
    tone: "neutral",
    message: "没有未保存的更改"
  });

  useEffect(() => {
    void setWindowMode(mode);
  }, [mode]);

  useEffect(() => {
    const openSettings = () => setMode("settings");
    window.addEventListener("lmm-open-settings", openSettings);
    return () => window.removeEventListener("lmm-open-settings", openSettings);
  }, []);

  const open = (next: WindowMode) => setMode(next);

  const save = async () => {
    try {
      const result = await saveSettings(salary, failure);
      setFeedback({
        tone: result.status === "saved" ? "success" : "neutral",
        message: result.message
      });
    } catch (error) {
      const reason = error instanceof Error ? error.message : String(error);
      setFeedback({
        tone: "error",
        message: `保存失败：${reason}，输入已保留`
      });
    }
  };

  return (
    <main className={`app-shell mode-${mode}`}>
      {mode === "mini" && (
        <MiniView
          onOpen={() => open("workbench")}
          onSettings={() => open("settings")}
          onHide={() => void hideToTray()}
        />
      )}
      {mode === "workbench" && (
        <WorkbenchView
          onSettings={() => open("settings")}
          onClose={() => open("mini")}
          onHide={() => void hideToTray()}
        />
      )}
      {mode === "settings" && (
        <SettingsView
          salary={salary}
          failure={failure}
          feedback={feedback}
          onSalaryChange={(value) => {
            setSalary(value);
            setFeedback({ tone: "neutral", message: "有未保存的更改" });
          }}
          onFailureChange={setFailure}
          onSave={() => void save()}
          onReset={() => {
            setSalary(savedBaseline);
            setFeedback({ tone: "neutral", message: "已恢复默认值，保存后生效" });
          }}
          onClose={() => open("mini")}
        />
      )}
    </main>
  );
}

function MiniView(props: {
  onOpen: () => void;
  onSettings: () => void;
  onHide: () => void;
}) {
  const [menuOpen, setMenuOpen] = useState(false);
  return (
    <section className="mini-window surface">
      <button className="coin-button" onClick={props.onOpen} aria-label="打开今日工作台">
        ¥
      </button>
      <div className="mini-content" data-tauri-drag-region>
        <div className="eyebrow">
          <span>今日已赚</span>
          <span className="success-text">工作中</span>
        </div>
        <strong className="mini-amount">¥ 186.42</strong>
        <div className="progress" aria-label="工作进度 56%">
          <span style={{ width: "56%" }} />
        </div>
        <div className="mini-meta">
          <span>工作进度 56%</span>
          <span>距离下班 4:38:20</span>
        </div>
      </div>
      <button
        className="icon-button"
        onClick={() => setMenuOpen((value) => !value)}
        aria-label="更多操作"
      >
        •••
      </button>
      {menuOpen && (
        <div className="menu mini-menu">
          <button onClick={props.onOpen}>打开今日工作台</button>
          <button onClick={props.onSettings}>设置</button>
          <div className="separator" />
          <button onClick={props.onHide}>隐藏到托盘</button>
        </div>
      )}
    </section>
  );
}

function WorkbenchView(props: {
  onSettings: () => void;
  onClose: () => void;
  onHide: () => void;
}) {
  const [tab, setTab] = useState<"today" | "calendar">("today");
  return (
    <section className="window surface">
      <Titlebar title="LetsMakeMoney" onSettings={props.onSettings} onClose={props.onClose} />
      <div className="workbench-layout">
        <nav className="side-nav" aria-label="工作台导航">
          <button className={tab === "today" ? "active" : ""} onClick={() => setTab("today")}>
            ◷ <span>今日</span>
          </button>
          <button className={tab === "calendar" ? "active" : ""} onClick={() => setTab("calendar")}>
            ▦ <span>日历</span>
          </button>
          <div className="grow" />
          <button onClick={props.onHide}>▭ <span>隐藏到托盘</span></button>
        </nav>
        <div className="workbench-content">
          {tab === "today" ? <TodayContent /> : <CalendarContent />}
        </div>
      </div>
    </section>
  );
}

function TodayContent() {
  return (
    <>
      <header className="page-heading">
        <div>
          <h1>今天，继续把时间变成看得见的进度</h1>
          <p>2026 年 7 月 23 日 · 周四</p>
        </div>
        <span className="badge success">工作中</span>
      </header>
      <div className="today-grid">
        <section className="card income-card">
          <span className="section-label">今日已赚</span>
          <strong className="hero-amount">¥ 186.42</strong>
          <p>日薪 ¥ 500.00 · 时薪 ¥ 62.50</p>
          <div className="progress-heading"><span>收入进度</span><strong>56%</strong></div>
          <div className="progress large"><span style={{ width: "56%" }} /></div>
          <Metric label="本月累计" value="¥ 3,842.00" />
          <Metric label="本月工作日" value="8 / 20 天" />
          <Metric label="距离下班" value="4:38:20" />
        </section>
        <section className="card schedule-card">
          <div className="schedule-heading">
            <div><span className="section-label">今日安排</span><h2>08:00—18:00</h2></div>
            <button className="text-button">调整今天</button>
          </div>
          <Timeline time="08:00" tone="success" title="开始工作" detail="已完成 3 小时 22 分钟" />
          <Timeline time="12:00" tone="accent" title="午休" detail="12:00—14:00" />
          <Timeline time="18:00" tone="neutral" title="结束工作" detail="预计今日收入 ¥ 500.00" />
        </section>
      </div>
    </>
  );
}

function CalendarContent() {
  const days = Array.from({ length: 31 }, (_, index) => index + 1);
  return (
    <>
      <header className="page-heading">
        <div><h1>收入日历</h1><p>只记录工作日、调休、节假日与收入结果</p></div>
        <button className="secondary-button">调整工作日</button>
      </header>
      <section className="card calendar-card">
        <div className="calendar-heading"><button>‹</button><strong>2026 年 7 月</strong><button>›</button></div>
        <div className="weekdays">{["日", "一", "二", "三", "四", "五", "六"].map((day) => <span key={day}>{day}</span>)}</div>
        <div className="calendar-grid">
          <i /><i /><i />
          {days.map((day) => (
            <button key={day} className={`${[4,5,11,12,18,19,25,26].includes(day) ? "rest" : "work"} ${day === 23 ? "today" : ""}`}>
              {day}
            </button>
          ))}
        </div>
      </section>
    </>
  );
}

function SettingsView(props: {
  salary: string;
  failure: boolean;
  feedback: Feedback;
  onSalaryChange: (value: string) => void;
  onFailureChange: (value: boolean) => void;
  onSave: () => void;
  onReset: () => void;
  onClose: () => void;
}) {
  return (
    <section className="window surface">
      <Titlebar title="设置" onClose={props.onClose} />
      <div className="settings-layout">
        <nav className="settings-nav">
          <strong>偏好设置</strong>
          <small>更改只保存在本机</small>
          <button className="active">¥ <span>收入与作息</span></button>
          <button disabled>▦ <span>日历</span></button>
          <button disabled>▭ <span>窗口与启动</span></button>
          <button disabled>ⓘ <span>数据与支持</span></button>
        </nav>
        <form className="settings-form" onSubmit={(event) => { event.preventDefault(); props.onSave(); }}>
          <div className="settings-scroll">
            <header className="settings-heading">
              <div><h1>收入与作息</h1><p>用于计算日薪、时薪、今日收益和工作进度。</p></div>
              <span className="badge success">本机配置</span>
            </header>
            <SettingSection title="收入">
              <SettingRow title="月薪" description="税前月薪，按当月工作日折算">
                <div className="input-unit">
                  <input aria-label="月薪" value={props.salary} onChange={(event) => props.onSalaryChange(event.target.value)} />
                  <span>元</span>
                </div>
              </SettingRow>
              <SettingRow title="休息模式" description="影响每月工作日和日薪计算">
                <select aria-label="休息模式"><option>双休</option><option>单休</option><option>大小周</option></select>
              </SettingRow>
            </SettingSection>
            <SettingSection title="工作时间">
              <SettingRow title="上班时间" description="默认按 8 小时有效工时推算下班"><input type="time" defaultValue="08:00" /></SettingRow>
              <SettingRow title="午休时长" description="午休不计入有效工时"><select defaultValue="2"><option value="2">2 小时</option><option value="1.5">1.5 小时</option><option value="1">1 小时</option></select></SettingRow>
              <SettingRow title="午休开始" description="修改后自动推算午休结束与下班时间"><input type="time" defaultValue="12:00" /></SettingRow>
            </SettingSection>
            <div className="prediction"><span>自动推算</span><strong>午休 12:00—14:00 · 下班 18:00 · 有效工时 8 小时</strong></div>
            <label className="failure-toggle">
              <input type="checkbox" checked={props.failure} onChange={(event) => props.onFailureChange(event.target.checked)} />
              模拟配置写入失败（技术 Spike）
            </label>
          </div>
          <footer className="settings-footer">
            <span className={`feedback ${props.feedback.tone}`}>{props.feedback.message}</span>
            <button type="button" className="secondary-button" onClick={props.onReset}>恢复默认</button>
            <button type="submit" className="primary-button">保存</button>
          </footer>
        </form>
      </div>
    </section>
  );
}

function Titlebar(props: { title: string; onClose: () => void; onSettings?: () => void }) {
  return (
    <header className="titlebar" data-tauri-drag-region>
      <span className="app-mark">¥</span>
      <strong>{props.title}</strong>
      <div className="grow" />
      {props.onSettings && <button className="icon-button" onClick={props.onSettings} aria-label="设置">⚙</button>}
      <button className="icon-button" onClick={props.onClose} aria-label="关闭">×</button>
    </header>
  );
}

function Metric({ label, value }: { label: string; value: string }) {
  return <div className="metric"><span>{label}</span><strong>{value}</strong></div>;
}

function Timeline(props: { time: string; tone: string; title: string; detail: string }) {
  return (
    <div className="timeline">
      <time>{props.time}</time><i className={props.tone} />
      <div><strong>{props.title}</strong><span>{props.detail}</span></div>
    </div>
  );
}

function SettingSection(props: { title: string; children: React.ReactNode }) {
  return <fieldset><legend>{props.title}</legend>{props.children}</fieldset>;
}

function SettingRow(props: { title: string; description: string; children: React.ReactNode }) {
  return (
    <label className="setting-row">
      <span><strong>{props.title}</strong><small>{props.description}</small></span>
      {props.children}
    </label>
  );
}

export default App;
