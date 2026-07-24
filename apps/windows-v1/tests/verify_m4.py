from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
app = (ROOT / "src" / "App.tsx").read_text(encoding="utf-8")
model = (ROOT / "src" / "configModel.ts").read_text(encoding="utf-8")
styles = (ROOT / "src" / "styles.css").read_text(encoding="utf-8")
rust_config = (ROOT / "src-tauri" / "src" / "config.rs").read_text(encoding="utf-8")
rust_app = (ROOT / "src-tauri" / "src" / "lib.rs").read_text(encoding="utf-8")

checks = {
    "shared-draft": "useConfigDraft" in app and "dirty" in model and "validate(draft)" in model,
    "wizard-income-rest": all(token in app for token in ("先告诉我你的月薪", "双休", "单休", "大小周")),
    "alternating-explicit": all(token in app for token in ("本周是哪一周？", "大周", "小周", "我们不会替你决定")),
    "schedule-inference": all(token in app for token in ("addHours", "午休开始", "推算下班时间", "有效工时")),
    "wizard-exits": all(token in app for token in ("上一步", "下一步", "放弃本次配置？", "确认配置")),
    "first-run-wizard": all(token in app + rust_app + rust_config for token in (
        "configuration_initialized",
        "config_missing_or_invalid",
        "退出首次配置？",
        'showWindow("mini")',
        "save_initial",
    )),
    "cross-window-config-refresh": all(token in model for token in (
        'window.addEventListener("focus"',
        "dirtyRef.current",
        "reload(true)",
    )),
    "failure-retains-draft": "配置目录不可写" in model and "setDraft" not in model[model.index("catch (error)"):model.index("const reset")],
    "settings-groups": all(token in app for token in ("收入与作息", "日历", "窗口与启动", "数据与支持")),
    "save-feedback-reset": all(token in app + model for token in ("没有需要保存的更改", "保存失败", "恢复默认设置？")),
    "side-effect-rollback": "SideEffectDenied" in rust_config and "配置已回滚" in rust_config,
    "a11y-modal-focus": all(token in app + styles for token in ("aria-invalid", "alertdialog", "aria-modal", "requestAnimationFrame", "prefers-reduced-motion")),
    "no-pet": not any(token in (app + model).lower() for token in ("pet_id", "pure_pet", "desktop pet")),
}

for name, passed in checks.items():
    print(f"{'PASS' if passed else 'FAIL'} {name}")

failed = [name for name, passed in checks.items() if not passed]
if failed:
    raise SystemExit(f"M4 checks failed: {', '.join(failed)}")
print(f"V10-M4 static PASS {len(checks)}/{len(checks)}")
