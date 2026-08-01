const windows = {
  mini: document.querySelector("#mini-window"),
  workbench: document.querySelector("#workbench-window"),
  wizard: document.querySelector("#wizard-window"),
  settings: document.querySelector("#settings-window"),
};

const state = {
  currentWindow: "mini",
  previousWindow: "mini",
  dirty: false,
  saving: false,
  wizardStep: 1,
  dialogAction: null,
  calendarYear: 2026,
  calendarMonth: 6,
  calendarMode: "official",
  naturalToday: "2026-07-27",
  selectedDate: "2026-07-27",
  calendarOverrides: new Map([
    ["2026-07-23", "workday"],
    ["2026-07-27", "paid_rest"],
    ["2026-07-28", "unpaid_rest"],
  ]),
  businessState: "working_after_rest",
  persistedTheme: "light",
  previewTheme: "light",
  persistedEdgeAutoHide: true,
  previewEdgeAutoHide: true,
  miniDock: "floating",
  miniDockRetracted: false,
  lastDockBeforeDisabled: null,
  todayVariant: "corner",
  surfaceMode: "single",
  longContent: false,
};

const salaryInput = document.querySelector("#salary-input");
const saveButton = document.querySelector("#save-button");
const saveFeedback = document.querySelector("#save-feedback");
const salaryError = document.querySelector("#salary-error");
const traySimulation = document.querySelector("#tray-simulation");
const toastStack = document.querySelector("#toast-stack");
const productDialog = document.querySelector("#product-dialog");
const calendarOverrideDialog = document.querySelector("#calendar-override-dialog");
const calendarGrid = document.querySelector(".calendar-grid");
const calendarStatus = document.querySelector("#calendar-status");
const themeModeControl = document.querySelector("#theme-mode");
const dpiModeControl = document.querySelector("#dpi-mode");
const themePreviewNote = document.querySelector("#theme-preview-note");
const edgeAutoHideControl = document.querySelector("#edge-auto-hide");
const miniWindow = windows.mini;
const privacyEdgeTab = document.querySelector("#privacy-edge-tab");
const privacyEdgeCopy = document.querySelector("#privacy-edge-copy");
let miniDockTimer = null;

function normalizeTheme(value) {
  return value === "dark" ? "dark" : "light";
}

function updateThemeControls(mode) {
  if (themeModeControl) themeModeControl.value = mode;
  document.querySelectorAll('input[name="settings-theme"]').forEach((control) => {
    control.checked = control.value === mode;
  });
}

function applyTheme(mode, { syncControls = true, message = "" } = {}) {
  const normalized = normalizeTheme(mode);
  state.previewTheme = normalized;
  document.documentElement.dataset.theme = normalized;
  document.documentElement.style.colorScheme = normalized;
  if (syncControls) updateThemeControls(normalized);
  if (themePreviewNote) {
    themePreviewNote.textContent = message || (
      normalized === "dark"
        ? "正在预览深色模式；保存后同步到全部应用窗口。"
        : "浅色是新用户和旧配置的默认主题。"
    );
  }
}

function commitTheme(mode) {
  const normalized = normalizeTheme(mode);
  state.persistedTheme = normalized;
  state.previewTheme = normalized;
  window.localStorage.setItem("lmm-v102-prototype-theme", normalized);
  applyTheme(normalized, {
    message: normalized === "dark"
      ? "深色模式已保存，并同步到全部应用窗口。"
      : "浅色模式已保存，并同步到全部应用窗口。",
  });
}

function revertThemeDraft(message = "主题预览已撤销，恢复上次保存的主题。") {
  applyTheme(state.persistedTheme, { syncControls: false, message });
}

function normalizeMiniDock(value) {
  return value === "left" || value === "right" ? value : "floating";
}

function clearMiniDockTimer() {
  if (miniDockTimer !== null) {
    window.clearTimeout(miniDockTimer);
    miniDockTimer = null;
  }
}

function updateMiniDockControls() {
  document.querySelectorAll("[data-mini-dock]").forEach((button) => {
    button.classList.toggle("is-active", button.dataset.miniDock === state.miniDock);
  });
}

function getPrivacyEdgePresentation() {
  const presentations = {
    loading: ["正在同步", "正在同步收入状态，展开迷你收入视图"],
    error: ["点击查看", "收入状态暂时无法计算，展开迷你收入视图查看详情"],
    before_work: ["距离上班 38分", "距离上班还有三十八分钟，展开迷你收入视图"],
    working_before_rest: ["距离休息 38分", "距离休息还有三十八分钟，展开迷你收入视图"],
    rest: ["距离复工 38分", "距离恢复工作还有三十八分钟，展开迷你收入视图"],
    working_after_rest: ["距离下班 4时38分", "距离下班还有四小时三十八分钟，展开迷你收入视图"],
    after_work: ["今日工作结束", "今日工作已经结束，展开迷你收入视图"],
    rest_day: ["今日休息", "今天是休息日，展开迷你收入视图"],
    paid_rest: ["今日休息", "今天是休息日，展开迷你收入视图"],
    unpaid_rest: ["今日休息", "今天是休息日，展开迷你收入视图"],
    overnight: ["距离下班 4时38分", "本次夜班距离下班还有四小时三十八分钟，展开迷你收入视图"],
  };
  return presentations[state.businessState] || presentations.working_after_rest;
}

function applyMiniDockVisual() {
  const docked = state.previewEdgeAutoHide && state.miniDock !== "floating";
  const [edgeCopy, edgeLabel] = getPrivacyEdgePresentation();
  miniWindow.classList.toggle("is-docked-left", docked && state.miniDock === "left");
  miniWindow.classList.toggle("is-docked-right", docked && state.miniDock === "right");
  miniWindow.classList.toggle("is-retracted", docked && state.miniDockRetracted);
  miniWindow.dataset.dock = docked ? state.miniDock : "floating";
  miniWindow.setAttribute(
    "aria-label",
    docked && state.miniDockRetracted
      ? `迷你收入视图，已在屏幕${state.miniDock === "left" ? "左" : "右"}侧收起`
      : "迷你收入视图",
  );
  privacyEdgeTab.hidden = !docked;
  privacyEdgeTab.tabIndex = docked ? 0 : -1;
  privacyEdgeCopy.textContent = edgeCopy;
  privacyEdgeTab.setAttribute("aria-label", `${edgeLabel}；当前停靠在屏幕${state.miniDock === "left" ? "左" : "右"}侧`);
  updateMiniDockControls();
}

