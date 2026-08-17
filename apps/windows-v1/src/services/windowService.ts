import {
  appRuntime,
  type AppRuntime,
} from "../runtime/appRuntime";
import type {
  DesktopCompanionMode,
  MiniEdgeDock,
} from "../domain/configuration";

export type WindowKind = "mini" | "pet" | "workbench" | "settings" | "wizard";

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

export interface PetRuntimePackageSummary {
  petId: string;
  packageVersion: string;
  actionCount: number;
  manifestSha256: string;
  packageTreeSha256: string;
}

export interface PetProductPackageStatus {
  available: boolean;
  reason: string | null;
  package: PetRuntimePackageSummary | null;
}

export interface WindowService {
  readonly isDesktop: boolean;
  show(label: WindowKind): Promise<void>;
  hide(label: WindowKind): Promise<void>;
  move(label: WindowKind, x: number, y: number): Promise<void>;
  finalizeDrag(label: WindowKind): Promise<void>;
  recover(label: WindowKind, source: string): Promise<void>;
  dragOrigin(label: WindowKind): Promise<WindowDragOrigin>;
  setMiniState(state: string): Promise<void>;
  miniEdgeStatus(): Promise<MiniEdgeStatus>;
  completeMiniDrag(reducedMotion: boolean): Promise<MiniEdgeStatus>;
  setMiniEdgeRetracted(
    retracted: boolean,
    source: string,
    reducedMotion: boolean,
  ): Promise<MiniEdgeStatus>;
  switchDesktopCompanion(mode: DesktopCompanionMode): Promise<void>;
  petPackageStatus(): Promise<PetProductPackageStatus>;
  showDesktopCompanion(): Promise<void>;
  configurationInitialized(): Promise<boolean>;
  workbenchReady(): Promise<void>;
  exit(): Promise<void>;
}

export type WindowOperation =
  | "show"
  | "hide"
  | "move"
  | "finalize_drag"
  | "recover"
  | "drag_origin"
  | "workbench_ready"
  | "always_on_top";

export interface WindowOperationFailureDetail {
  label: WindowKind;
  operation: WindowOperation;
  reason: string;
}

export class WindowOperationError extends Error {
  readonly label: WindowKind;
  readonly operation: WindowOperation;
  readonly reason: string;

  constructor(detail: WindowOperationFailureDetail) {
    super(`window_operation_failed:${detail.operation}:${detail.label}:${detail.reason}`);
    this.name = "WindowOperationError";
    this.label = detail.label;
    this.operation = detail.operation;
    this.reason = detail.reason;
  }
}

function reportWindowOperationFailure(detail: WindowOperationFailureDetail) {
  if (typeof window === "undefined") return;
  window.dispatchEvent(new CustomEvent<WindowOperationFailureDetail>(
    "lmm:window-operation-failed",
    { detail },
  ));
}

async function invokeWindowOperation<T>(
  runtime: AppRuntime,
  operation: WindowOperation,
  label: WindowKind,
  command: string,
  args?: Record<string, unknown>,
): Promise<T> {
  try {
    return await runtime.invoke<T>(command, args);
  } catch (error) {
    const detail: WindowOperationFailureDetail = {
      label,
      operation,
      reason: error instanceof Error ? error.message : String(error),
    };
    if (runtime.isDesktop) reportWindowOperationFailure(detail);
    throw new WindowOperationError(detail);
  }
}

export function createWindowService(runtime: AppRuntime): WindowService {
  return {
    isDesktop: runtime.isDesktop,
    show: label => invokeWindowOperation(runtime, "show", label, "show_app_window", { label }),
    hide: label => invokeWindowOperation(runtime, "hide", label, "hide_app_window", { label }),
    move: (label, x, y) => invokeWindowOperation(runtime, "move", label, "move_app_window", { label, x, y }),
    finalizeDrag: label => invokeWindowOperation(runtime, "finalize_drag", label, "finalize_window_drag", { label }),
    recover: (label, source) => invokeWindowOperation(runtime, "recover", label, "recover_app_window", { label, source }),
    dragOrigin: label => invokeWindowOperation<WindowDragOrigin>(runtime, "drag_origin", label, "window_drag_origin", { label }),
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
    switchDesktopCompanion: mode =>
      runtime.invoke("switch_desktop_companion", { mode }),
    petPackageStatus: () =>
      runtime.invoke<PetProductPackageStatus>("pet_package_status"),
    showDesktopCompanion: () =>
      runtime.invoke("show_desktop_companion"),
    configurationInitialized: () => runtime.invoke<boolean>("configuration_initialized"),
    workbenchReady: () => invokeWindowOperation(runtime, "workbench_ready", "workbench", "workbench_ready"),
    exit: () => runtime.invoke("exit_application"),
  };
}

export const windowService = createWindowService(appRuntime);
