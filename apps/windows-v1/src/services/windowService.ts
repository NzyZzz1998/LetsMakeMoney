import {
  appRuntime,
  type AppRuntime,
} from "../runtime/appRuntime";

export type WindowKind = "mini" | "workbench" | "settings" | "wizard";

export interface WindowDragOrigin {
  x: number;
  y: number;
  scale_factor: number;
}

export interface WindowService {
  show(label: WindowKind): Promise<void>;
  hide(label: WindowKind): Promise<void>;
  move(label: WindowKind, x: number, y: number): Promise<void>;
  dragOrigin(label: WindowKind): Promise<WindowDragOrigin>;
  setMiniState(state: string): Promise<void>;
  configurationInitialized(): Promise<boolean>;
  exit(): Promise<void>;
}

export function createWindowService(runtime: AppRuntime): WindowService {
  return {
    show: label => runtime.invoke("show_app_window", { label }),
    hide: label => runtime.invoke("hide_app_window", { label }),
    move: (label, x, y) => runtime.invoke("move_app_window", { label, x, y }),
    dragOrigin: label => runtime.invoke<WindowDragOrigin>("window_drag_origin", { label }),
    setMiniState: state => runtime.invoke("set_mini_window_state", { state }),
    configurationInitialized: () => runtime.invoke<boolean>("configuration_initialized"),
    exit: () => runtime.invoke("exit_application"),
  };
}

export const windowService = createWindowService(appRuntime);
