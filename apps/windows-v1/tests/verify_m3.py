from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
app = (ROOT / "src" / "App.tsx").read_text(encoding="utf-8")
model = (ROOT / "src" / "model.ts").read_text(encoding="utf-8")
styles = (ROOT / "src" / "styles.css").read_text(encoding="utf-8")

checks = {
    "mini-drag-region": 'data-tauri-drag-region' in app and "mini-window__drag" in styles,
    "live-dashboard": "useDashboard" in app and "setInterval(refresh, 1000)" in model,
    "shared-snapshot": all(token in app for token in ("<TodayView {...dashboard}", "formatMoney", "formatDuration")),
    "today-sections": all(token in app for token in ("今日已赚", "今日安排", "本月累计", "剩余有效工时")),
    "calendar-month": "calendar__grid" in app and "收入日历" in app,
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
