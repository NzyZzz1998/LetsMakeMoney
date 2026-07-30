import { invoke as tauriInvoke } from "@tauri-apps/api/core";
import {
  emit as tauriEmit,
  listen as tauriListen,
  type UnlistenFn,
} from "@tauri-apps/api/event";

export interface DesktopBridge {
  invoke<T>(command: string, args?: Record<string, unknown>): Promise<T>;
  emit(event: string, payload?: unknown): Promise<void>;
  listen<T>(event: string, handler: (payload: T) => void): Promise<UnlistenFn>;
}

export interface AppRuntime {
  readonly isDesktop: boolean;
  invoke<T>(command: string, args?: Record<string, unknown>): Promise<T>;
  emit(event: string, payload?: unknown): Promise<void>;
  listen<T>(event: string, handler: (payload: T) => void): Promise<UnlistenFn>;
}

export interface DeferredDisposer {
  attach(disposer: () => void): void;
  dispose(): void;
}

export function createDeferredDisposer(): DeferredDisposer {
  let disposed = false;
  let attached: (() => void) | null = null;

  return {
    attach(disposer) {
      if (disposed) {
        disposer();
        return;
      }
      attached?.();
      attached = disposer;
    },
    dispose() {
      if (disposed) return;
      disposed = true;
      attached?.();
      attached = null;
    },
  };
}

function unavailable(command: string) {
  return new Error(`desktop_runtime_unavailable:${command}`);
}

export function createAppRuntime(bridge?: DesktopBridge): AppRuntime {
  return {
    isDesktop: bridge !== undefined,
    invoke<T>(command: string, args?: Record<string, unknown>) {
      if (!bridge) return Promise.reject(unavailable(command));
      return bridge.invoke<T>(command, args);
    },
    emit(event: string, payload?: unknown) {
      if (!bridge) return Promise.reject(unavailable(event));
      return bridge.emit(event, payload);
    },
    listen<T>(event: string, handler: (payload: T) => void) {
      if (!bridge) return Promise.reject(unavailable(event));
      return bridge.listen(event, handler);
    },
  };
}

function detectDesktopBridge(): DesktopBridge | undefined {
  if (typeof window === "undefined" || !("__TAURI_INTERNALS__" in window)) {
    return undefined;
  }
  return {
    invoke: <T>(command: string, args?: Record<string, unknown>) => tauriInvoke<T>(command, args),
    emit: (event, payload) => tauriEmit(event, payload),
    listen: <T>(event: string, handler: (payload: T) => void) =>
      tauriListen<T>(event, message => handler(message.payload)),
  };
}

export const appRuntime = createAppRuntime(detectDesktopBridge());