function setTodayVariant(value, { rebuild = true } = {}) {
  state.todayVariant = value === "label" ? "label" : "corner";
  document.documentElement.dataset.todayVariant = state.todayVariant;
  document.querySelectorAll("[data-today-variant]").forEach((button) => {
    button.classList.toggle("is-active", button.dataset.todayVariant === state.todayVariant);
  });
  if (rebuild) buildCalendar();
}

function setSurfaceMode(value) {
  state.surfaceMode = value === "legacy" ? "legacy" : "single";
  document.documentElement.dataset.surfaceMode = state.surfaceMode;
  document.querySelectorAll("[data-surface-mode]").forEach((button) => {
    button.classList.toggle("is-active", button.dataset.surfaceMode === state.surfaceMode);
  });
}

function setMiniDock(value, { retracted = value !== "floating" } = {}) {
  clearMiniDockTimer();
  const normalized = normalizeMiniDock(value);
  if (!state.previewEdgeAutoHide && normalized !== "floating") {
    state.lastDockBeforeDisabled = normalized;
    state.miniDock = "floating";
    state.miniDockRetracted = false;
    applyMiniDockVisual();
    return false;
  }
  state.miniDock = normalized;
  state.miniDockRetracted = normalized !== "floating" && retracted;
  applyMiniDockVisual();
  return true;
}

function revealMiniDock() {
  clearMiniDockTimer();
  if (!state.previewEdgeAutoHide || state.miniDock === "floating") return;
  state.miniDockRetracted = false;
  applyMiniDockVisual();
}

function retractMiniDock() {
  if (
    !state.previewEdgeAutoHide
    || state.miniDock === "floating"
    || state.currentWindow !== "mini"
    || miniWindow.matches(":hover")
    || miniWindow.contains(document.activeElement)
    || document.querySelector("dialog[open]")
  ) {
    return;
  }
  state.miniDockRetracted = true;
  applyMiniDockVisual();
}

function queueMiniDockRetract() {
  clearMiniDockTimer();
  if (!state.previewEdgeAutoHide || state.miniDock === "floating") return;
  miniDockTimer = window.setTimeout(() => {
    miniDockTimer = null;
    retractMiniDock();
  }, 600);
}

function applyEdgeAutoHidePreview(enabled, { syncControl = true, restoreDock = true } = {}) {
  state.previewEdgeAutoHide = Boolean(enabled);
  if (syncControl && edgeAutoHideControl) edgeAutoHideControl.checked = state.previewEdgeAutoHide;
  if (!state.previewEdgeAutoHide) {
    if (state.miniDock !== "floating") state.lastDockBeforeDisabled = state.miniDock;
    setMiniDock("floating", { retracted: false });
    return;
  }
  if (restoreDock && state.lastDockBeforeDisabled) {
    const previousDock = state.lastDockBeforeDisabled;
    state.lastDockBeforeDisabled = null;
    setMiniDock(previousDock, { retracted: true });
    return;
  }
  applyMiniDockVisual();
}

function commitEdgeAutoHide(enabled) {
  state.persistedEdgeAutoHide = Boolean(enabled);
  window.localStorage.setItem("lmm-v104-prototype-edge-hide", String(state.persistedEdgeAutoHide));
  applyEdgeAutoHidePreview(state.persistedEdgeAutoHide, { syncControl: true });
  if (!state.persistedEdgeAutoHide) state.lastDockBeforeDisabled = null;
}

function revertEdgeAutoHideDraft({ syncControl = false } = {}) {
  applyEdgeAutoHidePreview(state.persistedEdgeAutoHide, { syncControl, restoreDock: true });
}

function showWindow(name) {
  if (!windows[name]) return;
  clearMiniDockTimer();
  const previous = state.currentWindow;
  Object.entries(windows).forEach(([key, element]) => {
    element.classList.toggle("is-visible", key === name);
  });
  document.querySelectorAll("[data-window]").forEach((button) => {
    button.classList.toggle("is-active", button.dataset.window === name);
  });
  state.previousWindow = previous;
  state.currentWindow = name;
  traySimulation.hidden = true;
  if (name === "mini") {
    revealMiniDock();
    queueMiniDockRetract();
  }
}

function hideToTray() {
  clearMiniDockTimer();
  Object.values(windows).forEach((element) => element.classList.remove("is-visible"));
  state.previousWindow = state.currentWindow;
  traySimulation.hidden = false;
  showToast("窗口已隐藏，托盘可随时找回。");
}

function showToast(message, error = false) {
  const toast = document.createElement("div");
  toast.className = `toast${error ? " error" : ""}`;
  toast.textContent = message;
  toastStack.append(toast);
  window.setTimeout(() => toast.remove(), 3200);
}

function setFeedback(message, kind = "") {
  saveFeedback.textContent = message;
  saveFeedback.className = `save-feedback${kind ? ` is-${kind}` : ""}`;
}

function openDialog({ title, message, kind = "", confirm = "确定", cancel = "取消", action = null }) {
  productDialog.className = `product-dialog${kind ? ` is-${kind}` : ""}`;
  document.querySelector("#dialog-title").textContent = title;
  document.querySelector("#dialog-message").textContent = message;
  document.querySelector("#dialog-icon").textContent = kind === "error" ? "!" : kind === "warning" ? "?" : "✓";
  document.querySelector("#dialog-confirm").textContent = confirm;
  document.querySelector("#dialog-cancel").textContent = cancel;
  document.querySelector("#dialog-cancel").hidden = !cancel;
  state.dialogAction = action;
  productDialog.showModal();
}

