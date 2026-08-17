from __future__ import annotations

import json
import re
import subprocess
from pathlib import Path


APP_ROOT = Path(__file__).resolve().parents[1]
REPO_ROOT = APP_ROOT.parents[1]
SCRIPTS = REPO_ROOT / "scripts"
RELEASE = REPO_ROOT / "doc" / "releases" / "v1.1.0"
PET_PACKAGE = APP_ROOT / "src-tauri" / "pet-packages" / "classic-first-return-vnext"
VERSION = "1.1.0"
V108_COMMIT = "40f3d5047024d0833dccb2b3638520d5ab9835ea"


def require(condition: bool, message: str) -> None:
    if not condition:
        raise AssertionError(message)


def read_json(path: Path) -> dict:
    value = json.loads(path.read_text(encoding="utf-8"))
    require(isinstance(value, dict), f"JSON root must be an object: {path}")
    return value


def verify_version_facts() -> None:
    package = read_json(APP_ROOT / "package.json")
    lock = read_json(APP_ROOT / "package-lock.json")
    tauri = read_json(APP_ROOT / "src-tauri" / "tauri.conf.json")
    current = read_json(SCRIPTS / "current-manifest.json")
    cargo = (APP_ROOT / "src-tauri" / "Cargo.toml").read_text(encoding="utf-8")
    cargo_lock = (APP_ROOT / "src-tauri" / "Cargo.lock").read_text(encoding="utf-8")

    require(package.get("version") == VERSION, "package.json version drift")
    require(lock.get("version") == VERSION, "package-lock root version drift")
    require(lock.get("packages", {}).get("", {}).get("version") == VERSION, "package-lock app version drift")
    require(tauri.get("version") == VERSION, "Tauri version drift")
    require(re.search(r'^version = "1\.1\.0"$', cargo, re.MULTILINE) is not None, "Cargo version drift")
    require(
        re.search(r'name = "letsmakemoney_windows_v1"\nversion = "1\.1\.0"', cargo_lock) is not None,
        "Cargo.lock application version drift",
    )
    require(current.get("version") == VERSION, "current manifest version drift")
    require(current.get("artifacts", {}).get("zip_name") == "LetsMakeMoney-v1.1.0-windows-x86_64.zip", "Zip identity drift")
    require([gate.get("id") for gate in current.get("gates", [])] == ["v110", "architecture"], "current gate set drift")


def verify_historical_identity() -> None:
    result = subprocess.run(
        ["git", "-C", str(REPO_ROOT), "rev-list", "-n", "1", "v1.0.8"],
        check=True,
        capture_output=True,
        text=True,
    )
    require(result.stdout.strip().lower() == V108_COMMIT, "historical v1.0.8 tag was moved")


def verify_pet_runtime_boundary() -> None:
    defaults = read_json(APP_ROOT / "contracts" / "config-v9-defaults.json")
    index = read_json(PET_PACKAGE / "package-index.json")
    license_data = read_json(PET_PACKAGE / "evidence" / "license.json")
    provenance = read_json(PET_PACKAGE / "evidence" / "provenance.json")
    source = read_json(PET_PACKAGE / "evidence" / "source-evidence.json")

    require(defaults.get("desktop_companion_mode") == "mini", "Classic must remain opt-in")
    require(index.get("status") == "approved" and index.get("ready") is True, "Classic package is not approved")
    require(index.get("packageVersion") == "0.4.1-rc.1", "Classic runtime package version drift")
    require(index.get("published") is False, "embedded package metadata must not claim publication")
    require(license_data.get("redistribution") == "product-runtime", "Classic redistribution boundary drift")
    require(provenance.get("productReturnApproved") is True, "product return approval is missing")
    require(provenance.get("published") is False, "provenance must not claim public release")
    require(source.get("petId") == "letsmakemoney-classic-pro", "unexpected first-return pet identity")
    require("working_pounce" in source.get("retiredScope", []), "retired rough action unexpectedly returned")
    manifest = read_json(PET_PACKAGE / "motion-manifest.json")
    require(manifest.get("logicalSize") == {"width": 256, "height": 208}, "Classic runtime surface drift")

    runtime_source = (APP_ROOT / "public" / "pet-runtime" / "main.mjs").read_text(encoding="utf-8")
    require('canvas.addEventListener("lostpointercapture"' in runtime_source, "pet drag capture-loss recovery missing")
    require('resetActiveInput("window_blur")' in runtime_source, "pet drag window-blur recovery missing")
    require("WindowMoveCoordinator" in runtime_source, "pet drag move coalescing missing")

    allowed = {
        "motion-manifest.json",
        "package-index.json",
        "assets/atlas-00.webp",
        "hitmasks/atlas-00.hitmask.json",
        "evidence/license.json",
        "evidence/provenance.json",
        "evidence/source-evidence.json",
    }
    actual = {path.relative_to(PET_PACKAGE).as_posix() for path in PET_PACKAGE.rglob("*") if path.is_file()}
    require(actual == allowed, f"Classic runtime package allowlist drift: {sorted(actual ^ allowed)}")


def verify_release_documents() -> None:
    required = {
        "README.md": "clean 候选",
        "release-notes.md": "Classic",
        "verification.md": "Tag publication approved = true",
        "manual-verification.md": "Mini 贴边首次自动隐藏",
        "release-checklist.md": "GitHub Release 仍冻结",
        "progress.md": "tag 无阻塞",
    }
    for name, marker in required.items():
        path = RELEASE / name
        require(path.is_file(), f"missing v1.1.0 release document: {name}")
        text = path.read_text(encoding="utf-8")
        require(marker in text, f"release document lacks marker '{marker}': {name}")
        require("\ufffd" not in text, f"release document contains replacement characters: {name}")

    current = (REPO_ROOT / "doc" / "current.md").read_text(encoding="utf-8")
    require(
        "当前公开版本 | Windows v1.1.0 Stable" in current
        and "Tag publication approved = true" in current
        and "GitHub Release approved = false" in current,
        "current.md does not preserve the split v1.1.0 tag and Release facts",
    )
    portable_zh = (APP_ROOT / "release-docs" / "portable-readme.zh-CN.md").read_text(encoding="utf-8")
    portable_en = (APP_ROOT / "release-docs" / "portable-readme.en.md").read_text(encoding="utf-8")
    require("默认使用 Mini" in portable_zh and "Classic" in portable_zh, "Chinese portable companion contract drift")
    require("Mini is the default" in portable_en and "Classic" in portable_en, "English portable companion contract drift")


def main() -> int:
    checks = [
        verify_version_facts,
        verify_historical_identity,
        verify_pet_runtime_boundary,
        verify_release_documents,
    ]
    try:
        for check in checks:
            check()
            print(f"PASS {check.__name__}")
    except (AssertionError, OSError, ValueError, json.JSONDecodeError, subprocess.CalledProcessError) as error:
        print(f"FAIL {error}")
        return 1
    print(f"PASS v1.1.0 release contract ({len(checks)} groups)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
