extends SceneTree

var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var calculator_script = load("res://src/utils/salary_schedule_calculator.gd")
	if calculator_script == null:
		failures.append("salary schedule calculator must exist")
		_finish()
		return

	_test_effective_work_time(calculator_script)
	_test_zero_length_lunch(calculator_script)
	_test_invalid_lunch_schedule(calculator_script)
	_test_lunch_freezes_elapsed_time(calculator_script)
	_test_calendar_workday_count(calculator_script)
	_test_alternating_weekends(calculator_script)
	_test_salary_snapshot(calculator_script)
	_test_config_defaults_and_migration()
	_test_salary_engine_integration()
	_test_main_salary_refresh_scope()
	await _test_settings_and_wizard_controls()
	_finish()


func _test_effective_work_time(calculator_script: Script) -> void:
	var minutes: int = int(calculator_script.effective_work_minutes("08:00", "18:00", "12:00", "14:00"))
	_expect_equal(minutes, 480, "08:00-18:00 with a two-hour lunch must equal eight effective hours")


func _test_zero_length_lunch(calculator_script: Script) -> void:
	var minutes: int = int(calculator_script.effective_work_minutes("09:00", "17:00", "12:00", "12:00"))
	_expect_equal(minutes, 480, "an existing no-lunch schedule must remain valid after migration")


func _test_invalid_lunch_schedule(calculator_script: Script) -> void:
	var minutes: int = int(calculator_script.effective_work_minutes("08:00", "18:00", "14:00", "12:00"))
	_expect_equal(minutes, 0, "a reversed lunch range must invalidate the schedule instead of becoming a ten-hour workday")


func _test_lunch_freezes_elapsed_time(calculator_script: Script) -> void:
	var at_lunch: int = int(calculator_script.effective_elapsed_seconds(13 * 3600, "08:00", "18:00", "12:00", "14:00"))
	var after_lunch: int = int(calculator_script.effective_elapsed_seconds(15 * 3600, "08:00", "18:00", "12:00", "14:00"))
	_expect_equal(at_lunch, 4 * 3600, "earnings must stop increasing during lunch")
	_expect_equal(after_lunch, 5 * 3600, "post-lunch elapsed time must exclude the lunch duration")


func _test_calendar_workday_count(calculator_script: Script) -> void:
	var double_count: int = int(calculator_script.workday_count(2026, 2, "double", "2026-02-02", "big"))
	var single_count: int = int(calculator_script.workday_count(2026, 2, "single", "2026-02-02", "big"))
	_expect_equal(double_count, 20, "February 2026 must contain 20 Monday-Friday workdays")
	_expect_equal(single_count, 24, "single-weekend mode must include every Saturday")


func _test_alternating_weekends(calculator_script: Script) -> void:
	var big_saturday := {"year": 2026, "month": 7, "day": 11}
	var small_saturday := {"year": 2026, "month": 7, "day": 18}
	_expect_true(calculator_script.is_workday(big_saturday, "alternating", "2026-07-06", "big"), "anchor big-week Saturday must be a workday")
	_expect_true(not calculator_script.is_workday(small_saturday, "alternating", "2026-07-06", "big"), "the following small-week Saturday must be a rest day")
	_expect_true(not calculator_script.is_big_week({"year": 2026, "month": 7, "day": 13}, "2026-07-06", "big"), "the week after a big anchor must be reported as the current small week")
	_expect_equal(calculator_script.week_anchor_date({"year": 2026, "month": 7, "day": 16}), "2026-07-13", "alternating-week anchor must normalize to Monday")


func _test_salary_snapshot(calculator_script: Script) -> void:
	var snapshot: Dictionary = calculator_script.calculate_snapshot(
		10000.0,
		{"year": 2026, "month": 2, "day": 2, "hour": 18, "minute": 0, "second": 0},
		"double",
		"08:00",
		"18:00",
		"12:00",
		"14:00",
		"2026-02-02",
		"big"
	)
	_expect_close(float(snapshot.get("daily_salary", 0.0)), 500.0, 0.001, "daily salary must be monthly salary divided by actual workdays")
	_expect_close(float(snapshot.get("today_earnings", 0.0)), 500.0, 0.001, "a completed workday must earn one full daily salary")
	_expect_close(float(snapshot.get("month_earnings", 0.0)), 500.0, 0.001, "monthly earnings must accumulate completed workdays, not natural-day ratio")
	_expect_close(float(snapshot.get("hourly_rate", 0.0)), 62.5, 0.001, "hourly rate must use eight effective work hours")