function renderTimeline(kind) {
  const timeline = document.querySelector("#today-timeline");
  const variants = {
    overnight: [
        ["23:00", "开始工作", "归属 2026 年 7 月 22 日", "is-done"],
        ["次日 02:00", "休息", "02:00—02:30", "is-current"],
        ["次日 02:30", "恢复工作", "继续本次夜班", ""],
        ["次日 07:30", "结束工作", "预计本次夜班收入 ¥ 500.00", ""],
    ],
    zero_rest: [
      ["08:00", "开始工作", "已完成 3 小时 22 分钟", "is-done"],
      ["16:00", "结束工作", "预计今日收入 ¥ 500.00", "is-current"],
    ],
    offday: [["全天", "休息", "今天没有工作安排", "is-current"]],
    paid_rest: [["全天", "带薪休息", "保留当天应计金额，不累计实时工时", "is-current"]],
    unpaid_rest: [["全天", "不带薪休息", "不计算当天收入与实时工时", "is-current"]],
    loading: [["—", "正在同步", "完成后自动更新今天的安排", "is-current"]],
    error: [["—", "暂时无法加载", "配置没有被修改，可以重试", "is-current"]],
    normal: [
      ["08:00", "开始工作", "已完成 3 小时 22 分钟", "is-done"],
      ["12:00", "休息", "12:00—14:00", "is-current"],
      ["14:00", "恢复工作", "继续完成今日安排", ""],
      ["18:00", "结束工作", "预计今日收入 ¥ 500.00", ""],
    ],
  };
  const rows = variants[kind] || variants.normal;
  timeline.replaceChildren(...rows.map(([time, title, description, className]) => {
    const row = document.createElement("li");
    row.className = className;
    const timeNode = document.createElement("time");
    timeNode.textContent = time;
    const dot = document.createElement("span");
    dot.className = "timeline-dot";
    const copy = document.createElement("div");
    const strong = document.createElement("strong");
    strong.textContent = title;
    const detail = document.createElement("span");
    detail.textContent = description;
    copy.append(strong, detail);
    row.append(timeNode, dot, copy);
    return row;
  }));
}

