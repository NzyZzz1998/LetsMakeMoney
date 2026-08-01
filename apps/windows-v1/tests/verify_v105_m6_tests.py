from __future__ import annotations

import copy
import tempfile
from pathlib import Path

from verify_v105_m6 import (
    M6Error,
    VERSION,
    ZIP_NAME,
    validate_app_version_contract,
    validate_candidate_identity,
)


def fixture() -> dict:
    names = (
        ZIP_NAME,
        "LetsMakeMoney.exe",
        "WebView2Loader.dll",
        "README.md",
        "README.en.md",
    )
    return {
        "schema_version": "1.0",
        "candidate_id": "V105-test-dirty",
        "release_version": VERSION,
        "source_head": "a" * 40,
        "source_tree_dirty": True,
        "build_timestamp_utc": "2026-08-01T00:00:00Z",
        "publication_allowed": False,
        "publication_blockers": [
            "independent acceptance is not complete",
            "source tree is dirty",
        ],
        "artifacts": [
            {"name": name, "size": index + 1, "sha256": f"{index + 1:064X}"}
            for index, name in enumerate(names)
        ],
        "verification": "candidate-package-contract-passed",
    }


def reject(label: str, mutate) -> None:
    value = copy.deepcopy(fixture())
    mutate(value)
    try:
        validate_candidate_identity(value, candidate_id="V105-test-dirty")
    except M6Error:
        print(f"PASS rejected {label}")
        return
    raise AssertionError(f"expected rejection: {label}")


def main() -> int:
    valid_app = f'''supportService.evaluateUpdate("{VERSION}", body, null)
supportService.evaluateUpdate("{VERSION}", null, String(error))
<div><dt>版本</dt><dd>{VERSION}</dd></div>'''
    validate_app_version_contract(valid_app)
    print("PASS accepted consistent app version contract")
    for label, invalid_app in (
        ("stale update version", valid_app.replace(f'evaluateUpdate("{VERSION}"', 'evaluateUpdate("1.0.4"', 1)),
        ("missing update path", valid_app.replace(f'supportService.evaluateUpdate("{VERSION}", null, String(error))\n', "")),
        ("stale About version", valid_app.replace(f"<dd>{VERSION}</dd>", "<dd>1.0.4</dd>")),
    ):
        try:
            validate_app_version_contract(invalid_app)
        except M6Error:
            print(f"PASS rejected {label}")
        else:
            raise AssertionError(f"expected app version rejection: {label}")

    validate_candidate_identity(fixture(), candidate_id="V105-test-dirty")
    print("PASS accepted controlled dirty candidate identity")

    cases = (
        ("unknown field", lambda value: value.update(extra=True)),
        ("directory identity drift", lambda value: value.update(candidate_id="other")),
        ("version drift", lambda value: value.update(release_version="1.0.4")),
        ("short source head", lambda value: value.update(source_head="abc")),
        ("string dirty state", lambda value: value.update(source_tree_dirty="true")),
        ("publishable before acceptance", lambda value: value.update(publication_allowed=True)),
        ("missing acceptance blocker", lambda value: value["publication_blockers"].pop(0)),
        ("source blocker mismatch", lambda value: value["publication_blockers"].remove("source tree is dirty")),
        ("missing artifact", lambda value: value["artifacts"].pop()),
        ("duplicate artifact", lambda value: value["artifacts"].__setitem__(1, copy.deepcopy(value["artifacts"][0]))),
        ("invalid artifact hash", lambda value: value["artifacts"][0].update(sha256="NO")),
        ("absolute artifact path", lambda value: value["artifacts"][0].update(name="C:\\private\\candidate.zip")),
    )
    for label, mutate in cases:
        reject(label, mutate)

    with tempfile.TemporaryDirectory() as raw:
        package = Path(raw) / ZIP_NAME
        package.write_bytes(b"candidate")
        value = fixture()
        value["artifacts"][0]["size"] = package.stat().st_size
        value["artifacts"][0]["sha256"] = "0" * 64
        try:
            validate_candidate_identity(
                value,
                candidate_id="V105-test-dirty",
                package_path=package,
            )
        except M6Error:
            print("PASS rejected actual Zip hash drift")
        else:
            raise AssertionError("expected actual Zip hash rejection")

    print(f"PASS v1.0.5 M6 negative contracts ({len(cases) + 1}/13)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
