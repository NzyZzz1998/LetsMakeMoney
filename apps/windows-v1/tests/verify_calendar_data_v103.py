from __future__ import annotations

import argparse
import hashlib
import json
import re
import sys
from dataclasses import dataclass
from datetime import date
from pathlib import Path
from urllib.parse import urlparse


APP_ROOT = Path(__file__).resolve().parents[1]
DEFAULT_CALENDAR_ROOT = APP_ROOT / "calendar-data"
DEFAULT_CONTRACTS_ROOT = APP_ROOT / "contracts"
ANNUAL_FILE_PATTERN = re.compile(r"^cn-(20\d{2})\.json$")
SHA256_PATTERN = re.compile(r"^[A-F0-9]{64}$")


class CalendarContractError(RuntimeError):
    pass


@dataclass(frozen=True)
class CalendarDatasetIdentity:
    year: int
    file: str
    sha256: str


def require(condition: bool, message: str) -> None:
    if not condition:
        raise CalendarContractError(message)


def load_json(path: Path) -> object:
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except UnicodeDecodeError as error:
        raise CalendarContractError(f"{path.name}: invalid UTF-8") from error
    except json.JSONDecodeError as error:
        raise CalendarContractError(
            f"{path.name}: invalid JSON at line {error.lineno}, column {error.colno}"
        ) from error


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest().upper()


def require_exact_keys(value: object, expected: set[str], label: str) -> dict[str, object]:
    require(isinstance(value, dict), f"{label}: expected object")
    actual = set(value)
    require(actual == expected, f"{label}: fields differ; actual={sorted(actual)}")
    return value


def parse_date(value: object, expected_year: int, label: str) -> str:
    require(isinstance(value, str), f"{label}: expected date string")
    try:
        parsed = date.fromisoformat(value)
    except ValueError as error:
        raise CalendarContractError(f"{label}: invalid date") from error
    require(parsed.year == expected_year, f"{label}: date is outside dataset year")
    return value


def validate_contract_documents(contracts_root: Path) -> None:
    manifest_schema = require_exact_keys(
        load_json(contracts_root / "calendar-manifest.schema.json"),
        {"$schema", "$id", "title", "type", "additionalProperties", "required", "properties"},
        "calendar-manifest.schema.json",
    )
    dataset_schema = require_exact_keys(
        load_json(contracts_root / "calendar-data.schema.json"),
        {"$schema", "$id", "title", "type", "additionalProperties", "required", "properties"},
        "calendar-data.schema.json",
    )
    require(manifest_schema["type"] == "object", "manifest schema root must be object")
    require(dataset_schema["type"] == "object", "dataset schema root must be object")


def validate_source(value: object, file_name: str) -> None:
    source = require_exact_keys(
        value,
        {"publisher", "title", "document_no", "published_at", "url"},
        f"{file_name}.source",
    )
    for key in ("publisher", "title", "document_no"):
        require(
            isinstance(source[key], str) and bool(source[key].strip()),
            f"{file_name}.source.{key}: must be non-empty",
        )
    require(
        isinstance(source["published_at"], str),
        f"{file_name}.source.published_at: expected date",
    )
    try:
        date.fromisoformat(source["published_at"])
    except ValueError as error:
        raise CalendarContractError(
            f"{file_name}.source.published_at: invalid date"
        ) from error
    require(isinstance(source["url"], str), f"{file_name}.source.url: expected URL")
    parsed = urlparse(source["url"])
    host = (parsed.hostname or "").lower()
    require(parsed.scheme == "https", f"{file_name}.source.url: HTTPS is required")
    require(
        host == "gov.cn" or host.endswith(".gov.cn"),
        f"{file_name}.source.url: source must be under gov.cn",
    )


def validate_dataset(
    calendar_root: Path,
    identity: CalendarDatasetIdentity,
    dataset_version: str,
) -> None:
    path = calendar_root / identity.file
    require(path.is_file(), f"{identity.file}: referenced dataset is missing")
    require(sha256(path) == identity.sha256, f"{identity.file}: SHA256 mismatch")
    dataset = require_exact_keys(
        load_json(path),
        {
            "schema_version",
            "dataset_id",
            "year",
            "source",
            "holidays",
            "holiday_dates",
            "adjusted_workdays",
        },
        identity.file,
    )
    require(dataset["schema_version"] == 1, f"{identity.file}: schema_version must be 1")
    require(dataset["year"] == identity.year, f"{identity.file}: year mismatch")
    require(
        dataset["dataset_id"] == f"cn-{identity.year}",
        f"{identity.file}: dataset_id mismatch",
    )
    require(bool(dataset_version.strip()), "manifest dataset_version must be non-empty")
    validate_source(dataset["source"], identity.file)

    holidays = dataset["holidays"]
    require(isinstance(holidays, list) and holidays, f"{identity.file}: holidays are empty")
    flattened: list[str] = []
    for index, value in enumerate(holidays):
        holiday = require_exact_keys(
            value,
            {"name", "dates"},
            f"{identity.file}.holidays[{index}]",
        )
        require(
            isinstance(holiday["name"], str) and bool(holiday["name"].strip()),
            f"{identity.file}.holidays[{index}].name: must be non-empty",
        )
        dates = holiday["dates"]
        require(
            isinstance(dates, list) and dates,
            f"{identity.file}.holidays[{index}].dates: must be non-empty",
        )
        for date_index, value in enumerate(dates):
            flattened.append(
                parse_date(
                    value,
                    identity.year,
                    f"{identity.file}.holidays[{index}].dates[{date_index}]",
                )
            )

    holiday_dates = dataset["holiday_dates"]
    adjusted_workdays = dataset["adjusted_workdays"]
    require(isinstance(holiday_dates, list), f"{identity.file}: holiday_dates must be array")
    require(
        isinstance(adjusted_workdays, list),
        f"{identity.file}: adjusted_workdays must be array",
    )
    parsed_holidays = [
        parse_date(value, identity.year, f"{identity.file}.holiday_dates[{index}]")
        for index, value in enumerate(holiday_dates)
    ]
    parsed_adjusted = [
        parse_date(value, identity.year, f"{identity.file}.adjusted_workdays[{index}]")
        for index, value in enumerate(adjusted_workdays)
    ]
    require(
        len(parsed_holidays) == len(set(parsed_holidays)),
        f"{identity.file}: duplicate holiday date",
    )
    require(
        len(flattened) == len(set(flattened)),
        f"{identity.file}: holiday groups overlap",
    )
    require(
        set(flattened) == set(parsed_holidays),
        f"{identity.file}: holiday groups and holiday_dates differ",
    )
    require(
        len(parsed_adjusted) == len(set(parsed_adjusted)),
        f"{identity.file}: duplicate adjusted workday",
    )
    require(
        not set(parsed_holidays).intersection(parsed_adjusted),
        f"{identity.file}: holiday and adjusted workday conflict",
    )


