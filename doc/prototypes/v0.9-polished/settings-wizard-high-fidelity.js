const byId = id => document.getElementById(id);
const all = selector => [...document.querySelectorAll(selector)];

const toast = byId('toast');
const toastText = toast.querySelector('span');
let toastTimer;
function showToast(message, isError = false) {
  toastText.textContent = message;
  toast.classList.toggle('error', isError);
  toast.classList.add('show');
  clearTimeout(toastTimer);
  toastTimer = setTimeout(() => toast.classList.remove('show'), 2400);
}

function activateView(view) {
  all('[data-view]').forEach(button => button.classList.toggle('active', button.dataset.view === view));
  all('[data-view-panel]').forEach(panel => panel.classList.toggle('active', panel.dataset.viewPanel === view));
  closePopovers();
}
all('[data-view]').forEach(button => button.addEventListener('click', () => activateView(button.dataset.view)));
byId('openSettingsFromPanel').addEventListener('click', () => activateView('settings'));
all('.window-close').forEach(button => button.addEventListener('click', () => activateView('desktop')));

const settingsMeta = {
  salary: ['工资设置', '设置收入计算的基础。'],
  schedule: ['作息设置', '配置上班、午休与下班。'],
  pet: ['桌宠设置', '选择伙伴与状态感知行为。'],
  display: ['显示设置', '调整桌面挂件的比例与窗口行为。'],
  general: ['通用设置', '管理启动、托盘与本地数据。']
};

all('[data-settings-tab]').forEach(button => button.addEventListener('click', () => {
  const key = button.dataset.settingsTab;
  all('[data-settings-tab]').forEach(item => {
    const active = item === button;
    item.classList.toggle('active', active);
    item.setAttribute('aria-selected', String(active));
  });
  all('[data-settings-page]').forEach(page => page.classList.toggle('active', page.dataset.settingsPage === key));
  byId('settingsTitle').textContent = settingsMeta[key][0];
  byId('settingsSubtitle').textContent = settingsMeta[key][1];
  closePopovers();
}));

let settingsDirty = false;
function setSettingsStatus(type, text) {
  const feedback = byId('settingsFeedback');
  const sync = byId('syncState');
  feedback.textContent = text;
  feedback.className = `feedback${type === 'success' ? ' success' : type === 'error' ? ' error' : ''}`;
  sync.className = `sync-state${type === 'dirty' ? ' dirty' : type === 'error' ? ' error' : ''}`;
  const syncText = type === 'dirty' ? '等待保存' : type === 'error' ? '保存失败' : '已同步';
  sync.innerHTML = `<svg class="icon"><use href="#${type === 'error' ? 'hf-alert' : 'hf-check'}"/></svg>${syncText}`;
}
function markDirty() {
  settingsDirty = true;
  setSettingsStatus('dirty', '有尚未保存的更改');
}

all('.dirty-control').forEach(control => {
  control.addEventListener('change', markDirty);
  if (control.matches('input')) control.addEventListener('input', markDirty);
});
byId('salaryInput').addEventListener('focus', event => {
  if (event.currentTarget.value === '10,000' || event.currentTarget.value === '0.00') event.currentTarget.select();
});
byId('salaryInput').addEventListener('blur', event => {
  const digits = event.currentTarget.value.replace(/[^0-9.]/g, '');
  const value = Number(digits || 0);
  event.currentTarget.value = value.toLocaleString('zh-CN', { maximumFractionDigits: 2 });
});

all('.toggle').forEach(toggle => toggle.addEventListener('click', () => {
  const next = !toggle.classList.contains('on');
  toggle.classList.toggle('on', next);
  toggle.setAttribute('aria-pressed', String(next));
  markDirty();
}));

all('input[type="range"]').forEach(range => {
  const output = byId(range.dataset.output);
  range.addEventListener('input', () => {
    output.textContent = `${range.value}%`;
    markDirty();
  });
});

function closePopovers(except = null) {
  all('[data-select-menu].open').forEach(menu => {
    if (menu !== except) menu.classList.remove('open');
  });
  all('[data-select-trigger][aria-expanded="true"]').forEach(trigger => {
    if (!except || trigger.dataset.selectTrigger !== except.dataset.selectMenu) trigger.setAttribute('aria-expanded', 'false');
  });
}
all('[data-select-trigger]').forEach(trigger => trigger.addEventListener('click', event => {
  event.stopPropagation();
  const menu = document.querySelector(`[data-select-menu="${trigger.dataset.selectTrigger}"]`);
  const opening = !menu.classList.contains('open');
  closePopovers(opening ? menu : null);
  menu.classList.toggle('open', opening);
  trigger.setAttribute('aria-expanded', String(opening));
}));
all('[data-select-menu] button').forEach(option => option.addEventListener('click', event => {
  event.stopPropagation();
  const menu = option.closest('[data-select-menu]');
  const trigger = document.querySelector(`[data-select-trigger="${menu.dataset.selectMenu}"]`);
  menu.querySelectorAll('button').forEach(item => item.classList.toggle('selected', item === option));
  trigger.querySelector('span').textContent = option.textContent;
  closePopovers();
  markDirty();
}));
document.addEventListener('click', () => closePopovers());
document.addEventListener('keydown', event => { if (event.key === 'Escape') closePopovers(); });

