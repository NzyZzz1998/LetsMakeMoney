from __future__ import annotations

import re
import sys
from pathlib import Path


APP_ROOT = Path(__file__).resolve().parents[1]
SRC = APP_ROOT / "src"
RUST = APP_ROOT / "src-tauri" / "src"


def require(condition: bool, message: str) -> None:
    if not condition:
        raise AssertionError(message)


def source(path: Path) -> str:
    return path.read_text(encoding="utf-8")


def verify_monthly_summary_contract() -> None:
    summary = source(SRC / "features" / "calendar" / "monthlySummary.ts")
    app = source(SRC / "App.tsx")
    for token in (
        "plannedMinutes",
        "elapsedPlannedMinutes",
        "overtimeMinutes",
        "elapsedPlannedMinutesForOwnerDate",
        "restEnd === restStart",
    ):
        require(token in summary, f"Monthly summary contract is missing {token}")
    for label in ("计划工时", "实际工时", "加班工时"):
        require(label in app, f"Calendar summary is missing the qualified label: {label}")
    require("不代表实际出勤" not in app, "Removed monthly summary disclaimer must not return")
    require("加班收入" not in app, "M4 must not expose overtime income")


def verify_independent_overtime_state() -> None:
    hook = source(SRC / "features" / "calendar" / "useOvertimeMonth.ts")
    state = source(SRC / "features" / "calendar" / "overtimeMonthState.ts")
    app = source(SRC / "App.tsx")
    require("useOvertimeMonth(displayMonth)" in app, "Calendar needs an independent overtime month source")
    require("state.data?.month === action.targetMonth" in state, "Only same-month cache may become stale")
    require('status: "stale"' in state, "Read failures must preserve valid same-month data as stale")
    require("未以 0 分钟替代" in app, "The UI must disclose that failures are not converted to zero")
    require("overtimeMonth.retry" in app, "Overtime read failures need an independent retry")
    require("overtime.month.failed" in hook and "overtime.month.loaded" in hook, "Overtime reads need semantic logs")


def verify_calendar_layout() -> None:
    app = source(SRC / "App.tsx")
    css = source(SRC / "styles.css")
    lib = source(RUST / "lib.rs")
    require("data-weeks={calendarWeeks}" in app, "Calendar must expose its 5/6-week layout state")
    require('calendar-day__overtime' in app and '>加</span>' in app, "Calendar needs a non-color overtime marker")
    require('.calendar__grid[data-weeks="6"] button { height: 40px; }' in css, "Six-week row height is not fixed")
    require(".calendar__grid button {" in css and "height: 46px" in css, "Five-week row height is not fixed")
    require(
        ".month-summary { display: grid; grid-template-columns: minmax(168px, .72fr) 1.6fr;" in css,
        "Summary must keep its copy and metrics in separate columns",
    )
    require("min-height: 64px" in css, "Summary must reserve a stable high-DPI content height")
    require(".month-summary__grid { display: grid; grid-template-columns: repeat(3" in css, "Summary must remain a fixed three-column grid")
    require(".month-summary__grid dt { overflow: hidden;" in css, "Summary labels need bounded single-line layout")
    require(".month-summary__heading .eyebrow, .month-summary__grid dt" in css, "Summary captions must share one typography contract")
    require('onDoubleClick={() => {' in app and 'setEditorMode("date")' in app, "Double-clicking a calendar day must open the shared date transaction")
    require("text-overflow: ellipsis; white-space: nowrap" in css, "Summary copy needs high-DPI overflow protection")
    require(".workbench-content--calendar { overflow: hidden; }" in css, "Calendar workbench must not gain a vertical scrollbar")
    workbench = re.search(r'label: "workbench"(?P<body>.*?)(?=WindowSpec \{)', lib, re.S)
    require(workbench is not None, "Workbench window contract not found")
    body = workbench.group("body")
    for token in ("width: 820.0", "height: 620.0", "min_width: 820.0", "min_height: 620.0"):
        require(token in body, f"Workbench window contract is missing {token}")


def verify_behavior_assets() -> None:
    for name in ("monthly-summary.behavior.ts", "overtime-month-state.behavior.ts"):
        require((APP_ROOT / "tests" / name).is_file(), f"Missing M4 behavior suite: {name}")


def main() -> int:
    checks = [
        verify_monthly_summary_contract,
        verify_independent_overtime_state,
        verify_calendar_layout,
        verify_behavior_assets,
    ]
    try:
        for check in checks:
            check()
            print(f"PASS {check.__name__}")
    except (AssertionError, OSError, TypeError, ValueError) as error:
        print(f"FAIL {error}", file=sys.stderr)
        return 1
    print(f"PASS v1.0.7 M4 static contracts ({len(checks)} groups)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
