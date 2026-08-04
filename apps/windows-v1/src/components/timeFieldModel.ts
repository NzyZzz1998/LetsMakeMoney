export interface ParsedTimeValue {
  hour: number;
  minute: number;
}

export function parseTimeValue(value: string): ParsedTimeValue {
  const match = /^(\d{1,2}):(\d{1,2})$/.exec(value.trim());
  if (!match) return { hour: 9, minute: 0 };
  return {
    hour: Math.min(23, Math.max(0, Number(match[1]))),
    minute: Math.min(59, Math.max(0, Number(match[2]))),
  };
}

export function formatTimeValue(hour: number, minute: number): string {
  const safeHour = Math.min(23, Math.max(0, Math.round(hour)));
  const safeMinute = Math.min(59, Math.max(0, Math.round(minute)));
  return `${String(safeHour).padStart(2, "0")}:${String(safeMinute).padStart(2, "0")}`;
}

export function moveTimePart(
  value: number,
  key: "ArrowDown" | "ArrowUp" | "Home" | "End",
  maximum: number,
): number {
  if (key === "Home") return 0;
  if (key === "End") return maximum;
  const delta = key === "ArrowDown" ? 1 : -1;
  return (value + delta + maximum + 1) % (maximum + 1);
}

export function shouldTimeFieldOpenUp({
  triggerTop,
  triggerBottom,
  popoverHeight,
  viewportHeight,
  margin = 12,
}: {
  triggerTop: number;
  triggerBottom: number;
  popoverHeight: number;
  viewportHeight: number;
  margin?: number;
}): boolean {
  const roomBelow = viewportHeight - triggerBottom - margin;
  const roomAbove = triggerTop - margin;
  return roomBelow < popoverHeight && roomAbove > roomBelow;
}
