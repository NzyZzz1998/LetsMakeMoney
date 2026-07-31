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
    const outcome = await executeConfigurationSave({
      persisted,
      draft,
      service: configurationService,
    });
    setPersisted(outcome.persisted);
    setDraft(outcome.draft);
    setFeedback(outcome.feedback);
    setMessage(outcome.message);
    void broadcastTheme(outcome.themeMode, outcome.themeReason);
    if (outcome.publishUpdated) {
      void configurationService.publishUpdated("settings");
    }
    return outcome.ok;
  }, [draft, persisted]);

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
