import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[3]
EXPORTER = ROOT / "scripts" / "apple" / "export_playgrounds_resource_probe.ps1"


class PlaygroundsResourceProbeTests(unittest.TestCase):
    def test_probe_checks_app_playground_main_bundle_resources(self):
        source = EXPORTER.read_text(encoding="utf-8")
        self.assertTrue(source.isascii())
        self.assertIn('resources: [.process("Resources")]', source)
        self.assertIn('Bundle.main.url(forResource: "cn-2026"', source)
        self.assertIn('bundle: .main', source)
        self.assertNotIn('Bundle.module', source)
        self.assertIn('Text("RESOURCE PROBE")', source)
        self.assertNotIn("SalaryCore", source)
        self.assertNotIn("#Preview", source)


if __name__ == "__main__":
    unittest.main()
