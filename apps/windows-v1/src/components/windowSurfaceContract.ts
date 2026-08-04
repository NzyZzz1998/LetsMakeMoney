export type WindowSurfaceVariant = "single-web-surface" | "native-shadow" | "opaque-outer";

export interface WindowSurfaceDecision {
  variant: WindowSurfaceVariant;
  accepted: boolean;
  reason: string;
}

export const WINDOW_SURFACE_ATTRIBUTES = {
  "data-surface-owner": "web-content",
  "data-shadow-owner": "none",
} as const;

export function evaluateWindowSurfaceVariant(variant: WindowSurfaceVariant): WindowSurfaceDecision {
  if (variant === "single-web-surface") {
    return {
      variant,
      accepted: true,
      reason: "Web 内容层独占圆角、边框和背景，透明原生窗口不再叠加外部弧线。",
    };
  }
  if (variant === "native-shadow") {
    return {
      variant,
      accepted: false,
      reason: "透明窗口的 DWM 阴影会在 Web 圆角外形成第二层弧线。",
    };
  }
  return {
    variant,
    accepted: false,
    reason: "非透明外层会破坏透明圆角，并在窗口四角暴露矩形底色。",
  };
}