function setBusinessState(value) {
  state.businessState = value;
  const values = {
    loading: {
      status: "正在同步",
      amount: "—",
      incomeLabel: "收入快照",
      progress: "正在载入权威快照",
      progressPercent: "—",
      miniRemaining: "请稍候",
      remaining: "—",
      width: "0%",
      title: "正在同步收入进度",
      subtitle: "正在读取本机配置与权威快照",
      bodyClass: "is-loading-state",
      timeline: "normal",
    },
    error: {
      status: "同步失败",
      amount: "—",
      incomeLabel: "收入快照",
      progress: "暂时无法计算",
      progressPercent: "—",
      miniRemaining: "请重试",
      remaining: "—",
      width: "0%",
      title: "暂时无法计算",
      subtitle: "当前配置没有被修改，请重试权威同步",
      bodyClass: "is-error-state",
      timeline: "normal",
    },
    before_work: {
      status: "上班前",
      amount: "¥ 0.00",
      incomeLabel: "今日已赚",
      progress: "工作进度 0%",
      progressPercent: "0%",
      miniRemaining: "距离上班 00:38:20",
      remaining: "00:38:20",
      width: "0%",
      title: "今天的收入进度",
      subtitle: "2026 年 7 月 23 日 · 周四",
      bodyClass: "",
      timeline: "normal",
    },
    working_before_rest: {
      status: "工作中",
      amount: "¥ 186.42",
      incomeLabel: "今日已赚",
      progress: "工作进度 32%",
      progressPercent: "32%",
      miniRemaining: "距离休息 00:38:20",
      remaining: "00:38:20",
      width: "32%",
      title: "今天的收入进度",
      subtitle: "2026 年 7 月 23 日 · 周四",
      bodyClass: "",
      timeline: "normal",
    },
    rest: {
      status: "休息中",
      amount: "¥ 250.00",
      incomeLabel: "今日已赚",
      progress: "收入已暂停累计",
      progressPercent: "50%",
      miniRemaining: "距离恢复工作 00:38:20",
      remaining: "00:38:20",
      width: "50%",
      title: "今天的收入进度",
      subtitle: "2026 年 7 月 23 日 · 周四",
      bodyClass: "is-rest-state",
      timeline: "normal",
    },
    working_after_rest: {
      status: "工作中",
      amount: "¥ 186.42",
      incomeLabel: "今日已赚",
      progress: "工作进度 56%",
      progressPercent: "56%",
      miniRemaining: "距离下班 04:38:20",
      remaining: "04:38:20",
      width: "56%",
      title: "今天的收入进度",
      subtitle: "2026 年 7 月 23 日 · 周四",
      bodyClass: "",
      timeline: "normal",
    },
    after_work: {
      status: "工作已结束",
      amount: "¥ 500.00",
      incomeLabel: "今日收入",
      progress: "今日工作已完成",
      progressPercent: "100%",
      miniRemaining: "今日工作已结束",
      remaining: "已完成",
      width: "100%",
      title: "今天的工作已完成",
      subtitle: "2026 年 7 月 23 日 · 周四",
      bodyClass: "is-after-work-state",
      timeline: "normal",
    },
    rest_day: {
      status: "休息日",
      amount: "—",
      incomeLabel: "今天休息",
      progress: "今天没有工作安排",
      progressPercent: "—",
      miniRemaining: "下个工作日 08:00",
      remaining: "明天 08:00",
      width: "0%",
      title: "今天休息",
      subtitle: "普通休息日 · 不计算实时收入与有效工时",
      bodyClass: "is-offday",
      timeline: "normal",
    },
    paid_rest: {
      status: "带薪休息",
      amount: "¥ 500.00",
      incomeLabel: "今日应计",
      progress: "不计算实时工时",
      progressPercent: "—",
      miniRemaining: "带薪休息",
      remaining: "已按带薪规则计入",
      width: "0%",
      title: "今天是带薪休息",
      subtitle: "手动日期调整 · 保留当天应计金额",
      bodyClass: "is-offday",
      timeline: "normal",
    },
    unpaid_rest: {
      status: "不带薪休息",
      amount: "—",
      incomeLabel: "今天休息",
      progress: "不计算实时工时",
      progressPercent: "—",
      miniRemaining: "不带薪休息",
      remaining: "已从本月预计收入扣除",
      width: "0%",
      title: "今天是不带薪休息",
      subtitle: "手动日期调整 · 不计算当天收入",
      bodyClass: "is-offday",
      timeline: "normal",
    },
    overnight: {
      status: "夜班工作中",
      amount: "¥ 312.50",
      incomeLabel: "本次夜班已赚",
      progress: "夜班进度 62%",
      progressPercent: "62%",
      miniRemaining: "距离下班 02:58:20",
      remaining: "02:58:20",
      width: "62%",
      title: "本次夜班收入进度",
      subtitle: "归属日期：2026 年 7 月 22 日，周三",
      bodyClass: "is-overnight",
      timeline: "overnight",
    },
  }[value] || {
    status: "状态未知",
    amount: "—",
    incomeLabel: "收入快照",
    progress: "暂时无法计算",
    progressPercent: "—",
    miniRemaining: "请重试",
    remaining: "—",
    width: "0%",
    title: "暂时无法计算",
    subtitle: "未识别的业务状态",
    bodyClass: "is-error-state",
    timeline: "error",
  };

  const details = {
    loading: {
      caption: "正在读取配置、日历与收入快照",
      progressLabel: "同步状态",
      boundaryLabel: "下一边界",
      scheduleRange: "正在同步",
      adjustLabel: "暂不可用",
      timeline: "loading",
    },
    error: {
      caption: "输入与上次成功配置均未被修改",
      progressLabel: "计算状态",
      boundaryLabel: "恢复路径",
      scheduleRange: "暂时不可用",
      adjustLabel: "先重试",
      timeline: "error",
    },
    before_work: {
      caption: "日薪 ¥ 500.00 · 时薪 ¥ 62.50",
      progressLabel: "工作进度",
      boundaryLabel: "距离上班",
      scheduleRange: "08:00—18:00",
      adjustLabel: "调整今天",
    },
    working_before_rest: {
      caption: "日薪 ¥ 500.00 · 时薪 ¥ 62.50",
      progressLabel: "工作进度",
      boundaryLabel: "距离休息",
      scheduleRange: "08:00—18:00",
      adjustLabel: "调整今天",
    },
    rest: {
      caption: "休息期间收入暂停累计",
      progressLabel: "工作进度",
      boundaryLabel: "距离恢复工作",
      scheduleRange: "08:00—18:00",
      adjustLabel: "调整今天",
    },
    working_after_rest: {
      caption: "日薪 ¥ 500.00 · 时薪 ¥ 62.50",
      progressLabel: "工作进度",
      boundaryLabel: "距离下班",
      scheduleRange: "08:00—18:00",
      adjustLabel: "调整今天",
    },
    after_work: {
      caption: "当天金额已封顶，不再继续累计",
      progressLabel: "工作进度",
      boundaryLabel: "完成状态",
      scheduleRange: "08:00—18:00",
      adjustLabel: "调整今天",
    },
    rest_day: {
      caption: "不计算实时收入与有效工时",
      progressLabel: "今日状态",
      boundaryLabel: "下个工作日",
      scheduleRange: "全天休息",
      adjustLabel: "调整日期",
      timeline: "offday",
    },
    paid_rest: {
      caption: "按带薪休息规则保留当天应计金额",
      progressLabel: "今日状态",
      boundaryLabel: "金额处理",
      scheduleRange: "全天带薪休息",
      adjustLabel: "调整日期",
      timeline: "paid_rest",
    },
    unpaid_rest: {
      caption: "当天收入与实时工时均不计算",
      progressLabel: "今日状态",
      boundaryLabel: "金额处理",
      scheduleRange: "全天不带薪休息",
      adjustLabel: "调整日期",
      timeline: "unpaid_rest",
    },
    overnight: {
      caption: "日薪 ¥ 500.00 · 时薪 ¥ 62.50",
      progressLabel: "夜班进度",
      boundaryLabel: "距离下班",
      scheduleRange: "23:00—次日 07:30",
      adjustLabel: "调整归属日",
    },
  }[value] || {};
  const presentation = { ...values, ...details };

  document.body.classList.remove(
    "is-loading-state",
    "is-error-state",
    "is-rest-state",
    "is-after-work-state",
    "is-offday",
    "is-overnight",
  );
  if (presentation.bodyClass) document.body.classList.add(presentation.bodyClass);
  document.querySelector("#today-title").textContent = presentation.title;
  document.querySelector("#today-subtitle").textContent = presentation.subtitle;
  document.querySelector("#income-caption").textContent = presentation.caption;
  document.querySelector("#boundary-label").textContent = presentation.boundaryLabel;
  document.querySelector("#schedule-range").textContent = presentation.scheduleRange;
  document.querySelector("#adjust-today").textContent = presentation.adjustLabel;
  document.querySelector("#adjust-today").disabled = ["loading", "error"].includes(value);
  document.querySelector("#open-workbench").setAttribute(
    "aria-label",
    value === "error" ? "打开今日工作台并重试" : "打开今日工作台",
  );
  document.querySelectorAll("[data-status]").forEach((node) => {
    node.textContent = presentation.status;
  });
  document.querySelectorAll("[data-income-label]").forEach((node) => {
    node.textContent = presentation.incomeLabel;
  });
  document.querySelectorAll("[data-amount]").forEach((node) => {
    node.textContent = state.longContent && presentation.amount !== "—"
      ? "¥ 99,999,999.99"
      : presentation.amount;
  });
  document.querySelectorAll("[data-progress]").forEach((node) => {
    node.textContent = presentation.progress;
  });
  document.querySelectorAll("[data-progress-label]").forEach((node) => {
    node.textContent = presentation.progressLabel;
  });
  document.querySelectorAll("[data-progress-percent]").forEach((node) => {
    node.textContent = presentation.progressPercent;
  });
  document.querySelectorAll("[data-remaining]").forEach((node) => {
    node.textContent = presentation.remaining;
  });
  document.querySelectorAll("[data-mini-remaining]").forEach((node) => {
    node.textContent = state.longContent && presentation.miniRemaining.includes("距离")
      ? "距离恢复工作 23:59:59"
      : presentation.miniRemaining;
  });
  document.querySelectorAll(".progress-track > span").forEach((node) => {
    node.style.width = presentation.width;
  });
  renderTimeline(presentation.timeline);
  applyMiniDockVisual();
}

function formatDateKey(year, month, day) {
  return `${year}-${String(month + 1).padStart(2, "0")}-${String(day).padStart(2, "0")}`;
}

function getAutomaticDayKind(year, month, day) {
  if (formatDateKey(year, month, day) === "2026-07-25") return "adjusted";
  const weekday = new Date(year, month, day).getDay();
  return weekday === 0 || weekday === 6 ? "restday" : "workday";
}

