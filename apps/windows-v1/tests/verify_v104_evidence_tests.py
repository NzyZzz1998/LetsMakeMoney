from __future__ import annotations

import copy
import json
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[3]
sys.path.insert(0, str(ROOT / "scripts"))
import v104_evidence as evidence  # noqa: E402


VALID = {
    "schema_version": "1.0",
    "release_version": "1.0.4",
    "channel": "stable-candidate",
    "branch": "main",
    "commit": "a" * 40,
    "source_tree_dirty": False,
    "artifacts": [
        {
            "name": "LetsMakeMoney-v1.0.4-windows-x86_64.zip",
            "size": 1024,
            "sha256": "A" * 64,
        }
    ],
    "environment": {
        "windows_version": "Windows 11 24H2",
        "architecture": "x86_64",
        "dpi": [100, 125, 150],
        "webview2_version": "150.0.4078.105",
    },
    "checks": [
        {
            "id": "V104-AUTO-PACKAGE",
            "method": "automatic",
            "result": "passed",
            "started_at": "2026-07-31T00:00:00Z",
            "finished_at": "2026-07-31T00:01:00Z",
            "evidence_ref": "repo:doc/releases/v1.0.4/evidence/package.json",
        }
    ],
    "conclusion": "pending",
    "limitations": [],
    "log_summary": {
        "event_counts": {"app.started": 1},
        "error_categories": [],
        "truncated": False,
    },
    "redaction": {
        "policy_version": "v1",
        "removed_fields": ["user_paths", "salary_values"],
    },
    "raw_archive": {
        "schema_version": "1.0",
        "archive_id": "LMM-V104-ACCEPTANCE-001",
        "archive_sha256": None,
        "availability": "not_collected",
        "custodian_role": "project-owner",
        "contents": [],
        "retention": "owner-managed",
        "reason": "候选尚未完成。",
        "updated_at": "2026-07-31T00:02:00Z",
    },
    "generated_at": "2026-07-31T00:03:00Z",
}


def reject(label: str, mutate) -> None:
    candidate = copy.deepcopy(VALID)
    mutate(candidate)
    try:
        evidence.validate_summary(candidate)
    except evidence.EvidenceError:
        print(f"PASS rejected {label}")
        return
    raise AssertionError(f"expected rejection: {label}")


def main() -> int:
    evidence.validate_summary(copy.deepcopy(VALID))
    print("PASS accepted valid evidence")

    reject("absolute path", lambda value: value["limitations"].append("C:\\Users\\owner\\capture"))
    reject("user directory", lambda value: value["limitations"].append("\\Users\\owner\\capture"))
    reject("email", lambda value: value["limitations"].append("owner@example.com"))
    reject("salary field", lambda value: value.update({"salary": 10000}))
    reject("secret field", lambda value: value["log_summary"].update({"access_token": "redacted"}))
    reject("invalid hash", lambda value: value["artifacts"][0].update({"sha256": "ABC"}))
    reject(
        "not-collected archive claiming a hash",
        lambda value: value["raw_archive"].update({"archive_sha256": "B" * 64}),
    )
    reject("duplicate check id", lambda value: value["checks"].append(copy.deepcopy(value["checks"][0])))

    schema_root = ROOT / "apps" / "windows-v1" / "tests" / "contracts"
    for path in (
        schema_root / "v104-acceptance-summary.schema.json",
        schema_root / "v104-raw-evidence-index.schema.json",
    ):
        json.loads(path.read_text(encoding="utf-8"))
        print(f"PASS parsed {path.name}")

    print("PASS v1.0.4 evidence privacy contracts (8/8 negative)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
