from __future__ import annotations

import hashlib
import json
from pathlib import Path


APP_ROOT = Path(__file__).resolve().parents[1]
PACKAGE = APP_ROOT / "src-tauri" / "pet-packages" / "classic-first-return-vnext"
RUNTIME = APP_ROOT / "public" / "pet-runtime"


def require(condition: bool, message: str) -> None:
    if not condition:
        raise AssertionError(message)


def load_json(path: Path) -> dict:
    value = json.loads(path.read_text(encoding="utf-8"))
    require(isinstance(value, dict), f"{path.name} must contain an object")
    return value


def main() -> int:
    expected_files = {
        "assets/atlas-00.webp",
        "evidence/license.json",
        "evidence/provenance.json",
        "evidence/source-evidence.json",
        "hitmasks/atlas-00.hitmask.json",
        "motion-manifest.json",
        "package-index.json",
    }
    actual_files = {
        path.relative_to(PACKAGE).as_posix()
        for path in PACKAGE.rglob("*")
        if path.is_file()
    }
    require(actual_files == expected_files, "formal pet package allowlist drift")
    require(all((PACKAGE / path).stat().st_size > 0 for path in expected_files), "empty pet runtime file")

    index = load_json(PACKAGE / "package-index.json")
    manifest_path = PACKAGE / "motion-manifest.json"
    manifest = load_json(manifest_path)
    manifest_sha = hashlib.sha256(manifest_path.read_bytes()).hexdigest().upper()
    require(index["manifestSha256"] == manifest_sha, "pet manifest SHA256 drift")
    require(index["ready"] is True and index["status"] == "approved", "PetManager ready gate drift")
    require(index["packageVersion"] == "0.4.0-rc.1", "product candidate version drift")
    require(index["published"] is False, "product candidate must not claim publication")
    require(
        [action["id"] for action in manifest["actions"]]
        == [
            "working_play_loop_a",
            "working_play_loop_b",
            "working_observe",
            "working_ack",
            "awake_rest_loop",
            "rest_ack",
            "sleeping_loop",
            "sleep_twitch",
            "sleep_ack",
            "run_prepare",
            "run_loop",
            "run_stop",
        ],
        "first-return action catalog drift",
    )

    license_document = load_json(PACKAGE / "evidence" / "license.json")
    provenance = load_json(PACKAGE / "evidence" / "provenance.json")
    require(license_document["redistribution"] == "product-runtime", "product redistribution approval missing")
    require(provenance["productReturnApproved"] is True, "product return approval missing")
    require(provenance["published"] is False, "product publication gate opened unexpectedly")

    source = (RUNTIME / "main.mjs").read_text(encoding="utf-8")
    pet_window = (APP_ROOT / "src" / "features" / "pet" / "PetWindow.tsx").read_text(encoding="utf-8")
    require("window.__TAURI__" not in source, "formal runtime must not depend on disabled global Tauri API")
    require("window.__LMM_PET_INVOKE__" in source, "formal runtime invoke bridge missing")
    require('import { invoke } from "@tauri-apps/api/core"' in pet_window, "pet window invoke import missing")
    require("window.__LMM_PET_INVOKE__ = invoke" in pet_window, "pet window invoke bridge injection missing")
    for forbidden in ("__PET_SPIKE__", "inject_fault", "acceptance", "frontend_heartbeat", "keydown"):
        require(forbidden not in source, f"formal runtime contains forbidden spike control: {forbidden}")
    for command in (
        "read_pet_package_file",
        "list_pet_package_files",
        "apply_pet_hit_region",
        "probe_pet_hit_region",
        "move_pet_window",
        "pet_runtime_ready",
        "pet_runtime_failed",
    ):
        require(f'\"{command}\"' in source, f"formal runtime command missing: {command}")

    package_core = (RUNTIME / "runtime" / "vnext-package-core.mjs").read_text(encoding="utf-8")
    require("pet_package_vnext_product" in package_core, "formal runtime adapter identity drift")
    require("sandbox-review-only" not in package_core, "formal runtime still accepts sandbox-only redistribution")
    require("productReturnApproved !== true" in package_core, "formal runtime must enforce product approval")

    print("PASS pet return product candidate, identity and surface contracts")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
