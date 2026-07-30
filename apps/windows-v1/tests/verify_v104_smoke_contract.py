from __future__ import annotations

from pathlib import Path


ROOT = Path(__file__).resolve().parents[3]
SCRIPT = ROOT / "scripts" / "smoke_v104_desktop.ps1"


def require(condition: bool, message: str) -> None:
    if not condition:
        raise AssertionError(message)


def main() -> int:
    text = SCRIPT.read_text(encoding="utf-8")
    checks = {
        "exact candidate identity": "LetsMakeMoney-v1.0.4-windows-x86_64.zip" in text,
        "existing process refusal": 'Get-Process -Name "LetsMakeMoney"' in text,
        "configuration backup": "Copy-Item -LiteralPath $appDataPath -Destination $backupData -Recurse" in text,
        "configuration restore": "Copy-Item -LiteralPath $backupData -Destination $appDataPath -Recurse" in text,
        "approved path guard": "Assert-ChildPath" in text and "Remove-ApprovedItem" in text,
        "evidence survives cleanup": "Evidence output cannot be inside the temporary smoke run directory." in text,
        "exact data restoration": "Get-DirectoryDigest" in text and "environment_restored_exact" in text,
        "new extraction launch": "Start-Process -FilePath $exePath" in text,
        "all-window observation": "EnumWindows" in text and "LmmWindowProbe" in text,
        "interactive surfaces": all(
            value in text for value in ("workbench", "settings", "wizard", "tray_recovery")
        ),
        "normal exit assertion": "The process is still running after the requested tray exit." in text,
        "residual process assertion": "LetsMakeMoney process remained after smoke cleanup." in text,
        "privacy declaration": "No user path, configuration value, salary, raw log line" in text,
    }
    for label, passed in checks.items():
        require(passed, f"desktop smoke contract is missing: {label}")
        print(f"PASS {label}")
    print(f"PASS v1.0.4 desktop smoke contract ({len(checks)}/{len(checks)})")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
