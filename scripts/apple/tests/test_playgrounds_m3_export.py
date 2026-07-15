import json
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[3]
EXPORTER = ROOT / "scripts" / "apple" / "export_playgrounds_m3.ps1"


class PlaygroundsM3ExportContractTests(unittest.TestCase):
    def test_exporter_uses_legacy_strings_instead_of_xcstrings(self):
        source = EXPORTER.read_text(encoding="utf-8")
        self.assertNotIn(
            "Copy-Item -LiteralPath (Join-Path $root 'apple\\Shared\\Resources\\Localizable.xcstrings')",
            source,
        )
        self.assertIn("zh-Hans.lproj", source)
        self.assertIn("Localizable.strings", source)
        self.assertIn("ConvertTo-LegacyStrings", source)
        self.assertIn("PackageName", source)
        self.assertIn("BundleIdentifier", source)
        self.assertIn("ExcludePreviews", source)

    def test_catalog_contains_translatable_chinese_values(self):
        catalog_path = ROOT / "apple" / "Shared" / "Resources" / "Localizable.xcstrings"
        strings = json.loads(catalog_path.read_text(encoding="utf-8"))["strings"]
        translated = [
            value["localizations"]["zh-Hans"]["stringUnit"]["value"]
            for value in strings.values()
            if "zh-Hans" in value.get("localizations", {})
        ]
        self.assertGreater(len(translated), 20)

    def test_exporter_includes_shared_live_activity_sources(self):
        source = EXPORTER.read_text(encoding="utf-8")
        self.assertIn("Shared\\LiveActivity", source)
        self.assertIn("$liveActivitySource", source)
        self.assertIn("Copy-Item -LiteralPath $_.FullName -Destination $destination", source)


if __name__ == "__main__":
    unittest.main()
