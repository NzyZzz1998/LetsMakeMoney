from __future__ import annotations

import re
from pathlib import Path


ROOT = Path(__file__).resolve().parents[3]
CARGO_TOML = ROOT / "apps" / "windows-v1" / "src-tauri" / "Cargo.toml"
LIB_RS = ROOT / "apps" / "windows-v1" / "src-tauri" / "src" / "lib.rs"


def require(text: str, pattern: str, message: str) -> None:
    if re.search(pattern, text, re.MULTILINE | re.DOTALL) is None:
        raise AssertionError(message)


def function_body(source: str, name: str) -> str:
    marker = f"fn {name}("
    start = source.find(marker)
    if start < 0:
        raise AssertionError(f"missing native lifecycle helper: {name}")

    brace = source.find("{", start)
    if brace < 0:
        raise AssertionError(f"missing body for native lifecycle helper: {name}")

    depth = 0
    for index in range(brace, len(source)):
        if source[index] == "{":
            depth += 1
        elif source[index] == "}":
            depth -= 1
            if depth == 0:
                return source[brace + 1 : index]
    raise AssertionError(f"unterminated body for native lifecycle helper: {name}")


def main() -> None:
    cargo = CARGO_TOML.read_text(encoding="utf-8")
    source = LIB_RS.read_text(encoding="utf-8")

    require(
        cargo,
        r"\[target\.'cfg\(windows\)'\.dependencies\].*"
        r"webview2-com\s*=\s*\"=0\.38\.2\".*"
        r"windows-core\s*=\s*\"=0\.61\.2\"",
        "Windows WebView2 suspend dependencies are not pinned to the locked versions",
    )

    suspend = function_body(source, "suspend_webview_internal")
    resume = function_body(source, "resume_webview_internal")
    hide = function_body(source, "hide_window_internal")
    show = function_body(source, "show_window_internal")

    require(suspend, r"\bTrySuspend\b", "hide lifecycle does not call WebView2 TrySuspend")
    require(resume, r"\bResume\b", "show lifecycle does not call WebView2 Resume")

    suspend_hidden = suspend.find("SetIsVisible(false)")
    suspend_request = suspend.find("TrySuspend")
    if suspend_hidden < 0 or suspend_request < 0 or suspend_hidden > suspend_request:
        raise AssertionError(
            "WebView2 controller must become invisible before TrySuspend"
        )

    resume_request = resume.find("Resume")
    resume_visible = resume.find("SetIsVisible(true)")
    if resume_request < 0 or resume_visible < 0 or resume_request > resume_visible:
        raise AssertionError(
            "WebView2 must Resume before its controller becomes visible"
        )

    for token in (
        "window.webview_suspend_requested",
        "window.webview_suspend_completed",
        "window.webview_suspend_failed",
    ):
        if token not in suspend:
            raise AssertionError(f"missing suspend diagnostic event: {token}")

    for token in (
        "window.webview_resume_requested",
        "window.webview_resume_completed",
        "window.webview_resume_failed",
    ):
        if token not in resume:
            raise AssertionError(f"missing resume diagnostic event: {token}")

    hide_call = hide.find("suspend_webview_internal")
    hide_match = re.search(r"window\s*\.\s*hide\s*\(\s*\)", hide)
    native_hide = -1 if hide_match is None else hide_match.start()
    if native_hide < 0 or hide_call < native_hide:
        raise AssertionError("WebView2 suspension must be requested after the native window is hidden")

    resume_call = show.find("resume_webview_internal")
    show_match = re.search(r"window\s*\.\s*show\s*\(\s*\)", show)
    native_show = -1 if show_match is None else show_match.start()
    if resume_call < 0 or native_show < 0 or resume_call > native_show:
        raise AssertionError("WebView2 resume must be requested before the native window is shown")

    if "lmm:window-hidden" not in hide or "lmm:window-shown" not in show:
        raise AssertionError("frontend lifecycle events must remain part of the native contract")

    print("v1.0.3 native WebView2 suspend/resume contract passed.")


if __name__ == "__main__":
    main()
