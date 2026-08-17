import { mirrorRegionRuns } from "./hit-mask.mjs";

export function resolveDirectionalFrame({ direction, hitMaskRuns, logicalWidth }) {
  if (direction !== "left" && direction !== "right") {
    throw new RangeError("Direction must be either left or right.");
  }
  if (!Array.isArray(hitMaskRuns) || hitMaskRuns.length === 0) {
    throw new RangeError("Directional frames require a non-empty hit mask.");
  }

  const mirrorX = direction === "left";
  return {
    direction,
    mirrorX,
    rects: mirrorX ? mirrorRegionRuns(hitMaskRuns, logicalWidth) : hitMaskRuns,
  };
}
