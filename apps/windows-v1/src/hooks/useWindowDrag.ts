import { useRef, type PointerEvent as ReactPointerEvent } from "react";
import {
  windowService,
  type WindowDragOrigin,
  type WindowKind,
} from "../services/windowService";

const DRAG_THRESHOLD_PX = 5;
const INTERACTIVE_DRAG_SELECTOR =
  "button, input, select, textarea, a, [role='switch'], [data-window-drag='false']";

interface WindowDragPointer {
  id: number;
  startX: number;
  startY: number;
  currentX: number;
  currentY: number;
  origin: WindowDragOrigin | null;
  dragging: boolean;
  frame: number | null;
  captureTarget: HTMLElement;
}

interface WindowDragOptions {
  allowInteractiveStart?: boolean;
  onDragStart?(): void | Promise<void>;
  onDragEnd?(): void | Promise<void>;
}

export function useWindowDrag(
  kind: WindowKind,
  {
    allowInteractiveStart = false,
    onDragStart,
    onDragEnd,
  }: WindowDragOptions = {},
) {
  const pointer = useRef<WindowDragPointer | null>(null);
  const dragged = useRef(false);

  const moveWindow = (current: NonNullable<typeof pointer.current>): Promise<void> => {
    if (!current.origin) return Promise.resolve();
    const scale = current.origin.scale_factor;
    return windowService.move(
      kind,
      Math.round(current.origin.x + (current.currentX - current.startX) * scale),
      Math.round(current.origin.y + (current.currentY - current.startY) * scale),
    );
  };

  const scheduleMove = (current: NonNullable<typeof pointer.current>) => {
    if (current.frame !== null) return;
    current.frame = window.requestAnimationFrame(() => {
      current.frame = null;
      if (pointer.current === current && current.dragging) void moveWindow(current);
    });
  };

  const cancel = (event?: ReactPointerEvent<HTMLElement>, commit = false) => {
    const current = pointer.current;
    if (!current || (event && current.id !== event.pointerId)) return;
    if (event) {
      current.currentX = event.screenX;
      current.currentY = event.screenY;
    }
    if (current.frame !== null) window.cancelAnimationFrame(current.frame);
    if (current.captureTarget.hasPointerCapture(current.id)) {
      current.captureTarget.releasePointerCapture(current.id);
    }
    pointer.current = null;
    if (current.dragging) {
      if (commit) {
        void moveWindow(current).finally(() => {
          void onDragEnd?.();
        });
      } else {
        void onDragEnd?.();
      }
    }
  };

  const handlers = {
    onPointerDownCapture(event: ReactPointerEvent<HTMLElement>) {
      if (event.button !== 0 || !event.isPrimary) return;
      const target = event.target as HTMLElement;
      if (!allowInteractiveStart && target.closest(INTERACTIVE_DRAG_SELECTOR)) return;
      dragged.current = false;
      const captureTarget = event.currentTarget;
      const current: WindowDragPointer = {
        id: event.pointerId,
        startX: event.screenX,
        startY: event.screenY,
        currentX: event.screenX,
        currentY: event.screenY,
        origin: null,
        dragging: false,
        frame: null,
        captureTarget,
      };
      pointer.current = current;
      void windowService.dragOrigin(kind)
        .then(origin => {
          if (pointer.current !== current) return;
          current.origin = origin;
          if (current.dragging) scheduleMove(current);
        })
        .catch(() => cancel());
    },
    onPointerMoveCapture(event: ReactPointerEvent<HTMLElement>) {
      const current = pointer.current;
      if (!current || current.id !== event.pointerId) return;
      if ((event.buttons & 1) === 0) {
        cancel(event, true);
        return;
      }
      current.currentX = event.screenX;
      current.currentY = event.screenY;
      const distance = Math.hypot(
        current.currentX - current.startX,
        current.currentY - current.startY,
      );
      if (distance < DRAG_THRESHOLD_PX) return;
      if (!current.dragging) {
        current.dragging = true;
        dragged.current = true;
        current.captureTarget.setPointerCapture(current.id);
        void onDragStart?.();
      }
      event.preventDefault();
      if (current.origin) scheduleMove(current);
    },
    onPointerUpCapture(event: ReactPointerEvent<HTMLElement>) {
      cancel(event, true);
    },
    onPointerCancelCapture(event: ReactPointerEvent<HTMLElement>) {
      cancel(event);
    },
  };

  return {
    handlers,
    consumeDraggedClick() {
      if (!dragged.current) return false;
      dragged.current = false;
      return true;
    },
  };
}
