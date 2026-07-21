const PAGE_NAMES = [
  "00 Foundations & Components",
  "01 Windows v0.9 Product UI",
  "02 Animation Contract"
];

const COLORS = {
  canvas: "#E8E7E1",
  canvasDeep: "#DDE2DA",
  paper: "#FFFDFA",
  paperWarm: "#FBF5E9",
  paperStrong: "#F3E5CA",
  ink: "#302B26",
  muted: "#76695D",
  subtle: "#9B8F84",
  line: "#DED7D0",
  lineStrong: "#C9BDB2",
  coin: "#F2B43A",
  coinStrong: "#DF951E",
  coinSoft: "#FCE8B3",
  orange: "#E97832",
  mint: "#709B74",
  mintSoft: "#DFEADC",
  sageDeep: "#56765B",
  surfaceCool: "#F1F4EF",
  danger: "#A94F43",
  dangerSoft: "#F7E7E3",
  white: "#FFFFFF"
};

const TYPE = {
  display: { size: 36, line: 44, weight: "bold" },
  title: { size: 24, line: 32, weight: "bold" },
  heading: { size: 18, line: 26, weight: "semibold" },
  body: { size: 14, line: 22, weight: "regular" },
  label: { size: 13, line: 18, weight: "semibold" },
  caption: { size: 12, line: 18, weight: "regular" },
  numericLarge: { size: 34, line: 40, weight: "bold" },
  numericSmall: { size: 15, line: 20, weight: "semibold" }
};

let fonts;
let primitiveVars = {};
let semanticVars = {};
let images = {};

function postStatus(text) {
  figma.ui.postMessage({ type: "status", text });
}

function rgb(hex) {
  const value = hex.replace("#", "");
  return {
    r: parseInt(value.slice(0, 2), 16) / 255,
    g: parseInt(value.slice(2, 4), 16) / 255,
    b: parseInt(value.slice(4, 6), 16) / 255
  };
}

function solidColor(hex, opacity = 1) {
  return { type: "SOLID", color: rgb(hex), opacity };
}

function boundPaint(name, opacity = 1) {
  const variable = semanticVars[name] || primitiveVars[name];
  if (!variable) return solidColor(COLORS.ink, opacity);
  let paint = solidColor(COLORS.ink, opacity);
  paint = figma.variables.setBoundVariableForPaint(paint, "color", variable);
  paint.opacity = opacity;
  return paint;
}

function fill(node, name, opacity = 1) {
  node.fills = [boundPaint(name, opacity)];
}

function stroke(node, name = "border/subtle", width = 1) {
  node.strokes = [boundPaint(name)];
  node.strokeWeight = width;
  node.strokeAlign = "INSIDE";
}

function shadow(node, kind = "window") {
  node.effects = kind === "floating"
    ? [{
        type: "DROP_SHADOW",
        color: { r: 0.16, g: 0.12, b: 0.08, a: 0.18 },
        offset: { x: 0, y: 12 },
        radius: 28,
        spread: -8,
        visible: true,
        blendMode: "NORMAL"
      }]
    : [{
        type: "DROP_SHADOW",
        color: { r: 0.16, g: 0.12, b: 0.08, a: 0.12 },
        offset: { x: 0, y: 18 },
        radius: 48,
        spread: -12,
        visible: true,
        blendMode: "NORMAL"
      }];
}

function tag(node, key, phase) {
  node.setSharedPluginData("lmm", "key", key);
  node.setSharedPluginData("lmm", "phase", phase);
  node.setSharedPluginData("lmm", "builder", "v0.9-local-1");
  return node;
}

function rect(parent, name, x, y, width, height, options = {}) {
  const node = figma.createRectangle();
  node.name = name;
  node.resize(width, height);
  node.x = x;
  node.y = y;
  node.cornerRadius = options.radius || 0;
  if (options.fill) fill(node, options.fill, options.opacity === undefined ? 1 : options.opacity);
  else node.fills = [];
  if (options.stroke) stroke(node, options.stroke, options.strokeWidth || 1);
  if (options.shadow) shadow(node, options.shadow);
  parent.appendChild(node);
  return node;
}

function frame(parent, name, x, y, width, height, options = {}) {
  const node = figma.createFrame();
  node.name = name;
  node.resize(width, height);
  node.x = x;
  node.y = y;
  node.clipsContent = options.clip === undefined ? false : options.clip;
  node.cornerRadius = options.radius || 0;
  if (options.fill) fill(node, options.fill, options.opacity === undefined ? 1 : options.opacity);
  else node.fills = [];
  if (options.stroke) stroke(node, options.stroke, options.strokeWidth || 1);
  if (options.shadow) shadow(node, options.shadow);
  parent.appendChild(node);
  return node;
}

function autoFrame(parent, name, direction = "VERTICAL", gap = 0, padding = 0, options = {}) {
  const node = figma.createFrame();
  node.name = name;
  node.layoutMode = direction;
  node.primaryAxisSizingMode = "AUTO";
  node.counterAxisSizingMode = "AUTO";
  node.itemSpacing = gap;
  node.paddingTop = padding;
  node.paddingRight = padding;
  node.paddingBottom = padding;
  node.paddingLeft = padding;
  node.counterAxisAlignItems = options.align || "MIN";
  node.primaryAxisAlignItems = options.distribute || "MIN";
  node.clipsContent = false;
  node.cornerRadius = options.radius || 0;
  if (options.fill) fill(node, options.fill);
  else node.fills = [];
  if (options.stroke) stroke(node, options.stroke);
  if (options.shadow) shadow(node, options.shadow);
  parent.appendChild(node);
  return node;
}

function text(parent, value, x, y, kind = "body", color = "text/primary", width = null, options = {}) {
  const spec = TYPE[kind] || TYPE.body;
  const node = figma.createText();
  node.name = options.name || `Text / ${value.slice(0, 24)}`;
  node.fontName = fonts[spec.weight];
  node.fontSize = options.size || spec.size;
  node.lineHeight = { unit: "PIXELS", value: options.line || spec.line };
  node.letterSpacing = { unit: "PIXELS", value: 0 };
  node.characters = value;
  node.fills = [boundPaint(color)];
  node.textAlignHorizontal = options.align || "LEFT";
  node.textAlignVertical = options.verticalAlign || "TOP";
  if (width !== null) {
    node.textAutoResize = "HEIGHT";
    node.resize(width, options.height || spec.line);
  } else {
    node.textAutoResize = "WIDTH_AND_HEIGHT";
  }
  node.x = x;
  node.y = y;
  parent.appendChild(node);
  return node;
}

function line(parent, x, y, width, color = "border/subtle") {
  return rect(parent, "Divider", x, y, width, 1, { fill: color });
}

