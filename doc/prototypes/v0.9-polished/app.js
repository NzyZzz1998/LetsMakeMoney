const screenMeta = {
  desktop: ["桌面陪伴", "让收入、安排和桌宠在桌面上形成一个安静、清晰的整体。"],
  today: ["今日详情", "从桌面便签进入完整的一天：收入、进度和安排放在同一条时间线上。"],
  wizard: ["首次配置", "渐进提问、自动推算；一次只让用户做一个清楚的决定。"],
  settings: ["偏好设置", "以任务组织配置，用同一套控件和事务反馈维护长期设置。"],
  pet: ["宠物外观", "先审核 Classic 与多多的展示层级、尺寸和切换体验；动画节奏与动作语义后续单独对齐。"],
  menu: ["菜单与找回", "桌宠菜单处理当下，托盘菜单承担找回、维护和退出。"]
};

const settingsData = {
  salary: {
    title: "工资设置", lead: "收入小票的计算来源。",
    html: `<section class="setting-section"><h3>基础收入</h3>
      <div class="setting-row"><label>月薪<small>按工作日折算日薪和时薪</small></label><input class="warm-input setting-control" value="10000" inputmode="decimal"></div>
      <div class="setting-row"><label>休息模式</label><select class="warm-select setting-control"><option>双休</option><option>单休</option><option>大小周</option></select></div>
    </section><section class="setting-section"><h3>计算结果</h3>
      <div class="setting-row"><label>每日工作时长</label><strong class="setting-control">8 小时</strong></div>
      <div class="setting-row"><label>当前日薪</label><strong class="setting-control">¥ 500.00</strong></div>
    </section>`
  },
  schedule: {
    title: "作息设置", lead: "从上班时间和午休时长推算完整工作日。",
    html: `<section class="setting-section"><h3>工作安排</h3>
      <div class="setting-row"><label>上班时间</label><input class="warm-input setting-control" type="time" value="08:00"></div>
      <div class="setting-row"><label>午休时长</label><select class="warm-select setting-control"><option>2 小时</option><option>1.5 小时</option><option>1 小时</option></select></div>
      <div class="setting-row"><label>午休开始</label><input class="warm-input setting-control" type="time" value="12:00"></div>
      <div class="setting-row"><label>推算下班时间</label><strong class="setting-control">18:00</strong></div>
    </section>`
  },
  pet: {
    title: "桌宠设置", lead: "选择伙伴，并调整不会破坏清晰度的显示参数。",
    html: `<section class="setting-section"><h3>当前伙伴</h3>
      <div class="setting-row"><label>宠物</label><select class="warm-select setting-control"><option>Classic Pro</option><option>多多</option></select></div>
      <div class="setting-row"><label>环境动作<small>在清醒休息时低频触发</small></label><button class="toggle on" aria-label="环境动作"><i></i></button></div>
      <div class="setting-row"><label>指针跟随</label><button class="toggle on" aria-label="指针跟随"><i></i></button></div>
    </section>`
  },
  display: {
    title: "显示设置", lead: "控制桌面挂件的大小、透明度与窗口行为。",
    html: `<section class="setting-section"><h3>视觉</h3>
      <div class="setting-row"><label>透明度</label><div class="slider-line setting-control"><input type="range" min="20" max="100" value="94"><b>94%</b></div></div>
      <div class="setting-row"><label>缩放</label><div class="slider-line setting-control"><input type="range" min="80" max="160" value="110"><b>110%</b></div></div>
      <div class="setting-row"><label>纯桌宠模式</label><button class="toggle" aria-label="纯桌宠模式"><i></i></button></div>
    </section>`
  },
  general: {
    title: "通用设置", lead: "维护启动、关闭和本地诊断路径。",
    html: `<section class="setting-section"><h3>应用行为</h3>
      <div class="setting-row"><label>开机自启</label><button class="toggle" aria-label="开机自启"><i></i></button></div>
      <div class="setting-row"><label>关闭时隐藏到托盘</label><button class="toggle on" aria-label="隐藏到托盘"><i></i></button></div>
    </section><section class="setting-section"><h3>维护</h3>
      <div class="setting-row"><label>数据与日志</label><button class="button secondary setting-control">打开数据目录</button></div>
    </section>`
  }
};

