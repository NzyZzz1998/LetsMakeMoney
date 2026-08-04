import {
  normalizeThemeMode,
  type ThemeMode,
} from "./domain/theme";
import {
  appRuntime,
  type AppRuntime,
} from "./runtime/appRuntime";

export { normalizeThemeMode } from "./domain/theme";
export type { ThemeMode } from "./domain/theme";

export type ThemeSessionAction = "preview" | "commit" | "revert";
export type ThemeSessionSource = "persisted" | "preview" | "fallback";

export interface ThemeSessionSnapshot {
  theme_mode: ThemeMode;
  source: ThemeSessionSource;
  transaction_id: string | null;
  revision: number;
  reason: string;
}

interface ThemeRoot {
  dataset: Record<string, string | undefined>;
  style: { colorScheme: string };
}

interface ThemeStorage {
  getItem(key: string): string | null;
  setItem?(key: string, value: string): void;
  removeItem?(key: string): void;
}

interface ThemeControllerEnvironment {
  root: ThemeRoot;
  storage?: ThemeStorage;
  events?: Pick<EventTarget, "dispatchEvent">
    & Partial<Pick<EventTarget, "addEventListener" | "removeEventListener">>;
  windowLabel: string;
}

const THEME_EVENT = "lmm://theme-preview";
const BROWSER_THEME_EVENT = "lmm:theme-preview";
const LEGACY_THEME_STORAGE_KEY = "lmm.theme";
const CONFIG_STORAGE_KEY = "lmm.config";
const RETRY_DELAYS_MS = [0, 50, 100, 250, 500, 1000] as const;

let transactionCounter = 0;

function browserEnvironment(): ThemeControllerEnvironment {
  const hasWindow = typeof window !== "undefined";
  const hasDocument = typeof document !== "undefined";
  return {
    root: hasDocument
      ? document.documentElement as unknown as ThemeRoot
      : { dataset: {}, style: { colorScheme: "light" } },
    storage: hasWindow ? window.localStorage : undefined,
    events: hasWindow ? window : undefined,
    windowLabel: hasWindow
      ? new URLSearchParams(window.location.search).get("window") ?? "mini"
      : "unknown",
  };
}

function wait(delayMs: number) {
  if (delayMs === 0) return Promise.resolve();
  return new Promise<void>(resolve => globalThis.setTimeout(resolve, delayMs));
}

function normalizeSnapshot(
  value: unknown,
  fallback: ThemeMode,
  reason: string,
): ThemeSessionSnapshot {
  if (!value || typeof value !== "object") {
    return {
      theme_mode: fallback,
      source: "fallback",
      transaction_id: null,
      revision: 0,
      reason,
    };
  }
  const candidate = value as Partial<ThemeSessionSnapshot>;
  return {
    theme_mode: normalizeThemeMode(candidate.theme_mode),
    source: candidate.source === "preview" || candidate.source === "persisted"
      ? candidate.source
      : "fallback",
    transaction_id: typeof candidate.transaction_id === "string"
      ? candidate.transaction_id
      : null,
    revision: typeof candidate.revision === "number" && Number.isFinite(candidate.revision)
      ? Math.max(0, Math.trunc(candidate.revision))
      : 0,
    reason: typeof candidate.reason === "string" ? candidate.reason : reason,
  };
}

function browserSnapshot(storage: ThemeStorage | undefined): ThemeSessionSnapshot {
  try {
    const serialized = storage?.getItem(CONFIG_STORAGE_KEY);
    const configuration = serialized ? JSON.parse(serialized) as { theme_mode?: unknown } : null;
    return {
      theme_mode: normalizeThemeMode(configuration?.theme_mode),
      source: "persisted",
      transaction_id: null,
      revision: 0,
      reason: "browser_configuration",
    };
  } catch {
    return {
      theme_mode: "light",
      source: "fallback",
      transaction_id: null,
      revision: 0,
      reason: "browser_configuration_invalid",
    };
  }
}

export function themeActionForReason(reason: string): ThemeSessionAction {
  if (reason === "draft_changed" || reason === "reset_draft") return "preview";
  if (reason === "saved") return "commit";
  return "revert";
}

export function createThemeTransactionId() {
  transactionCounter += 1;
  return `theme-${Date.now().toString(36)}-${transactionCounter.toString(36)}`;
}

export function applyTheme(mode: ThemeMode) {
  const root = document.documentElement as unknown as ThemeRoot;
  root.dataset.theme = mode;
  root.style.colorScheme = mode;
}

