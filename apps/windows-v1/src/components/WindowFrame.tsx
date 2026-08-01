import type { ReactNode } from "react";
import { IconButton } from "../components";
import { useWindowDrag } from "../hooks/useWindowDrag";
import {
  windowService,
  type WindowKind,
} from "../services/windowService";

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
    void windowService.hide(kind).catch(() => {
      // Browser preview intentionally has no native window to hide.
    });
  });

  return (
    <main
      className={`window-frame ${className}`}
      data-window={kind}
      data-surface-owner="window-frame"
      data-shadow-owner="native-window"
      {...drag.handlers}
    >
      <header className="titlebar">
        <div className="titlebar__identity">
          <span className="coin-mark" aria-hidden="true">¥</span>
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
