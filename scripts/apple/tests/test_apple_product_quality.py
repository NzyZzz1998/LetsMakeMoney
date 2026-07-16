import json
import tempfile
import unittest
from pathlib import Path

from scripts.apple.validate_apple_product_quality import validate


class AppleProductQualityTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.root = Path(self.temporary.name)
        self.catalog = self.root / "apple/Shared/Resources/Localizable.xcstrings"
        self.catalog.parent.mkdir(parents=True)
        self.catalog.write_text(
            json.dumps(
                {
                    "sourceLanguage": "zh-Hans",
                    "strings": {"today.amount": {}},
                    "version": "1.0",
                }
            ),
            encoding="utf-8",
        )
        self.source = self.root / "apple/App/ContentView.swift"
        self.source.parent.mkdir(parents=True)

    def tearDown(self):
        self.temporary.cleanup()

    def write_source(self, value: str):
        self.source.write_text(value, encoding="utf-8")

    def test_registered_copy_and_structured_event_pass(self):
        self.write_source(
            'Text("today.amount")\n'
            'logger.record(level: .info, event: "settings.saved")\n'
        )
        self.assertEqual(validate(self.root), [])

    def test_unregistered_localization_key_fails(self):
        self.write_source('Button("settings.missing") {}\n')
        self.assertIn(
            "UNREGISTERED_LOCALIZATION_KEY: apple/App/ContentView.swift:1",
            validate(self.root),
        )

    def test_hardcoded_user_copy_and_mojibake_fail(self):
        self.write_source('Text("Save changes")\nText("bad \ufffd copy")\n')
        failures = validate(self.root)
        self.assertIn("HARDCODED_USER_COPY: apple/App/ContentView.swift:1", failures)
        self.assertIn("MOJIBAKE_MARKER: apple/App/ContentView.swift:2", failures)

    def test_private_path_email_and_raw_error_metadata_fail_without_echoing_values(self):
        secret_email = "person@example.invalid"
        self.write_source(
            'let path = "C:\\\\Users\\\\private\\\\config.json"\n'
            f'let email = "{secret_email}"\n'
            'logger.record(level: .error, event: "failed", '
            'metadata: ["reason": String(describing: error)])\n'
        )
        failures = validate(self.root)
        output = "\n".join(failures)
        self.assertIn("PRIVATE_ABSOLUTE_PATH: apple/App/ContentView.swift:1", failures)
        self.assertIn("EMAIL_LITERAL: apple/App/ContentView.swift:2", failures)
        self.assertIn("RAW_ERROR_METADATA: apple/App/ContentView.swift:3", failures)
        self.assertNotIn("private", output)
        self.assertNotIn(secret_email, output)


if __name__ == "__main__":
    unittest.main()
