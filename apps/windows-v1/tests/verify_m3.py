from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
app = (ROOT / "src" / "App.tsx").read_text(encoding="utf-8")
model = (ROOT / "src" / "model.ts").read_text(encoding="utf-8")
mini = (ROOT / "src" / "features" / "mini" / "MiniWindow.tsx").read_text(encoding="utf-8")
window_frame = (ROOT / "src" / "components" / "WindowFrame.tsx").read_text(encoding="utf-8")
window_drag = (ROOT / "src" / "hooks" / "useWindowDrag.ts").read_text(encoding="utf-8")
window_service = (ROOT / "src" / "services" / "windowService.ts").read_text(encoding="utf-8")
dashboard_service = (ROOT / "src" / "services" / "dashboardService.ts").read_text(encoding="utf-8")
styles = (ROOT / "src" / "styles.css").read_text(encoding="utf-8")
presentation = (ROOT / "src" / "presentation.ts").read_text(encoding="utf-8")
native = (ROOT / "src-tauri" / "src" / "lib.rs").read_text(encoding="utf-8")
income_commands = (ROOT / "src-tauri" / "src" / "commands" / "income.rs").read_text(encoding="utf-8")
capability = (ROOT / "src-tauri" / "capabilities" / "mini-window.json").read_text(encoding="utf-8")

drag_sources = app + mini + window_frame + window_drag + window_service
frontend_sources = app + mini + model + dashboard_service
native_sources = native + income_commands

checks = {
    "mini-drag-region": all(token in drag_sources + native_sources for token in (
        'invoke<WindowDragOrigin>("window_drag_origin"',
        'invoke("move_app_window"',
        "event.button !== 0",
        "event.screenX",
        "event.screenY",
        "setPointerCapture",
        "allowInteractiveStart: true",
        "consumeDraggedClick",
        'data-window-drag="false"',
        "fn window_drag_origin",
    )) and "mini-window__drag-handle" not in mini + styles,
    "mini-drag-click-suppression": all(token in mini for token in (
        'activateClick(() => onOpenWindow("settings"))',
        "activateClick(refresh)",
        'activateClick(() => onOpenWindow("workbench"))',
    )),
    "all-window-threshold-drag": all(token in drag_sources + capability for token in (
        "DRAG_THRESHOLD_PX",
        "useWindowDrag",
        "onPointerMoveCapture",
        "Math.hypot",
        "scale_factor",
        "workbench",
        "settings",
        "wizard",
    )),
    "drag-does-not-use-delay": "dragTimer" not in drag_sources and "setTimeout" not in window_drag,
    "drag-does-not-use-unreliable-native-loop": "startDragging" not in drag_sources and "getCurrentWindow" not in drag_sources,
    "field-suffix-single-line": all(token in styles for token in (
        ".field__suffix",
        "white-space: nowrap",
        "flex: 0 0 auto",
    )),
    "mini-position-persistence": all(token in native for token in (
        "WindowEvent::Moved(position)",
        "fn schedule_mini_position_save",
        "Duration::from_millis(300)",
        "window.position_saved",
        "if let Some(position) = config.mini_window_position",
    )),
    "mini-no-redundant-more": "更多操作" not in mini and "mini-window__more" not in mini + styles,
    "live-dashboard": all(token in app + model for token in (
        "useDashboard",
        "calculateLocalTick",
        "window.setInterval(runLocalTick, 1000)",
        "30_000",
    )),
    "shared-snapshot": all(token in app for token in ("<TodayView {...dashboard}", "formatMoney", "formatDuration")),
    "today-sections": all(token in app + presentation for token in (
        "今日已赚",
        "今日安排",
        "本月累计",
        "boundary-summary",
        "距离下班",
    )),
    "calendar-month": all(token in app + model for token in (
        "calendar__grid",
        "收入日历",
        "useCalendarMonth",
        "查看上个月",
        "查看下个月",
    )),
    "rest-day-presentation": all(token in app for token in (
        'snapshot.phase === "rest_day"',
        "今天安心休息",
        "休息日不计算有效工时、工作进度和今日收入",
        "今天没有工作安排",
    )),
    "real-calendar-date": all(token in frontend_sources for token in (
        "snapshot.ownerDate",
        "aria-current={",
        "resolve_calendar_month",
        "resolve_next_workday",
    )),
    "no-demo-calendar-date": "day === 24" not in app and "7 月 24 日" not in app,
    "no-demo-income": "预计今日收入 ¥ 500.00" not in app and "monthTotal: 3842" not in model,
    "manual-override": all(token in app for token in (
        "DateOverrideEditor",
        "自动判断",
        "工作日",
        "带薪休息",
        "不带薪休息",
    )),
    "loading-error": all(token in app + mini + model for token in ("正在计算今天的收入", "暂时无法计算", "重新计算")),
    "actionable-calculation-error": all(token in frontend_sources + native_sources for token in (
        "dashboardErrorTitle",
        "检查设置",
        "salary.calculate.invalid",
        "请检查上班、下班和休息时间后重试",
    )),
    "zero-lunch-presentation": all(token in app + presentation for token in (
        "function hasRest(schedule: TimelineSchedule)",
        'config.draft.lunch_start_time === config.draft.lunch_end_time',
        '"无休息时段"',
    )),
    "long-content": "long-number" in app and "overflow-wrap: anywhere" in styles,
    "accessibility": all(token in app for token in ('role="dialog"', "aria-label", "IconButton")),
    "no-pet": not any(token in frontend_sources.lower() for token in ("pet_id", "pure_pet", "desktop pet")),
}

for name, passed in checks.items():
    print(f"{'PASS' if passed else 'FAIL'} {name}")

failed = [name for name, passed in checks.items() if not passed]
if failed:
    raise SystemExit(f"M3 checks failed: {', '.join(failed)}")
print(f"V10-M3 static PASS {len(checks)}/{len(checks)}")