function updateCalendarStatus(mode) {
  state.calendarMode = mode;
  calendarStatus.className = `calendar-status is-${mode}`;
  calendarStatus.hidden = mode === "official";
  const retryButton = document.querySelector("#calendar-retry");
  const adjustButton = document.querySelector("#calendar-adjust");
  adjustButton.disabled = ["loading", "stale", "error"].includes(mode);
  const statusCopy = {
    official: ["官方日历", "2025—2026 · 数据随应用离线提供"],
    estimated: ["估算日历", "当前年份尚无内置官方数据，按休息模式推算；不代表法定放假安排"],
    loading: ["正在加载日历", "当前页面保持稳定，完成后自动刷新"],
    stale: ["本次加载失败，正在使用上次成功数据", "旧日历仍可查看；恢复成功前暂停新的日期调整"],
    error: ["日历加载失败", "没有可安全保留的旧数据，请重试"],
  }[mode];
  calendarStatus.querySelector("span").textContent = statusCopy[0];
  calendarStatus.querySelector("small").textContent = statusCopy[1];
  retryButton.hidden = !["stale", "error"].includes(mode);
  const coverageCopy = {
    official: ["官方日历", "is-official"],
    estimated: ["估算日历", "is-estimated"],
    loading: ["正在加载", "is-loading"],
    stale: ["数据过期", "is-stale"],
    error: ["加载失败", "is-error"],
  }[mode];
  document.querySelectorAll("[data-calendar-coverage]").forEach((node) => {
    node.textContent = coverageCopy[0];
    node.className = `coverage-badge ${coverageCopy[1]}`;
    node.hidden = mode === "official";
  });
  const shortCopy = {
    official: "官方",
    estimated: "估算",
    loading: "读取中",
    stale: "过期",
    error: "失败",
  }[mode];
  document.querySelectorAll("[data-calendar-coverage-short]").forEach((node) => {
    node.textContent = shortCopy;
    node.className = `mini-source ${coverageCopy[1]}`;
    node.hidden = mode === "official";
  });
}

function buildCalendar() {
  const root = calendarGrid;
  root.replaceChildren();
  root.className = "calendar-grid";
  root.removeAttribute("data-empty-message");
  document.querySelector("#calendar-month-label").textContent =
    `${state.calendarYear} 年 ${state.calendarMonth + 1} 月`;
  root.setAttribute("aria-label", `${state.calendarYear} 年 ${state.calendarMonth + 1} 月收入日历`);

  if (state.calendarMode === "error") {
    root.classList.add("is-empty");
    root.dataset.emptyMessage = "日历尚未加载成功。点击上方“重试”重新读取，现有配置不会被修改。";
    return;
  }

  const weekdays = ["日", "一", "二", "三", "四", "五", "六"];
  weekdays.forEach((label) => {
    const cell = document.createElement("span");
    cell.className = "calendar-cell heading";
    cell.textContent = label;
    root.append(cell);
  });
  const firstWeekday = new Date(state.calendarYear, state.calendarMonth, 1).getDay();
  for (let empty = 0; empty < firstWeekday; empty += 1) {
    const cell = document.createElement("span");
    cell.className = "calendar-cell empty";
    root.append(cell);
  }
  const daysInMonth = new Date(state.calendarYear, state.calendarMonth + 1, 0).getDate();
  for (let day = 1; day <= daysInMonth; day += 1) {
    const cell = document.createElement("button");
    const dateKey = formatDateKey(state.calendarYear, state.calendarMonth, day);
    const automaticKind = getAutomaticDayKind(state.calendarYear, state.calendarMonth, day);
    const manualKind = state.calendarOverrides.get(dateKey);
    const resolvedClass = manualKind && manualKind !== "auto"
      ? manualKind.replaceAll("_", "-")
      : automaticKind;
    cell.className = `calendar-cell ${resolvedClass}`;
    if (manualKind && manualKind !== "auto") cell.classList.add("manual");
    if (dateKey === state.naturalToday) cell.classList.add("today");
    if (dateKey === state.selectedDate) cell.classList.add("selected");
    const number = document.createElement("span");
    number.className = "calendar-number";
    number.textContent = String(day);
    cell.append(number);
    if (dateKey === state.naturalToday) {
      const todayCue = document.createElement("span");
      todayCue.className = "calendar-today-cue";
      todayCue.textContent = state.todayVariant === "label" ? "今天" : "今";
      todayCue.setAttribute("aria-hidden", "true");
      cell.append(todayCue);
    }
    cell.type = "button";
    let businessCopy = {
      workday: "工作日",
      restday: "休息日",
      adjusted: "官方调休工作日",
      "paid-rest": "手动设为带薪休息",
      "unpaid-rest": "手动设为不带薪休息",
    }[resolvedClass] || "手动设为工作日";
    if (manualKind === "workday") businessCopy = "手动设为工作日";
    const states = [
      `${state.calendarYear} 年 ${state.calendarMonth + 1} 月 ${day} 日`,
      dateKey === state.naturalToday ? "今天" : "",
      businessCopy,
      dateKey === state.selectedDate ? "当前选中" : "",
    ].filter(Boolean);
    cell.setAttribute("aria-label", states.join("，"));
    if (dateKey === state.naturalToday) cell.setAttribute("aria-current", "date");
    cell.setAttribute("aria-selected", String(dateKey === state.selectedDate));
    const markerCopy = automaticKind === "adjusted" && !manualKind
      ? "调"
      : manualKind && manualKind !== "auto"
        ? "手"
        : "";
    if (markerCopy) {
      const marker = document.createElement("span");
      marker.className = "calendar-marker";
      marker.textContent = markerCopy;
      marker.setAttribute("aria-hidden", "true");
      cell.append(marker);
    }
    cell.addEventListener("click", () => {
      state.selectedDate = dateKey;
      buildCalendar();
    });
    root.append(cell);
  }

  if (state.calendarMode === "loading") root.classList.add("is-loading");
  if (state.calendarMode === "stale") root.classList.add("is-stale");
  if (state.calendarMode === "estimated") root.classList.add("is-estimated");
}

function setCalendarMode(mode) {
  const calendarStateControl = document.querySelector("#calendar-state");
  if (calendarStateControl && calendarStateControl.value !== mode) {
    calendarStateControl.value = mode;
  }
  updateCalendarStatus(mode);
  buildCalendar();
}