all('.time-button').forEach(button => button.addEventListener('click', () => {
  const value = button.querySelector('span');
  value.textContent = value.textContent === '08:00' ? '09:00' : value.textContent === '12:00' ? '12:30' : '08:00';
  markDirty();
  showToast('原型已切换时间；产品中将打开专用时间选择器');
}));

byId('saveSettings').addEventListener('click', () => {
  if (!settingsDirty) {
    setSettingsStatus('normal', '没有需要保存的更改');
    showToast('没有需要保存的更改');
    return;
  }
  if (byId('saveScenario').value === 'failure') {
    setSettingsStatus('error', '保存失败：配置文件暂时不可写，输入已保留');
    showToast('保存失败，输入已保留，请稍后重试', true);
    return;
  }
  settingsDirty = false;
  setSettingsStatus('success', '设置已保存并立即生效');
  showToast('设置已保存，窗口行为已更新');
});

const resetBackdrop = byId('confirmBackdrop');
byId('resetSettings').addEventListener('click', () => { resetBackdrop.hidden = false; });
byId('cancelReset').addEventListener('click', () => { resetBackdrop.hidden = true; });
byId('confirmReset').addEventListener('click', () => {
  resetBackdrop.hidden = true;
  byId('salaryInput').value = '10,000';
  all('input[type="range"]').forEach(range => {
    range.value = '100';
    byId(range.dataset.output).textContent = '100%';
  });
  all('.toggle').forEach(toggle => {
    const shouldBeOn = toggle.closest('[data-settings-page="general"]') && toggle.closest('.setting-row').textContent.includes('隐藏到托盘');
    toggle.classList.toggle('on', Boolean(shouldBeOn));
    toggle.setAttribute('aria-pressed', String(Boolean(shouldBeOn)));
  });
  markDirty();
  setSettingsStatus('dirty', '已恢复默认，保存后生效');
  showToast('默认值已恢复，等待保存');
});
resetBackdrop.addEventListener('click', event => { if (event.target === resetBackdrop) resetBackdrop.hidden = true; });
byId('rollbackPet').addEventListener('click', () => { markDirty(); showToast('已选择 v0.8 默认宠物，保存后生效'); });

const wizardState = {
  step: 0,
  salary: '10,000',
  rest: '双休',
  start: '08:00',
  lunchStart: '12:00',
  lunch: '2 小时'
};

function wizardField(label, value, icon = '', helper = '', controlClass = '') {
  const control = icon
    ? `<button class="time-button ${controlClass}" type="button"><span>${value}</span><svg class="icon"><use href="#${icon}"/></svg></button>`
    : `<input class="field wizard-salary" value="${value}" inputmode="decimal" aria-label="${label}">`;
  return `<div class="task-row"><div><strong>${label}</strong>${helper ? `<small>${helper}</small>` : ''}</div>${control}</div>`;
}

function minutesFromTime(value) {
  const [hours, minutes] = value.split(':').map(Number);
  return (hours * 60) + minutes;
}

function formatTime(totalMinutes) {
  const normalized = ((totalMinutes % 1440) + 1440) % 1440;
  const hours = Math.floor(normalized / 60);
  const minutes = normalized % 60;
  return `${String(hours).padStart(2, '0')}:${String(minutes).padStart(2, '0')}`;
}

function lunchDurationMinutes() {
  return wizardState.lunch === '1 小时' ? 60 : wizardState.lunch === '1.5 小时' ? 90 : 120;
}

function lunchEndTime() {
  return formatTime(minutesFromTime(wizardState.lunchStart) + lunchDurationMinutes());
}

function workEndTime() {
  return formatTime(minutesFromTime(wizardState.start) + 480 + lunchDurationMinutes());
}

function cycleWizardValue(current, values) {
  const index = values.indexOf(current);
  return values[(index + 1) % values.length];
}