function button(parent, label, x, y, width = 104, style = "primary", state = "default") {
  const height = 38;
  const styles = {
    primary: { fill: "accent/default", stroke: "accent/strong", text: "text/primary" },
    secondary: { fill: "bg/window", stroke: "border/strong", text: "text/primary" },
    ghost: { fill: "bg/window", stroke: "border/subtle", text: "text/secondary" },
    danger: { fill: "status/danger-soft", stroke: "status/danger", text: "status/danger" }
  };
  const preset = styles[style] || styles.primary;
  const node = frame(parent, `Button / ${style} / ${state}`, x, y, width, height, {
    fill: state === "disabled" ? "surface/disabled" : preset.fill,
    stroke: preset.stroke,
    radius: 8
  });
  if (state === "hover") node.effects = [{
    type: "DROP_SHADOW",
    color: { r: 0.32, g: 0.21, b: 0.08, a: 0.16 },
    offset: { x: 0, y: 4 },
    radius: 10,
    spread: -4,
    visible: true,
    blendMode: "NORMAL"
  }];
  const labelColor = state === "disabled" ? "text/tertiary" : preset.text;
  text(node, label, 0, 9, "label", labelColor, width, { align: "CENTER", height: 20 });
  return node;
}

function iconButton(parent, glyph, x, y, size = 34, active = false) {
  const node = frame(parent, `Icon Button / ${glyph}`, x, y, size, size, {
    fill: active ? "surface/accent-soft" : "bg/window",
    stroke: active ? "accent/default" : "border/subtle",
    radius: size / 2
  });
  text(node, glyph, 0, Math.round((size - 18) / 2), "label", active ? "accent/strong" : "text/secondary", size, {
    align: "CENTER",
    height: 20,
    size: 14,
    line: 18
  });
  return node;
}

function chip(parent, label, x, y, tone = "neutral") {
  const width = Math.max(58, label.length * 14 + 20);
  const toneMap = {
    neutral: ["bg/window", "border/subtle", "text/secondary"],
    active: ["surface/accent-soft", "accent/default", "text/primary"],
    success: ["status/success-soft", "status/success", "status/success-strong"],
    danger: ["status/danger-soft", "status/danger", "status/danger"]
  };
  const [fillName, strokeName, textName] = toneMap[tone] || toneMap.neutral;
  const node = frame(parent, `Status Chip / ${tone}`, x, y, width, 26, {
    fill: fillName,
    stroke: strokeName,
    radius: 13
  });
  text(node, label, 0, 4, "caption", textName, width, { align: "CENTER", height: 18 });
  return node;
}

function input(parent, label, value, x, y, width = 180, state = "default", helper = "") {
  text(parent, label, x, y, "label", "text/primary");
  const border = state === "focus" ? "accent/default" : state === "error" ? "status/danger" : "border/subtle";
  const field = frame(parent, `Input / ${state}`, x, y + 24, width, 36, {
    fill: state === "disabled" ? "surface/disabled" : "bg/window",
    stroke: border,
    strokeWidth: state === "focus" ? 2 : 1,
    radius: 8
  });
  text(field, value, 12, 8, "body", state === "disabled" ? "text/tertiary" : "text/primary", width - 24, { height: 20 });
  if (helper) text(parent, helper, x, y + 66, "caption", state === "error" ? "status/danger" : "text/tertiary", width);
  return field;
}

function toggle(parent, x, y, on = false, disabled = false) {
  const node = frame(parent, `Toggle / ${on ? "On" : "Off"}${disabled ? " / Disabled" : ""}`, x, y, 40, 22, {
    fill: disabled ? "surface/disabled" : on ? "accent/default" : "border/strong",
    stroke: disabled ? "border/subtle" : on ? "accent/strong" : "border/strong",
    radius: 11
  });
  rect(node, "Thumb", on ? 19 : 2, 2, 18, 18, { fill: "bg/window", radius: 9, shadow: "floating" });
  return node;
}

function slider(parent, x, y, width, progress = 0.56) {
  rect(parent, "Slider / Track", x, y, width, 6, { fill: "surface/disabled", radius: 3 });
  rect(parent, "Slider / Fill", x, y, width * progress, 6, { fill: "accent/default", radius: 3 });
  rect(parent, "Slider / Thumb", x + width * progress - 8, y - 5, 16, 16, {
    fill: "bg/window",
    stroke: "accent/default",
    radius: 8,
    shadow: "floating"
  });
}

function segmented(parent, labels, selected, x, y, width, height = 40) {
  const node = frame(parent, "Segmented Control", x, y, width, height, {
    fill: "bg/subtle",
    stroke: "border/subtle",
    radius: 10
  });
  const itemWidth = width / labels.length;
  labels.forEach((label, index) => {
    if (index === selected) {
      rect(node, `Selected / ${label}`, index * itemWidth + 4, 4, itemWidth - 8, height - 8, {
        fill: "bg/window",
        stroke: "accent/default",
        radius: 8,
        shadow: "floating"
      });
    }
    text(node, label, index * itemWidth, 10, "label", index === selected ? "text/primary" : "text/secondary", itemWidth, {
      align: "CENTER",
      height: 20
    });
  });
  return node;
}

function imageRect(parent, image, name, x, y, width, height, scaleMode = "FIT", radius = 0) {
  const node = figma.createRectangle();
  node.name = name;
  node.resize(width, height);
  node.x = x;
  node.y = y;
  node.cornerRadius = radius;
  node.fills = [{ type: "IMAGE", imageHash: image.hash, scaleMode }];
  parent.appendChild(node);
  return node;
}

async function createVerifiedImage(base64Value, label) {
  const decoded = figma.base64Decode(base64Value);
  if (decoded.length < 24) throw new Error(`${label} 资源为空或损坏`);
  const pngSignature = [137, 80, 78, 71, 13, 10, 26, 10];
  for (let index = 0; index < pngSignature.length; index += 1) {
    if (decoded[index] !== pngSignature[index]) {
      throw new Error(`${label} 不是 Figma 兼容 PNG`);
    }
  }
  const image = figma.createImage(decoded);
  const stored = await image.getBytesAsync();
  if (stored.length !== decoded.length) {
    throw new Error(`${label} 写入 Figma 后字节长度不一致`);
  }
  return image;
}

function screenHeader(parent, titleValue, subtitleValue, x = 24, y = 20, width = 420) {
  text(parent, titleValue, x, y, "title", "text/primary");
  if (subtitleValue) text(parent, subtitleValue, x, y + 36, "caption", "text/secondary", width);
}

async function chooseFonts() {
  const available = await figma.listAvailableFontsAsync();
  const all = available.map((item) => item.fontName);
  const find = (families, styles) => {
    for (const family of families) {
      for (const style of styles) {
        const match = all.find((font) => font.family === family && font.style === style);
        if (match) return match;
      }
    }
    return all.find((font) => font.family === "Inter" && font.style === "Regular") || all[0];
  };
  const families = ["Noto Sans SC", "Microsoft YaHei UI", "Microsoft YaHei", "Inter"];
  fonts = {
    regular: find(families, ["Regular", "Normal"]),
    medium: find(families, ["Medium", "Regular", "Normal"]),
    semibold: find(families, ["SemiBold", "DemiBold", "Bold", "Medium", "Regular"]),
    bold: find(families, ["Bold", "SemiBold", "DemiBold", "Medium", "Regular"])
  };
  const unique = {};
  Object.values(fonts).forEach((font) => { unique[`${font.family}/${font.style}`] = font; });
  for (const font of Object.values(unique)) await figma.loadFontAsync(font);
}

