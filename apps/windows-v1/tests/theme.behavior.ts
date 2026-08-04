import {
  createThemeController,
  normalizeThemeMode,
  themeActionForReason,
  type ThemeSessionSnapshot,
} from "../src/theme";
import { createAppRuntime, type DesktopBridge } from "../src/runtime/appRuntime";

function assert(condition: unknown, message: string): asserts condition {
  if (!condition) throw new Error(message);
}

assert(normalizeThemeMode("light") === "light", "light must remain light");
assert(normalizeThemeMode("dark") === "dark", "dark must remain dark");
assert(normalizeThemeMode("system") === "light", "unsupported system mode must fall back to light");
assert(normalizeThemeMode("midnight") === "light", "unknown modes must fall back to light");
assert(normalizeThemeMode(undefined) === "light", "missing mode must fall back to light");

assert(themeActionForReason("draft_changed") === "preview", "draft changes start a preview");
assert(themeActionForReason("saved") === "commit", "saved configuration commits the preview");
assert(themeActionForReason("save_failed") === "revert", "failed saves revert to persisted theme");

const root = {
  dataset: {} as Record<string, string>,
  style: { colorScheme: "" },
};
let legacyThemeRemoved = false;
let writesToLegacyTheme = 0;
let currentSnapshot: ThemeSessionSnapshot = {
  theme_mode: "light",
  source: "persisted",
  transaction_id: null,
  revision: 1,
  reason: "bootstrap",
};
let themeHandler: ((payload: unknown) => void) | null = null;
const invocations: Array<{ command: string; args?: Record<string, unknown> }> = [];
const bridge: DesktopBridge = {
  async invoke<T>(command: string, args?: Record<string, unknown>) {
    invocations.push({ command, args });
    if (command === "read_theme_session") return currentSnapshot as T;
    if (command === "update_theme_session") {
      const request = args?.request as Record<string, unknown> | undefined;
      currentSnapshot = {
        theme_mode: request?.themeMode === "dark" ? "dark" : "light",
        source: request?.action === "preview" ? "preview" : "persisted",
        transaction_id: request?.action === "preview" ? String(request?.transactionId) : null,
        revision: currentSnapshot.revision + 1,
        reason: String(request?.reason ?? "test"),
      };
      return currentSnapshot as T;
    }
    return undefined as T;
  },
  async emit() {},
  async listen(_event, handler) {
    themeHandler = handler as (payload: unknown) => void;
    return () => {
      themeHandler = null;
    };
  },
};

const controller = createThemeController(createAppRuntime(bridge), {
  root,
  storage: {
    getItem(key) {
      return key === "lmm.theme" ? "dark" : null;
    },
    setItem(key) {
      if (key === "lmm.theme") writesToLegacyTheme += 1;
    },
    removeItem(key) {
      if (key === "lmm.theme") legacyThemeRemoved = true;
    },
  },
  events: new EventTarget(),
  windowLabel: "workbench",
});

await controller.bootstrap();
assert(root.dataset.theme === "light", "persisted configuration outranks stale dark cache");
assert(root.dataset.themeReady === "true", "the first visible frame waits for theme bootstrap");
assert(legacyThemeRemoved, "legacy theme cache is retired during bootstrap");
assert(writesToLegacyTheme === 0, "theme application cannot recreate a second persistent source");

currentSnapshot = {
  theme_mode: "dark",
  source: "preview",
  transaction_id: "tx-settings",
  revision: 2,
  reason: "draft_changed",
};
await controller.listen();
assert(root.dataset.theme === "dark", "late listener registration replays the current preview snapshot");

themeHandler?.({
  theme_mode: "light",
  source: "persisted",
  transaction_id: null,
  revision: 1,
  reason: "stale_event",
});
assert(root.dataset.theme === "dark", "stale theme events cannot overwrite a newer session revision");

await controller.update("light", "revert", "tx-settings", "draft_discarded");
assert(root.dataset.theme === "light", "revert applies the persisted theme returned by authority");
assert(
  invocations.some(item => item.command === "update_theme_session"),
  "theme transactions use the replayable native session command",
);

console.log("v1.0.6 theme behavior: 17/17 passed");
