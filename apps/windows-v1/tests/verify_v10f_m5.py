from __future__ import annotations

import json
import sys
from pathlib import Path


APP_ROOT = Path(__file__).resolve().parents[1]
REPO_ROOT = APP_ROOT.parents[1]


def require(condition: bool, message: str) -> None:
    if not condition:
        raise AssertionError(message)


def verify_removed_phase_ipc() -> None:
    rust = (APP_ROOT / "src-tauri" / "src" / "lib.rs").read_text(encoding="utf-8")
    require("fn implementation_phase" not in rust, "stale implementation_phase command remains")
    require("implementation_phase," not in rust, "stale implementation_phase handler remains")


def verify_browser_preview_boundary() -> None:
    app = (APP_ROOT / "src" / "App.tsx").read_text(encoding="utf-8")
    require("BrowserPreviewNotice" in app, "browser preview marker is missing")
    require("非权威模拟数据" in app, "browser preview marker does not disclose non-authoritative data")
    require("if (windowService.isDesktop) return null" in app, "preview marker could leak into desktop builds")


def verify_governance_documents() -> None:
    required = {
        "support-matrix.md": ("Windows 11", "待重新验证", "Windows 10", "多显示器"),
        "evidence/README.md": ("脱敏", "external", "source_head"),
        "brand-asset-governance.md": ("L2", "brand-assets.json", "候选"),
        "v2-debt-handoff.md": ("CSP", "App.tsx", "model.ts", "lib.rs"),
        "browser-preview-boundary.md": ("非权威", "Tauri/Rust", "dev-preview"),
    }
    release = REPO_ROOT / "doc" / "releases" / "v1.0.F"
    for relative, markers in required.items():
        path = release / relative
        require(path.is_file(), f"missing governance document: {relative}")
        text = path.read_text(encoding="utf-8")
        for marker in markers:
            require(marker in text, f"{relative} is missing marker: {marker}")


def verify_current_gate() -> None:
    manifest = json.loads((REPO_ROOT / "scripts" / "current-manifest.json").read_text(encoding="utf-8"))
    gates = {item["id"]: item for item in manifest["gates"]}
    require(gates.get("v10f-m5", {}).get("path") == "scripts/verify_v10f_m5.ps1", "M5 gate is not current")


def main() -> int:
    verify_removed_phase_ipc()
    verify_browser_preview_boundary()
    verify_governance_documents()
    verify_current_gate()
    print("PASS v1.0.F M5 governance and support contracts (4 groups)")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (AssertionError, OSError, ValueError, json.JSONDecodeError) as error:
        print(f"FAIL v1.0.F M5: {error}", file=sys.stderr)
        raise SystemExit(1)