function moveCalendarMonth(offset) {
  const date = new Date(state.calendarYear, state.calendarMonth + offset, 1);
  state.calendarYear = date.getFullYear();
  state.calendarMonth = date.getMonth();
  state.selectedDate = formatDateKey(state.calendarYear, state.calendarMonth, 1);
  const supported = state.calendarYear === 2025 || state.calendarYear === 2026;
  setCalendarMode(supported ? "loading" : "estimated");
  if (!supported) return;
  window.setTimeout(() => setCalendarMode("official"), 420);
}

function openCalendarOverride() {
  if (["error", "loading", "stale"].includes(state.calendarMode)) {
    showToast("当前日历不可调整，请先恢复可用数据。", true);
    return;
  }
  const [year, month, day] = state.selectedDate.split("-").map(Number);
  const currentOverride = state.calendarOverrides.get(state.selectedDate) || "auto";
  const automaticKind = getAutomaticDayKind(year, month - 1, day);
  const canSetLeave =
    automaticKind === "workday" || ["paid_rest", "unpaid_rest"].includes(currentOverride);
  document.querySelector("#override-date-title").textContent = `${year} 年 ${month} 月 ${day} 日`;
  document.querySelector(`input[name="override-kind"][value="${currentOverride}"]`).checked = true;
  document.querySelector("#override-auto-source").textContent =
    state.calendarMode === "estimated"
      ? "当前来源：休息模式估算"
      : automaticKind === "restday"
        ? "当前来源：休息模式"
        : "当前来源：官方日历";
  document.querySelectorAll('input[name="override-kind"][value="paid_rest"], input[name="override-kind"][value="unpaid_rest"]').forEach((control) => {
    control.disabled = !canSetLeave;
    control.closest("label").classList.toggle("is-disabled", !canSetLeave);
  });
  document.querySelector("#override-leave-hint").hidden = canSetLeave;
  document.querySelector("#override-error").hidden = true;
  updateOverrideImpact();
  calendarOverrideDialog.showModal();
}

function updateOverrideImpact() {
  const value = document.querySelector('input[name="override-kind"]:checked')?.value || "auto";
  const copy = {
    auto: "恢复自动判断，不保留手动覆盖",
    workday: "重算为工作日并计入月度分配",
    paid_rest: "不计算工时，保留当天应计金额和本月预计收入",
    unpaid_rest: "不计算工时，并从本月预计收入中扣除当天应计金额",
  };
  document.querySelector("#override-impact-copy").textContent = copy[value];
}

function closeCalendarOverride() {
  document.querySelector("#override-error").hidden = true;
  calendarOverrideDialog.close();
}

function applyCalendarOverride() {
  const value = document.querySelector('input[name="override-kind"]:checked')?.value || "auto";
  if (document.querySelector("#failure-mode").checked) {
    document.querySelector("#override-error").hidden = false;
    return;
  }
  if (value === "auto") {
    state.calendarOverrides.delete(state.selectedDate);
  } else {
    state.calendarOverrides.set(state.selectedDate, value);
  }
  buildCalendar();
  closeCalendarOverride();
  showToast("日期调整已应用，相关收入与状态已重新计算。");
}

function showSettingsPanel(name) {
  const copy = {
    income: ["收入与作息", "用于计算日薪、时薪、今日收益和工作进度。"],
    calendar: ["日历", "管理工作日口径与大小周锚点。"],
    window: ["窗口与启动", "决定应用启动、关闭和托盘驻留方式。"],
    support: ["数据与支持", "查看本地数据、诊断信息与版本更新。"],
  }[name];
  document.querySelectorAll("[data-settings-panel]").forEach((button) => {
    button.classList.toggle("is-active", button.dataset.settingsPanel === name);
  });
  document.querySelectorAll("[data-settings-content]").forEach((panel) => {
    panel.classList.toggle("is-active", panel.dataset.settingsContent === name);
  });
  document.querySelector("#settings-title").textContent = copy[0];
  document.querySelector("#settings-description").textContent = copy[1];
}

function setWizardStep(step) {
  state.wizardStep = Math.max(1, Math.min(3, step));
  document.querySelectorAll("[data-wizard-step]").forEach((panel) => {
    panel.classList.toggle("is-active", Number(panel.dataset.wizardStep) === state.wizardStep);
  });
  document.querySelectorAll("[data-step-marker]").forEach((marker) => {
    const markerStep = Number(marker.dataset.stepMarker);
    marker.classList.toggle("is-current", markerStep === state.wizardStep);
    marker.classList.toggle("is-done", markerStep < state.wizardStep);
    marker.querySelector("span").textContent = markerStep < state.wizardStep ? "✓" : String(markerStep);
  });
  document.querySelector("#wizard-back").disabled = state.wizardStep === 1;
  document.querySelector("#wizard-next").textContent = state.wizardStep === 3 ? "完成" : "下一步";
}

function syncAlternatingWeekChoice() {
  const selectedRest = document.querySelector('input[name="wizard-rest"]:checked')?.value;
  const weekTypeField = document.querySelector("#wizard-week-type");
  const weekType = document.querySelector('input[name="wizard-week-type"]:checked')?.value;
  const isAlternating = selectedRest === "alternate";
  weekTypeField.hidden = !isAlternating;
  document.querySelector("#wizard-week-error").hidden = true;

  const labels = {
    double: "双休",
    single: "单休",
    alternate: `大小周${weekType ? ` · 本周${weekType === "big" ? "大周" : "小周"}` : ""}`,
  };
  const estimates = {
    double: "23 天",
    single: "27 天",
    big: "25 天",
    small: "24 天",
  };
  document.querySelector("#wizard-confirm-rest").textContent = labels[selectedRest];
  document.querySelector("#wizard-workday-estimate").textContent = isAlternating
    ? estimates[weekType] || "待确认"
    : estimates[selectedRest];
}

function syncSettingsWeekChoice() {
  const isAlternating = document.querySelector("#rest-mode").value === "大小周";
  document.querySelector("#settings-week-type-row").hidden = !isAlternating;
}

function restoreDefaults() {
  salaryInput.value = "10,000";
  document.querySelector("#rest-mode").value = "双休";
  document.querySelector("#settings-week-type").value = "";
  document.querySelector("#work-start").value = "08:00";
  document.querySelector("#lunch-duration").value = "2 小时";
  document.querySelector("#lunch-start").value = "12:00";
  applyTheme("light");
  applyEdgeAutoHidePreview(true);
  state.dirty = true;
  syncSettingsWeekChoice();
  setFeedback("已恢复默认值，保存后生效");
}

