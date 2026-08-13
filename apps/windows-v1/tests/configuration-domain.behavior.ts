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

assert(CURRENT_CONFIG_VERSION === 9, "the current configuration version is v9");
assert(defaultConfig.config_version === CURRENT_CONFIG_VERSION, "defaults use the version constant");

const normalized = normalizeConfiguration({
  config_version: 3 as 9,
  theme_mode: "unexpected" as "light",
  monthly_salary: 15_000,
});
assert(normalized.config_version === 9, "legacy frontend values normalize to the current version");
assert(normalized.theme_mode === "light", "invalid themes fall back to light");
assert(normalized.monthly_salary === 15_000, "valid persisted values are preserved");
assert(normalized.work_hours_per_day === 8, "missing values inherit safe defaults");
assert(normalized.mini_edge_auto_hide === true, "legacy configs enable privacy auto-hide safely");
assert(normalized.mini_edge_dock === "none", "legacy configs begin without an implicit dock side");

const invalidDock = normalizeConfiguration({
  mini_edge_auto_hide: true,
  mini_edge_dock: "top" as "left",
});
assert(invalidDock.mini_edge_auto_hide === true, "an explicit auto-hide preference is preserved");
assert(invalidDock.mini_edge_dock === "none", "unknown dock sides fall back to none");

const disabledDock = normalizeConfiguration({
  mini_edge_auto_hide: false,
  mini_edge_dock: "left",
});
assert(!disabledDock.mini_edge_auto_hide, "users can disable edge privacy");
assert(disabledDock.mini_edge_dock === "none", "disabling edge privacy clears a persisted side");

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

console.log("configuration domain behavior: 16/16 passed");
