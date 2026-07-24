import { readFile } from "node:fs/promises";
import { fileURLToPath } from "node:url";
import { dirname, join } from "node:path";

const root = dirname(dirname(fileURLToPath(import.meta.url)));
const app = await readFile(join(root, "src", "App.tsx"), "utf8");
const bridge = await readFile(join(root, "src", "tauri.ts"), "utf8");
const rust = await readFile(join(root, "src-tauri", "src", "lib.rs"), "utf8");
const config = JSON.parse(await readFile(join(root, "src-tauri", "tauri.conf.json"), "utf8"));
const ui = `${app}\n${bridge}`;

const requiredUi = [
  "今日已赚",
  "收入日历",
  "收入与作息",
  "已保存到本机",
  "没有需要保存的更改",
  "保存失败"
];
const requiredRust = [
  "set_window_mode",
  "hide_to_tray",
  "save_settings",
  "TrayIconBuilder",
  "CloseRequested",
  "配置文件暂时不可写"
];

const missing = [
  ...requiredUi.filter((token) => !ui.includes(token)),
  ...["输入已保留", "lmm-open-settings"].filter((token) => !app.includes(token)),
  ...requiredRust.filter((token) => !rust.includes(token))
];

const window = config.app.windows[0];
if (window.width !== 344 || window.height !== 120) {
  missing.push("initial-window-size");
}
if (missing.length > 0) {
  console.error(`TAURI_SPIKE_VERIFY_FAILED: ${missing.join(", ")}`);
  process.exit(1);
}
console.log("TAURI_SPIKE_VERIFY_OK");
