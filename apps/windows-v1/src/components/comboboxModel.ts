export type ComboboxKeyAction =
  | { type: "open"; index: number }
  | { type: "move"; index: number }
  | { type: "select" }
  | { type: "close"; restoreFocus: boolean }
  | { type: "none" };

export function normalizeComboboxIndex(index: number, optionCount: number): number {
  if (optionCount <= 0) return -1;
  return Math.min(Math.max(index, 0), optionCount - 1);
}

export function selectedComboboxIndex(value: string, values: readonly string[]): number {
  const selected = values.indexOf(value);
  return selected >= 0 ? selected : 0;
}

export function nextComboboxIndex(
  currentIndex: number,
  key: "ArrowDown" | "ArrowUp" | "Home" | "End",
  optionCount: number,
): number {
  if (optionCount <= 0) return -1;
  if (key === "Home") return 0;
  if (key === "End") return optionCount - 1;
  const current = normalizeComboboxIndex(currentIndex, optionCount);
  const delta = key === "ArrowDown" ? 1 : -1;
  return (current + delta + optionCount) % optionCount;
}

export function comboboxKeyAction({
  key,
  open,
  activeIndex,
  selectedIndex,
  optionCount,
}: {
  key: string;
  open: boolean;
  activeIndex: number;
  selectedIndex: number;
  optionCount: number;
}): ComboboxKeyAction {
  if (key === "Escape") {
    return open ? { type: "close", restoreFocus: true } : { type: "none" };
  }
  if (key === "Tab") {
    return open ? { type: "close", restoreFocus: false } : { type: "none" };
  }
  if (key === "Enter" || key === " ") {
    if (!open) return { type: "open", index: normalizeComboboxIndex(selectedIndex, optionCount) };
    return { type: "select" };
  }
  if (key === "ArrowDown" || key === "ArrowUp" || key === "Home" || key === "End") {
    if (!open) {
      const initial = key === "ArrowUp" || key === "End"
        ? optionCount - 1
        : key === "Home"
          ? 0
          : selectedIndex;
      return { type: "open", index: normalizeComboboxIndex(initial, optionCount) };
    }
    return { type: "move", index: nextComboboxIndex(activeIndex, key, optionCount) };
  }
  return { type: "none" };
}

export function shouldComboboxOpenUp({
  triggerTop,
  triggerBottom,
  listHeight,
  viewportHeight,
  margin = 12,
}: {
  triggerTop: number;
  triggerBottom: number;
  listHeight: number;
  viewportHeight: number;
  margin?: number;
}): boolean {
  const roomBelow = viewportHeight - triggerBottom - margin;
  const roomAbove = triggerTop - margin;
  return roomBelow < listHeight && roomAbove > roomBelow;
}
