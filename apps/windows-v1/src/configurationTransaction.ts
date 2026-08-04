import {
  validateConfiguration,
  type AppConfig,
} from "./domain/configuration";
import type { ConfigurationService } from "./services/configurationService";

export type SaveFeedback = "idle" | "saved" | "unchanged" | "failed";

export interface ConfigurationSaveOutcome {
  ok: boolean;
  feedback: Exclude<SaveFeedback, "idle">;
  message: string;
  persisted: AppConfig;
  draft: AppConfig;
  publishUpdated: boolean;
  themeMode: AppConfig["theme_mode"];
  themeReason:
    | "hydration_incomplete"
    | "validation_failed"
    | "unchanged"
    | "saved"
    | "save_failed";
}

interface ConfigurationSaveInput {
  persisted: AppConfig;
  draft: AppConfig;
  service: Pick<ConfigurationService, "save">;
  hydrated?: boolean;
}

export async function executeConfigurationSave({
  persisted,
  draft,
  service,
  hydrated = true,
}: ConfigurationSaveInput): Promise<ConfigurationSaveOutcome> {
  if (!hydrated) {
    return {
      ok: false,
      feedback: "failed",
      message: "配置仍在加载，暂时无法保存。请稍后重试。",
      persisted,
      draft,
      publishUpdated: false,
      themeMode: persisted.theme_mode,
      themeReason: "hydration_incomplete",
    };
  }

  const validation = validateConfiguration(draft);
  if (Object.keys(validation).length > 0) {
    return {
      ok: false,
      feedback: "failed",
      message: Object.values(validation)[0],
      persisted,
      draft,
      publishUpdated: false,
      themeMode: persisted.theme_mode,
      themeReason: "validation_failed",
    };
  }

  if (JSON.stringify(draft) === JSON.stringify(persisted)) {
    return {
      ok: true,
      feedback: "unchanged",
      message: "没有需要保存的更改",
      persisted,
      draft,
      publishUpdated: false,
      themeMode: persisted.theme_mode,
      themeReason: "unchanged",
    };
  }

  try {
    const result = await service.save(draft);
    if (result.status === "failed") {
      throw new Error(result.message);
    }
    return {
      ok: true,
      feedback: result.status,
      message: result.message,
      persisted: draft,
      draft,
      publishUpdated: true,
      themeMode: draft.theme_mode,
      themeReason: result.status,
    };
  } catch (error) {
    return {
      ok: false,
      feedback: "failed",
      message: `保存失败：${error instanceof Error ? error.message : String(error)}`,
      persisted,
      draft,
      publishUpdated: false,
      themeMode: persisted.theme_mode,
      themeReason: "save_failed",
    };
  }
}
