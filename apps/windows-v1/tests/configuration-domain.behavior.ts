import {
  CURRENT_CONFIG_VERSION,
  addHours,
  defaultConfig,
  normalizeConfiguration,
  validateConfiguration,
} from "../src/domain/configuration";

function assert(condition: unknown, message: string): asserts condition {
  if (!condition) throw new Error(message);
}

assert(CURRENT_CONFIG_VERSION === 8, "the current configuration version remains v8");
assert(defaultConfig.config_version === CURRENT_CONFIG_VERSION, "defaults use the version constant");

const normalized = normalizeConfiguration({
  config_version: 3 as 8,
  theme_mode: "unexpected" as "light",
  monthly_salary: 15_000,
});
assert(normalized.config_version === 8, "legacy frontend values normalize to the current version");
assert(normalized.theme_mode === "light", "invalid themes fall back to light");
assert(normalized.monthly_salary === 15_000, "valid persisted values are preserved");
assert(normalized.work_hours_per_day === 8, "missing values inherit safe defaults");

const invalidSalary = validateConfiguration({ ...defaultConfig, monthly_salary: 0 });
assert(invalidSalary.monthly_salary === "请输入大于 0 的月薪", "salary validation remains stable");

const missingWeekType = validateConfiguration({
  ...defaultConfig,
  monthly_salary: 10_000,
  rest_mode: "alternating",
  alternating_anchor_week_type: null,
});
assert(
  missingWeekType.alternating_anchor_week_type === "请选择本周是大周还是小周",
  "alternating weeks require an explicit owner choice",
);

assert(addHours("23:30", 2) === "01:30", "time inference must wrap across midnight");
assert(addHours("08:00", 0.5) === "08:30", "time inference must preserve half hours");

console.log("configuration domain behavior: 10/10 passed");
