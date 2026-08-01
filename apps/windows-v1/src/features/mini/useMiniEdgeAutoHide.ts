import {
  useCallback,
  useEffect,
  useRef,
  useState,
  type FocusEvent,
} from "react";

import { createDeferredDisposer } from "../../runtime/appRuntime";
import { configurationService } from "../../services/configurationService";
import { windowService } from "../../services/windowService";
import { recordSemanticEvent } from "../../model";
import {
  createMiniEdgeAutoHideController,
  type MiniEdgeAutoHideController,
  type MiniEdgeSnapshot,
} from "./miniEdgeAutoHide";

const INITIAL_SNAPSHOT: MiniEdgeSnapshot = {
  autoHide: true,
  dock: "none",
  phase: "expanded",
  pointerInside: false,
  locks: {
    dragging: false,
    focus_inside: false,
    menu_open: false,
    modal_open: false,
  },
};

export function useMiniEdgeAutoHide() {
  const [snapshot, setSnapshot] = useState<MiniEdgeSnapshot>(INITIAL_SNAPSHOT);
  const [feedback, setFeedback] = useState<string | null>(null);
  const controller = useRef<MiniEdgeAutoHideController | null>(null);
  const feedbackTimer = useRef<number | null>(null);

  useEffect(() => {
    const reducedMotion = () =>
      window.matchMedia("(prefers-reduced-motion: reduce)").matches;
    const reportError = () => {
      setFeedback("贴边隐藏暂不可用，已恢复完整窗口");
      if (feedbackTimer.current !== null) {
        window.clearTimeout(feedbackTimer.current);
      }
      feedbackTimer.current = window.setTimeout(() => {
        feedbackTimer.current = null;
        setFeedback(null);
      }, 4_000);
    };
    const current = createMiniEdgeAutoHideController({
      readStatus: windowService.miniEdgeStatus,
      setRetracted: (retracted, source) =>
        windowService.setMiniEdgeRetracted(retracted, source, reducedMotion()),
      completeDrag: () => windowService.completeMiniDrag(reducedMotion()),
      onChange: setSnapshot,
      onError: reportError,
      onEvent: recordSemanticEvent,
    });
    controller.current = current;
    void current.initialize();

    const handleFocus = () => {
      current.setLock("focus_inside", true);
    };
    const handleBlur = () => {
      current.setLock("focus_inside", false);
    };
    const handleShown = () => {
      void current.reveal("window_shown");
    };
    const handleConfigurationUpdated = () => {
      void current.refresh();
    };
    window.addEventListener("focus", handleFocus);
    window.addEventListener("blur", handleBlur);
    window.addEventListener("lmm:window-shown", handleShown);
    window.addEventListener(
      "lmm:configuration-updated",
      handleConfigurationUpdated,
    );
    const configurationListener = createDeferredDisposer();
    if (configurationService.isDesktop) {
      void configurationService
        .listenUpdated(handleConfigurationUpdated)
        .then(unlisten => configurationListener.attach(unlisten))
        .catch(reportError);
    }
    return () => {
      window.removeEventListener("focus", handleFocus);
      window.removeEventListener("blur", handleBlur);
      window.removeEventListener("lmm:window-shown", handleShown);
      window.removeEventListener(
        "lmm:configuration-updated",
        handleConfigurationUpdated,
      );
      configurationListener.dispose();
      current.dispose();
      if (controller.current === current) controller.current = null;
      if (feedbackTimer.current !== null) {
        window.clearTimeout(feedbackTimer.current);
        feedbackTimer.current = null;
      }
    };
  }, []);

  const onFocusCapture = useCallback(() => {
    controller.current?.setLock("focus_inside", true);
  }, []);

  const onBlurCapture = useCallback((event: FocusEvent<HTMLElement>) => {
    const next = event.relatedTarget;
    if (!(next instanceof Node) || !event.currentTarget.contains(next)) {
      controller.current?.setLock("focus_inside", false);
    }
  }, []);

  return {
    snapshot,
    feedback,
    handlers: {
      onPointerEnter: () => controller.current?.pointerEntered(),
      onPointerLeave: () => controller.current?.pointerLeft(),
      onFocusCapture,
      onBlurCapture,
    },
    dragStarted: () => controller.current?.dragStarted(),
    dragCompleted: () => controller.current?.dragCompleted(),
    reveal: (source: string) => controller.current?.reveal(source),
  };
}
