from __future__ import annotations

import copy
import json

import verify_v105_m0 as verifier


def require_rejected(value: dict, label: str) -> None:
    try:
        verifier.validate_evidence(value)
    except AssertionError:
        print(f"PASS rejected {label}")
        return
    raise AssertionError(f"invalid evidence was accepted: {label}")


def main() -> int:
    baseline = verifier.load_json(verifier.EVIDENCE_PATH)

    confused_candidate = copy.deepcopy(baseline)
    confused_candidate["local_dirty_candidate"]["zip"]["sha256"] = (
        baseline["official_release"]["zip"]["sha256"]
    )
    require_rejected(confused_candidate, "dirty candidate confused with official asset")

    dirty_official = copy.deepcopy(baseline)
    dirty_official["official_release"]["build_info"]["source_tree_dirty"] = True
    require_rejected(dirty_official, "dirty official BUILD-INFO")

    wrong_scheme = copy.deepcopy(baseline)
    wrong_scheme["decisions"]["calendar_today_scheme"] = "B_full_cell_highlight"
    require_rejected(wrong_scheme, "calendar scheme drift")

    shortened_reproduction = copy.deepcopy(baseline)
    shortened_reproduction["decisions"]["fr004_reproduction_runs"] = 19
    require_rejected(shortened_reproduction, "FR-004 run count drift")

    wrong_rollback = copy.deepcopy(baseline)
    wrong_rollback["decisions"]["fr008_failure_outcome"] = "ship_candidate_anyway"
    require_rejected(wrong_rollback, "FR-008 rollback drift")

    absolute_path = copy.deepcopy(baseline)
    absolute_path["verification"]["source"] = "E:/codex/private/evidence"
    require_rejected(absolute_path, "absolute local path")

    leaked_secret = copy.deepcopy(baseline)
    leaked_secret["verification"]["token"] = "sensitive-value"
    require_rejected(leaked_secret, "secret-like field")

    serialized = json.dumps(baseline, ensure_ascii=False)
    assert "monthly_salary" not in serialized, "M0 evidence must not contain salary values"
    print("PASS accepted valid evidence")
    print("PASS v1.0.5 M0 negative verifier contracts (8/8)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
