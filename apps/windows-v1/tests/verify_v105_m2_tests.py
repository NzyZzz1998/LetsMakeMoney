from __future__ import annotations

import copy

import verify_v105_m2 as verifier


def require_rejected(value: dict, label: str) -> None:
    try:
        verifier.validate_evidence(value)
    except AssertionError:
        print(f"PASS rejected {label}")
        return
    raise AssertionError(f"invalid M2 evidence was accepted: {label}")


def main() -> int:
    baseline = verifier.load_json(verifier.EVIDENCE_PATH)
    verifier.validate_evidence(baseline)
    print("PASS accepted valid M2 evidence")

    wrong_runs = copy.deepcopy(baseline)
    wrong_runs["fr004_reproduction"]["valid_runs"] = 19
    require_rejected(wrong_runs, "incomplete GUI run count")

    native_shown = copy.deepcopy(baseline)
    native_shown["fr004_reproduction"]["native_mini_shown_events"] = 1
    require_rejected(native_shown, "root cause contradicted by native shown")

    wrong_route = copy.deepcopy(baseline)
    wrong_route["fr004_reproduction"]["route"] = "keep-observing"
    require_rejected(wrong_route, "20/20 result not routed to M3")

    target_green = copy.deepcopy(baseline)
    target_green["fr003_characterization"]["target_behavior_test"] = "pass"
    require_rejected(target_green, "unimplemented target fabricated as passing")

    config_changed = copy.deepcopy(baseline)
    config_changed["baseline_integrity"]["configuration_sha256_after"] = "0" * 64
    require_rejected(config_changed, "user configuration not restored")

    business_changed = copy.deepcopy(baseline)
    business_changed["baseline_integrity"]["business_code_modified"] = True
    require_rejected(business_changed, "M2 business code change")

    absolute_path = copy.deepcopy(baseline)
    absolute_path["raw_evidence"]["index"] = "E:/codex/private/raw"
    require_rejected(absolute_path, "absolute private evidence path")

    leaked_secret = copy.deepcopy(baseline)
    leaked_secret["token"] = "not-redacted"
    require_rejected(leaked_secret, "secret-like field")

    print("PASS v1.0.5 M2 negative contract tests (8/8)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