document.querySelectorAll("[data-window]").forEach((button) => {
  button.addEventListener("click", () => showWindow(button.dataset.window));
});

document.querySelectorAll("[data-mini-dock]").forEach((button) => {
  button.addEventListener("click", () => {
    showWindow("mini");
    const nextDock = normalizeMiniDock(button.dataset.miniDock);
    if (!state.previewEdgeAutoHide && nextDock !== "floating") {
      showToast("请先在“窗口与启动”中开启贴边自动隐藏。", true);
      updateMiniDockControls();
      return;
    }
    setMiniDock(nextDock, { retracted: nextDock !== "floating" });
  });
});

document.querySelectorAll("[data-today-variant]").forEach((button) => {
  button.addEventListener("click", () => setTodayVariant(button.dataset.todayVariant));
});

document.querySelectorAll("[data-surface-mode]").forEach((button) => {
  button.addEventListener("click", () => setSurfaceMode(button.dataset.surfaceMode));
});

miniWindow.addEventListener("pointerenter", revealMiniDock);
miniWindow.addEventListener("pointerleave", queueMiniDockRetract);
miniWindow.addEventListener("focusin", revealMiniDock);
miniWindow.addEventListener("focusout", queueMiniDockRetract);
privacyEdgeTab.addEventListener("click", revealMiniDock);

document.querySelector("#open-workbench").addEventListener("click", () => showWindow("workbench"));
document.querySelector("#workbench-settings").addEventListener("click", () => showWindow("settings"));
document.querySelector("#workbench-close").addEventListener("click", () => showWindow("mini"));
document.querySelector("#settings-close").addEventListener("click", () => {
  if (state.dirty) {
    openDialog({
      title: "放弃未保存的更改？",
      message: "关闭设置不会修改当前配置，刚才的输入将被丢弃。",
      kind: "warning",
      confirm: "放弃更改",
      action: () => {
        state.dirty = false;
        revertThemeDraft();
        updateThemeControls(state.persistedTheme);
        revertEdgeAutoHideDraft({ syncControl: true });
        showWindow("mini");
      },
    });
    return;
  }
  showWindow(state.previousWindow === "settings" ? "mini" : state.previousWindow);
});
document.querySelector("#wizard-close").addEventListener("click", () => showWindow("mini"));
document.querySelector("#wizard-cancel").addEventListener("click", () => showWindow("mini"));
document.querySelector("#wizard-back").addEventListener("click", () => setWizardStep(state.wizardStep - 1));
document.querySelector("#wizard-next").addEventListener("click", () => {
  if (
    state.wizardStep === 1
    && document.querySelector('input[name="wizard-rest"]:checked')?.value === "alternate"
    && !document.querySelector('input[name="wizard-week-type"]:checked')
  ) {
    document.querySelector("#wizard-week-error").hidden = false;
    return;
  }
  if (state.wizardStep < 3) {
    setWizardStep(state.wizardStep + 1);
    return;
  }
  if (document.querySelector("#failure-mode").checked) {
    openDialog({
      title: "配置保存失败",
      message: "无法写入测试配置。输入仍保留在确认页，请检查数据目录权限后重试。",
      kind: "error",
      confirm: "知道了",
      cancel: "",
    });
    return;
  }
  showToast("首次配置已完成。");
  showWindow("mini");
});

document.querySelector("#workbench-hide").addEventListener("click", hideToTray);
document.querySelector("#tray-restore").addEventListener("click", () => showWindow(state.previousWindow));

document.querySelector("#business-state").addEventListener("change", (event) => {
  setBusinessState(event.target.value);
});
document.querySelector("#calendar-state").addEventListener("change", (event) => {
  const nextMode = event.target.value;
  if (nextMode === "estimated" && (state.calendarYear === 2025 || state.calendarYear === 2026)) {
    state.calendarYear = 2027;
    state.calendarMonth = 0;
    state.selectedDate = "2027-01-01";
  } else if (nextMode !== "estimated" && state.calendarYear !== 2025 && state.calendarYear !== 2026) {
    state.calendarYear = 2026;
    state.calendarMonth = 6;
    state.selectedDate = "2026-07-23";
  }
  setCalendarMode(nextMode);
});
document.querySelector("#long-content").addEventListener("change", (event) => {
  state.longContent = event.target.checked;
  document.body.classList.toggle("is-long", event.target.checked);
  setBusinessState(state.businessState);
});
themeModeControl.addEventListener("change", (event) => {
  const mode = normalizeTheme(event.target.value);
  state.persistedTheme = mode;
  window.localStorage.setItem("lmm-v102-prototype-theme", mode);
  applyTheme(mode);
});
dpiModeControl.addEventListener("change", (event) => {
  const dpi = ["100", "125", "150"].includes(event.target.value) ? event.target.value : "100";
  document.documentElement.dataset.dpi = dpi;
  document.querySelector(".desktop-label span:last-child").textContent =
    `${dpi}% DPI · 逻辑窗口尺寸保持不变`;
});

