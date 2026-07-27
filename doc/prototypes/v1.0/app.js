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
  calendarMode: "ready",
  selectedDate: "2026-07-23",
  calendarOverrides: new Map(),
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

function showWindow(name) {
  if (!windows[name]) return;
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
}

function hideToTray() {
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

function setBusinessState(value) {
  document.body.classList.toggle("is-lunch", value === "lunch");
  document.body.classList.toggle("is-offday", value === "offday");
  const values = {
    working: {
      status: "工作中",
      amount: "¥ 186.42",
      progress: "工作进度 56%",
      miniRemaining: "距离下班 4:38:20",
      remaining: "4:38:20",
      width: "56%",
    },
    lunch: {
      status: "午休中",
      amount: "¥ 250.00",
      progress: "工作进度 50%",
      miniRemaining: "距离复工 38:20",
      remaining: "38:20",
      width: "50%",
    },
    offday: {
      status: "休息日",
      amount: "¥ 0.00",
      progress: "今日无需工作",
      miniRemaining: "下个工作日 08:00",
      remaining: "明天 08:00",
      width: "0%",
    },
  }[value];

  document.querySelectorAll("[data-status]").forEach((node) => {
    node.textContent = values.status;
  });
  document.querySelectorAll("[data-amount]").forEach((node) => {
    node.textContent = values.amount;
  });
  document.querySelectorAll("[data-progress]").forEach((node) => {
    node.textContent = values.progress;
  });
  document.querySelectorAll("[data-remaining]").forEach((node) => {
    node.textContent = values.remaining;
  });
  document.querySelectorAll("[data-mini-remaining]").forEach((node) => {
    node.textContent = values.miniRemaining;
  });
  document.querySelectorAll(".progress-track > span").forEach((node) => {
    node.style.width = values.width;
  });
}

function formatDateKey(year, month, day) {
  return `${year}-${String(month + 1).padStart(2, "0")}-${String(day).padStart(2, "0")}`;
}

function getAutomaticDayKind(year, month, day) {
  const weekday = new Date(year, month, day).getDay();
  return weekday === 0 || weekday === 6 ? "restday" : "workday";
}

function updateCalendarStatus(mode) {
  state.calendarMode = mode;
  calendarStatus.className = `calendar-status is-${mode}`;
  calendarStatus.hidden = mode === "ready";
  const retryButton = document.querySelector("#calendar-retry");
  const adjustButton = document.querySelector("#calendar-adjust");
  adjustButton.disabled = ["loading", "error"].includes(mode);
  if (mode === "ready") {
    retryButton.hidden = true;
    return;
  }
  const statusCopy = {
    loading: ["正在加载日历", "当前页面保持稳定，完成后自动刷新"],
    stale: ["本次加载失败，正在使用上次成功数据", "旧日历仍可查看和调整；重试成功前不会覆盖"],
    error: ["日历暂时不可用", "没有可安全保留的旧数据，请重试"],
    unsupported: ["当前年份不在官方数据范围内", "仅支持 2025—2026；将按休息模式判断，不猜测节假日"],
  }[mode];
  calendarStatus.querySelector("span").textContent = statusCopy[0];
  calendarStatus.querySelector("small").textContent = statusCopy[1];
  retryButton.hidden = !["stale", "error"].includes(mode);
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
    if (dateKey === state.selectedDate) cell.classList.add("selected");
    cell.textContent = String(day);
    cell.type = "button";
    cell.setAttribute("aria-label", `${state.calendarYear} 年 ${state.calendarMonth + 1} 月 ${day} 日`);
    cell.addEventListener("click", () => {
      state.selectedDate = dateKey;
      buildCalendar();
    });
    root.append(cell);
  }

  if (state.calendarMode === "loading") root.classList.add("is-loading");
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
  setCalendarMode(supported ? "loading" : "unsupported");
  if (!supported) return;
  window.setTimeout(() => setCalendarMode("ready"), 420);
}

function openCalendarOverride() {
  if (state.calendarMode === "error" || state.calendarMode === "loading") {
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
    automaticKind === "restday"
      ? "当前来源：休息模式"
      : "当前来源：官方日历或休息模式";
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
  state.dirty = true;
  syncSettingsWeekChoice();
  setFeedback("已恢复默认值，保存后生效");
}

document.querySelectorAll("[data-window]").forEach((button) => {
  button.addEventListener("click", () => showWindow(button.dataset.window));
});

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
  if (nextMode === "unsupported" && (state.calendarYear === 2025 || state.calendarYear === 2026)) {
    state.calendarYear = 2027;
    state.calendarMonth = 0;
    state.selectedDate = "2027-01-01";
  } else if (nextMode !== "unsupported" && state.calendarYear !== 2025 && state.calendarYear !== 2026) {
    state.calendarYear = 2026;
    state.calendarMonth = 6;
    state.selectedDate = "2026-07-23";
  }
  setCalendarMode(nextMode);
});
document.querySelector("#long-content").addEventListener("change", (event) => {
  document.body.classList.toggle("is-long", event.target.checked);
  document.querySelectorAll("[data-amount]").forEach((node) => {
    node.textContent = event.target.checked ? "¥ 1,234,567,890.12" : "¥ 186.42";
  });
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
document.querySelector("#calendar-retry").addEventListener("click", () => {
  document.querySelector("#calendar-state").value = "loading";
  setCalendarMode("loading");
  window.setTimeout(() => {
    document.querySelector("#calendar-state").value = "ready";
    setCalendarMode("ready");
    showToast("日历已重新加载，上次成功数据已安全替换。");
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
      setFeedback("保存失败：无法写入测试配置。输入已保留，请检查数据目录权限后重试。", "error");
      showToast("保存失败，输入已保留。", true);
      return;
    }
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
    message: "当前版本 v1.0.1，没有可用更新。",
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

setCalendarMode("ready");
setBusinessState("working");
showSettingsPanel("income");
syncAlternatingWeekChoice();
syncSettingsWeekChoice();
setWizardStep(1);
showWindow("mini");
