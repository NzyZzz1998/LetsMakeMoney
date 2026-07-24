from __future__ import annotations

import json
import re
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
FAILURES: list[str] = []


def check(condition: bool, message: str) -> None:
    if not condition:
        FAILURES.append(message)


def read(path: Path) -> str:
    try:
        return path.read_text(encoding="utf-8")
    except UnicodeDecodeError:
        FAILURES.append(f"不是 UTF-8：{path.relative_to(ROOT)}")
        return ""


def main() -> int:
    package = json.loads(read(ROOT / "package.json"))
    tauri = json.loads(read(ROOT / "src-tauri" / "tauri.conf.json"))
    window_contract = json.loads(read(ROOT / "contracts" / "window-contract.json"))
    visual_contract = json.loads(read(ROOT / "contracts" / "visual-contract.json"))
    app = read(ROOT / "src" / "App.tsx")
    components = read(ROOT / "src" / "components.tsx")
    styles = read(ROOT / "src" / "styles.css")
    rust = read(ROOT / "src-tauri" / "src" / "lib.rs")

    exact_versions = [
        package["packageManager"],
        *package["dependencies"].values(),
        *package["devDependencies"].values(),
    ]
    check(all(re.search(r"\d+\.\d+\.\d+", value) for value in exact_versions), "Node/React/Tauri 依赖未全部锁定到精确版本")

    expected_sizes = {
        "mini": (344, 120),
        "workbench": (920, 640),
        "settings": (760, 560),
        "wizard": (780, 580),
    }
    for label, (width, height) in expected_sizes.items():
        check(f'label: "{label}"' in rust, f"Rust 窗口注册表缺少 {label}")
        check(f'width: {width}.0' in rust and f'height: {height}.0' in rust, f"{label} 窗口尺寸不正确")
        check(f'kind="{label}"' in app or label == "mini" and 'data-window="mini"' in app, f"React 缺少 {label} 窗口壳")

    contract_sizes = {item["id"]: tuple(item["default_size"]) for item in window_contract["windows"]}
    check(contract_sizes == expected_sizes, "窗口合同与 M1 实现尺寸不一致")
    check(tauri["app"]["windows"][0]["skipTaskbar"] is True, "迷你窗口必须不显示任务栏入口")
    check("CreateMutexW" in rust and "ERROR_ALREADY_EXISTS" in rust, "单实例互斥没有实现")
    check("ensure_window" in rust and "get_webview_window" in rust, "窗口复用没有实现")
    check("CloseRequested" in rust and "prevent_close" in rust, "关闭隐藏策略没有实现")

    required_components = ["Button", "IconButton", "Field", "Switch", "SegmentedControl", "ProgressBar", "Feedback"]
    for component in required_components:
        check(f"function {component}" in components or f"const {component}" in components, f"缺少基础组件 {component}")

    required_states = ["hover", "active", "focus-visible", "disabled", "error", "success"]
    for state in required_states:
        check(state in styles, f"样式缺少 {state} 状态")
    check("prefers-reduced-motion" in styles, "缺少减少动态效果适配")
    check("aria-label" in app and "role=\"switch\"" in components, "缺少基础可访问性语义")
    check("--shadow-window" in styles and "--radius-window" in styles, "生产级窗口 token 未落地")
    check(visual_contract["motion"]["reduced_motion"] is True, "视觉合同没有要求 reduced motion")

    searchable = "\n".join([app, components, styles, rust]).lower()
    forbidden = [r"\bpet\b", r"\bcat\b", "宠物", "桌宠", "pure_pet"]
    for term in forbidden:
        check(re.search(term, searchable) is None, f"M1 正式应用壳出现宠物能力：{term}")

    check((ROOT / "src-tauri" / "icons" / "icon.ico").stat().st_size > 1000, "无宠物应用图标为空或过小")
    check((ROOT / "dist" / "index.html").exists(), "前端构建产物不存在")

    if FAILURES:
        print("M1 验证失败：")
        for failure in FAILURES:
            print(f"- {failure}")
        return 1

    print("M1 验证通过：9/9")
    print("- 四窗口真实尺寸与复用合同通过")
    print("- 单实例、关闭隐藏和任务栏骨架通过")
    print("- 生产 token、基础控件、可访问性与 reduced motion 通过")
    print("- 无宠物应用边界通过")
    return 0


if __name__ == "__main__":
    sys.exit(main())
