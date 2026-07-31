from __future__ import annotations

import copy
import json

import verify_v104_m0 as verifier


def require_rejected(value: dict, label: str) -> None:
    try:
        verifier.validate_evidence(value)
    except AssertionError:
        print(f"PASS rejected {label}")
        return
    raise AssertionError(f"invalid evidence was accepted: {label}")


def main() -> int:
    baseline = verifier.load_json(verifier.EVIDENCE_PATH)

    wrong_hash = copy.deepcopy(baseline)
    wrong_hash["release_payload"]["zip"]["sha256"] = "0" * 64
    require_rejected(wrong_hash, "release hash drift")

    absolute_path = copy.deepcopy(baseline)
    absolute_path["environment"]["node"]["source"] = "C:/Users/example/runtime"
    require_rejected(absolute_path, "absolute local path")

    wrong_storage = copy.deepcopy(baseline)
    wrong_storage["decisions"]["mini_edge_state_storage"] = "window_state_json"
    require_rejected(wrong_storage, "storage decision drift")

    leaked_secret = copy.deepcopy(baseline)
    leaked_secret["verification"]["token"] = "sensitive-value"
    require_rejected(leaked_secret, "secret-like field")

    serialized = json.dumps(baseline, ensure_ascii=False)
    assert "monthly_salary" not in serialized, "evidence must not contain salary values"
    print("PASS accepted valid evidence")
    print("PASS v1.0.4 M0 negative verifier contracts (5/5)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
