const petLabels = { classic: "Classic Pro", duoduo: "多多" };
const stateCopy = {
  working: ["工作中", "工资按秒增长；环境动作低频触发，显式互动可以中断基础循环。"],
  awake_rest: ["清醒休息", "午休、下班后、周末或节假日；保持陪伴感，但避免持续高强度动作。"],
  sleeping: ["睡眠", "23:00-07:30 且工作时段未覆盖；关闭指针跟随，只保留轻量睡眠反馈。"]
};

const currentRoutes = {
  working: [
    route("基础循环", "working", "making-money", "existing", "现有直接映射"),
    route("点击", "clicked_single", "celebrating", "reusable", "三种状态共用"),
    route("长按 / 拖动", "legacy_drag", "eating", "reusable", "窗口移动与动画语义未连贯")
  ],
  awake_rest: [
    route("基础循环", "awake_rest", "eating", "reusable", "环境动作被当作基础状态"),
    route("点击", "clicked_single", "celebrating", "reusable", "与工作状态相同"),
    route("长按 / 拖动", "legacy_drag", "eating", "reusable", "与基础循环相同")
  ],
  sleeping: [
    route("基础循环", "sleeping", "sleeping", "existing", "现有直接映射"),
    route("点击", "clicked_single", "celebrating", "reusable", "会突然完全清醒"),
    route("长按 / 拖动", "legacy_drag", "eating", "reusable", "睡眠语义不自然")
  ]
};

const targetRoutes = {
  working: [
    route("基础循环", "working_loop", "making-money", "planned", "主动玩耍；用节奏表达工作状态，不使用办公道具"),
    route("环境 · 赚钱", "working_money_feedback", "making-money", "existing", "低频金币反馈，不再承担全部工作状态"),
    route("环境 · 伸展", "working_play_stretch", "eating", "planned", "玩耍间隙低频伸展"),
    route("指针 · 短暂看向", "working_brief_glance", "making-money", "planned", "短暂回应后继续工作"),
    route("单击", "working_ack", "celebrating", "planned", "停下玩耍、看向用户并轻拍回应"),
    route("跑动 · 准备", "run_prepare", "eating", "planned", "长按达到阈值后进入，不再触发点击"),
    route("跑动 · 左 / 右", "running_directional", "making-money", "planned", "指针直接驱动窗口，按水平移动方向翻转"),
    route("跑动 · 停稳", "run_settle", "eating", "planned", "释放后落脚，再解析最新基础状态"),
    route("事件 · 午休", "lunch_relief", "celebrating", "planned", "停止高能玩耍，伸展或翻滚后进入清醒休息"),
    route("事件 · 下班", "work_end_celebrate", "celebrating", "reusable", "完整玩耍庆祝；按工作日去重")
  ],
  awake_rest: [
    route("基础循环", "rest_breathe", "eating", "planned", "坐姿呼吸或尾巴微动"),
    route("环境 · 吃东西", "rest_eating", "eating", "existing", "60 秒以上冷却"),
    route("环境 · 观察", "rest_look_around", "eating", "planned", "根据指针方向轻转头"),
    route("环境 · 理毛", "rest_grooming", "eating", "planned", "低频长间隔动作"),
    route("环境 · 哈欠", "rest_yawn", "eating", "planned", "长间隔动作，不与事件争抢"),
    route("单击", "rest_ack", "celebrating", "planned", "抬爪或眨眼回应"),
    route("跑动 · 准备", "run_prepare", "eating", "planned", "长按达到阈值后进入"),
    route("跑动 · 左 / 右", "running_directional", "making-money", "planned", "跟随指针移动并稳定脚底线"),
    route("跑动 · 停稳", "run_settle", "eating", "planned", "释放后恢复最新状态"),
    route("事件 · 午休结束", "lunch_return", "celebrating", "planned", "起身伸展并进入玩耍准备姿势"),
    route("事件 · 首次出现", "first_show_wave", "celebrating", "planned", "当天首次启动或长时间隐藏后首次恢复")
  ],
  sleeping: [
    route("基础循环", "sleeping_loop", "sleeping", "existing", "持续睡眠，关闭指针跟随"),
    route("环境 · 翻身", "sleep_turn", "sleeping", "planned", "低频、低幅度、不完全醒来"),
    route("环境 · 梦泡", "dream_bubble", "sleeping", "planned", "纯视觉小变化，长冷却"),
    route("环境 · 蜷缩", "sleep_curl_up", "sleeping", "planned", "保持睡眠语义"),
    route("单击", "sleep_ear_twitch", "sleeping", "planned", "耳朵或尾巴轻动"),
    route("跑动 · 唤醒准备", "run_prepare", "eating", "planned", "长按达到阈值后自然醒来"),
    route("跑动 · 左 / 右", "running_directional", "making-money", "planned", "进入统一跑动合同"),
    route("跑动 · 停稳", "run_settle", "eating", "planned", "释放后重新计算是否继续睡眠")
  ]
};