async function preparePages() {
  await figma.loadAllPagesAsync();
  const existing = new Map(figma.root.children.map((page) => [page.name, page]));
  const pages = [];
  for (let index = 0; index < PAGE_NAMES.length; index += 1) {
    const name = PAGE_NAMES[index];
    let page = existing.get(name);
    if (!page && index === 0) {
      const blank = figma.root.children.find((candidate) => candidate.name === "Page 1" && candidate.children.length === 0);
      if (blank) page = blank;
    }
    if (!page) page = figma.createPage();
    page.name = name;
    await page.loadAsync();
    for (const child of [...page.children]) child.remove();
    tag(page, `page/${index}`, "structure");
    pages.push(page);
  }
  return pages;
}

async function resetStylesAndVariables() {
  const collections = await figma.variables.getLocalVariableCollectionsAsync();
  collections
    .filter((collection) => ["LMM Primitives", "LMM Semantic"].includes(collection.name))
    .forEach((collection) => collection.remove());

  const textStyles = await figma.getLocalTextStylesAsync();
  textStyles.filter((style) => style.name.startsWith("LMM/")).forEach((style) => style.remove());
  const effectStyles = await figma.getLocalEffectStylesAsync();
  effectStyles.filter((style) => style.name.startsWith("LMM/")).forEach((style) => style.remove());
}

function createVariable(collection, modeId, name, type, value, scopes, cssName) {
  const variable = figma.variables.createVariable(name, collection, type);
  variable.setValueForMode(modeId, value);
  variable.scopes = scopes;
  variable.setVariableCodeSyntax("WEB", `var(--${cssName})`);
  return variable;
}

function createAlias(collection, modeId, name, source, scopes, cssName) {
  const variable = figma.variables.createVariable(name, collection, source.resolvedType);
  variable.setValueForMode(modeId, figma.variables.createVariableAlias(source));
  variable.scopes = scopes;
  variable.setVariableCodeSyntax("WEB", `var(--${cssName})`);
  return variable;
}

async function createFoundations() {
  await resetStylesAndVariables();
  const primitives = figma.variables.createVariableCollection("LMM Primitives");
  primitives.hiddenFromPublishing = true;
  const primitiveMode = primitives.defaultModeId;

  const colorEntries = {
    "color/canvas": COLORS.canvas,
    "color/canvas-deep": COLORS.canvasDeep,
    "color/paper": COLORS.paper,
    "color/paper-warm": COLORS.paperWarm,
    "color/paper-strong": COLORS.paperStrong,
    "color/ink": COLORS.ink,
    "color/muted": COLORS.muted,
    "color/subtle": COLORS.subtle,
    "color/line": COLORS.line,
    "color/line-strong": COLORS.lineStrong,
    "color/coin": COLORS.coin,
    "color/coin-strong": COLORS.coinStrong,
    "color/coin-soft": COLORS.coinSoft,
    "color/orange": COLORS.orange,
    "color/mint": COLORS.mint,
    "color/mint-soft": COLORS.mintSoft,
    "color/sage-deep": COLORS.sageDeep,
    "color/surface-cool": COLORS.surfaceCool,
    "color/danger": COLORS.danger,
    "color/danger-soft": COLORS.dangerSoft,
    "color/white": COLORS.white
  };
  Object.entries(colorEntries).forEach(([name, value]) => {
    primitiveVars[name] = createVariable(
      primitives,
      primitiveMode,
      name,
      "COLOR",
      rgb(value),
      [],
      `lmm-${name.replaceAll("/", "-")}`
    );
  });

  [0, 2, 4, 8, 12, 16, 20, 24, 32, 40, 48].forEach((value) => {
    primitiveVars[`space/${value}`] = createVariable(
      primitives,
      primitiveMode,
      `space/${value}`,
      "FLOAT",
      value,
      [],
      `lmm-space-${value}`
    );
  });
  [0, 6, 8, 12, 16, 20, 24, 999].forEach((value) => {
    primitiveVars[`radius/${value}`] = createVariable(
      primitives,
      primitiveMode,
      `radius/${value}`,
      "FLOAT",
      value,
      [],
      `lmm-radius-${value}`
    );
  });

  const semantic = figma.variables.createVariableCollection("LMM Semantic");
  const semanticMode = semantic.defaultModeId;
  const aliases = {
    "bg/canvas": "color/canvas",
    "bg/window": "color/paper",
    "bg/subtle": "color/paper-warm",
    "surface/raised": "color/paper",
    "surface/accent-soft": "color/coin-soft",
    "surface/disabled": "color/surface-cool",
    "text/primary": "color/ink",
    "text/secondary": "color/muted",
    "text/tertiary": "color/subtle",
    "border/subtle": "color/line",
    "border/strong": "color/line-strong",
    "accent/default": "color/coin",
    "accent/strong": "color/coin-strong",
    "accent/warm": "color/orange",
    "status/success": "color/mint",
    "status/success-soft": "color/mint-soft",
    "status/success-strong": "color/sage-deep",
    "status/danger": "color/danger",
    "status/danger-soft": "color/danger-soft"
  };
  Object.entries(aliases).forEach(([name, source]) => {
    const isText = name.startsWith("text/");
    const isBorder = name.startsWith("border/");
    semanticVars[name] = createAlias(
      semantic,
      semanticMode,
      name,
      primitiveVars[source],
      isText ? ["TEXT_FILL"] : isBorder ? ["STROKE_COLOR"] : ["FRAME_FILL", "SHAPE_FILL"],
      `lmm-${name.replaceAll("/", "-")}`
    );
  });
  [4, 8, 12, 16, 20, 24, 32, 40].forEach((value) => {
    semanticVars[`spacing/${value}`] = createAlias(
      semantic,
      semanticMode,
      `spacing/${value}`,
      primitiveVars[`space/${value}`],
      ["GAP"],
      `lmm-spacing-${value}`
    );
  });
  [6, 8, 12, 16, 20, 24].forEach((value) => {
    semanticVars[`radius/${value}`] = createAlias(
      semantic,
      semanticMode,
      `radius/${value}`,
      primitiveVars[`radius/${value}`],
      ["CORNER_RADIUS"],
      `lmm-radius-${value}`
    );
  });

  const styleDefinitions = [
    ["Display", TYPE.display],
    ["Title", TYPE.title],
    ["Heading", TYPE.heading],
    ["Body", TYPE.body],
    ["Label", TYPE.label],
    ["Caption", TYPE.caption],
    ["Numeric Large", TYPE.numericLarge],
    ["Numeric Small", TYPE.numericSmall]
  ];
  styleDefinitions.forEach(([name, spec]) => {
    const style = figma.createTextStyle();
    style.name = `LMM/Type/${name}`;
    style.fontName = fonts[spec.weight];
    style.fontSize = spec.size;
    style.lineHeight = { unit: "PIXELS", value: spec.line };
    style.letterSpacing = { unit: "PIXELS", value: 0 };
    style.description = "LetsMakeMoney Warm Desktop typography";
  });

  const windowEffect = figma.createEffectStyle();
  windowEffect.name = "LMM/Effect/Window";
  windowEffect.effects = [{
    type: "DROP_SHADOW",
    color: { r: 0.16, g: 0.12, b: 0.08, a: 0.12 },
    offset: { x: 0, y: 18 },
    radius: 48,
    spread: -12,
    visible: true,
    blendMode: "NORMAL"
  }];
  const floatingEffect = figma.createEffectStyle();
  floatingEffect.name = "LMM/Effect/Floating";
  floatingEffect.effects = [{
    type: "DROP_SHADOW",
    color: { r: 0.16, g: 0.12, b: 0.08, a: 0.18 },
    offset: { x: 0, y: 8 },
    radius: 20,
    spread: -6,
    visible: true,
    blendMode: "NORMAL"
  }];

  return {
    primitiveCollection: primitives,
    semanticCollection: semantic,
    primitiveCount: Object.keys(primitiveVars).length,
    semanticCount: Object.keys(semanticVars).length
  };
}

