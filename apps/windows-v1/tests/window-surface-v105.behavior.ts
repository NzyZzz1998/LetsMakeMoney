import assert from "node:assert/strict";
import { existsSync, readFileSync } from "node:fs";
import { resolve } from "node:path";
import { cwd } from "node:process";

const repositoryCandidate = resolve(cwd(), "apps/windows-v1");
const appRoot = existsSync(resolve(repositoryCandidate, "package.json"))
  ? repositoryCandidate
  : cwd();
const read = (path: string) => readFileSync(resolve(appRoot, path), "utf8");

const frame = read("src/components/WindowFrame.tsx");
const app = read("src/App.tsx");
const styles = read("src/styles.css");
const rust = read("src-tauri/src/lib.rs");
const tauri = JSON.parse(read("src-tauri/tauri.conf.json"));

let assertions = 0;
const check = (condition: unknown, message: string) => {
  assert.ok(condition, message);
  assertions += 1;
};

check(frame.includes('data-surface-owner="window-frame"'), "WindowFrame must own the web surface");
check(frame.includes('data-shadow-owner="native-window"'), "native window must own the external shadow");
check(/\.window-frame\s*\{\s*box-shadow:\s*none;/s.test(styles), "WindowFrame CSS shadow must be disabled");
check(/\.mini-window\s*\{\s*box-shadow:\s*var\(--shadow-window\);/s.test(styles), "Mini shadow must remain unchanged");
check(/body\s*\{[^}]*background:\s*transparent;/s.test(styles), "WebView root must stay transparent");
check(/\.window-frame,\s*\.mini-window\s*\{[^}]*border:[^}]*border-radius:[^}]*background:/s.test(styles), "web surface must retain border, radius and background");
check(rust.includes(".transparent(true)"), "dynamic native windows must stay transparent");
check(rust.includes(".shadow(true)"), "dynamic native windows must retain DWM shadow");
check(tauri.app.windows[0].transparent === true, "Mini native root must stay transparent");
check(tauri.app.windows[0].shadow === true, "Mini native shadow must stay enabled");
check((app.match(/<WindowFrame\b/g) ?? []).length === 3, "only three product windows may use WindowFrame");
check(app.includes('<WindowFrame kind="workbench"'), "Workbench surface contract missing");
check(app.includes('<WindowFrame kind="settings"'), "Settings surface contract missing");
check(app.includes('<WindowFrame kind="wizard"'), "Wizard surface contract missing");
check(!read("src/features/mini/MiniWindow.tsx").includes("WindowFrame"), "Mini must remain outside the M5 surface Spike");
check(styles.includes("@media (prefers-reduced-motion: reduce)"), "reduced-motion contract missing");

console.log(`window surface contract ${assertions}/16 passed`);