func _test_config_defaults_and_migration() -> void:
	var config := root.get_node_or_null("/root/Config")
	if config == null:
		failures.append("Config autoload must exist")
		return
	var defaults: Dictionary = config.call("merge_with_defaults", {})
	_expect_equal(int(defaults.get("config_version", 0)), 4, "new configuration must use schema version 4")
	_expect_equal(defaults.get("work_start_time"), "08:00", "new configuration must default to 08:00")
	_expect_equal(defaults.get("work_end_time"), "18:00", "new configuration must default to 18:00")
	_expect_equal(defaults.get("lunch_start_time"), "12:00", "new configuration must default lunch to noon")
	_expect_equal(defaults.get("lunch_end_time"), "14:00", "new configuration must default to a two-hour lunch")

	var migrated: Dictionary = config.call("merge_with_defaults", {
		"config_version": 3,
		"work_start_time": "09:00",
		"work_end_time": "18:00",
		"work_hours_per_day": 8.0
	})
	_expect_equal(migrated.get("work_start_time"), "09:00", "migration must preserve an existing work start")
	_expect_equal(migrated.get("work_end_time"), "18:00", "migration must preserve an existing work end")
	_expect_equal(migrated.get("lunch_start_time"), "12:00", "migration must infer a noon lunch start")
	_expect_equal(migrated.get("lunch_end_time"), "13:00", "migration must infer lunch duration from the stored effective hours")
	_expect_equal(int(migrated.get("config_version", 0)), 4, "migration must advance the schema version")

	var migrated_without_lunch: Dictionary = config.call("merge_with_defaults", {
		"config_version": 3,
		"work_start_time": "09:00",
		"work_end_time": "17:00",
		"work_hours_per_day": 8.0
	})
	_expect_equal(migrated_without_lunch.get("lunch_start_time"), "12:00", "no-lunch migration must keep a stable noon boundary")
	_expect_equal(migrated_without_lunch.get("lunch_end_time"), "12:00", "no-lunch migration must preserve the full effective work span")


func _test_salary_engine_integration() -> void:
	var config := root.get_node_or_null("/root/Config")
	var engine := root.get_node_or_null("/root/SalaryEngine")
	if config == null or engine == null:
		failures.append("Config and SalaryEngine autoloads must exist")
		return
	var original: Dictionary = config.call("get_data_snapshot")
	config.call("restore_data_snapshot", config.call("merge_with_defaults", {
		"monthly_salary": 10000.0,
		"rest_mode": "double",
		"work_start_time": "08:00",
		"work_end_time": "18:00",
		"lunch_start_time": "12:00",
		"lunch_end_time": "14:00",
		"work_hours_per_day": 8.0
	}))
	engine.call("reload")
	_expect_close(float(engine.call("get_work_hours_per_day")), 8.0, 0.001, "SalaryEngine must expose effective work hours")
	var snapshot: Dictionary = engine.call("calculate_for_datetime", {"year": 2026, "month": 2, "day": 2, "hour": 13, "minute": 0, "second": 0})
	_expect_equal(snapshot.get("state"), "lunch", "SalaryEngine must expose lunch state")
	_expect_close(float(snapshot.get("today_earnings", 0.0)), 250.0, 0.001, "SalaryEngine earnings must freeze halfway through the workday during lunch")
	config.call("restore_data_snapshot", original)
	engine.call("reload")


func _test_main_salary_refresh_scope() -> void:
	var main_script := load("res://src/scenes/main/main.gd")
	if main_script == null:
		failures.append("Main script must load")
		return
	var main = main_script.new()
	var lunch_keys: Array[String] = ["lunch_start_time"]
	var alternating_keys: Array[String] = ["alternating_anchor_week_type"]
	_expect_true(main.call("_config_scope_requires_salary_refresh", lunch_keys), "lunch changes must refresh SalaryEngine and Panel")
	_expect_true(main.call("_config_scope_requires_salary_refresh", alternating_keys), "alternating-week changes must refresh SalaryEngine and Panel")
	main.free()