document.querySelectorAll(".nav-item[data-view]").forEach((button) => {
  button.addEventListener("click", () => {
    document.querySelectorAll(".nav-item[data-view]").forEach((item) => item.classList.toggle("is-active", item === button));
    document.querySelectorAll("[data-panel]").forEach((panel) => panel.classList.toggle("is-active", panel.dataset.panel === button.dataset.view));
  });
});
document.querySelector("#calendar-prev").addEventListener("click", () => moveCalendarMonth(-1));
document.querySelector("#calendar-next").addEventListener("click", () => moveCalendarMonth(1));
document.querySelector("#calendar-adjust").addEventListener("click", openCalendarOverride);
document.querySelector("#adjust-today").addEventListener("click", () => {
  state.calendarYear = 2026;
  state.calendarMonth = 6;
  state.selectedDate = state.businessState === "overnight" ? "2026-07-22" : state.naturalToday;
  setCalendarMode("official");
  showWindow("workbench");
  document.querySelectorAll(".nav-item[data-view]").forEach((item) => {
    item.classList.toggle("is-active", item.dataset.view === "calendar");
  });
  document.querySelectorAll("[data-panel]").forEach((panel) => {
    panel.classList.toggle("is-active", panel.dataset.panel === "calendar");
  });
  window.setTimeout(openCalendarOverride, 120);
});
document.querySelector("#calendar-retry").addEventListener("click", () => {
  document.querySelector("#calendar-state").value = "loading";
  setCalendarMode("loading");
  window.setTimeout(() => {
    const restoredMode = state.calendarYear === 2025 || state.calendarYear === 2026
      ? "official"
      : "estimated";
    document.querySelector("#calendar-state").value = restoredMode;
    setCalendarMode(restoredMode);
    showToast(restoredMode === "official"
      ? "官方日历已重新加载，上次成功数据已安全替换。"
      : "已恢复休息模式估算，现有配置保持不变。");
  }, 520);
});
document.querySelectorAll('input[name="override-kind"]').forEach((control) => {
  control.addEventListener("change", updateOverrideImpact);
});
document.querySelector("#override-close").addEventListener("click", closeCalendarOverride);
document.querySelector("#override-cancel").addEventListener("click", closeCalendarOverride);
document.querySelector("#override-apply").addEventListener("click", applyCalendarOverride);
document.querySelectorAll("[data-settings-panel]").forEach((button) => {
  button.addEventListener("click", () => showSettingsPanel(button.dataset.settingsPanel));
});
document.querySelectorAll('input[name="wizard-rest"], input[name="wizard-week-type"]').forEach((control) => {
  control.addEventListener("change", syncAlternatingWeekChoice);
});
document.querySelector("#rest-mode").addEventListener("change", syncSettingsWeekChoice);
document.querySelectorAll('input[name="settings-theme"]').forEach((control) => {
  control.addEventListener("change", () => {
    applyTheme(control.value);
    state.dirty = true;
    setFeedback("正在预览主题；保存后同步到全部窗口");
  });
});

edgeAutoHideControl.addEventListener("change", () => {
  applyEdgeAutoHidePreview(edgeAutoHideControl.checked, { syncControl: false });
  state.dirty = true;
  setFeedback(
    edgeAutoHideControl.checked
      ? "正在预览贴边自动隐藏；保存后生效"
      : "贴边自动隐藏已在预览中关闭；保存后清除停靠",
  );
});

document.querySelectorAll("#settings-form input, #settings-form select").forEach((control) => {
  control.addEventListener("input", () => {
    state.dirty = true;
    salaryError.hidden = true;
    setFeedback("有未保存的更改");
  });
});

document.querySelector("#reset-button").addEventListener("click", () => {
  openDialog({
    title: "恢复默认设置？",
    message: "这会重置当前表单。只有点击保存后，新值才会写入本机。",
    kind: "warning",
    confirm: "恢复默认",
    action: restoreDefaults,
  });
});

document.querySelector("#settings-form").addEventListener("submit", (event) => {
  event.preventDefault();
  if (state.saving) return;
  if (!salaryInput.value.trim() || Number(salaryInput.value.replaceAll(",", "")) <= 0) {
    salaryError.hidden = false;
    salaryInput.focus();
    showSettingsPanel("income");
    setFeedback("请先修正输入内容", "error");
    return;
  }
  if (!state.dirty) {
    setFeedback("没有需要保存的更改");
    showToast("配置没有变化。");
    return;
  }
  state.saving = true;
  saveButton.disabled = true;
  saveButton.textContent = "保存中…";
  setFeedback("正在保存…");
  window.setTimeout(() => {
    state.saving = false;
    saveButton.disabled = false;
    saveButton.textContent = "保存";
    if (document.querySelector("#failure-mode").checked) {
      revertThemeDraft("保存失败，全部窗口已恢复上次保存的主题；所选主题仍保留，可重试。");
      revertEdgeAutoHideDraft({ syncControl: false });
      setFeedback("保存失败：无法写入测试配置。输入已保留，请检查数据目录权限后重试。", "error");
      showToast("保存失败，输入已保留。", true);
      return;
    }
    commitTheme(document.querySelector('input[name="settings-theme"]:checked')?.value);
    commitEdgeAutoHide(edgeAutoHideControl.checked);
    state.dirty = false;
    setFeedback("已保存到本机", "success");
    showToast("设置已保存。");
  }, 650);
});

document.querySelector("#run-wizard").addEventListener("click", () => {
  setWizardStep(1);
  showWindow("wizard");
});
document.querySelector("#open-data-directory").addEventListener("click", () => showToast("已请求打开本地数据目录。"));
document.querySelector("#copy-diagnostics").addEventListener("click", () => showToast("诊断摘要已复制，敏感路径已脱敏。"));
document.querySelector("#check-update").addEventListener("click", () => {
  if (document.querySelector("#failure-mode").checked) {
    openDialog({
      title: "暂时无法检查更新",
      message: "网络请求失败。当前版本和配置不受影响，你可以稍后重试。",
      kind: "error",
      confirm: "稍后重试",
      cancel: "",
    });
    return;
  }
  openDialog({
    title: "已经是最新版本",
    message: "当前版本 v1.0.4，没有可用更新。",
    confirm: "完成",
    cancel: "",
  });
});

document.querySelector("#dialog-cancel").addEventListener("click", () => {
  state.dialogAction = null;
  productDialog.close();
});
document.querySelector("#dialog-confirm").addEventListener("click", () => {
  const action = state.dialogAction;
  state.dialogAction = null;
  productDialog.close();
  action?.();
});

state.persistedTheme = normalizeTheme(window.localStorage.getItem("lmm-v102-prototype-theme"));
applyTheme(state.persistedTheme);
state.persistedEdgeAutoHide = window.localStorage.getItem("lmm-v104-prototype-edge-hide") !== "false";
state.previewEdgeAutoHide = state.persistedEdgeAutoHide;
edgeAutoHideControl.checked = state.persistedEdgeAutoHide;
applyEdgeAutoHidePreview(state.persistedEdgeAutoHide);
document.documentElement.dataset.dpi = "100";
setCalendarMode("official");
setTodayVariant("corner");
setSurfaceMode("single");
setBusinessState("working_after_rest");
showSettingsPanel("income");
syncAlternatingWeekChoice();
syncSettingsWeekChoice();
setWizardStep(1);
showWindow("mini");