const wizardViews = [
  () => `<h2>你的月薪是多少？</h2><p>先填写收入，再选择休息模式；工作时间会在下一步推算。</p><div class="task-block">${wizardField('月薪', wizardState.salary, '', '只用于本地收入计算')}<div class="task-row"><div><strong>休息模式</strong></div><button class="select-button wizard-rest" type="button"><span>${wizardState.rest}</span><svg class="icon"><use href="#hf-chevron-down"/></svg></button></div></div><div class="inference"><span>预计本月工作日</span><strong>23 天</strong></div>`,
  () => `<h2>几点开始工作？</h2><p>先确定上班时间，再按 8 小时有效工时推算完整安排。</p><div class="task-block">${wizardField('上班时间', wizardState.start, 'hf-clock', '使用本地时间', 'wizard-work-start')}</div><div class="inference"><span>预计下班时间</span><strong>${workEndTime()}</strong></div>`,
  () => `<h2>午休怎么安排？</h2><p>设置开始时间和时长，午休结束与下班时间会自动推算。</p><div class="task-block">${wizardField('午休开始', wizardState.lunchStart, 'hf-clock', '默认 12:00，可按实际安排调整', 'wizard-lunch-start')}${wizardField('午休时长', wizardState.lunch, 'hf-clock', '固定时长，结束时间自动联动', 'wizard-lunch-duration')}</div><div class="inference"><span>预计午休区间</span><strong>${wizardState.lunchStart}–${lunchEndTime()}</strong></div>`,
  () => `<h2>确认你的工作安排</h2><p>确认后开始计算；所有内容仍可在偏好设置中修改。</p><div class="confirmation-list"><div class="confirmation-row"><span>月薪与休息</span><strong>¥ ${wizardState.salary} · ${wizardState.rest}</strong></div><div class="confirmation-row"><span>工作时间</span><strong>${wizardState.start}–${workEndTime()}</strong></div><div class="confirmation-row"><span>午休</span><strong>${wizardState.lunchStart}–${lunchEndTime()}</strong></div><div class="confirmation-row"><span>每日有效工时</span><strong>8 小时</strong></div></div><div class="inference"><span>配置状态</span><strong>可以开始计算</strong></div>`
];

function renderWizard() {
  byId('wizardContent').innerHTML = wizardViews[wizardState.step]();
  all('#wizardSteps li').forEach((item, index) => {
    item.classList.toggle('active', index === wizardState.step);
    item.classList.toggle('complete', index < wizardState.step);
    item.querySelector('span').textContent = index < wizardState.step ? '✓' : String(index + 1);
  });
  byId('wizardCounter').textContent = `第 ${wizardState.step + 1} 步，共 4 步`;
  byId('wizardBack').disabled = wizardState.step === 0;
  byId('wizardNext').textContent = wizardState.step === 3 ? '完成' : '下一步';

  const salary = document.querySelector('.wizard-salary');
  if (salary) salary.addEventListener('input', () => { wizardState.salary = salary.value; });
  const rest = document.querySelector('.wizard-rest');
  if (rest) rest.addEventListener('click', () => {
    wizardState.rest = wizardState.rest === '双休' ? '大小周' : wizardState.rest === '大小周' ? '单休' : '双休';
    rest.querySelector('span').textContent = wizardState.rest;
  });
  const workStart = document.querySelector('.wizard-work-start');
  if (workStart) workStart.addEventListener('click', () => {
    wizardState.start = cycleWizardValue(wizardState.start, ['08:00', '08:30', '09:00']);
    renderWizard();
    showToast(`上班时间已调整为 ${wizardState.start}`);
  });
  const lunchStart = document.querySelector('.wizard-lunch-start');
  if (lunchStart) lunchStart.addEventListener('click', () => {
    wizardState.lunchStart = cycleWizardValue(wizardState.lunchStart, ['11:30', '12:00', '12:30', '13:00']);
    renderWizard();
    showToast(`午休开始已调整为 ${wizardState.lunchStart}`);
  });
  const lunchDuration = document.querySelector('.wizard-lunch-duration');
  if (lunchDuration) lunchDuration.addEventListener('click', () => {
    wizardState.lunch = cycleWizardValue(wizardState.lunch, ['1 小时', '1.5 小时', '2 小时']);
    renderWizard();
    showToast(`午休时长已调整为 ${wizardState.lunch}`);
  });
}

byId('wizardBack').addEventListener('click', () => {
  if (wizardState.step > 0) { wizardState.step -= 1; renderWizard(); }
});
byId('wizardNext').addEventListener('click', () => {
  if (wizardState.step < 3) { wizardState.step += 1; renderWizard(); return; }
  showToast('配置已保存，收入进度开始计算');
  setTimeout(() => activateView('desktop'), 700);
});
byId('wizardCancel').addEventListener('click', () => {
  showToast('已取消，原配置保持不变');
  setTimeout(() => activateView('desktop'), 500);
});

renderWizard();
