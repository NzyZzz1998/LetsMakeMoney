import json
import tempfile
import unittest
from pathlib import Path

from scripts.apple.validate_apple_localization import validate


class AppleLocalizationValidationTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.root = Path(self.temporary.name)
        self.source = (
            self.root
            / "apple/Packages/SalaryCore/Sources/SalaryCore/SalaryCoreError.swift"
        )
        self.source.parent.mkdir(parents=True)
        self.source.write_text(
            'case .invalidConfiguration: "salary.error.invalid_configuration"\n',
            encoding="utf-8",
        )
        self.catalog = self.root / "apple/Shared/Resources/Localizable.xcstrings"
        self.catalog.parent.mkdir(parents=True)
        self.write_catalog(include_key=True)

    def tearDown(self):
        self.temporary.cleanup()

    def write_catalog(self, include_key: bool):
        strings = {}
        if include_key:
            strings["salary.error.invalid_configuration"] = {
                "localizations": {
                    "zh-Hans": {
                        "stringUnit": {"state": "translated", "value": "配置无效"}
                    }
                }
            }
        self.catalog.write_text(
            json.dumps({"sourceLanguage": "zh-Hans", "strings": strings, "version": "1.0"}),
            encoding="utf-8",
        )

    def test_valid_catalog_passes(self):
        self.assertEqual(validate(self.root), [])

    def test_missing_catalog_key_fails(self):
        self.write_catalog(include_key=False)
        self.assertIn(
            "CATALOG_KEY_INCOMPLETE: salary.error.invalid_configuration",
            validate(self.root),
        )

    def test_hardcoded_product_copy_fails_without_echoing_copy(self):
        app = self.root / "apple/App/ContentView.swift"
        app.parent.mkdir(parents=True)
        app.write_text('let title = "今日已赚"\n', encoding="utf-8")
        failures = validate(self.root)
        self.assertIn("HARDCODED_CJK_LITERAL: apple/App/ContentView.swift:1", failures)
        self.assertNotIn("今日已赚", "\n".join(failures))


if __name__ == "__main__":
    unittest.main()
