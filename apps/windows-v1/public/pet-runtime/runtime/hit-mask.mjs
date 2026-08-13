export function alphaToRegionRuns(pixels, width, height, alphaThreshold = 8) {
  if (pixels.length !== width * height * 4) {
    throw new RangeError("RGBA buffer size does not match dimensions.");
  }
  const runs = [];
  for (let y = 0; y < height; y += 1) {
    let runStart = null;
    for (let x = 0; x <= width; x += 1) {
      const opaque = x < width && pixels[(y * width + x) * 4 + 3] >= alphaThreshold;
      if (opaque && runStart === null) {
        runStart = x;
      } else if (!opaque && runStart !== null) {
        runs.push({ x: runStart, y, width: x - runStart, height: 1 });
        runStart = null;
      }
    }
  }
  return runs;
}

export function mirrorRegionRuns(runs, logicalWidth) {
  return runs.map((run) => ({
    ...run,
    x: logicalWidth - run.x - run.width,
  }));
}

export function isPermanentRectangleFallback(runs, width, height) {
  if (runs.length === 1) {
    const [run] = runs;
    return run.x === 0 && run.y === 0 && run.width === width && run.height === height;
  }
  const coverage = new Uint8Array(width * height);
  for (const run of runs) {
    const right = Math.min(width, run.x + run.width);
    const bottom = Math.min(height, run.y + run.height);
    for (let y = Math.max(0, run.y); y < bottom; y += 1) {
      coverage.fill(1, y * width + Math.max(0, run.x), y * width + right);
    }
  }
  return coverage.every((value) => value === 1);
}