const wizardViews = [
  `<h2>你的月薪是多少？</h2><p>输入税前固定月薪，默认按工作日计算。</p><div class="field-stack">
    <label class="field-label">月薪<input class="warm-input" value="10000" inputmode="decimal"><span>聚焦时可直接输入整数</span></label>
    <div class="choice-grid" id="restChoices"><button class="active"><b>双休</b><small>每周休 2 天</small></button><button><b>单休</b><small>每周休 1 天</small></button><button><b>大小周</b><small>本周从大周开始</small></button></div>
  </div>`,
  `<h2>你几点开始工作？</h2><p>先确认上班时间，下一步再补充午休。</p><div class="field-stack">
    <label class="field-label">上班时间<input class="warm-input" type="time" value="08:00"><span>使用专用时间选择，不接受无效字符</span></label>
    <div class="inference-card"><span>标准工作时长<b>8 小时</b></span><span>预计下班<b>16:00（未计午休）</b></span></div>
  </div>`,
  `<h2>午休多久？</h2><p>午休开始默认 12:00，结束时间会随时长自动推算。</p><div class="field-stack">
    <label class="field-label">午休时长<select class="warm-select"><option>2 小时</option><option>1.5 小时</option><option>1 小时</option></select></label>
    <label class="field-label">午休开始<input class="warm-input" type="time" value="12:00"></label>
    <div class="inference-card"><span>午休结束<b>14:00</b></span><span>推算下班<b>18:00</b></span></div>
  </div>`,
  `<h2>确认你的工作节奏</h2><p>保存后立即用于今日收入和工作进度。</p><div class="field-stack">
    <div class="inference-card"><span>月薪<b>¥ 10,000</b></span><span>休息模式<b>双休</b></span><span>工作时间<b>08:00-18:00</b></span><span>午休<b>12:00-14:00</b></span></div>
    <div class="contract-note"><b>每天有效工作 8 小时</b><span>今日收益在工作时间内按秒计算，午休期间暂停增长。</span></div>
  </div>`
];

const menuData = {
  pet: `<button data-jump="today"><span>查看今日详情</span><small>¥ 186.42</small></button><button data-jump="pet"><span>互动动作</span><small>›</small></button><hr><button data-jump="settings"><span>偏好设置</span><small>Ctrl+,</small></button><button><span>隐藏桌宠</span></button>`,
  tray: `<button><span>显示 / 隐藏桌宠</span></button><button data-jump="today"><span>今日详情</span></button><button data-jump="settings"><span>偏好设置</span></button><hr><button><span>重新运行向导</span></button><button><span>退出 LetsMakeMoney</span></button>`
};

let wizardStep = 0;
let toastTimer;
let selectedPet = "classic";

const petPackages = {
  classic: {
    label: "Classic Pro",
    atlas: "assets/classic/extra-actions.webp",
    actions: {
      sleeping: { row: 0, frameCount: 8, durations: [240, 240, 240, 240, 240, 240, 240, 420] },
      eating: { row: 1, frameCount: 8, durations: [140, 140, 140, 140, 140, 140, 140, 260] },
      celebrating: { row: 2, frameCount: 8, durations: [120, 120, 120, 120, 120, 120, 120, 240] },
      "making-money": { row: 3, frameCount: 8, durations: [140, 140, 140, 140, 140, 140, 140, 260] }
    }
  },
  duoduo: {
    label: "多多",
    atlas: "assets/duoduo/extra-actions.webp",
    actions: {
      sleeping: { row: 0, frameCount: 8, durations: [240, 240, 240, 240, 240, 240, 240, 420] },
      eating: { row: 1, frameCount: 8, durations: [140, 140, 140, 140, 140, 140, 140, 260] },
      celebrating: { row: 2, frameCount: 8, durations: [120, 120, 120, 120, 120, 120, 120, 240] },
      "making-money": { row: 3, frameCount: 8, durations: [140, 140, 140, 140, 140, 140, 140, 260] }
    }
  }
};

