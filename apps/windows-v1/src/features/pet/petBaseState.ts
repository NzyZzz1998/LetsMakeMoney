import type { DashboardState, WorkPhase } from "../../dashboardProjection";

export type PetBaseState = "working" | "awake_rest" | "sleeping";

export interface PetDashboardState {
  state: DashboardState;
  phase: WorkPhase;
}

function minuteOfDay(value: Date) {
  return value.getHours() * 60 + value.getMinutes();
}

function isSleepingWindow(value: Date) {
  const minute = minuteOfDay(value);
  return minute >= 23 * 60 || minute < 7 * 60 + 30;
}

export function resolvePetBaseState(
  dashboard: PetDashboardState,
  now: Date,
): PetBaseState {
  if (dashboard.state !== "ready") return "awake_rest";
  if (dashboard.phase === "working") return "working";
  if (dashboard.phase === "lunch") return "awake_rest";
  return isSleepingWindow(now) ? "sleeping" : "awake_rest";
}
