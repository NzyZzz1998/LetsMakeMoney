import json
import tempfile
import unittest
from pathlib import Path

from scripts.apple.validate_ios_prototype_contract import validate


class IOSPrototypeContractTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.root = Path(self.temporary.name)
        self.catalog = self.root / "apple/Shared/Resources/Localizable.xcstrings"
        self.prototype = self.root / "doc/prototypes/ios-v0.1/index.html"
        self.catalog.parent.mkdir(parents=True)
        self.prototype.parent.mkdir(parents=True)

    def tearDown(self):
        self.temporary.cleanup()

    def write_catalog(self, values: dict[str, str]):
        strings = {
            key: {
                "localizations": {
                    "zh-Hans": {"stringUnit": {"state": "translated", "value": value}}
                }
            }
            for key, value in values.items()
        }
        self.catalog.write_text(
            json.dumps({"sourceLanguage": "zh-Hans", "strings": strings, "version": "1.0"}),
            encoding="utf-8",
        )

    def test_critical_copy_and_interactions_pass(self):
        self.write_catalog(
            {
                "nav.today": "今日",
                "nav.calendar": "日历",
                "nav.settings": "设置",
                "today.amount": "今日已赚",
                "today.month_total": "本月累计",
                "today.progress": "工作进度",
                "today.schedule": "今日安排",
                "onboarding.step.compensation": "工资与休息制度",
                "onboarding.step.schedule": "工作与午休时间",
                "onboarding.step.summary": "确认计算结果",
            }
        )
        self.prototype.write_text(
            """
            <button data-phone-nav="today">今日</button>
            <button data-phone-nav="calendar">日历</button>
            <button data-open-modal="settingsModal">设置</button>
            <span>今日已赚</span><span>本月累计</span><span>工作进度</span><span>今日安排</span>
            <section data-wizard-step="0">工资与休息制度</section>
            <section data-wizard-step="1">工作与午休时间</section>
            <section data-wizard-step="2">确认计算结果</section>
            <button id="wizardBack">上一步</button><button id="wizardNext">下一步</button>
            <button id="wizardCancel">取消</button>
            """,
            encoding="utf-8",
        )
        self.assertEqual(validate(self.root), [])

    def test_missing_catalog_key_and_interaction_fail(self):
        self.write_catalog({"nav.today": "今日"})
        self.prototype.write_text("<div>今日</div>", encoding="utf-8")

        failures = validate(self.root)

        self.assertIn("MISSING_CATALOG_KEY: nav.calendar", failures)
        self.assertIn("MISSING_PROTOTYPE_INTERACTION: data-phone-nav=calendar", failures)

    def test_copy_drift_fails(self):
        values = {
            "nav.today": "今日",
            "nav.calendar": "日历",
            "nav.settings": "设置",
            "today.amount": "今日已赚",
            "today.month_total": "本月累计",
            "today.progress": "工作进度",
            "today.schedule": "今日安排",
            "onboarding.step.compensation": "工资与休息制度",
            "onboarding.step.schedule": "工作与午休时间",
            "onboarding.step.summary": "确认计算结果",
        }
        self.write_catalog(values)
        self.prototype.write_text(
            " ".join(value for key, value in values.items() if key != "today.amount")
            + ' data-phone-nav="today" data-phone-nav="calendar" '
            + ' data-open-modal="settingsModal" data-wizard-step="0" '
            + ' data-wizard-step="1" data-wizard-step="2" '
            + ' id="wizardBack" id="wizardNext" id="wizardCancel"',
            encoding="utf-8",
        )

        self.assertIn("PROTOTYPE_COPY_DRIFT: today.amount", validate(self.root))


if __name__ == "__main__":
    unittest.main()
