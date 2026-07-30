import {
  appRuntime,
  type AppRuntime,
} from "../runtime/appRuntime";

export interface PlatformCapabilities {
  webview2_available: boolean;
  tray_available: boolean;
  explorer_available: boolean;
}

export interface UpdateEvaluation {
  status: "up_to_date" | "available" | "unavailable";
  message: string;
}

export interface SupportService {
  capabilities(): Promise<PlatformCapabilities>;
  record(event: string, detail: string): Promise<void>;
  openDataDirectory(): Promise<string>;
  diagnosticSummary(): Promise<string>;
  evaluateUpdate(
    currentVersion: string,
    responseBody: string | null,
    failureReason: string | null,
  ): Promise<UpdateEvaluation>;
}

export function createSupportService(runtime: AppRuntime): SupportService {
  return {
    capabilities: () => runtime.invoke("platform_capabilities"),
    record: (event, detail) => runtime.invoke("record_semantic_event", { event, detail }),
    openDataDirectory: () => runtime.invoke("open_data_directory"),
    diagnosticSummary: () => runtime.invoke("diagnostic_summary"),
    evaluateUpdate: (currentVersion, responseBody, failureReason) =>
      runtime.invoke("evaluate_update_response", {
        currentVersion,
        responseBody,
        failureReason,
      }),
  };
}

export const supportService = createSupportService(appRuntime);