const petActionMap = {
  working: { action: "making-money", loop: true, label: "making-money" },
  rest: { action: "eating", loop: true, label: "awake_rest · eating" },
  sleep: { action: "sleeping", loop: true, label: "sleeping" },
  single: { action: "celebrating", loop: false, label: "状态感知单击 · 素材待补" },
  run: { action: "making-money", loop: false, label: "长按拖拽跑动 · 素材待补" },
  event: { action: "celebrating", loop: false, label: "午休 / 下班事件" }
};

let desktopPetPlayer;
let previewPetPlayer;
let menuPetPlayer;
let currentBaseAction = "making-money";

class AtlasPetPlayer {
  constructor(canvas, petId = "classic") {
    this.canvas = canvas;
    this.ctx = canvas?.getContext("2d");
    this.petId = petId;
    this.image = new Image();
    this.frame = 0;
    this.actionName = "making-money";
    this.loop = true;
    this.timer = 0;
    this.loaded = false;
    this.loadPet(petId);
  }

  loadPet(petId) {
    if (!this.canvas || !this.ctx) return;
    window.clearTimeout(this.timer);
    this.petId = petId;
    this.frame = 0;
    this.loaded = false;
    this.image = new Image();
    this.image.onload = () => {
      this.loaded = true;
      this.play(this.actionName || "making-money", { loop: this.loop });
    };
    this.image.onerror = () => {
      this.ctx.clearRect(0, 0, this.canvas.width, this.canvas.height);
      this.ctx.fillStyle = "#fff8e9";
      this.ctx.fillRect(0, 0, this.canvas.width, this.canvas.height);
      this.ctx.fillStyle = "#7a5431";
      this.ctx.font = "26px sans-serif";
      this.ctx.textAlign = "center";
      this.ctx.fillText("动画资源未加载", this.canvas.width / 2, this.canvas.height / 2);
    };
    this.image.src = petPackages[petId].atlas;
  }

  play(actionName, options = {}) {
    if (!this.canvas || !this.ctx) return;
    window.clearTimeout(this.timer);
    this.actionName = actionName;
    this.loop = options.loop ?? true;
    this.restoreAction = options.restoreAction;
    this.speed = options.speed || 1;
    this.frame = 0;
    if (!this.loaded) return;
    this.drawFrame();
  }

  drawFrame() {
    const geometry = { cellWidth: 192, cellHeight: 208 };
    const action = petPackages[this.petId].actions[this.actionName] || petPackages[this.petId].actions["making-money"];
    const x = this.frame * geometry.cellWidth;
    const y = action.row * geometry.cellHeight;
    this.ctx.clearRect(0, 0, this.canvas.width, this.canvas.height);
    this.ctx.drawImage(this.image, x, y, geometry.cellWidth, geometry.cellHeight, 0, 0, this.canvas.width, this.canvas.height);

    const duration = Math.max(60, Math.round((action.durations[this.frame] || 140) * this.speed));
    this.frame += 1;

    if (this.frame >= action.frameCount) {
      if (this.loop) {
        this.frame = 0;
      } else if (this.restoreAction) {
        this.play(this.restoreAction, { loop: true });
        return;
      } else {
        this.frame = action.frameCount - 1;
        return;
      }
    }

    this.timer = window.setTimeout(() => this.drawFrame(), duration);
  }
}

function syncPetCanvases(petId = selectedPet) {
  [desktopPetPlayer, previewPetPlayer, menuPetPlayer].forEach(player => player?.loadPet(petId));
}

function previewPetAction(actionKey) {
  const mapped = petActionMap[actionKey] || petActionMap.working;
  const restoreAction = mapped.loop ? undefined : currentBaseAction;
  previewPetPlayer?.play(mapped.action, { loop: mapped.loop, restoreAction, speed: mapped.speed });
  document.getElementById("petStageLabel").textContent = `${petPackages[selectedPet].label} · ${mapped.label} · 8 帧`;
  document.getElementById("runtimeNote").textContent = `已接入 PetManager extra-actions.webp：${mapped.label} 使用真实 8 帧逐帧时长播放，非 CSS 假动作。`;
}

