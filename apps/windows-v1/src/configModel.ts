import { useCallback, useEffect, useMemo, useRef, useState } from "react";
import {
  addHours,
  defaultConfig,
  normalizeConfiguration,
  validateConfiguration,
  type AppConfig,
} from "./domain/configuration";
import {
  executeConfigurationSave,
  type SaveFeedback,
} from "./configurationTransaction";
import { configurationService } from "./services/configurationService";
import {
  broadcastTheme,
  createThemeTransactionId,
  normalizeThemeMode,
} from "./theme";

export {
  CURRENT_CONFIG_VERSION,
  addHours,
  defaultConfig,
  normalizeConfiguration,
  validateConfiguration,
} from "./domain/configuration";
export type {
  AppConfig,
  DateOverrideKind,
  MiniEdgeDock,
  RestMode,
  WeekType,
} from "./domain/configuration";

export type { SaveFeedback } from "./configurationTransaction";

export function useConfigDraft(seed?: Partial<AppConfig>) {
  const seedKey = JSON.stringify(seed ?? {});
  const seeded = useMemo(() => normalizeConfiguration(seed), [seedKey]);
  const [persisted, setPersisted] = useState<AppConfig>(seeded);
  const [draft, setDraft] = useState<AppConfig>(seeded);
  const [loading, setLoading] = useState(true);
  const [hydrationError, setHydrationError] = useState("");
  const [feedback, setFeedback] = useState<SaveFeedback>("idle");
  const [message, setMessage] = useState("");
  const dirtyRef = useRef(false);
  const themeTransactionId = useRef(createThemeTransactionId());

  const reload = useCallback(async (preserveDirty = true) => {
    if (preserveDirty && dirtyRef.current) return;
    setLoading(true);
    setHydrationError("");
    try {
      const loadedValue = await configurationService.read(seeded);
      const loaded = normalizeConfiguration(loadedValue);
      setPersisted(loaded);
      setDraft(loaded);
      setFeedback("idle");
      setMessage("");
    } catch (error) {
      const detail = error instanceof Error ? error.message : String(error);
      setHydrationError(detail || "configuration_read_failed");
      setFeedback("failed");
      setMessage("无法读取本地配置。当前输入不会被保存，请重试。");
    } finally {
      setLoading(false);
    }
  }, [seeded]);

  useEffect(() => {
    void reload(false);
  }, [reload]);

  const errors = useMemo(() => validateConfiguration(draft), [draft]);
  const dirty = useMemo(() => JSON.stringify(draft) !== JSON.stringify(persisted), [draft, persisted]);
  useEffect(() => {
    dirtyRef.current = dirty;
  }, [dirty]);

  useEffect(() => {
    const refresh = () => void reload(true);
    window.addEventListener("focus", refresh);
    return () => {
      window.removeEventListener("focus", refresh);
    };
  }, [reload]);

  const update = useCallback(<K extends keyof AppConfig>(key: K, value: AppConfig[K]) => {
    setDraft(current => ({ ...current, [key]: value }));
    if (key === "theme_mode") {
      void broadcastTheme(
        normalizeThemeMode(value),
        "draft_changed",
        themeTransactionId.current,
      );
    }
    setFeedback("idle");
    setMessage("");
  }, []);

  const save = useCallback(async () => {
    const outcome = await executeConfigurationSave({
      persisted,
      draft,
      service: configurationService,
      hydrated: !loading && hydrationError.length === 0,
    });
    setPersisted(outcome.persisted);
    setDraft(outcome.draft);
    setFeedback(outcome.feedback);
    setMessage(outcome.message);
    const transactionId = themeTransactionId.current;
    void broadcastTheme(outcome.themeMode, outcome.themeReason, transactionId);
    if (outcome.ok) themeTransactionId.current = createThemeTransactionId();
    if (outcome.publishUpdated) {
      void configurationService.publishUpdated("settings");
    }
    return outcome.ok;
  }, [draft, hydrationError, loading, persisted]);

  const reset = useCallback(() => {
    setDraft(defaultConfig);
    void broadcastTheme(defaultConfig.theme_mode, "reset_draft", themeTransactionId.current);
    setFeedback("idle");
    setMessage("");
  }, []);

  const cancel = useCallback(() => {
    setDraft(persisted);
    const transactionId = themeTransactionId.current;
    void broadcastTheme(persisted.theme_mode, "draft_discarded", transactionId);
    themeTransactionId.current = createThemeTransactionId();
    setFeedback("idle");
    setMessage("");
  }, [persisted]);

  return {
    draft,
    persisted,
    loading,
    hydrationError,
    dirty,
    errors,
    feedback,
    message,
    update,
    save,
    reset,
    cancel,
    reload,
  };
}