function createComponentButton(parent, name, labelValue, style, state, x, y) {
  const component = figma.createComponent();
  component.name = name;
  component.description = "Warm Desktop compact command button";
  component.resize(112, 38);
  component.x = x;
  component.y = y;
  component.cornerRadius = 8;
  const styleMap = {
    primary: ["accent/default", "accent/strong", "text/primary"],
    secondary: ["bg/window", "border/strong", "text/primary"],
    ghost: ["bg/window", "border/subtle", "text/secondary"]
  };
  const [fillName, strokeName, textName] = styleMap[style];
  fill(component, state === "disabled" ? "surface/disabled" : fillName);
  stroke(component, strokeName);
  if (state === "hover") shadow(component, "floating");
  text(component, labelValue, 0, 9, "label", state === "disabled" ? "text/tertiary" : textName, 112, {
    align: "CENTER",
    height: 20,
    name: "Label"
  });
  tag(component, `component/button/${style}/${state}`, "components");
  parent.appendChild(component);
  return component;
}

function createComponentsDocumentation(parent, top) {
  text(parent, "核心组件", 56, top, "title", "text/primary");
  text(parent, "Warm Fluent Compact / 组件状态直接对应 Godot Theme 合同", 56, top + 38, "body", "text/secondary", 920);

  const section = frame(parent, "Component Inventory", 56, top + 88, 1328, 760, {
    fill: "bg/window",
    stroke: "border/subtle",
    radius: 20
  });

  text(section, "Button", 28, 28, "heading");
  const styles = ["primary", "secondary", "ghost"];
  const states = ["default", "hover", "pressed", "disabled"];
  styles.forEach((styleName, row) => {
    text(section, styleName, 28, 80 + row * 66, "caption", "text/secondary", 86);
    states.forEach((stateName, col) => {
      createComponentButton(
        section,
        `Button / Style=${styleName}, State=${stateName}`,
        stateName === "disabled" ? "不可用" : stateName === "pressed" ? "已按下" : "保存",
        styleName,
        stateName,
        120 + col * 138,
        70 + row * 66
      );
    });
  });

  text(section, "Input", 28, 292, "heading");
  input(section, "默认", "10,000", 28, 334, 188, "default");
  input(section, "焦点", "10,000", 236, 334, 188, "focus");
  input(section, "错误", "10,000", 444, 334, 188, "error", "请输入有效金额");
  input(section, "禁用", "8 小时", 652, 334, 188, "disabled");

  text(section, "Choice & Feedback", 28, 444, "heading");
  segmented(section, ["工资", "作息", "桌宠", "显示", "通用"], 0, 28, 488, 470, 40);
  toggle(section, 532, 497, false);
  toggle(section, 596, 497, true);
  toggle(section, 660, 497, true, true);
  chip(section, "工作中", 738, 494, "active");
  chip(section, "已保存", 828, 494, "success");
  chip(section, "保存失败", 918, 494, "danger");
  slider(section, 28, 586, 390, 0.56);
  text(section, "工作进度", 28, 604, "caption", "text/secondary");
  text(section, "56%", 378, 604, "caption", "text/primary", 40, { align: "RIGHT" });

  const notes = [
    "输入 / 选择器：36px",
    "命令按钮：38px",
    "设置行：48–52px",
    "圆角：8 / 12 / 20",
    "焦点：金币黄 2px",
    "禁用：仍保持可读"
  ];
  notes.forEach((note, index) => chip(section, note, 28 + (index % 3) * 210, 660 + Math.floor(index / 3) * 36, "neutral"));
}

