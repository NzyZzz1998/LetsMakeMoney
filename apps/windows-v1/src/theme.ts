import { emit, listen, type UnlistenFn } from "@tauri-apps/api/event";
import { invoke } from "@tauri-apps/api/core";

export type ThemeMode = "light" | "dark";

const THEME_STORAGE_KEY = "lmm.theme";
const THEME_EVENT = "lmm://theme-preview";
const BROWSER_THEME_EVENT = "lmm:theme-preview";

function isTauri() {
  return "__TAURI_INTERNALS__" in window;
}

export function normalizeThemeMode(value: unknown): ThemeMode {
  return value === "dark" ? "dark" : "light";
}

export function applyTheme(mode: ThemeMode) {
  document.documentElement.dataset.theme = mode;
  document.documentElement.style.colorScheme = mode;
  localStorage.setItem(THEME_STORAGE_KEY, mode);
}

export async function broadcastTheme(mode: ThemeMode, reason: string) {
  applyTheme(mode);
  if (isTauri()) {
    await emit(THEME_EVENT, { theme_mode: mode, reason });
    void invoke("record_semantic_event", {
      event: "theme.preview_applied",
      detail: `theme=${mode} reason=${reason}`,
    }).catch(() => undefined);
    return;
  }
  window.dispatchEvent(new CustomEvent(BROWSER_THEME_EVENT, {
    detail: { theme_mode: mode, reason },
  }));
}

export async function listenForThemeChanges(): Promise<UnlistenFn> {
  const applyPayload = (payload: unknown) => {
    if (!payload || typeof payload !== "object") return;
    const mode = normalizeThemeMode((payload as { theme_mode?: unknown }).theme_mode);
    applyTheme(mode);
  };
  if (isTauri()) {
    return listen(THEME_EVENT, event => applyPayload(event.payload));
  }
  const listener = (event: Event) => applyPayload((event as CustomEvent).detail);
  window.addEventListener(BROWSER_THEME_EVENT, listener);
  return () => window.removeEventListener(BROWSER_THEME_EVENT, listener);
}
