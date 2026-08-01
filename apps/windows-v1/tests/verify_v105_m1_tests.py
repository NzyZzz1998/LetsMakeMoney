from __future__ import annotations

import copy

import verify_v105_m1 as verifier


def require_rejected(value: dict, label: str) -> None:
    try:
        verifier.validate_contract(value)
    except AssertionError:
        print(f"PASS rejected {label}")
        return
    raise AssertionError(f"invalid M1 contract was accepted: {label}")


def main() -> int:
    baseline = verifier.load_json(verifier.EVIDENCE_PATH)
    verifier.validate_contract(baseline)
    print("PASS accepted valid M1 contract")

    wrong_official = copy.deepcopy(baseline)
    wrong_official["public_baseline"]["zip_sha256"] = "0" * 64
    require_rejected(wrong_official, "official v1.0.4 SHA drift")

    candidate_claims_publish = copy.deepcopy(baseline)
    candidate_claims_publish["candidate_contract"]["can_claim_published"] = True
    require_rejected(candidate_claims_publish, "candidate claims published identity")

    dirty_published = copy.deepcopy(baseline)
    dirty_published["published_contract"]["allows_dirty"] = True
    require_rejected(dirty_published, "published mode allows dirty source")

    deletable_unique = copy.deepcopy(baseline)
    deletable_unique["evidence_contract"]["unique_copy_deletion_allowed"] = True
    require_rejected(deletable_unique, "unique evidence deletion enabled")

    history_overwrite = copy.deepcopy(baseline)
    history_overwrite["evidence_contract"]["replacement_evidence_can_overwrite_history"] = True
    require_rejected(history_overwrite, "replacement evidence overwrites history")

    deletion_authorized = copy.deepcopy(baseline)
    deletion_authorized["dirty_v104_candidate"]["deletion_authorized"] = True
    require_rejected(deletion_authorized, "dirty candidate deletion authorization fabricated")

    absolute_path = copy.deepcopy(baseline)
    absolute_path["directories"][0]["path"] = "E:/codex/private/candidate"
    require_rejected(absolute_path, "absolute local path")

    leaked_secret = copy.deepcopy(baseline)
    leaked_secret["token"] = "not-redacted"
    require_rejected(leaked_secret, "secret-like field")

    print("PASS v1.0.5 M1 negative contract tests (8/8)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