func _test_settings_and_wizard_controls() -> void:
	var settings_scene := load("res://src/scenes/settings/settings_dialog.tscn")
	var wizard_scene := load("res://src/scenes/wizard/wizard_dialog.tscn")
	if settings_scene == null or wizard_scene == null:
		failures.append("Settings and Wizard scenes must load")
		return
	var config := root.get_node_or_null("/root/Config")
	if config == null:
		failures.append("Config autoload must exist for Settings integration checks")
		return
	var original_config: Dictionary = config.call("get_data_snapshot")
	config.call("restore_data_snapshot", config.call("merge_with_defaults", {
		"rest_mode": "alternating",
		"alternating_anchor_date": "2000-01-03",
		"alternating_anchor_week_type": "big",
		"work_start_time": "08:00",
		"work_end_time": "18:00",
		"lunch_start_time": "12:00",
		"lunch_end_time": "14:00",
		"work_hours_per_day": 8.0
	}))
	var settings = settings_scene.instantiate()
	root.add_child(settings)
	await process_frame
	_expect_equal(settings.rest_mode_option.item_count, 3, "Settings rest mode must include alternating weekends")
	_expect_true(settings.get("lunch_start_hour_input") != null, "Settings must expose lunch start controls")
	_expect_true(settings.get("lunch_end_hour_input") != null, "Settings must expose lunch end controls")
	var unchanged_form: Dictionary = settings.call("_collect_form_values")
	_expect_true(not bool(settings.call("_has_form_changes", unchanged_form)), "an unchanged alternating schedule must preserve its historical anchor instead of creating a weekly save")
	settings.start_hour_input.value = 8
	settings.start_min_input.value = 0
	settings.end_hour_input.value = 18
	settings.end_min_input.value = 0
	settings.get("lunch_start_hour_input").value = 12
	settings.get("lunch_start_min_input").value = 0
	settings.get("lunch_end_hour_input").value = 14
	settings.get("lunch_end_min_input").value = 0
	settings.call("_update_hours_preview")
	_expect_close(float(settings.hours_input.value), 8.0, 0.001, "Settings hours preview must exclude lunch")
	settings.end_hour_input.value = 17
	settings.end_min_input.value = 10
	settings.call("_update_hours_preview")
	_expect_close(float(settings.hours_input.value), 7.17, 0.001, "Settings hours preview must show minute-based work time to two decimals instead of rounding to quarter-hours")
	settings.queue_free()
	await process_frame
	config.call("restore_data_snapshot", original_config)

	var wizard = wizard_scene.instantiate()
	root.add_child(wizard)
	await process_frame
	_expect_equal(wizard.rest_mode_option.item_count, 3, "Wizard rest mode must include alternating weekends")
	_expect_true(wizard.get("lunch_start_hour_input") != null, "Wizard must expose lunch start controls")
	_expect_true(wizard.get("lunch_end_hour_input") != null, "Wizard must expose lunch end controls")
	wizard.start_hour_input.value = 8
	wizard.start_min_input.value = 0
	wizard.end_hour_input.value = 17
	wizard.end_min_input.value = 10
	wizard.get("lunch_start_hour_input").value = 12
	wizard.get("lunch_start_min_input").value = 0
	wizard.get("lunch_end_hour_input").value = 14
	wizard.get("lunch_end_min_input").value = 0
	wizard.call("_update_hours_preview")
	_expect_close(float(wizard.hours_input.value), 7.17, 0.001, "Wizard hours preview must use the same minute precision as Settings")
	wizard.queue_free()
	await process_frame


func _finish() -> void:
	if failures.is_empty():
		print("v0.8 salary schedule verification passed")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)


func _expect_equal(actual: Variant, expected: Variant, message: String) -> void:
	if actual != expected:
		failures.append("%s (expected=%s actual=%s)" % [message, str(expected), str(actual)])


func _expect_close(actual: float, expected: float, tolerance: float, message: String) -> void:
	if abs(actual - expected) > tolerance:
		failures.append("%s (expected=%s actual=%s)" % [message, str(expected), str(actual)])


func _expect_true(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
