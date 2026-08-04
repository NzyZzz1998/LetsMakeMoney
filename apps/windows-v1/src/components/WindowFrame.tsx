import type { ReactNode } from "react";
import { IconButton } from "../components";
import { useWindowDrag } from "../hooks/useWindowDrag";
import {
  windowService,
  type WindowKind,
} from "../services/windowService";
import { AppMark } from "./AppMark";
import { WINDOW_SURFACE_ATTRIBUTES } from "./windowSurfaceContract";

export function WindowFrame({
  kind,
  title,
  children,
  className = "",
  onClose,
}: {
  kind: WindowKind;
  title: string;
  children: ReactNode;
  className?: string;
  onClose?: () => void;
}) {
  const drag = useWindowDrag(kind);
  const close = onClose ?? (() => {
    void windowService.hide(kind).catch(() => undefined);
  });

  return (
    <main
      className={`window-frame ${className}`}
      data-window={kind}
      {...WINDOW_SURFACE_ATTRIBUTES}
      {...drag.handlers}
    >
      <header className="titlebar">
        <div className="titlebar__identity">
          <AppMark />
          <strong>{title}</strong>
        </div>
        <IconButton
          label={`关闭${title}`}
          icon="close"
          data-window-drag="false"
          onClick={close}
        />
      </header>
      {children}
    </main>
  );
}