function showScreen(id) {
  document.querySelectorAll(".screen").forEach(el => el.classList.toggle("active", el.dataset.view === id));
  document.querySelectorAll(".flow-link").forEach(el => el.classList.toggle("active", el.dataset.screen === id));
  document.getElementById("screenTitle").textContent = screenMeta[id][0];
  document.getElementById("screenLead").textContent = screenMeta[id][1];
  window.scrollTo({ top: 0, behavior: "smooth" });
}

function showToast(message) {
  const toast = document.getElementById("toast");
  toast.textContent = message;
  toast.classList.add("show");
  clearTimeout(toastTimer);
  toastTimer = setTimeout(() => toast.classList.remove("show"), 2200);
}

function renderWizard() {
  document.getElementById("wizardContent").innerHTML = wizardViews[wizardStep];
  document.getElementById("wizardProgress").style.width = `${(wizardStep + 1) * 25}%`;
  document.querySelectorAll("#wizardSteps li").forEach((el, index) => el.classList.toggle("active", index === wizardStep));
  const back = document.getElementById("wizardBack");
  const next = document.getElementById("wizardNext");
  back.disabled = wizardStep === 0;
  next.textContent = wizardStep === wizardViews.length - 1 ? "完成配置" : "下一步";
  document.querySelectorAll("#restChoices button").forEach(button => button.addEventListener("click", () => {
    document.querySelectorAll("#restChoices button").forEach(item => item.classList.toggle("active", item === button));
  }));
}

function renderSettings(tab) {
  const data = settingsData[tab];
  document.getElementById("settingsTitle").textContent = data.title;
  document.getElementById("settingsLead").textContent = data.lead;
  document.getElementById("settingsContent").innerHTML = data.html;
  document.querySelectorAll(".toggle").forEach(toggle => toggle.addEventListener("click", () => toggle.classList.toggle("on")));
}

function renderMenu(kind) {
  const menu = document.getElementById("contextMenu");
  menu.innerHTML = menuData[kind];
  menu.querySelectorAll("[data-jump]").forEach(button => button.addEventListener("click", () => showScreen(button.dataset.jump)));
}

document.querySelectorAll(".flow-link").forEach(button => button.addEventListener("click", () => showScreen(button.dataset.screen)));
document.getElementById("openToday").addEventListener("click", () => showScreen("today"));
document.querySelectorAll(".close-demo").forEach(button => button.addEventListener("click", () => showScreen("desktop")));

document.getElementById("petWave").addEventListener("click", () => {
  const pet = document.getElementById("desktopPet");
  pet.classList.remove("play");
  requestAnimationFrame(() => pet.classList.add("play"));
  document.getElementById("petBubble").textContent = "收到，继续陪你一会儿";
  setTimeout(() => pet.classList.remove("play"), 650);
});

document.querySelectorAll("[data-desktop-state]").forEach(button => button.addEventListener("click", () => {
  document.querySelectorAll("[data-desktop-state]").forEach(item => item.classList.toggle("active", item === button));
  const resting = button.dataset.desktopState === "resting";
  document.getElementById("panelStatus").textContent = resting ? "午休中 · 14:00 继续工作" : "工作中 · 距午休 38 分钟";
  document.getElementById("petBubble").textContent = resting ? "先歇一会儿" : "今天也在认真积累";
  document.getElementById("panelProgress").style.width = resting ? "48%" : "56%";
}));

document.getElementById("wizardBack").addEventListener("click", () => { if (wizardStep > 0) { wizardStep -= 1; renderWizard(); } });
document.getElementById("wizardNext").addEventListener("click", () => {
  if (wizardStep < wizardViews.length - 1) { wizardStep += 1; renderWizard(); }
  else { showToast("配置已保存，今日收入已重新计算"); showScreen("desktop"); }
});

document.querySelectorAll("#settingsTabs [data-tab]").forEach(button => button.addEventListener("click", () => {
  document.querySelectorAll("#settingsTabs [data-tab]").forEach(item => item.classList.toggle("active", item === button));
  renderSettings(button.dataset.tab);
}));
document.getElementById("saveSettings").addEventListener("click", () => {
  document.getElementById("saveState").textContent = "已保存";
  document.getElementById("inlineFeedback").textContent = "设置已应用到桌宠与收入计算";
  showToast("设置已保存");
});
document.getElementById("resetSettings").addEventListener("click", () => {
  document.getElementById("inlineFeedback").textContent = "已恢复为推荐值，保存后生效";
  showToast("已恢复推荐设置");
});

