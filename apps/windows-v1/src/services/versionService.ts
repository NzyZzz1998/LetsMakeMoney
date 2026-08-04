import { getVersion as readTauriVersion } from "@tauri-apps/api/app";
import {
  appRuntime,
  type AppRuntime,
} from "../runtime/appRuntime";

export interface VersionService {
  read(): Promise<string>;
}

const VERSION_PATTERN = /^\d+\.\d+\.\d+(?:[-+][0-9A-Za-z.-]+)?$/;

export function createVersionService(
  runtime: AppRuntime,
  desktopReader: () => Promise<string> = readTauriVersion,
): VersionService {
  return {
    async read() {
      if (!runtime.isDesktop) return "dev-preview";
      const version = (await desktopReader()).trim();
      if (!VERSION_PATTERN.test(version)) {
        throw new Error("invalid_desktop_version_metadata");
      }
      return version;
    },
  };
}

export const versionService = createVersionService(appRuntime);
