#!/usr/bin/env python3
"""Validate the iOS v0.1 prototype against the formal Chinese copy contract."""

from __future__ import annotations

import html
import json
import re
import sys
from pathlib import Path


COPY_KEYS = (
    "nav.today",
    "nav.calendar",
    "nav.settings",
    "today.amount",
    "today.month_total",
    "today.progress",
    "today.schedule",
    "onboarding.step.compensation",
    "onboarding.step.schedule",
    "onboarding.step.summary",
)

INTERACTIONS = {
    "data-phone-nav=today": 'data-phone-nav="today"',
    "data-phone-nav=calendar": 'data-phone-nav="calendar"',
    "data-open-modal=settingsModal": 'data-open-modal="settingsModal"',
    "data-wizard-step=0": 'data-wizard-step="0"',
    "data-wizard-step=1": 'data-wizard-step="1"',
    "data-wizard-step=2": 'data-wizard-step="2"',
    "wizardBack": 'id="wizardBack"',
    "wizardNext": 'id="wizardNext"',
    "wizardCancel": 'id="wizardCancel"',
}


def _visible_text(source: str) -> str:
    without_script = re.sub(r"<(script|style)\b[^>]*>.*?</\1>", " ", source, flags=re.S | re.I)
    without_tags = re.sub(r"<[^>]+>", " ", without_script)
    return " ".join(html.unescape(without_tags).split())


def _localized_value(entry: dict) -> str | None:
    return (
        entry.get("localizations", {})
        .get("zh-Hans", {})
        .get("stringUnit", {})
        .get("value")
    )


def validate(root: Path) -> list[str]:
    catalog_path = root / "apple/Shared/Resources/Localizable.xcstrings"
    prototype_path = root / "doc/prototypes/ios-v0.1/index.html"
    failures: list[str] = []

    if not catalog_path.is_file():
        return ["MISSING_PROTOTYPE_CONTRACT_INPUT: apple/Shared/Resources/Localizable.xcstrings"]
    if not prototype_path.is_file():
        return ["MISSING_PROTOTYPE_CONTRACT_INPUT: doc/prototypes/ios-v0.1/index.html"]

    catalog = json.loads(catalog_path.read_text(encoding="utf-8"))
    strings = catalog.get("strings", {})
    prototype = prototype_path.read_text(encoding="utf-8")
    visible = _visible_text(prototype)

    for key in COPY_KEYS:
        entry = strings.get(key)
        if not isinstance(entry, dict):
            failures.append(f"MISSING_CATALOG_KEY: {key}")
            continue
        value = _localized_value(entry)
        if not value:
            failures.append(f"MISSING_CATALOG_TRANSLATION: {key}")
            continue
        if " ".join(value.split()) not in visible:
            failures.append(f"PROTOTYPE_COPY_DRIFT: {key}")

    for name, marker in INTERACTIONS.items():
        if marker not in prototype:
            failures.append(f"MISSING_PROTOTYPE_INTERACTION: {name}")

    return failures


def main() -> int:
    root = Path(__file__).resolve().parents[2]
    failures = validate(root)
    if failures:
        for failure in failures:
            print(failure)
        return 1
    print("IOS_PROTOTYPE_CONTRACT_PASS")
    return 0


if __name__ == "__main__":
    sys.exit(main())
