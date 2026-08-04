import {
  comboboxKeyAction,
  nextComboboxIndex,
  normalizeComboboxIndex,
  selectedComboboxIndex,
  shouldComboboxOpenUp,
} from "../src/components/comboboxModel";

function assert(condition: unknown, message: string): asserts condition {
  if (!condition) throw new Error(message);
}

assert(normalizeComboboxIndex(-2, 3) === 0, "negative indices must clamp to the first option");
assert(normalizeComboboxIndex(8, 3) === 2, "overflow indices must clamp to the last option");
assert(selectedComboboxIndex("single", ["double", "single", "alternating"]) === 1, "selected option must resolve");
assert(selectedComboboxIndex("", ["big", "small"]) === 0, "empty values must keep the first option navigable");
assert(nextComboboxIndex(2, "ArrowDown", 3) === 0, "ArrowDown must wrap");
assert(nextComboboxIndex(0, "ArrowUp", 3) === 2, "ArrowUp must wrap");
assert(nextComboboxIndex(1, "Home", 3) === 0, "Home must select the first option");
assert(nextComboboxIndex(1, "End", 3) === 2, "End must select the last option");

const open = comboboxKeyAction({ key: "Enter", open: false, activeIndex: 0, selectedIndex: 1, optionCount: 3 });
assert(open.type === "open" && open.index === 1, "Enter must open at the selected option");
const select = comboboxKeyAction({ key: " ", open: true, activeIndex: 2, selectedIndex: 1, optionCount: 3 });
assert(select.type === "select", "Space must select the active option");
const escape = comboboxKeyAction({ key: "Escape", open: true, activeIndex: 0, selectedIndex: 0, optionCount: 3 });
assert(escape.type === "close" && escape.restoreFocus, "Escape must close and restore trigger focus");
const tab = comboboxKeyAction({ key: "Tab", open: true, activeIndex: 0, selectedIndex: 0, optionCount: 3 });
assert(tab.type === "close" && !tab.restoreFocus, "Tab must close without trapping focus");
assert(shouldComboboxOpenUp({ triggerTop: 420, triggerBottom: 456, listHeight: 120, viewportHeight: 500 }), "near-bottom controls must open upward");
assert(!shouldComboboxOpenUp({ triggerTop: 100, triggerBottom: 136, listHeight: 120, viewportHeight: 500 }), "controls with room below must open downward");

console.log("combobox behavior: 14/14 passed");
