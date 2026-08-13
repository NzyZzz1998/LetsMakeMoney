import { invoke } from "@tauri-apps/api/core";
import { useEffect, useRef } from "react";
import { useDashboard } from "../../model";
import { systemTime } from "../../runtime/timeService";
import { resolvePetBaseState } from "./petBaseState";

const PET_RUNTIME_SCRIPT_ID = "lmm-pet-runtime";

declare global {
  interface Window {
    __LMM_PET_INVOKE__?: typeof invoke;
  }
}

export function PetWindow() {
  const { snapshot: dashboard } = useDashboard();
  const revision = useRef(0);
  const baseState = resolvePetBaseState(dashboard, systemTime.now());

  useEffect(() => {
    const canvas = document.querySelector<HTMLCanvasElement>("#pet-canvas");
    if (canvas) canvas.dataset.baseState = baseState;
    revision.current += 1;
    window.dispatchEvent(new CustomEvent("lmm:pet-base-state", {
      detail: {
        baseState,
        ownerDate: dashboard.ownerDate,
        revision: revision.current,
      },
    }));
  }, [baseState, dashboard.ownerDate]);

  useEffect(() => {
    if (document.getElementById(PET_RUNTIME_SCRIPT_ID)) return;
    window.__LMM_PET_INVOKE__ = invoke;
    const script = document.createElement("script");
    script.id = PET_RUNTIME_SCRIPT_ID;
    script.type = "module";
    script.src = "/pet-runtime/main.mjs";
    document.body.append(script);
  }, []);

  return (
    <main className="pet-window" aria-label="Classic 桌宠">
      <canvas
        id="pet-canvas"
        width="256"
        height="208"
        data-base-state={baseState}
        aria-label="Classic 桌宠动画"
      />
    </main>
  );
}
