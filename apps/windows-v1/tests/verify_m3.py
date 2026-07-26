from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
app = (ROOT / "src" / "App.tsx").read_text(encoding="utf-8")
model = (ROOT / "src" / "model.ts").read_text(encoding="utf-8")
styles = (ROOT / "src" / "styles.css").read_text(encoding="utf-8")
native = (ROOT / "src-tauri" / "src" / "lib.rs").read_text(encoding="utf-8")
capability = (ROOT / "src-tauri" / "capabilities" / "mini-window.json").read_text(encoding="utf-8")

checks = {
    "mini-drag-region": all(token in app + styles + capability for token in (
        'import { getCurrentWindow } from "@tauri-apps/api/window"',
        "getCurrentWindow().startDragging()",
        "event.button === 0",
        "core:window:allow-start-dragging",
        "data-tauri-drag-region",
        'aria-label="拖动迷你收入视图"',
        "width: 76px",
        "height: 20px",
        "pointer-events: none",
    )),
    "mini-position-persistence": all(token in native for token in (
        "WindowEvent::Moved(position)",
        "fn schedule_mini_position_save",
        "Duration::from_millis(300)",
        "window.position_saved",
        "if let Some(position) = config.mini_window_position",
    )),
    "mini-no-redundant-more": "更多操作" not in app and "mini-window__more" not in app + styles,
    "live-dashboard": "useDashboard" in app and "setInterval(refresh, 1000)" in model,
    "shared-snapshot": all(token in app for token in ("<TodayView {...dashboard}", "formatMoney", "formatDuration")),
    "today-sections": all(token in app for token in ("今日已赚", "今日安排", "本月累计", "剩余有效工时")),
    "calendar-month": "calendar__grid" in app and "收入日历" in app,
    "rest-day-presentation": all(token in app for token in (
        'snapshot.phase === "rest_day"',
        "今天安心休息",
        "休息日不计算有效工时、工作进度和今日收入",
        "今天没有工作安排",
    )),
    "real-calendar-date": all(token in app + model for token in (
        "snapshot.ownerDate",
        "aria-current={",
        "resolve_calendar_month",
        "resolve_next_workday",
    )),
    "no-demo-calendar-date": "day === 24" not in app and "7 月 24 日" not in app,
    "no-demo-income": "预计今日收入 ¥ 500.00" not in app and "monthTotal: 3842" not in model,
    "manual-override": all(token in app for token in ("useCalendarOverrides", "跟随规则", "工作日", "休息日")),
    "loading-error": all(token in app for token in ("正在计算今天的收入", "暂时无法计算", "重新计算")),
    "long-content": "long-number" in app and "overflow-wrap: anywhere" in styles,
    "accessibility": all(token in app for token in ('role="dialog"', "aria-label", "IconButton")),
    "no-pet": not any(token in (app + model).lower() for token in ("pet_id", "pure_pet", "desktop pet")),
}

for name, passed in checks.items():
    print(f"{'PASS' if passed else 'FAIL'} {name}")

failed = [name for name, passed in checks.items() if not passed]
if failed:
    raise SystemExit(f"M3 checks failed: {', '.join(failed)}")
print(f"V10-M3 static PASS {len(checks)}/{len(checks)}")