export function createThemeController(
  runtime: AppRuntime,
  environment: ThemeControllerEnvironment,
) {
  let appliedRevision = -1;

  const record = (event: string, detail: string) => {
    if (!runtime.isDesktop) return;
    void runtime.invoke("record_semantic_event", { event, detail }).catch(() => undefined);
  };

  const applySnapshot = (value: unknown, reason: string, force = false) => {
    const snapshot = normalizeSnapshot(value, "light", reason);
    if (!force && snapshot.revision < appliedRevision) return snapshot;
    environment.root.dataset.theme = snapshot.theme_mode;
    environment.root.style.colorScheme = snapshot.theme_mode;
    appliedRevision = Math.max(appliedRevision, snapshot.revision);
    record(
      "theme.window_applied",
      `window=${environment.windowLabel} theme=${snapshot.theme_mode} source=${snapshot.source} revision=${snapshot.revision} reason=${reason}`,
    );
    return snapshot;
  };

  const readAuthority = async () => {
    if (!runtime.isDesktop) return browserSnapshot(environment.storage);
    let lastError: unknown;
    for (const delayMs of RETRY_DELAYS_MS) {
      await wait(delayMs);
      try {
        return await runtime.invoke<ThemeSessionSnapshot>("read_theme_session", {
          windowLabel: environment.windowLabel,
        });
      } catch (error) {
        lastError = error;
      }
    }
    throw lastError ?? new Error("theme_session_unavailable");
  };

  const synchronize = async (reason: string) => {
    const snapshot = await readAuthority();
    return applySnapshot(snapshot, reason);
  };

  return {
    async bootstrap() {
      environment.storage?.removeItem?.(LEGACY_THEME_STORAGE_KEY);
      try {
        await synchronize("bootstrap");
      } catch (error) {
        applySnapshot({
          theme_mode: "light",
          source: "fallback",
          transaction_id: null,
          revision: 0,
          reason: "bootstrap_failed",
        }, "bootstrap_failed", true);
        record(
          "theme.bootstrap_failed",
          `window=${environment.windowLabel} reason=${error instanceof Error ? error.message : String(error)}`,
        );
      }
      environment.root.dataset.themeReady = "true";
    },

    async listen() {
      const applyPayload = (payload: unknown) => {
        applySnapshot(payload, "session_event");
      };
      if (!runtime.isDesktop) {
        const listener = (event: Event) => applyPayload((event as CustomEvent).detail);
        environment.events?.addEventListener?.(BROWSER_THEME_EVENT, listener);
        return () => environment.events?.removeEventListener?.(BROWSER_THEME_EVENT, listener);
      }

      let disposer: (() => void) | null = null;
      let lastError: unknown;
      for (const delayMs of RETRY_DELAYS_MS) {
        await wait(delayMs);
        try {
          disposer = await runtime.listen(THEME_EVENT, applyPayload);
          break;
        } catch (error) {
          lastError = error;
        }
      }
      if (!disposer) throw lastError ?? new Error("theme_listener_unavailable");
      await synchronize("listener_registered");
      return disposer;
    },

    synchronize,

    async update(
      mode: ThemeMode,
      action: ThemeSessionAction,
      transactionId: string,
      reason: string,
    ) {
      environment.root.dataset.theme = mode;
      environment.root.style.colorScheme = mode;
      if (!runtime.isDesktop) {
        const snapshot: ThemeSessionSnapshot = {
          theme_mode: mode,
          source: action === "preview" ? "preview" : "persisted",
          transaction_id: action === "preview" ? transactionId : null,
          revision: appliedRevision + 1,
          reason,
        };
        applySnapshot(snapshot, reason);
        environment.events?.dispatchEvent(new CustomEvent(BROWSER_THEME_EVENT, { detail: snapshot }));
        return snapshot;
      }
      const snapshot = await runtime.invoke<ThemeSessionSnapshot>("update_theme_session", {
        request: {
          action,
          themeMode: mode,
          transactionId,
          reason,
          windowLabel: environment.windowLabel,
        },
      });
      return applySnapshot(snapshot, reason);
    },
  };
}

const themeController = createThemeController(appRuntime, browserEnvironment());

export function bootstrapTheme() {
  return themeController.bootstrap();
}

export function synchronizeTheme(reason: string) {
  return themeController.synchronize(reason);
}

export async function broadcastTheme(
  mode: ThemeMode,
  reason: string,
  transactionId = "legacy",
) {
  return themeController.update(mode, themeActionForReason(reason), transactionId, reason);
}

export function listenForThemeChanges() {
  return themeController.listen();
}