def validate_calendar_tree(
    calendar_root: Path = DEFAULT_CALENDAR_ROOT,
    contracts_root: Path = DEFAULT_CONTRACTS_ROOT,
) -> list[CalendarDatasetIdentity]:
    validate_contract_documents(contracts_root)
    manifest_path = calendar_root / "manifest.json"
    require(manifest_path.is_file(), "manifest.json: file is missing")
    manifest = require_exact_keys(
        load_json(manifest_path),
        {"schema_version", "dataset_version", "supported_years", "datasets"},
        "manifest.json",
    )
    require(manifest["schema_version"] == 1, "manifest.json: schema_version must be 1")
    require(
        isinstance(manifest["dataset_version"], str)
        and bool(manifest["dataset_version"].strip()),
        "manifest.json: dataset_version must be non-empty",
    )
    supported_years = manifest["supported_years"]
    datasets = manifest["datasets"]
    require(
        isinstance(supported_years, list) and supported_years,
        "manifest.json: supported_years must be non-empty",
    )
    require(
        all(isinstance(year, int) and year >= 2025 for year in supported_years),
        "manifest.json: supported_years contains invalid year",
    )
    require(
        supported_years == sorted(set(supported_years)),
        "manifest.json: supported_years must be sorted and unique",
    )
    require(isinstance(datasets, list) and datasets, "manifest.json: datasets must be non-empty")

    identities: list[CalendarDatasetIdentity] = []
    for index, value in enumerate(datasets):
        entry = require_exact_keys(
            value,
            {"year", "file", "sha256"},
            f"manifest.json.datasets[{index}]",
        )
        year = entry["year"]
        file_name = entry["file"]
        digest = entry["sha256"]
        require(isinstance(year, int), f"manifest dataset {index}: year must be integer")
        require(isinstance(file_name, str), f"manifest dataset {index}: file must be string")
        require(
            file_name == f"cn-{year}.json" and bool(ANNUAL_FILE_PATTERN.fullmatch(file_name)),
            f"manifest dataset {index}: file name does not match year",
        )
        require(
            isinstance(digest, str) and bool(SHA256_PATTERN.fullmatch(digest)),
            f"manifest dataset {index}: SHA256 must be uppercase hexadecimal",
        )
        identities.append(CalendarDatasetIdentity(year, file_name, digest))

    years = [identity.year for identity in identities]
    files = [identity.file for identity in identities]
    require(len(years) == len(set(years)), "manifest.json: duplicate dataset year")
    require(len(files) == len(set(files)), "manifest.json: duplicate dataset file")
    require(
        years == supported_years,
        "manifest.json: datasets and supported_years must use the same sorted years",
    )
    discovered = sorted(
        path.name
        for path in calendar_root.iterdir()
        if path.is_file() and ANNUAL_FILE_PATTERN.fullmatch(path.name)
    )
    require(
        discovered == files,
        "calendar-data: unknown or unreferenced annual dataset file",
    )

    for identity in identities:
        validate_dataset(calendar_root, identity, manifest["dataset_version"])
    return identities


def main() -> int:
    parser = argparse.ArgumentParser(description="Verify v1.0.3 bundled calendar data.")
    parser.add_argument(
        "--calendar-root",
        type=Path,
        default=DEFAULT_CALENDAR_ROOT,
        help="Directory containing manifest.json and annual datasets.",
    )
    parser.add_argument(
        "--contracts-root",
        type=Path,
        default=DEFAULT_CONTRACTS_ROOT,
        help="Directory containing calendar JSON contract documents.",
    )
    args = parser.parse_args()
    try:
        identities = validate_calendar_tree(args.calendar_root, args.contracts_root)
    except (CalendarContractError, OSError) as error:
        print(f"FAIL calendar-data: {error}", file=sys.stderr)
        return 1
    for identity in identities:
        print(f"PASS {identity.year} {identity.file} SHA256={identity.sha256}")
    print(f"PASS calendar-data manifest ({len(identities)} annual datasets)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
