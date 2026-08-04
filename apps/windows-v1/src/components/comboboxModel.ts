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

export function selectedComboboxIndex(
  value: string,
  values: readonly string[],
  disabled: readonly boolean[] = [],
): number {
  const selected = values.indexOf(value);
  if (selected >= 0 && !disabled[selected]) return selected;
  return enabledIndex(0, 1, values.length, disabled);
}

function enabledIndex(
  start: number,
  direction: 1 | -1,
  optionCount: number,
  disabled: readonly boolean[],
): number {
  if (optionCount <= 0) return -1;
  for (let offset = 0; offset < optionCount; offset += 1) {
    const index = (start + direction * offset + optionCount) % optionCount;
    if (!disabled[index]) return index;
  }
  return -1;
}

export function nextComboboxIndex(
  currentIndex: number,
  key: "ArrowDown" | "ArrowUp" | "Home" | "End",
  optionCount: number,
  disabled: readonly boolean[] = [],
): number {
  if (optionCount <= 0) return -1;
  if (key === "Home") return enabledIndex(0, 1, optionCount, disabled);
  if (key === "End") return enabledIndex(optionCount - 1, -1, optionCount, disabled);
  const current = normalizeComboboxIndex(currentIndex, optionCount);
  const delta = key === "ArrowDown" ? 1 : -1;
  return enabledIndex(current + delta, delta, optionCount, disabled);
}

export function comboboxKeyAction({
  key,
  open,
  activeIndex,
  selectedIndex,
  optionCount,
  disabled = [],
}: {
  key: string;
  open: boolean;
  activeIndex: number;
  selectedIndex: number;
  optionCount: number;
  disabled?: readonly boolean[];
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
    return { type: "move", index: nextComboboxIndex(activeIndex, key, optionCount, disabled) };
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
