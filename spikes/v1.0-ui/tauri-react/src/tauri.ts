import { invoke } from "@tauri-apps/api/core";

export type WindowMode = "mini" | "workbench" | "settings";

export type SaveResult = {
  status: "saved" | "unchanged";
  message: string;
};

const isTauri = () => "__TAURI_INTERNALS__" in window;

export async function setWindowMode(mode: WindowMode): Promise<void> {
  if (isTauri()) {
    await invoke("set_window_mode", { mode });
  }
}

export async function hideToTray(): Promise<void> {
  if (isTauri()) {
    await invoke("hide_to_tray");
  }
}

export async function saveSettings(
  salary: string,
  simulateFailure: boolean
): Promise<SaveResult> {
  if (isTauri()) {
    return invoke<SaveResult>("save_settings", {
      payload: { salary, simulateFailure }
    });
  }
  if (simulateFailure) {
    throw new Error("配置文件暂时不可写");
  }
  return {
    status: salary === "10,000" ? "unchanged" : "saved",
    message: salary === "10,000" ? "没有需要保存的更改" : "已保存到本机"
  };
}

