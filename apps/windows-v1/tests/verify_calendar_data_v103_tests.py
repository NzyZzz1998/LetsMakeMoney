from __future__ import annotations

import hashlib
import json
import shutil
import tempfile
from pathlib import Path

from verify_calendar_data_v103 import (
    APP_ROOT,
    CalendarContractError,
    validate_calendar_tree,
)


SOURCE = APP_ROOT / "calendar-data"
CONTRACTS = APP_ROOT / "contracts"


def read_json(path: Path) -> dict[str, object]:
    return json.loads(path.read_text(encoding="utf-8"))


def write_json(path: Path, value: object) -> None:
    path.write_text(
        json.dumps(value, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )


def update_manifest_hash(root: Path, file_name: str) -> None:
    manifest_path = root / "manifest.json"
    manifest = read_json(manifest_path)
    digest = hashlib.sha256((root / file_name).read_bytes()).hexdigest().upper()
    for entry in manifest["datasets"]:
        if entry["file"] == file_name:
            entry["sha256"] = digest
            break
    write_json(manifest_path, manifest)


def expect_failure(label: str, mutate) -> None:
    with tempfile.TemporaryDirectory(prefix="lmm-v103-calendar-") as temporary:
        root = Path(temporary) / "calendar-data"
        shutil.copytree(SOURCE, root)
        mutate(root)
        try:
            validate_calendar_tree(root, CONTRACTS)
        except CalendarContractError:
            print(f"PASS rejects {label}")
            return
        raise AssertionError(f"Expected calendar validation failure: {label}")


def main() -> int:
    identities = validate_calendar_tree(SOURCE, CONTRACTS)
    assert [identity.year for identity in identities] == [2025, 2026]
    print("PASS accepts current calendar tree")

    expect_failure(
        "missing dataset",
        lambda root: (root / "cn-2026.json").unlink(),
    )
    expect_failure(
        "unreferenced annual file",
        lambda root: shutil.copy2(root / "cn-2026.json", root / "cn-2027.json"),
    )

    def hash_mismatch(root: Path) -> None:
        path = root / "cn-2025.json"
        path.write_bytes(path.read_bytes() + b"\n")

    expect_failure("hash mismatch", hash_mismatch)

    def invalid_source(root: Path) -> None:
        path = root / "cn-2025.json"
        dataset = read_json(path)
        dataset["source"]["url"] = "https://example.invalid/calendar"
        write_json(path, dataset)
        update_manifest_hash(root, path.name)

    expect_failure("untrusted source", invalid_source)

    def invalid_date(root: Path) -> None:
        path = root / "cn-2025.json"
        dataset = read_json(path)
        dataset["holiday_dates"][0] = "2025-02-30"
        write_json(path, dataset)
        update_manifest_hash(root, path.name)

    expect_failure("invalid date", invalid_date)

    def duplicate_date(root: Path) -> None:
        path = root / "cn-2025.json"
        dataset = read_json(path)
        dataset["holiday_dates"].append(dataset["holiday_dates"][0])
        write_json(path, dataset)
        update_manifest_hash(root, path.name)

    expect_failure("duplicate holiday", duplicate_date)

    def conflicting_date(root: Path) -> None:
        path = root / "cn-2025.json"
        dataset = read_json(path)
        dataset["adjusted_workdays"].append(dataset["holiday_dates"][0])
        write_json(path, dataset)
        update_manifest_hash(root, path.name)

    expect_failure("holiday/workday conflict", conflicting_date)

    def year_set_mismatch(root: Path) -> None:
        manifest_path = root / "manifest.json"
        manifest = read_json(manifest_path)
        manifest["supported_years"] = [2025, 2026, 2027]
        write_json(manifest_path, manifest)

    expect_failure("supported year without dataset", year_set_mismatch)

    def filename_mismatch(root: Path) -> None:
        manifest_path = root / "manifest.json"
        manifest = read_json(manifest_path)
        manifest["datasets"][0]["file"] = "cn-2026.json"
        write_json(manifest_path, manifest)

    expect_failure("dataset filename mismatch", filename_mismatch)
    print("PASS calendar-data negative matrix (8 cases)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
