import { useCallback, useEffect, useMemo, useRef, useState } from "react";
import {
  addHours,
  defaultConfig,
  normalizeConfiguration,
  validateConfiguration,
  type AppConfig,
} from "./domain/configuration";
import { configurationService } from "./services/configurationService";
import {
  applyTheme,
  broadcastTheme,
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
  RestMode,
  WeekType,
} from "./domain/configuration";

export type SaveFeedback = "idle" | "saved" | "unchanged" | "failed";

export function useConfigDraft(seed?: Partial<AppConfig>) {
  const seedKey = JSON.stringify(seed ?? {});
  const seeded = useMemo(() => normalizeConfiguration(seed), [seedKey]);
  const [persisted, setPersisted] = useState<AppConfig>(seeded);
  const [draft, setDraft] = useState<AppConfig>(seeded);
  const [loading, setLoading] = useState(true);
  const [feedback, setFeedback] = useState<SaveFeedback>("idle");
  const [message, setMessage] = useState("");
  const dirtyRef = useRef(false);

  const reload = useCallback(async (preserveDirty = true) => {
    if (preserveDirty && dirtyRef.current) return;
    try {
      const loadedValue = await configurationService.read(seeded);
      const loaded = normalizeConfiguration(loadedValue);
      setPersisted(loaded);
      setDraft(loaded);
      applyTheme(loaded.theme_mode);
      setFeedback("idle");
      setMessage("");
    } catch {
      setPersisted(seeded);
      setDraft(seeded);
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
      void broadcastTheme(normalizeThemeMode(value), "draft_changed");
    }
    setFeedback("idle");
    setMessage("");
  }, []);

  const save = useCallback(async () => {
    const validation = validateConfiguration(draft);
    if (Object.keys(validation).length) {
      setFeedback("failed");
      setMessage(Object.values(validation)[0]);
      void broadcastTheme(persisted.theme_mode, "validation_failed");
      return false;
    }
    if (!dirty) {
      setFeedback("unchanged");
      setMessage("没有需要保存的更改");
      return true;
    }
    try {
      const result = await configurationService.save(draft);
      if (result.status === "failed") throw new Error(result.message);
      setPersisted(draft);
      void broadcastTheme(draft.theme_mode, result.status);
      void configurationService.publishUpdated("settings");
      setFeedback(result.status === "unchanged" ? "unchanged" : "saved");
      setMessage(result.message);
      return true;
    } catch (error) {
      setFeedback("failed");
      setMessage(`保存失败：${error instanceof Error ? error.message : String(error)}`);
      void broadcastTheme(persisted.theme_mode, "save_failed");
      return false;
    }
  }, [dirty, draft, persisted.theme_mode]);

  const reset = useCallback(() => {
    setDraft(defaultConfig);
    void broadcastTheme(defaultConfig.theme_mode, "reset_draft");
    setFeedback("idle");
    setMessage("");
  }, []);

  const cancel = useCallback(() => {
    setDraft(persisted);
    void broadcastTheme(persisted.theme_mode, "draft_discarded");
    setFeedback("idle");
    setMessage("");
  }, [persisted]);

  return { draft, persisted, loading, dirty, errors, feedback, message, update, save, reset, cancel, reload };
}
