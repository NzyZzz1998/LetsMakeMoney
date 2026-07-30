import {
  normalizeThemeMode,
  type ThemeMode,
} from "./domain/theme";
import { appRuntime } from "./runtime/appRuntime";

export { normalizeThemeMode } from "./domain/theme";
export type { ThemeMode } from "./domain/theme";

const THEME_STORAGE_KEY = "lmm.theme";
const THEME_EVENT = "lmm://theme-preview";
const BROWSER_THEME_EVENT = "lmm:theme-preview";

export function applyTheme(mode: ThemeMode) {
  document.documentElement.dataset.theme = mode;
  document.documentElement.style.colorScheme = mode;
  localStorage.setItem(THEME_STORAGE_KEY, mode);
}

export async function broadcastTheme(mode: ThemeMode, reason: string) {
  applyTheme(mode);
  if (appRuntime.isDesktop) {
    await appRuntime.emit(THEME_EVENT, { theme_mode: mode, reason });
    void appRuntime.invoke("record_semantic_event", {
      event: "theme.preview_applied",
      detail: `theme=${mode} reason=${reason}`,
    }).catch(() => undefined);
    return;
  }
  window.dispatchEvent(new CustomEvent(BROWSER_THEME_EVENT, {
    detail: { theme_mode: mode, reason },
  }));
}

export async function listenForThemeChanges(): Promise<() => void> {
  const applyPayload = (payload: unknown) => {
    if (!payload || typeof payload !== "object") return;
    const mode = normalizeThemeMode((payload as { theme_mode?: unknown }).theme_mode);
    applyTheme(mode);
  };
  if (appRuntime.isDesktop) {
    return appRuntime.listen(THEME_EVENT, applyPayload);
  }
  const listener = (event: Event) => applyPayload((event as CustomEvent).detail);
  window.addEventListener(BROWSER_THEME_EVENT, listener);
  return () => window.removeEventListener(BROWSER_THEME_EVENT, listener);
}
