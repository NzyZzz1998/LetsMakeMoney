function physicalBounds(rect, scale) {
  return {
    left: Math.floor(rect.x * scale),
    top: Math.floor(rect.y * scale),
    right: Math.ceil((rect.x + rect.width) * scale),
    bottom: Math.ceil((rect.y + rect.height) * scale),
  };
}

export function regionSignature(rects) {
  return rects.map(({ x, y, width, height }) => `${x},${y},${width},${height}`).join(";");
}

export function chooseNativeProbePoints({ rects, logicalWidth, logicalHeight, scale }) {
  if (!Array.isArray(rects) || rects.length === 0) {
    throw new Error("opaque probe unavailable");
  }
  const first = physicalBounds(rects[0], scale);
  const opaque = {
    x: Math.floor((first.left + first.right - 1) / 2),
    y: Math.floor((first.top + first.bottom - 1) / 2),
  };

  const coverage = new Uint8Array(logicalWidth * logicalHeight);
  for (const rect of rects) {
    for (let y = rect.y; y < rect.y + rect.height; y += 1) {
      coverage.fill(1, y * logicalWidth + rect.x, y * logicalWidth + rect.x + rect.width);
    }
  }
  const transparentIndex = coverage.findIndex((value) => value === 0);
  if (transparentIndex < 0) {
    throw new Error("transparent probe unavailable");
  }

  return {
    expected: [true, false],
    points: [
      opaque,
      {
        x: Math.floor((transparentIndex % logicalWidth) * scale),
        y: Math.floor(Math.floor(transparentIndex / logicalWidth) * scale),
      },
    ],
  };
}
