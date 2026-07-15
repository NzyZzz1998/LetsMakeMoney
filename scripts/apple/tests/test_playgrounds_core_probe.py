import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[3]
EXPORTER = ROOT / "scripts" / "apple" / "export_playgrounds_core_probe.ps1"


class PlaygroundsCoreProbeTests(unittest.TestCase):
    def test_probe_loads_salary_core_without_resources_or_previews(self):
        source = EXPORTER.read_text(encoding="utf-8")
        self.assertIn('Text("SALARY CORE OK")', source)
        self.assertIn("AppConfiguration.defaultValue", source)
        self.assertIn('.target(name: "SalaryCore")', source)
        self.assertNotIn("resources:", source)
        self.assertNotIn("#Preview", source)


if __name__ == "__main__":
    unittest.main()
