export type WindowSurfaceVariant = "native-shadow" | "web-shadow" | "opaque-outer";

export interface WindowSurfaceDecision {
  variant: WindowSurfaceVariant;
  accepted: boolean;
  reason: string;
}

export const WINDOW_SURFACE_ATTRIBUTES = {
  "data-surface-owner": "web-content",
  "data-shadow-owner": "native-window",
} as const;

export function evaluateWindowSurfaceVariant(variant: WindowSurfaceVariant): WindowSurfaceDecision {
  if (variant === "native-shadow") {
    return {
      variant,
      accepted: true,
      reason: "原生窗口独占外部阴影，Web 内容层独占圆角、边框和背景。",
    };
  }
  if (variant === "web-shadow") {
    return {
      variant,
      accepted: false,
      reason: "透明 WebView 的 Web 阴影会与原生阴影叠加，形成双弧或裁切风险。",
    };
  }
  return {
    variant,
    accepted: false,
    reason: "非透明外层会破坏透明圆角，并在窗口四角暴露矩形底色。",
  };
}
