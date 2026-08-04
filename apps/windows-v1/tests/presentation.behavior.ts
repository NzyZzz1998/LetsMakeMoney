import {
  boundaryPresentation,
  calendarCellContract,
  calendarCoveragePresentation,
  timelineRows,
  workbenchHeading,
} from "../src/presentation";

function assert(condition: unknown, message: string): asserts condition {
  if (!condition) throw new Error(message);
}

assert(
  boundaryPresentation({
    phase: "before_work",
    nextBoundaryKind: "work_start",
    nextBoundarySeconds: 600,
  }).countdownLabel === "距离上班",
  "before work must name the actual start boundary",
);
assert(
  boundaryPresentation({
    phase: "working",
    nextBoundaryKind: "rest_start",
    nextBoundarySeconds: 600,
  }).countdownLabel === "距离休息",
  "working before rest must name the rest boundary",
);
assert(
  boundaryPresentation({
    phase: "lunch",
    nextBoundaryKind: "work_resume",
    nextBoundarySeconds: 600,
  }).countdownLabel === "距离恢复工作",
  "rest must name the resume boundary",
);
assert(
  boundaryPresentation({
    phase: "working",
    nextBoundaryKind: "work_end",
    nextBoundarySeconds: 600,
  }).countdownLabel === "距离下班",
  "working after rest must name the end boundary",
);
assert(
  boundaryPresentation({
    phase: "after_work",
    nextBoundaryKind: null,
    nextBoundarySeconds: null,
  }).completeLabel === "今日工作已结束",
  "after work must not show a fake countdown",
);

const zeroRest = timelineRows({
  phase: "working",
  nextBoundaryKind: "work_end",
  workStartTime: "09:00",
  restStartTime: "12:00",
  restEndTime: "12:00",
  workEndTime: "17:00",
});
assert(zeroRest.length === 2, "zero-rest schedules must omit rest rows");
assert(zeroRest[1]?.state === "current", "work end must be current when it is the next boundary");

const overnight = timelineRows({
  phase: "lunch",
  nextBoundaryKind: "work_resume",
  workStartTime: "23:00",
  restStartTime: "02:00",
  restEndTime: "02:30",
  workEndTime: "07:30",
});
assert(
  overnight.every(row => row.kind === "work_start" || row.time.endsWith("次日")),
  "overnight rows after work start must identify the next day",
);
assert(overnight[0]?.time === "23:00", "overnight work start must remain on the owner date");
assert(overnight.find(row => row.kind === "work_resume")?.state === "current", "rest resume must be current");

const nightHeading = workbenchHeading("2026-07-27", "2026-07-28");
assert(nightHeading.title === "本次夜班收入进度", "overnight owner date must change the heading");
assert(nightHeading.subtitle.includes("2026-07-27"), "overnight heading must expose its owner date");

const calendar = calendarCellContract({
  businessState: "paid_rest",
  isToday: true,
  isSelected: true,
});
assert(calendar.classNames.includes("calendar-day--paid_rest"), "business state must remain visible");
assert(calendar.classNames.includes("is-today"), "today must be an independent layer");
assert(calendar.classNames.includes("is-selected"), "selection must be an independent layer");
assert(calendar.ariaLabel.includes("带薪休息"), "calendar aria text must name the business state");
assert(calendar.todayCue === "今", "today must expose the approved corner cue");

const officialCoverage = calendarCoveragePresentation({ mode: "official", year: 2026 });
assert(!officialCoverage.isVisible, "normal official coverage must stay quiet");
const estimatedCoverage = calendarCoveragePresentation({ mode: "estimated", year: 2027 });
assert(estimatedCoverage.isVisible, "estimated coverage must remain visible");
assert(estimatedCoverage.detail.includes("不代表法定放假安排"), "estimated coverage must disclose its boundary");
const staleCoverage = calendarCoveragePresentation({ mode: "stale", year: 2026 });
assert(staleCoverage.title.includes("可能已过期"), "stale coverage must disclose trust risk");
const errorCoverage = calendarCoveragePresentation({ mode: "integrity_error", year: 2026 });
assert(errorCoverage.isVisible && errorCoverage.tone === "error", "error coverage must remain visible");

console.log("v1.0.5 presentation behavior: 17/17 passed");
