import type { AppConfig } from "../domain/configuration";
import {
  appRuntime,
  type AppRuntime,
} from "../runtime/appRuntime";

export interface SaveConfigurationResult {
  status: "saved" | "unchanged" | "failed";
  message: string;
}

interface BrowserConfigurationEnvironment {
  localStorage?: Pick<Storage, "getItem" | "setItem">;
  sessionStorage?: Pick<Storage, "getItem">;
  events?: Pick<EventTarget, "dispatchEvent">
    & Partial<Pick<EventTarget, "addEventListener" | "removeEventListener">>;
}

export interface ConfigurationService {
  readonly isDesktop: boolean;
  read(fallback: AppConfig): Promise<AppConfig>;
  save(draft: AppConfig): Promise<SaveConfigurationResult>;
  publishUpdated(source: string): Promise<void>;
  listenUpdated(handler: () => void): Promise<() => void>;
}

function browserEnvironment(): BrowserConfigurationEnvironment {
  if (typeof window === "undefined") return {};
  return {
    localStorage: window.localStorage,
    sessionStorage: window.sessionStorage,
    events: window,
  };
}

export function createConfigurationService(
  runtime: AppRuntime,
  environment: BrowserConfigurationEnvironment = browserEnvironment(),
): ConfigurationService {
  return {
    isDesktop: runtime.isDesktop,
    async read(fallback) {
      if (runtime.isDesktop) {
        return runtime.invoke<AppConfig>("read_configuration");
      }
      const serialized = environment.localStorage?.getItem("lmm.config");
      return serialized ? JSON.parse(serialized) as AppConfig : fallback;
    },
    async save(draft) {
      if (runtime.isDesktop) {
        return runtime.invoke<SaveConfigurationResult>("save_configuration", { draft });
      }
      if (environment.sessionStorage?.getItem("lmm.simulateSaveFailure") === "true") {
        throw new Error("配置目录不可写");
      }
      environment.localStorage?.setItem("lmm.config", JSON.stringify(draft));
      return { status: "saved", message: "设置已保存" };
    },
    async publishUpdated(source) {
      if (runtime.isDesktop) {
        try {
          await runtime.emit("lmm://configuration-updated", { source });
          return;
        } catch {
          environment.events?.dispatchEvent(new Event("lmm:configuration-updated"));
          return;
        }
      }
      environment.events?.dispatchEvent(new Event("lmm:configuration-updated"));
    },
    listenUpdated(handler) {
      if (runtime.isDesktop) {
        return runtime.listen("lmm://configuration-updated", handler);
      }
      const events = environment.events;
      if (!events?.addEventListener || !events.removeEventListener) {
        return Promise.resolve(() => undefined);
      }
      const listener = () => handler();
      events.addEventListener("lmm:configuration-updated", listener);
      return Promise.resolve(() => {
        events.removeEventListener?.("lmm:configuration-updated", listener);
      });
    },
  };
}

export const configurationService = createConfigurationService(appRuntime);
