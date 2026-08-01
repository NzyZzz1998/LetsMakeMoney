import {
  calendarCellContract,
  calendarCoveragePresentation,
  type CalendarBusinessState,
} from "../src/presentation";

function assert(condition: unknown, message: string): asserts condition {
  if (!condition) throw new Error(message);
}

const businessStates: CalendarBusinessState[] = [
  "workday",
  "rest_day",
  "adjusted_workday",
  "manual_workday",
  "paid_rest",
  "unpaid_rest",
];

for (const businessState of businessStates) {
  const contract = calendarCellContract({
    businessState,
    isToday: true,
    isSelected: true,
    isStale: true,
    isDisabled: true,
  });
  assert(
    contract.classNames.includes(`calendar-day--${businessState}`),
    `${businessState} must retain its business-state class`,
  );
  for (const navigationClass of ["is-today", "is-selected", "is-stale", "is-disabled"]) {
    assert(contract.classNames.includes(navigationClass), `${businessState} lost ${navigationClass}`);
  }
  assert(contract.todayCue === "今", `${businessState} must expose the approved today cue`);
  assert(contract.ariaLabel.includes("今天"), `${businessState} must announce today`);
  assert(contract.ariaLabel.includes("当前选中"), `${businessState} must announce selection`);
  assert(contract.ariaLabel.includes("数据可能不是最新"), `${businessState} must announce stale data`);
  assert(contract.ariaLabel.includes("不可用"), `${businessState} must announce disabled state`);
}

const ordinaryDay = calendarCellContract({
  businessState: "workday",
  isToday: false,
  isSelected: false,
});
assert(ordinaryDay.todayCue === null, "ordinary dates must not expose a today cue");
assert(!ordinaryDay.classNames.includes("is-today"), "ordinary dates must not receive today styling");

const official = calendarCoveragePresentation({ mode: "official", year: 2026 });
assert(!official.isVisible && official.tone === null, "official data must not occupy calendar content space");

const estimated = calendarCoveragePresentation({ mode: "estimated", year: 2027 });
assert(estimated.isVisible && estimated.tone === "estimated", "estimated data must remain visible");
assert(estimated.detail.includes("按你的休息模式推算"), "estimated data must explain its basis");
assert(estimated.detail.includes("不代表法定放假安排"), "estimated data must disclose its limit");

const stale = calendarCoveragePresentation({ mode: "stale", year: 2026 });
assert(stale.isVisible && stale.tone === "stale", "stale data must remain visible");
assert(stale.detail.includes("上次有效数据"), "stale data must explain retained content");

const integrityError = calendarCoveragePresentation({ mode: "integrity_error", year: 2026 });
assert(integrityError.isVisible && integrityError.tone === "error", "integrity errors must remain visible");
assert(integrityError.detail.includes("未使用估算结果替代"), "integrity errors must reject silent estimation");

console.log("v1.0.5 calendar presentation: 49/49 passed");