function buildFoundationsPage(page) {
  const root = frame(page, "LMM Design System", 0, 0, 1440, 2140, { fill: "bg/canvas" });
  tag(root, "foundation/root", "foundations");
  const cover = frame(root, "Cover", 32, 32, 1376, 330, {
    fill: "bg/window",
    stroke: "border/subtle",
    radius: 24,
    shadow: "window"
  });
  chip(cover, "WINDOWS · v0.9", 56, 52, "active");
  text(cover, "LetsMakeMoney", 56, 102, "display", "text/primary");
  text(cover, "Warm Desktop Product UI & Animation Contract", 56, 152, "heading", "text/secondary");
  text(cover, "从桌面陪伴、收入进度到宠物状态机，统一成可实现、可验收的设计事实源。", 56, 210, "body", "text/secondary", 720);
  const coverStatus = frame(cover, "Design Status", 1020, 52, 300, 216, {
    fill: "bg/subtle",
    stroke: "border/subtle",
    radius: 16
  });
  text(coverStatus, "设计状态", 24, 24, "label");
  chip(coverStatus, "可编辑本地组件", 24, 62, "success");
  chip(coverStatus, "Starter 3 页结构", 24, 102, "neutral");
  chip(coverStatus, "Classic + 多多", 24, 142, "active");

  text(root, "颜色与层次", 56, 416, "title");
  text(root, "浅奶油画布、白纸窗口、深咖啡文字、金币状态和柔和绿色反馈。", 56, 454, "body", "text/secondary", 900);
  const swatches = [
    ["Canvas", "bg/canvas", "#E8E7E1"],
    ["Window", "bg/window", "#FFFDFA"],
    ["Warm", "bg/subtle", "#FBF5E9"],
    ["Ink", "text/primary", "#302B26"],
    ["Muted", "text/secondary", "#76695D"],
    ["Coin", "accent/default", "#F2B43A"],
    ["Orange", "accent/warm", "#E97832"],
    ["Mint", "status/success", "#709B74"],
    ["Danger", "status/danger", "#A94F43"]
  ];
  swatches.forEach(([label, token, hex], index) => {
    const x = 56 + (index % 5) * 254;
    const y = 510 + Math.floor(index / 5) * 150;
    const card = frame(root, `Swatch / ${label}`, x, y, 226, 124, {
      fill: "bg/window",
      stroke: "border/subtle",
      radius: 12
    });
    rect(card, "Color", 12, 12, 64, 100, { fill: token, radius: 8 });
    text(card, label, 90, 22, "label");
    text(card, token, 90, 50, "caption", "text/secondary", 124);
    text(card, hex, 90, 80, "caption", "text/tertiary");
  });

  text(root, "字体与数字", 56, 826, "title");
  const typePanel = frame(root, "Typography", 56, 874, 1328, 330, {
    fill: "bg/window",
    stroke: "border/subtle",
    radius: 20
  });
  text(typePanel, "今日已赚", 28, 30, "caption", "text/secondary");
  text(typePanel, "¥ 186.42", 28, 58, "numericLarge");
  text(typePanel, "收入进度", 28, 118, "title");
  text(typePanel, "保持普通信息克制，把强调留给金额、状态与明确命令。", 28, 160, "body", "text/secondary", 570);
  text(typePanel, "Display 36 / 44", 760, 30, "display");
  text(typePanel, "Title 24 / 32", 760, 90, "title");
  text(typePanel, "Heading 18 / 26", 760, 140, "heading");
  text(typePanel, "Body 14 / 22 · Label 13 / 18 · Caption 12 / 18", 760, 190, "body", "text/secondary", 500);
  text(typePanel, `中文：${fonts.regular.family} · 数字同族等宽特性`, 760, 242, "caption", "text/tertiary", 500);

  createComponentsDocumentation(root, 1250);
  return root;
}

function board(parent, titleValue, subtitleValue, x, y, width, height) {
  const node = frame(parent, `Board / ${titleValue}`, x, y, width, height, {
    fill: "bg/subtle",
    stroke: "border/subtle",
    radius: 24
  });
  text(node, titleValue, 24, 22, "heading");
  text(node, subtitleValue, 24, 52, "caption", "text/secondary", width - 48);
  return node;
}

function productWindow(parent, titleValue, x, y, width, height) {
  const node = frame(parent, `Window / ${titleValue}`, x, y, width, height, {
    fill: "bg/window",
    stroke: "border/subtle",
    radius: 20,
    shadow: "window",
    clip: true
  });
  rect(node, "Title Bar", 0, 0, width, 54, { fill: "bg/window" });
  line(node, 0, 53, width);
  chip(node, titleValue, 18, 14, "neutral");
  iconButton(node, "×", width - 48, 11, 32, false);
  return node;
}

function drawDesktopCompanion(parent, x, y) {
  const desktop = frame(parent, "Desktop Companion", x, y, 700, 500, { fill: "surface/disabled", radius: 16, clip: true });
  rect(desktop, "Desktop Wallpaper", 0, 0, 700, 500, { fill: "bg/canvas" });
  text(desktop, "DESKTOP", 24, 22, "caption", "text/tertiary");
  const panel = frame(desktop, "Income Panel", 340, 126, 314, 88, {
    fill: "bg/window",
    stroke: "border/subtle",
    radius: 18,
    shadow: "floating"
  });
  rect(panel, "Coin", 18, 18, 52, 52, { fill: "accent/default", radius: 26 });
  text(panel, "¥", 18, 31, "heading", "text/primary", 52, { align: "CENTER" });
  text(panel, "¥ 186.42", 86, 15, "numericSmall");
  text(panel, "工作中 · 距离午休 38 分钟", 86, 46, "caption", "text/secondary", 202);
  slider(panel, 86, 69, 202, 0.56);
  imageRect(desktop, images.classicWorking, "Classic Pro / Working", 48, 158, 280, 236, "FIT");
  chip(desktop, "长按拖动 · 左右跑动反馈", 52, 412, "active");
  const taskbar = frame(desktop, "Taskbar", 0, 462, 700, 38, { fill: "text/primary", opacity: 0.92 });
  text(taskbar, "开始", 18, 10, "caption", "bg/window");
  text(taskbar, "普通模式显示任务栏入口 · 纯桌宠模式隐藏", 378, 10, "caption", "bg/window", 300, { align: "RIGHT" });
  return desktop;
}

function drawTodayWindow(parent, x, y) {
  const win = productWindow(parent, "今日详情", x, y, 500, 700);
  chip(win, "工作中", 28, 82, "active");
  text(win, "今日已赚", 28, 126, "body", "text/secondary");
  text(win, "¥ 186.42", 28, 154, "numericLarge");
  text(win, "日薪 ¥ 500.00 · 时薪 ¥ 62.50", 28, 202, "caption", "text/secondary");
  slider(win, 28, 238, 444, 0.56);
  text(win, "工作进度", 28, 256, "caption", "text/secondary");
  text(win, "56%", 426, 256, "caption", "text/primary", 46, { align: "RIGHT" });
  line(win, 28, 292, 444);
  text(win, "今天", 28, 316, "caption", "accent/warm");
  text(win, "今日安排", 28, 344, "heading");
  text(win, "调整今天", 370, 346, "label", "accent/warm", 102, { align: "RIGHT" });
  rect(win, "Timeline", 80, 394, 2, 154, { fill: "border/subtle", radius: 1 });
  const rows = [
    ["08:00", "开始工作", "已完成 3 小时 22 分钟", "status/success"],
    ["12:00", "午休", "12:00–14:00", "accent/default"],
    ["18:00", "结束工作", "预计今日收入 ¥ 500.00", "border/strong"]
  ];
  rows.forEach(([timeValue, titleValue, helper, tone], index) => {
    const rowY = 386 + index * 76;
    text(win, timeValue, 28, rowY, "caption", "text/secondary", 44);
    rect(win, "Timeline Dot", 73, rowY + 4, 16, 16, { fill: tone, stroke: "bg/window", strokeWidth: 4, radius: 8 });
    text(win, titleValue, 108, rowY - 2, "heading");
    text(win, helper, 108, rowY + 26, "caption", "text/secondary", 330);
  });
  const stats = frame(win, "Monthly Stats", 28, 592, 444, 78, { fill: "bg/subtle", stroke: "border/subtle", radius: 12 });
  const statValues = [["本月累计", "¥ 3,842.00"], ["本月工作日", "23 天"], ["距离下班", "4:38:20"]];
  statValues.forEach(([label, value], index) => {
    const sx = 18 + index * 144;
    if (index > 0) rect(stats, "Stat Divider", sx - 12, 16, 1, 46, { fill: "border/subtle" });
    text(stats, label, sx, 14, "caption", "text/secondary");
    text(stats, value, sx, 42, "numericSmall");
  });
  return win;
}

