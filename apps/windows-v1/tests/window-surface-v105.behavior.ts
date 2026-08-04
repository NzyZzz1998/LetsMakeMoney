import assert from "node:assert/strict";
import { existsSync, readFileSync } from "node:fs";
import { resolve } from "node:path";
import { cwd } from "node:process";
import { WINDOW_SURFACE_ATTRIBUTES } from "../src/components/windowSurfaceContract";

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

check(
  WINDOW_SURFACE_ATTRIBUTES["data-surface-owner"] === "web-content"
    && frame.includes("{...WINDOW_SURFACE_ATTRIBUTES}"),
  "WindowFrame must bind the web-content surface contract",
);
check(
  WINDOW_SURFACE_ATTRIBUTES["data-shadow-owner"] === "native-window",
  "native window must own the external shadow",
);
check(/\.window-frame\s*\{\s*box-shadow:\s*none;/s.test(styles), "WindowFrame CSS shadow must be disabled");
check(/\.mini-window\s*\{\s*box-shadow:\s*none;/s.test(styles), "Mini must not draw a second web shadow");
check(/body\s*\{[^}]*background:\s*transparent;/s.test(styles), "WebView root must stay transparent");
check(/\.window-frame,\s*\.mini-window\s*\{[^}]*border:[^}]*border-radius:[^}]*background:/s.test(styles), "web surface must retain border, radius and background");
check(rust.includes(".transparent(true)"), "dynamic native windows must stay transparent");
check(rust.includes(".shadow(true)"), "dynamic native windows must retain DWM shadow");
check(tauri.app.windows[0].transparent === true, "Mini native root must stay transparent");
check(tauri.app.windows[0].shadow === true, "Mini native shadow must stay enabled");
const frameKinds = [...app.matchAll(/<WindowFrame kind="([^"]+)"/g)].map(match => match[1]);
check(
  new Set(frameKinds).size === 3
    && frameKinds.every(kind => ["workbench", "settings", "wizard"].includes(kind)),
  "only the three product window kinds may use WindowFrame",
);
check(app.includes('<WindowFrame kind="workbench"'), "Workbench surface contract missing");
check(app.includes('<WindowFrame kind="settings"'), "Settings surface contract missing");
check(app.includes('<WindowFrame kind="wizard"'), "Wizard surface contract missing");
check(
  read("src/features/mini/MiniWindow.tsx").includes("WINDOW_SURFACE_ATTRIBUTES"),
  "Mini must bind the shared surface ownership contract",
);
check(styles.includes("@media (prefers-reduced-motion: reduce)"), "reduced-motion contract missing");
check(
  app.includes('window.addEventListener("lmm:window-close-requested", requestClose)'),
  "Settings and Wizard must route native close requests through their React close transaction",
);
check(
  rust.includes('matches!(window.label(), "settings" | "wizard")')
    && rust.includes("lmm:window-close-requested"),
  "native Settings and Wizard close requests must not bypass draft confirmation and preview rollback",
);

console.log(`window surface contract ${assertions}/18 passed`);
