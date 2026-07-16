#!/usr/bin/env python3
"""Check Apple product copy, encoding, and privacy-sensitive source patterns."""

from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path


UI_LITERAL = re.compile(
    r"(?:Text|Button|Label|Toggle|Picker|Section|ContentUnavailableView|TextField)"
    r"\s*\(\s*\"((?:[^\"\\]|\\.)*)\""
    r"|(?:navigationTitle|accessibilityLabel)\s*\(\s*\"((?:[^\"\\]|\\.)*)\""
)
KEY_LIKE = re.compile(r"^[a-z][a-z0-9_-]*(?:\.[a-zA-Z0-9_-]+)+$")
LATIN_COPY = re.compile(r"[A-Za-z]{2,}(?:\s+[A-Za-z]{2,})+")
MOJIBAKE = re.compile(r"\ufffd|锟|Ã.|â(?:€|™|œ|“|”)")
PRIVATE_PATH = re.compile(r"(?i)(?:[a-z]:\\+users\\+|/users/|/home/)")
EMAIL = re.compile(r"(?i)\b[a-z0-9._%+-]+@[a-z0-9.-]+\.[a-z]{2,}\b")
RAW_ERROR_METADATA = re.compile(
    r"metadata\s*:\s*\[[\s\S]{0,500}?"
    r"(?:String\s*\(\s*describing\s*:\s*(?:error|reason)|localizedDescription)"
)
SECRET_LITERAL = re.compile(
    r"(?i)\b(?:api[_-]?key|token|secret|password)\b\s*[:=]\s*\"[^\"]{8,}\""
)


def product_swift_files(root: Path) -> list[Path]:
    apple = root / "apple"
    roots = [
        apple / "App",
        apple / "WidgetExtension",
        apple / "WatchApp",
        apple / "WatchWidgetExtension",
        apple / "Shared",
        apple / "Packages" / "SalaryCore" / "Sources",
    ]
    files: list[Path] = []
    for source_root in roots:
        if source_root.exists():
            files.extend(source_root.rglob("*.swift"))
    return sorted(
        path
        for path in files
        if ".build" not in path.parts
        and "DerivedData" not in path.parts
        and "Tests" not in path.parts
    )


def line_number(text: str, offset: int) -> int:
    return text.count("\n", 0, offset) + 1


def finding(code: str, path: Path, root: Path, line: int) -> str:
    return f"{code}: {path.relative_to(root).as_posix()}:{line}"


def validate(root: Path) -> list[str]:
    failures: list[str] = []
    catalog_path = root / "apple/Shared/Resources/Localizable.xcstrings"
    try:
        catalog = json.loads(catalog_path.read_text(encoding="utf-8"))
        catalog_keys = set(catalog.get("strings", {}))
    except (OSError, UnicodeError, json.JSONDecodeError):
        return [f"CATALOG_INVALID: {catalog_path.relative_to(root).as_posix()}"]

    for path in product_swift_files(root):
        try:
            text = path.read_text(encoding="utf-8")
        except (OSError, UnicodeError):
            failures.append(finding("SWIFT_UTF8_INVALID", path, root, 1))
            continue

        for match in UI_LITERAL.finditer(text):
            value = match.group(1) or match.group(2) or ""
            line = line_number(text, match.start())
            if "\\(" in value:
                continue
            if KEY_LIKE.fullmatch(value):
                if value not in catalog_keys:
                    failures.append(finding("UNREGISTERED_LOCALIZATION_KEY", path, root, line))
            elif LATIN_COPY.search(value):
                failures.append(finding("HARDCODED_USER_COPY", path, root, line))

        line_patterns = (
            (MOJIBAKE, "MOJIBAKE_MARKER"),
            (PRIVATE_PATH, "PRIVATE_ABSOLUTE_PATH"),
            (EMAIL, "EMAIL_LITERAL"),
            (SECRET_LITERAL, "SECRET_LITERAL"),
        )
        for number, line in enumerate(text.splitlines(), start=1):
            for pattern, code in line_patterns:
                if pattern.search(line):
                    failures.append(finding(code, path, root, number))

        for match in RAW_ERROR_METADATA.finditer(text):
            failures.append(
                finding("RAW_ERROR_METADATA", path, root, line_number(text, match.start()))
            )

    return sorted(set(failures))


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--root", type=Path, default=Path(__file__).resolve().parents[2])
    args = parser.parse_args()
    failures = validate(args.root.resolve())
    if failures:
        for failure in failures:
            print(failure)
        return 1
    print("IOS_PRODUCT_QUALITY_PASS")
    return 0


if __name__ == "__main__":
    sys.exit(main())
