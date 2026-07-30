import {
  appRuntime,
  type AppRuntime,
} from "../runtime/appRuntime";
import type { MiniEdgeDock } from "../domain/configuration";

export type WindowKind = "mini" | "workbench" | "settings" | "wizard";

export interface WindowDragOrigin {
  x: number;
  y: number;
  scale_factor: number;
}

export type MiniEdgeVisibility = "expanded" | "retracted";

export interface MiniEdgeStatus {
  auto_hide: boolean;
  dock: MiniEdgeDock;
  visibility: MiniEdgeVisibility;
  notice: "fallback" | null;
}

export interface WindowService {
  show(label: WindowKind): Promise<void>;
  hide(label: WindowKind): Promise<void>;
  move(label: WindowKind, x: number, y: number): Promise<void>;
  dragOrigin(label: WindowKind): Promise<WindowDragOrigin>;
  setMiniState(state: string): Promise<void>;
  miniEdgeStatus(): Promise<MiniEdgeStatus>;
  completeMiniDrag(reducedMotion: boolean): Promise<MiniEdgeStatus>;
  setMiniEdgeRetracted(
    retracted: boolean,
    source: string,
    reducedMotion: boolean,
  ): Promise<MiniEdgeStatus>;
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
    miniEdgeStatus: () => runtime.invoke<MiniEdgeStatus>("mini_edge_status"),
    completeMiniDrag: reducedMotion =>
      runtime.invoke<MiniEdgeStatus>("complete_mini_drag", { reducedMotion }),
    setMiniEdgeRetracted: (retracted, source, reducedMotion) =>
      runtime.invoke<MiniEdgeStatus>("set_mini_edge_retracted", {
        retracted,
        source,
        reducedMotion,
      }),
    configurationInitialized: () => runtime.invoke<boolean>("configuration_initialized"),
    exit: () => runtime.invoke("exit_application"),
  };
}

export const windowService = createWindowService(appRuntime);