function drawWizard(parent, x, y) {
  const win = frame(parent, "Wizard", x, y, 760, 560, {
    fill: "bg/window",
    stroke: "border/subtle",
    radius: 20,
    shadow: "window",
    clip: true
  });
  const side = frame(win, "Wizard Progress", 0, 0, 224, 560, { fill: "bg/subtle" });
  text(side, "开始配置", 28, 28, "title");
  text(side, "四步完成收入进度", 28, 66, "caption", "text/secondary", 160);
  const steps = ["收入与休息", "工作与午休", "桌宠伙伴", "确认配置"];
  steps.forEach((step, index) => {
    rect(side, `Step ${index + 1}`, 28, 118 + index * 70, 30, 30, {
      fill: index <= 1 ? "accent/default" : "bg/window",
      stroke: index <= 1 ? "accent/strong" : "border/subtle",
      radius: 15
    });
    text(side, String(index + 1), 28, 124 + index * 70, "label", "text/primary", 30, { align: "CENTER" });
    text(side, step, 72, 123 + index * 70, "body", index === 1 ? "text/primary" : "text/secondary");
  });
  text(win, "几点开始工作？", 260, 42, "title");
  text(win, "先确定上班时间，再按 8 小时工作制推算完整安排。", 260, 82, "body", "text/secondary", 444);
  const question = frame(win, "Progressive Question", 260, 132, 444, 116, { fill: "bg/subtle", stroke: "border/subtle", radius: 16 });
  text(question, "上班时间", 20, 18, "label");
  input(question, "", "08:00", 20, 40, 152, "focus");
  chip(question, "专用时间选择器", 204, 58, "active");
  const reveal = frame(win, "Derived Schedule", 260, 268, 444, 176, { fill: "bg/window", stroke: "border/subtle", radius: 16 });
  text(reveal, "自动推算", 20, 18, "label", "status/success-strong");
  const schedule = [["午休时长", "2 小时"], ["午休区间", "12:00–14:00"], ["下班时间", "18:00"], ["有效工时", "8 小时"]];
  schedule.forEach(([label, value], index) => {
    const ry = 52 + index * 30;
    text(reveal, label, 20, ry, "body", "text/secondary");
    text(reveal, value, 260, ry, "body", "text/primary", 150, { align: "RIGHT" });
  });
  button(win, "上一步", 486, 492, 98, "secondary");
  button(win, "下一步", 598, 492, 106, "primary");
  return win;
}

function drawSettings(parent, x, y) {
  const win = frame(parent, "Settings", x, y, 720, 540, {
    fill: "bg/window",
    stroke: "border/subtle",
    radius: 20,
    shadow: "window",
    clip: true
  });
  segmented(win, ["工资", "作息", "桌宠", "显示", "通用"], 1, 24, 18, 480, 40);
  iconButton(win, "×", 666, 20, 32);
  line(win, 0, 72, 720);
  text(win, "作息设置", 28, 96, "title");
  text(win, "明确工作时段，自动计算午休、有效工时和今日进度。", 28, 134, "caption", "text/secondary", 560);
  text(win, "工作安排", 28, 178, "label", "text/secondary");
  const settingsRows = [
    ["上班时间", "08:00"],
    ["午休时长", "2 小时"],
    ["午休开始", "12:00"],
    ["下班时间", "18:00"]
  ];
  settingsRows.forEach(([label, value], index) => {
    const ry = 208 + index * 52;
    text(win, label, 28, ry + 14, "body");
    const field = frame(win, `Setting Control / ${label}`, 540, ry + 8, 132, 36, { fill: "bg/window", stroke: "border/subtle", radius: 8 });
    text(field, value, 12, 8, "body", "text/primary", 108, { align: "RIGHT", height: 20 });
    if (index < settingsRows.length - 1) line(win, 28, ry + 51, 644);
  });
  const info = frame(win, "Calculated Result", 28, 430, 644, 44, { fill: "status/success-soft", radius: 8 });
  text(info, "自动计算：每日有效工作 8 小时", 14, 11, "caption", "status/success-strong", 420);
  line(win, 0, 490, 720);
  button(win, "取消", 472, 502, 96, "secondary");
  button(win, "保存", 580, 502, 92, "primary");
  return win;
}

function drawPetStudio(parent, x, y) {
  const win = frame(parent, "Pet Studio", x, y, 900, 600, {
    fill: "bg/window",
    stroke: "border/subtle",
    radius: 20,
    shadow: "window",
    clip: true
  });
  const sidebar = frame(win, "Pet Navigation", 0, 0, 240, 600, { fill: "bg/subtle" });
  text(sidebar, "宠物外观", 24, 28, "title");
  text(sidebar, "选择伙伴与动作预览", 24, 66, "caption", "text/secondary", 180);
  const pets = [["Classic Pro", true], ["多多", false], ["v0.8 回退宠物", false]];
  pets.forEach(([label, active], index) => {
    const rowY = 116 + index * 58;
    if (active) rect(sidebar, `Pet Selected / ${label}`, 16, rowY, 208, 44, { fill: "surface/accent-soft", stroke: "accent/default", radius: 10 });
    text(sidebar, label, 30, rowY + 12, "body", active ? "text/primary" : "text/secondary");
  });
  text(win, "Classic Pro", 276, 32, "title");
  chip(win, "默认候选", 742, 30, "active");
  const preview = frame(win, "Pet Preview", 276, 92, 588, 274, { fill: "surface/disabled", stroke: "border/subtle", radius: 16 });
  imageRect(preview, images.classicSleeping, "Classic Pro / Sleeping", 130, 22, 328, 218, "FIT");
  chip(preview, "sleeping", 24, 224, "neutral");
  chip(preview, "脚底线稳定", 112, 224, "success");
  text(win, "状态预览", 276, 398, "label", "text/secondary");
  const stateCards = [
    ["working", images.classicWorking],
    ["awake_rest", images.classicSleeping],
    ["sleeping", images.classicSleeping]
  ];
  stateCards.forEach(([label, image], index) => {
    const sx = 276 + index * 194;
    const card = frame(win, `Pet State / ${label}`, sx, 430, 178, 116, { fill: "bg/subtle", stroke: "border/subtle", radius: 12 });
    imageRect(card, image, label, 8, 8, 74, 74, "FIT", 8);
    text(card, label, 92, 24, "caption", "text/primary", 78);
    text(card, index === 0 ? "工作循环" : index === 1 ? "清醒休息" : "夜间睡眠", 92, 52, "caption", "text/secondary", 78);
  });
  return win;
}

