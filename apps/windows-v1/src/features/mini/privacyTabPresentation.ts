import type { DashboardState, WorkPhase } from "../../dashboardProjection";
import type { BoundaryKind } from "../../presentation";

export interface PrivacyTabPresentationInput {
  state: DashboardState;
  phase?: WorkPhase;
  nextBoundaryKind?: BoundaryKind;
  nextBoundarySeconds?: number | null;
}

export interface PrivacyTabPresentation {
  visibleText: string;
  ariaLabel: string;
}

type BoundaryAction = "上班" | "休息" | "恢复工作" | "下班";

function compactBoundaryAction(action: BoundaryAction) {
  return action === "恢复工作" ? "复工" : action;
}

function durationText(seconds: number, compact = false) {
  const minutes = Math.max(1, Math.ceil(seconds / 60));
  if (minutes > 99 * 60) return compact ? "99时+" : "99+小时";
  const hours = Math.floor(minutes / 60);
  const remainder = minutes % 60;
  if (hours === 0) return compact ? `${minutes}分` : `${minutes}分钟`;
  return remainder === 0
    ? compact ? `${hours}时` : `${hours}小时`
    : compact ? `${hours}时${remainder}分` : `${hours}小时${remainder}分`;
}

function boundaryAction(input: PrivacyTabPresentationInput): BoundaryAction | null {
  if (input.phase === "before_work") return "上班";
  if (input.phase === "lunch") return "恢复工作";
  if (input.phase === "working" && input.nextBoundaryKind === "rest_start") return "休息";
  if (input.phase === "working" && input.nextBoundaryKind === "work_end") return "下班";
  return null;
}

export function privacyTabPresentation(
  input: PrivacyTabPresentationInput,
): PrivacyTabPresentation {
  let visibleText = "点击展开";
  let accessibleText = "点击展开查看";
  if (input.state === "loading") {
    visibleText = "同步中";
    accessibleText = "正在同步";
  } else if (
    input.state === "ready"
    && input.phase
    && ["rest_day", "paid_rest", "unpaid_rest"].includes(input.phase)
  ) {
    visibleText = "今日休息";
    accessibleText = visibleText;
  } else if (input.state === "ready" && input.phase === "after_work") {
    visibleText = "今日结束";
    accessibleText = "今日工作已结束";
  } else if (input.state === "ready") {
    const action = boundaryAction(input);
    if (action && input.nextBoundarySeconds !== null && input.nextBoundarySeconds !== undefined) {
      visibleText = input.nextBoundarySeconds < 60
        ? `即将${action}`
        : `距离${compactBoundaryAction(action)}${durationText(input.nextBoundarySeconds, true)}`;
      accessibleText = input.nextBoundarySeconds < 60
        ? visibleText
        : `距离${action} ${durationText(input.nextBoundarySeconds)}`;
    }
  }

  return {
    visibleText,
    ariaLabel: `${accessibleText}，按 Enter 或空格键展开迷你收入视图`,
  };
}
