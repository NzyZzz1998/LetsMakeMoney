import json
import tempfile
import subprocess
import sys
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[3]
VALIDATOR = ROOT / "scripts" / "apple" / "validate_salary_contract.py"
SCHEMA_ROOT = ROOT / "shared" / "salary-schema" / "v1"


class SalaryContractTests(unittest.TestCase):
    def run_validator(self, *args: str) -> subprocess.CompletedProcess[str]:
        return subprocess.run(
            [sys.executable, str(VALIDATOR), *args],
            cwd=ROOT,
            text=True,
            capture_output=True,
            check=False,
        )

    def test_valid_examples_pass(self) -> None:
        for name in ("minimal-valid.json", "full-valid.json", "boundary-valid.json"):
            with self.subTest(name=name):
                result = self.run_validator("config", str(SCHEMA_ROOT / "examples" / name))
                self.assertEqual(result.returncode, 0, result.stdout + result.stderr)

    def test_invalid_examples_fail(self) -> None:
        for name in (
            "invalid-future-version.json",
            "invalid-unknown-field.json",
            "invalid-time-range.json",
            "invalid-missing-anchor.json",
            "invalid-duplicate-override.json",
        ):
            with self.subTest(name=name):
                result = self.run_validator("config", str(SCHEMA_ROOT / "examples" / name))
                self.assertNotEqual(result.returncode, 0, result.stdout + result.stderr)

    def test_vectors_match_reference_results(self) -> None:
        result = self.run_validator("vectors", str(SCHEMA_ROOT / "vectors" / "salary-vectors.json"))
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)

    def test_holiday_manifest_and_checksums(self) -> None:
        result = self.run_validator("holidays", str(SCHEMA_ROOT / "holidays" / "manifest.json"))
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)

    def test_mutated_holiday_checksum_fails(self) -> None:
        source = json.loads((SCHEMA_ROOT / "holidays" / "manifest.json").read_text(encoding="utf-8"))
        source["files"][0]["sha256"] = "0" * 64
        with tempfile.NamedTemporaryFile("w", suffix=".json", dir=SCHEMA_ROOT / "holidays", delete=False, encoding="utf-8") as handle:
            json.dump(source, handle, ensure_ascii=False)
            path = Path(handle.name)
        try:
            result = self.run_validator("holidays", str(path))
            self.assertNotEqual(result.returncode, 0, result.stdout + result.stderr)
        finally:
            path.unlink(missing_ok=True)

    def test_invalid_timezone_vector_fails(self) -> None:
        source = json.loads((SCHEMA_ROOT / "vectors" / "salary-vectors.json").read_text(encoding="utf-8"))
        source["cases"][0]["timeZone"] = "Invalid/Nowhere"
        with tempfile.NamedTemporaryFile("w", suffix=".json", delete=False, encoding="utf-8") as handle:
            json.dump(source, handle, ensure_ascii=False)
            path = Path(handle.name)
        try:
            result = self.run_validator("vectors", str(path))
            self.assertNotEqual(result.returncode, 0, result.stdout + result.stderr)
        finally:
            path.unlink(missing_ok=True)


if __name__ == "__main__":
    unittest.main()