function drawMenus(parent, x, y) {
  const area = frame(parent, "Menus and Recovery", x, y, 720, 520, { fill: "surface/disabled", radius: 16 });
  text(area, "菜单职责分层", 28, 24, "heading");
  text(area, "桌宠右键处理高频动作，托盘负责找回与生命周期。", 28, 54, "caption", "text/secondary", 560);
  const menu = frame(area, "Pet Context Menu", 40, 112, 236, 308, { fill: "bg/window", stroke: "border/subtle", radius: 12, shadow: "floating" });
  text(menu, "桌宠菜单", 16, 16, "label");
  line(menu, 12, 48, 212);
  const menuItems = ["今日详情", "收入面板", "偏好设置", "重新配置", "纯桌宠模式", "退出"];
  menuItems.forEach((label, index) => {
    const iy = 60 + index * 39;
    if (index === 0) rect(menu, "Hover", 8, iy - 4, 220, 34, { fill: "surface/accent-soft", radius: 8 });
    text(menu, label, 18, iy + 2, "body", index === 5 ? "status/danger" : "text/primary");
    if (label === "纯桌宠模式") toggle(menu, 176, iy + 1, true);
  });
  const tray = frame(area, "Tray Menu", 340, 112, 330, 258, { fill: "bg/window", stroke: "border/subtle", radius: 12, shadow: "floating" });
  text(tray, "托盘菜单", 18, 16, "label");
  line(tray, 12, 48, 306);
  const trayItems = [["显示 / 隐藏窗口", "左键"], ["偏好设置", ""], ["重新配置", ""], ["打开数据目录", ""], ["退出 LetsMakeMoney", ""]];
  trayItems.forEach(([label, hint], index) => {
    const iy = 62 + index * 38;
    text(tray, label, 18, iy, "body", index === trayItems.length - 1 ? "status/danger" : "text/primary");
    if (hint) chip(tray, hint, 248, iy - 4, "neutral");
  });
  const recovery = frame(area, "Recovery Contract", 340, 392, 330, 88, { fill: "status/success-soft", stroke: "status/success", radius: 12 });
  text(recovery, "窗口找回合同", 16, 14, "label", "status/success-strong");
  text(recovery, "普通模式恢复任务栏入口；纯桌宠模式只恢复桌宠。", 16, 42, "caption", "status/success-strong", 298);
  return area;
}

function buildProductPage(page) {
  const root = frame(page, "Windows v0.9 Product UI", 0, 0, 2920, 1900, { fill: "bg/canvas" });
  tag(root, "product/root", "product-ui");
  text(root, "Windows v0.9 产品链路", 44, 40, "display");
  text(root, "保留 Windows 桌宠特色，同时把收入、配置与维护体验收敛到同一套 Warm Desktop 语言。", 44, 94, "body", "text/secondary", 1100);
  chip(root, "六条真实链路", 2520, 46, "active");
  chip(root, "100 / 125 / 150% DPI", 2656, 46, "success");

  const b1 = board(root, "01 桌面陪伴", "桌宠、收入 Panel、任务栏策略", 44, 156, 760, 620);
  drawDesktopCompanion(b1, 30, 94);
  const b2 = board(root, "02 今日详情", "金额、进度、今日安排和月度摘要", 836, 156, 568, 850);
  drawTodayWindow(b2, 34, 100);
  const b3 = board(root, "03 首次配置", "按问题逐步展开，不先抛出完整表单", 1436, 156, 824, 700);
  drawWizard(b3, 32, 102);
  const b4 = board(root, "04 偏好设置", "任务化页面与统一反馈", 44, 1040, 784, 680);
  drawSettings(b4, 32, 100);
  const b5 = board(root, "05 宠物外观", "Classic 默认候选、多多正式可选、v0.8 回退", 860, 1040, 964, 760);
  drawPetStudio(b5, 32, 100);
  const b6 = board(root, "06 菜单与找回", "右键菜单高频操作，托盘承担可靠找回", 1856, 1040, 796, 650);
  drawMenus(b6, 38, 98);
  return root;
}

function stateCard(parent, name, titleValue, description, x, y, tone) {
  const node = frame(parent, name, x, y, 310, 174, { fill: "bg/window", stroke: tone, radius: 16 });
  chip(node, name.replace("State / ", ""), 20, 20, tone === "accent/default" ? "active" : tone === "status/success" ? "success" : "neutral");
  text(node, titleValue, 20, 62, "heading");
  text(node, description, 20, 98, "caption", "text/secondary", 270);
  return node;
}

function flowArrow(parent, x, y, width, labelValue) {
  rect(parent, "Flow Line", x, y + 13, width, 2, { fill: "border/strong", radius: 1 });
  text(parent, "›", x + width - 12, y, "heading", "text/secondary");
  text(parent, labelValue, x, y + 26, "caption", "text/tertiary", width, { align: "CENTER" });
}