document.querySelectorAll("#petChoice button").forEach(button => button.addEventListener("click", () => {
  document.querySelectorAll("#petChoice button").forEach(item => item.classList.toggle("active", item === button));
  selectedPet = button.dataset.pet;
  document.getElementById("petStageLabel").textContent = `${selectedPet === "classic" ? "Classic" : "多多"} · working`;
  showToast(selectedPet === "classic" ? "已选择 Classic Pro" : "已选择多多");
}));
document.querySelectorAll("#actionPalette button").forEach(button => button.addEventListener("click", () => {
  document.querySelectorAll("#actionPalette button").forEach(item => item.classList.toggle("active", item === button));
  const labels = { working: "working", rest: "awake_rest", sleep: "sleeping", single: "状态感知单击", run: "长按拖拽跑动", event: "午休 / 下班事件" };
  const preview = document.getElementById("petPreview");
  preview.classList.remove("play");
  requestAnimationFrame(() => preview.classList.add("play"));
  setTimeout(() => preview.classList.remove("play"), 650);
  document.getElementById("petStageLabel").textContent = `${selectedPet === "classic" ? "Classic" : "多多"} · ${labels[button.dataset.action]}`;
  const isProxy = button.dataset.action === "single" || button.dataset.action === "run";
  document.getElementById("runtimeNote").textContent = isProxy
    ? `动作请求：${labels[button.dataset.action]}。当前 GIF 仅用于节奏占位，等待 PetManager custom profile 产出后替换。`
    : `动作请求：${labels[button.dataset.action]}。播放完成后重新解析当前基础状态，不使用固定 1.55 秒恢复。`;
}));

document.querySelectorAll("#menuSwitcher button").forEach(button => button.addEventListener("click", () => {
  document.querySelectorAll("#menuSwitcher button").forEach(item => item.classList.toggle("active", item === button));
  renderMenu(button.dataset.menu);
}));

document.getElementById("motionToggle").addEventListener("click", event => {
  document.body.classList.toggle("reduce-motion");
  const reduced = document.body.classList.contains("reduce-motion");
  event.currentTarget.setAttribute("aria-pressed", String(reduced));
  showToast(reduced ? "已减少界面动效" : "已恢复轻量动效");
});

renderWizard();
renderSettings("salary");
renderMenu("pet");

desktopPetPlayer = new AtlasPetPlayer(document.getElementById("desktopPetCanvas"), "classic");
previewPetPlayer = new AtlasPetPlayer(document.getElementById("petPreviewCanvas"), "classic");
menuPetPlayer = new AtlasPetPlayer(document.getElementById("menuPetCanvas"), "classic");
desktopPetPlayer.play("making-money", { loop: true });
previewPetPlayer.play("making-money", { loop: true });
menuPetPlayer.play("making-money", { loop: true });

document.getElementById("petWave").addEventListener("click", () => {
  desktopPetPlayer?.play("celebrating", { loop: false, restoreAction: currentBaseAction });
});

document.querySelectorAll("[data-desktop-state]").forEach(button => button.addEventListener("click", () => {
  currentBaseAction = button.dataset.desktopState === "resting" ? "eating" : "making-money";
  desktopPetPlayer?.play(currentBaseAction, { loop: true });
  menuPetPlayer?.play(currentBaseAction, { loop: true });
}));

document.querySelectorAll("#petChoice button").forEach(button => button.addEventListener("click", () => {
  syncPetCanvases(button.dataset.pet);
  window.setTimeout(() => previewPetAction("working"), 0);
}));

document.querySelectorAll("#actionPalette button").forEach(button => button.addEventListener("click", () => {
  if (button.dataset.action === "working") currentBaseAction = "making-money";
  if (button.dataset.action === "rest") currentBaseAction = "eating";
  if (button.dataset.action === "sleep") currentBaseAction = "sleeping";
  previewPetAction(button.dataset.action);
}));