function route(label, semantic, physical, status, note) {
  return { label, semantic, physical, status, note };
}

let selectedPet = "classic";
let selectedState = "working";
let selectedMode = "current";
let selectedIndex = 0;

const petSelector = document.getElementById("petSelector");
const modeSelector = document.getElementById("modeSelector");
const stateSelector = document.getElementById("stateSelector");
const actionList = document.getElementById("actionList");
const actionPreview = document.getElementById("actionPreview");
const previewPetLabel = document.getElementById("previewPetLabel");
const previewStatus = document.getElementById("previewStatus");
const semanticLabel = document.getElementById("semanticLabel");
const physicalLabel = document.getElementById("physicalLabel");
const proxyNote = document.getElementById("proxyNote");
const stateContext = document.getElementById("stateContext");

function currentRoutesForSelection() {
  return (selectedMode === "current" ? currentRoutes : targetRoutes)[selectedState];
}

function render() {
  const routes = currentRoutesForSelection();
  selectedIndex = Math.min(selectedIndex, routes.length - 1);
  const selected = routes[selectedIndex];
  const [stateTitle, stateDescription] = stateCopy[selectedState];
  stateContext.innerHTML = `<b>${stateTitle}</b><span>${stateDescription}</span>`;
  actionList.innerHTML = routes.map((item, index) => `
    <button class="action-card${index === selectedIndex ? " active" : ""}" data-index="${index}">
      <span><b>${item.label}</b><em class="${item.status}">${statusLabel(item.status)}</em></span>
      <small>${item.semantic} · ${item.note}</small>
    </button>`).join("");
  actionList.querySelectorAll(".action-card").forEach(button => button.addEventListener("click", () => {
    selectedIndex = Number(button.dataset.index);
    render();
  }));

  const cacheBust = Date.now();
  actionPreview.src = `assets/animation-plan/${selectedPet}/${selected.physical}.gif?v=${cacheBust}`;
  actionPreview.alt = `${petLabels[selectedPet]} ${selected.physical} 动画`;
  previewPetLabel.textContent = petLabels[selectedPet];
  previewStatus.textContent = statusLabel(selected.status);
  semanticLabel.textContent = selected.semantic;
  physicalLabel.textContent = selected.physical;
  proxyNote.hidden = selected.status !== "planned";
}

function statusLabel(status) {
  return { existing: "已有素材", reusable: "明确复用", planned: "待生成" }[status];
}

function bindSegmented(container, key, onChange) {
  container.querySelectorAll("button").forEach(button => button.addEventListener("click", () => {
    container.querySelectorAll("button").forEach(item => item.classList.toggle("active", item === button));
    onChange(button.dataset[key]);
  }));
}

bindSegmented(petSelector, "pet", value => { selectedPet = value; render(); });
bindSegmented(modeSelector, "mode", value => { selectedMode = value; selectedIndex = 0; render(); });
bindSegmented(stateSelector, "state", value => { selectedState = value; selectedIndex = 0; render(); });

function applyPlayFirstRevision() {
  const replacements = {
    "keyboard-work": "working_loop · active play",
    "desk-stretch": "play-stretch",
    "work-ack": "working_ack"
  };
  document.querySelectorAll(".matrix-band .tag").forEach(item => {
    const replacement = replacements[item.textContent.trim()];
    if (replacement) item.textContent = replacement;
  });

  const matrixNote = document.querySelector(".matrix-note");
  if (matrixNote) {
    matrixNote.textContent = "2026-07-21 修订：工作、午休和复工动画全部禁用电脑及办公道具；状态改由玩耍节奏、动作能量与姿态转换表达。Classic 先行，多多复用同一语义合同。";
  }

  const evidenceNote = document.querySelector(".evidence-note");
  if (evidenceNote) {
    evidenceNote.textContent = "当前图片是带电脑方向的历史问题证据，工程 QA 可复用，但视觉候选已淘汰。";
  }
}

applyPlayFirstRevision();
render();