function buildAnimationPage(page) {
  const root = frame(page, "Animation Contract", 0, 0, 1840, 2360, { fill: "bg/canvas" });
  tag(root, "animation/root", "animation");
  text(root, "动画 1 对多合同", 44, 40, "display");
  text(root, "同一套状态机消费 Classic 与多多资源；动作语义、输入仲裁和回退不按 pet_id 特判。", 44, 94, "body", "text/secondary", 1100);
  chip(root, "电脑道具禁用", 1458, 46, "neutral");
  chip(root, "单击状态感知", 1570, 46, "active");
  chip(root, "长按 + 拖动 = 跑动", 1692, 46, "success");

  const model = frame(root, "State Model", 44, 152, 1752, 350, { fill: "bg/subtle", stroke: "border/subtle", radius: 24 });
  text(model, "基础状态", 28, 24, "title");
  stateCard(model, "State / working", "工作中", "主动玩耍与赚钱反馈交替；单击触发 working_ack。", 28, 80, "accent/default");
  flowArrow(model, 356, 142, 90, "下班 / 午休");
  stateCard(model, "State / awake_rest", "清醒休息", "承接旧 idle + rest；利用更多轻量呼吸、观察和伸展动作。", 466, 80, "status/success");
  flowArrow(model, 794, 142, 90, "23:00–07:30");
  stateCard(model, "State / sleeping", "深度睡眠", "仅在非工作时段进入；单击回应后回到 sleeping。", 904, 80, "border/strong");
  const priority = frame(model, "State Priority", 1246, 80, 476, 174, { fill: "bg/window", stroke: "border/subtle", radius: 16 });
  text(priority, "优先级", 20, 18, "label");
  text(priority, "用户拖动 > 一次性交互 > 业务事件 > 基础状态", 20, 54, "body", "text/primary", 432);
  text(priority, "夜班覆盖睡眠窗口；午休保持清醒休息；节假日不进入 working。", 20, 104, "caption", "text/secondary", 432);

  const interaction = frame(root, "Interaction Contract", 44, 538, 856, 480, { fill: "bg/window", stroke: "border/subtle", radius: 20 });
  text(interaction, "互动与输入仲裁", 28, 24, "title");
  const rows = [
    ["单击", "working_ack / rest_ack / sleep_ack", "完整播放后恢复原基础状态"],
    ["长按", "run_prepare", "进入可拖动跑动状态"],
    ["拖动", "运行态 + 水平镜像", "移动方向决定朝向，不生成左右两套素材"],
    ["释放", "run_stop", "停止后按当前业务状态恢复"],
    ["双击", "移除", "避免与单击等待、拖动仲裁冲突"]
  ];
  rows.forEach(([inputName, actionName, rule], index) => {
    const ry = 86 + index * 68;
    chip(interaction, inputName, 28, ry, index === 4 ? "neutral" : "active");
    text(interaction, actionName, 142, ry + 2, "label");
    text(interaction, rule, 360, ry + 2, "caption", "text/secondary", 452);
    if (index < rows.length - 1) line(interaction, 28, ry + 48, 800);
  });

  const events = frame(root, "Business Events", 932, 538, 864, 480, { fill: "bg/window", stroke: "border/subtle", radius: 20 });
  text(events, "额外业务事件", 28, 24, "title");
  const eventCards = [
    ["午休开始", "lunch_relief", "停止高能玩耍，伸展后进入 awake_rest"],
    ["午休结束", "lunch_return", "起身伸展，进入 active play"],
    ["下班", "celebration", "一次完整玩耍庆祝后进入 awake_rest"],
    ["看鼠标", "pointer_follow", "B 方案：低频、带死区、仅清醒状态"],
    ["环境动作", "ambient", "按冷却抽样，不打断高优先级交互"]
  ];
  eventCards.forEach(([label, actionName, detail], index) => {
    const col = index % 2;
    const row = Math.floor(index / 2);
    const card = frame(events, `Event / ${label}`, 28 + col * 400, 86 + row * 112, 374, 92, { fill: "bg/subtle", stroke: "border/subtle", radius: 12 });
    chip(card, label, 14, 14, label === "下班" ? "active" : "neutral");
    text(card, actionName, 118, 16, "label");
    text(card, detail, 14, 52, "caption", "text/secondary", 344);
  });

  const assetsPanel = frame(root, "Pet Asset Evidence", 44, 1054, 1752, 900, { fill: "bg/window", stroke: "border/subtle", radius: 24 });
  text(assetsPanel, "历史素材问题对照", 28, 24, "title");
  text(assetsPanel, "图片来自 PetManager 旧审查产物；工程证据保留，但其中电脑道具方向已淘汰，不得作为发布候选。", 28, 62, "caption", "text/secondary", 1200);
  const classic = frame(assetsPanel, "Classic Evidence", 28, 108, 820, 730, { fill: "bg/subtle", stroke: "border/subtle", radius: 16 });
  text(classic, "Classic Pro", 20, 18, "heading");
  chip(classic, "历史候选 · 待无电脑重制", 548, 16, "active");
  imageRect(classic, images.classic, "Classic Contact Sheet", 20, 64, 780, 628, "FIT", 12);
  const duoduo = frame(assetsPanel, "Duoduo Evidence", 876, 108, 820, 730, { fill: "bg/subtle", stroke: "border/subtle", radius: 16 });
  text(duoduo, "多多 Pro", 20, 18, "heading");
  chip(duoduo, "历史候选 · 待无电脑重制", 548, 16, "success");
  imageRect(duoduo, images.duoduo, "Duoduo Contact Sheet", 20, 64, 780, 628, "FIT", 12);

  const fallback = frame(root, "Fallback Contract", 44, 1990, 1752, 300, { fill: "bg/subtle", stroke: "border/subtle", radius: 24 });
  text(fallback, "资源回退与发布门禁", 28, 24, "title");
  const fallbackSteps = [
    ["目标动作", "使用当前宠物对应动作"],
    ["同基础状态通用动作", "缺少专属动作时自然回退"],
    ["旧版兼容动作", "idle / working / resting 映射"],
    ["v0.8 默认宠物", "包损坏或许可失败时安全恢复"]
  ];
  fallbackSteps.forEach(([titleValue, detail], index) => {
    const sx = 28 + index * 420;
    const card = frame(fallback, `Fallback ${index + 1}`, sx, 92, 388, 132, { fill: "bg/window", stroke: "border/subtle", radius: 14 });
    rect(card, "Index", 16, 18, 28, 28, { fill: index === 0 ? "accent/default" : "bg/subtle", stroke: "border/subtle", radius: 14 });
    text(card, String(index + 1), 16, 23, "label", "text/primary", 28, { align: "CENTER" });
    text(card, titleValue, 58, 18, "label");
    text(card, detail, 58, 50, "caption", "text/secondary", 300);
    if (index < fallbackSteps.length - 1) text(fallback, "→", sx + 396, 138, "heading", "text/secondary");
  });
  return root;
}

async function buildAll(assetPayload) {
  postStatus("载入字体与文件结构...");
  await chooseFonts();
  const pages = await preparePages();

  postStatus("创建变量、文字样式和阴影样式...");
  const foundationSummary = await createFoundations();

  postStatus("载入 Classic 与多多真实审查资源...");
  images = {
    classic: await createVerifiedImage(assetPayload.classic, "Classic Contact Sheet"),
    duoduo: await createVerifiedImage(assetPayload.duoduo, "多多 Contact Sheet"),
    classicWorking: await createVerifiedImage(assetPayload.classicWorking, "Classic Working"),
    classicSleeping: await createVerifiedImage(assetPayload.classicSleeping, "Classic Sleeping"),
    duoduoWorking: await createVerifiedImage(assetPayload.duoduoWorking, "多多 Working"),
    duoduoSleeping: await createVerifiedImage(assetPayload.duoduoSleeping, "多多 Sleeping")
  };

  postStatus("绘制 Foundations & Components...");
  const foundationRoot = buildFoundationsPage(pages[0]);
  postStatus("绘制 Windows v0.9 六条产品链路...");
  buildProductPage(pages[1]);
  postStatus("绘制动画 1 对多合同与素材对照...");
  buildAnimationPage(pages[2]);

  await figma.setCurrentPageAsync(pages[0]);
  figma.currentPage.selection = [foundationRoot];
  figma.viewport.scrollAndZoomIntoView([foundationRoot]);

  return {
    pageCount: pages.length,
    primitiveCount: foundationSummary.primitiveCount,
    semanticCount: foundationSummary.semanticCount,
    textStyleCount: 8,
    effectStyleCount: 2
  };
}

figma.showUI(__html__, { width: 380, height: 278, themeColors: true });

figma.ui.onmessage = async (message) => {
  if (!message || message.type !== "build") return;
  try {
    const result = await buildAll(message.assets);
    figma.ui.postMessage({
      type: "done",
      text: `完成：${result.pageCount} 页 · ${result.primitiveCount + result.semanticCount} 个变量 · ${result.textStyleCount} 个文字样式`
    });
    figma.notify("LetsMakeMoney v0.9 设计已生成", { timeout: 3500 });
  } catch (error) {
    const detail = error && error.stack ? error.stack : String(error);
    console.error(detail);
    figma.ui.postMessage({ type: "error", text: `生成失败：${error.message || String(error)}` });
  }
};
