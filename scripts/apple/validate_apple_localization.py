#!/usr/bin/env python3
"""Validate the Apple String Catalog and reject user-facing CJK literals in product Swift."""

from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path


CJK_LITERAL = re.compile(r'"(?:[^"\\]|\\.)*[\u3400-\u9fff](?:[^"\\]|\\.)*"')
LOCALIZATION_KEY = re.compile(r'case\s+\.\w+\s*:\s*"([a-z0-9._-]+)"')


def product_swift_files(root: Path) -> list[Path]:
    apple = root / "apple"
    return [
        path
        for path in apple.rglob("*.swift")
        if ".build" not in path.parts
        and "Tests" not in path.parts
        and "DerivedData" not in path.parts
    ]


def validate(root: Path) -> list[str]:
    failures: list[str] = []
    catalog_path = root / "apple" / "Shared" / "Resources" / "Localizable.xcstrings"
    error_path = (
        root
        / "apple"
        / "Packages"
        / "SalaryCore"
        / "Sources"
        / "SalaryCore"
        / "SalaryCoreError.swift"
    )

    try:
        catalog = json.loads(catalog_path.read_text(encoding="utf-8"))
    except (OSError, UnicodeError, json.JSONDecodeError) as error:
        return [f"CATALOG_INVALID: {catalog_path}: {type(error).__name__}"]

    strings = catalog.get("strings")
    if catalog.get("sourceLanguage") != "zh-Hans" or not isinstance(strings, dict):
        failures.append("CATALOG_SHAPE_INVALID: sourceLanguage/strings")
        strings = {}

    source = error_path.read_text(encoding="utf-8")
    required_keys = set(LOCALIZATION_KEY.findall(source))
    if not required_keys:
        failures.append("LOCALIZATION_KEYS_MISSING: SalaryCoreError")

    for key in sorted(required_keys):
        entry = strings.get(key, {})
        unit = entry.get("localizations", {}).get("zh-Hans", {}).get("stringUnit", {})
        if unit.get("state") != "translated" or not str(unit.get("value", "")).strip():
            failures.append(f"CATALOG_KEY_INCOMPLETE: {key}")

    for path in product_swift_files(root):
        text = path.read_text(encoding="utf-8")
        for line_number, line in enumerate(text.splitlines(), start=1):
            if CJK_LITERAL.search(line):
                relative = path.relative_to(root).as_posix()
                failures.append(f"HARDCODED_CJK_LITERAL: {relative}:{line_number}")

    return failures


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--root", type=Path, default=Path(__file__).resolve().parents[2])
    args = parser.parse_args()
    failures = validate(args.root.resolve())
    if failures:
        for failure in failures:
            print(failure)
        return 1
    print("IOS_LOCALIZATION_PASS")
    return 0


if __name__ == "__main__":
    sys.exit(main())
