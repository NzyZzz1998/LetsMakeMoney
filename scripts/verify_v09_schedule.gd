extends SceneTree

var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var calendar_script = load("res://src/utils/holiday_calendar.gd")
	var resolver_script = load("res://src/utils/work_schedule_resolver.gd")
	if calendar_script == null or resolver_script == null:
		push_error("v0.9 schedule services are missing")
		quit(1)
		return

	var calendar = calendar_script.new("res://assets/calendar/cn")
	_expect_true(calendar.has_year(2026), "2026 official calendar must load")
	_expect_equal(calendar.classify({"year": 2026, "month": 1, "day": 4}).get("type"), "adjusted_workday", "January 4 must override Sunday as a workday")
	_expect_equal(calendar.classify({"year": 2026, "month": 2, "day": 16}).get("type"), "official_holiday", "Spring Festival weekday must be a holiday")
	_expect_true(not bool(calendar.classify({"year": 2027, "month": 1, "day": 1}).get("covered", true)), "missing years must report uncovered instead of pretending official accuracy")

	var resolver = resolver_script.new(calendar)
	_test_shared_salary_vectors(resolver)
	var base := {
		"monthly_salary": 10000.0,
		"rest_mode": "double",
		"work_start_time": "08:00",
		"work_end_time": "18:00",
		"lunch_start_time": "12:00",
		"lunch_end_time": "14:00",
		"alternating_anchor_date": "2026-01-05",
		"alternating_anchor_week_type": "big"
	}

	var february: Dictionary = resolver.calculate_snapshot(base, {"year": 2026, "month": 2, "day": 28, "hour": 18, "minute": 0, "second": 0})
	_expect_equal(int(february.get("workdays", 0)), 16, "February 2026 must apply official holidays and adjusted Saturdays")
	_expect_close(float(february.get("daily_salary", 0.0)), 625.0, 0.001, "daily salary must use the resolved official workday count")

	var lunch: Dictionary = resolver.resolve_state(base, {"year": 2026, "month": 1, "day": 5, "hour": 13, "minute": 0, "second": 0})
	_expect_equal(lunch.get("state"), "awake_rest", "lunch must resolve to awake_rest")
	_expect_equal(lunch.get("reason"), "lunch", "lunch must retain a specific reason")

	var sleeping: Dictionary = resolver.resolve_state(base, {"year": 2026, "month": 1, "day": 5, "hour": 23, "minute": 0, "second": 0})
	_expect_equal(sleeping.get("state"), "sleeping", "23:00 outside work must enter sleeping")
	var morning_boundary: Dictionary = resolver.resolve_state(base, {"year": 2026, "month": 1, "day": 6, "hour": 7, "minute": 30, "second": 0})
	_expect_equal(morning_boundary.get("state"), "awake_rest", "07:30 must leave sleeping")

	var night := base.duplicate(true)
	night["work_start_time"] = "22:00"
	night["work_end_time"] = "06:00"
	night["lunch_start_time"] = "02:00"
	night["lunch_end_time"] = "02:30"
	var night_work: Dictionary = resolver.resolve_state(night, {"year": 2026, "month": 1, "day": 6, "hour": 23, "minute": 30, "second": 0})
	_expect_equal(night_work.get("state"), "working", "night work must override sleeping")
	var night_lunch: Dictionary = resolver.resolve_state(night, {"year": 2026, "month": 1, "day": 7, "hour": 2, "minute": 15, "second": 0})
	_expect_equal(night_lunch.get("state"), "awake_rest", "overnight lunch must pause work")
	_expect_equal(night_lunch.get("reason"), "lunch", "overnight lunch reason must be preserved")
	var adjusted_overnight: Dictionary = resolver.resolve_state(night, {"year": 2026, "month": 1, "day": 5, "hour": 2, "minute": 30, "second": 0})
	_expect_equal(adjusted_overnight.get("state"), "working", "an adjusted Sunday night shift must remain owned by its workday across midnight")

	var forward: Dictionary = resolver.calculate_snapshot(base, {"year": 2026, "month": 1, "day": 5, "hour": 10, "minute": 0, "second": 0})
	var backward: Dictionary = resolver.calculate_snapshot(base, {"year": 2026, "month": 1, "day": 5, "hour": 9, "minute": 0, "second": 0})
	_expect_equal(int(forward.get("elapsed_effective_seconds", 0)), 7200, "forward wall-clock snapshot must calculate from the schedule")
	_expect_equal(int(backward.get("elapsed_effective_seconds", 0)), 3600, "backward system-time jumps must recalculate instead of accumulating stale elapsed time")

	var unset := base.duplicate(true)
	unset["monthly_salary"] = 0.0
	_expect_equal(resolver.resolve_state(unset, {"year": 2026, "month": 1, "day": 5, "hour": 9}).get("state"), "setup_required", "zero salary must require setup")

	_test_config_v5()
	_test_calendar_corruption(calendar_script)
	_test_salary_engine_v09()
	_finish()


func _test_config_v5() -> void:
	var config := root.get_node_or_null("/root/Config")
	if config == null:
		failures.append("Config autoload must exist")
		return
	var migrated: Dictionary = config.merge_with_defaults({
		"config_version": 4,
		"monthly_salary": 10000,
		"work_start_time": "08:00",
		"work_end_time": "18:00",
		"lunch_start_time": "12:00",
		"lunch_end_time": "14:00"
	})
	_expect_equal(int(migrated.get("config_version", 0)), 5, "v4 configuration must migrate to v5")
	_expect_equal(migrated.get("calendar_dataset_version"), "cn-2026-gov-20251104", "v5 must record the bundled calendar dataset")
	_expect_true(migrated.has("pet_package_id"), "v5 must reserve the pet package identity")
	_expect_true(migrated.has("today_window_position"), "v5 must reserve Today window position")


func _test_shared_salary_vectors(resolver: RefCounted) -> void:
	var path := "res://shared/salary-schema/v1/vectors/salary-vectors.json"
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		failures.append("shared Windows/iOS salary vectors must exist")
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if not parsed is Dictionary:
		failures.append("shared salary vectors must be valid JSON")
		return
	var configs: Dictionary = {}
	for raw_case in parsed.get("cases", []):
		var vector: Dictionary = raw_case
		var vector_id := String(vector.get("id", ""))
		var source_config: Dictionary = vector.get("config", configs.get(String(vector.get("configRef", "")), {}))
		if source_config.is_empty():
			failures.append("shared vector %s has no resolvable config" % vector_id)
			continue
		if vector.has("config"):
			configs[vector_id] = source_config.duplicate(true)
		var config := _shared_config_to_windows(source_config)
		var now := _parse_iso_datetime(String(vector.get("now", "")))
		var actual: Dictionary = resolver.calculate_snapshot(config, now)
		var expected: Dictionary = vector.get("expected", {})
		_expect_equal(int(actual.get("workdays", 0)), int(expected.get("monthPaidWorkdays", 0)), "%s workday count" % vector_id)
		_expect_close(float(actual.get("daily_salary", 0.0)), float(expected.get("dailySalaryMinor", 0)) / 100.0, 0.01, "%s daily salary" % vector_id)
		_expect_close(float(actual.get("hourly_rate", 0.0)), float(expected.get("standardHourlySalaryMinor", 0)) / 100.0, 0.01, "%s hourly salary" % vector_id)
		_expect_close(float(actual.get("today_earnings", 0.0)), float(expected.get("todayEarnedMinor", 0)) / 100.0, 0.01, "%s today earnings" % vector_id)
		_expect_close(float(actual.get("month_earnings", 0.0)), float(expected.get("monthEarnedMinor", 0)) / 100.0, 0.01, "%s month earnings" % vector_id)
		_expect_equal(int(actual.get("elapsed_effective_seconds", 0)), int(expected.get("completedEffectiveSeconds", 0)), "%s elapsed seconds" % vector_id)
		_expect_equal(roundi(float(actual.get("progress", 0.0)) * 10000.0), int(expected.get("progressBasisPoints", 0)), "%s progress" % vector_id)
		var expected_state := String(expected.get("status", ""))
		if expected_state in ["lunchBreak", "finished"]:
			expected_state = "awake_rest"
		_expect_equal(actual.get("state"), expected_state, "%s state" % vector_id)


func _shared_config_to_windows(source: Dictionary) -> Dictionary:
	var rest_mode_map := {
		"doubleWeekend": "double",
		"singleWeekend": "single",
		"alternatingWeekend": "alternating"
	}
	var overrides: Array = []
	for raw_override in source.get("dateOverrides", []):
		var item: Dictionary = raw_override
		overrides.append({
			"date": String(item.get("date", "")),
			"is_workday": bool(item.get("isWorkday", false)),
			"is_paid": bool(item.get("isPaid", false))
		})
	return {
		"monthly_salary": float(source.get("monthlySalaryMinor", 0)) / 100.0,
		"rest_mode": String(rest_mode_map.get(String(source.get("restMode", "doubleWeekend")), "double")),
		"work_start_time": String(source.get("workStart", "08:00")),
		"work_end_time": String(source.get("workEnd", "18:00")),
		"lunch_start_time": String(source.get("lunchStart", "12:00")),
		"lunch_end_time": String(source.get("lunchEnd", "14:00")),
		"alternating_anchor_date": String(source.get("alternatingAnchor", "")),
		"alternating_anchor_week_type": "small",
		"date_overrides": overrides
	}


func _parse_iso_datetime(value: String) -> Dictionary:
	var halves := value.split("T")
	if halves.size() != 2:
		return {}
	var date_parts := String(halves[0]).split("-")
	var time_parts := String(halves[1]).split(":")
	if date_parts.size() != 3 or time_parts.size() != 3:
		return {}
	return {
		"year": int(date_parts[0]),
		"month": int(date_parts[1]),
		"day": int(date_parts[2]),
		"hour": int(time_parts[0]),
		"minute": int(time_parts[1]),
		"second": int(time_parts[2])
	}


func _test_salary_engine_v09() -> void:
	var config := root.get_node_or_null("/root/Config")
	var engine := root.get_node_or_null("/root/SalaryEngine")
	if config == null or engine == null:
		failures.append("Config and SalaryEngine autoloads must exist")
		return
	var original: Dictionary = config.get_data_snapshot()
	config.restore_data_snapshot(config.merge_with_defaults({
		"monthly_salary": 10000.0,
		"rest_mode": "double",
		"work_start_time": "08:00",
		"work_end_time": "18:00",
		"lunch_start_time": "12:00",
		"lunch_end_time": "14:00"
	}))
	engine.reload()
	var holiday: Dictionary = engine.calculate_for_datetime({"year": 2026, "month": 2, "day": 16, "hour": 10, "minute": 0, "second": 0})
	_expect_equal(int(holiday.get("workdays", 0)), 16, "SalaryEngine must consume the official calendar")
	_expect_equal(holiday.get("state"), "awake_rest", "SalaryEngine must expose the v0.9 state model")
	_expect_equal(holiday.get("state_reason"), "rest_day", "SalaryEngine must preserve the state reason")
	config.restore_data_snapshot(original)
	engine.reload()


func _test_calendar_corruption(calendar_script: Script) -> void:
	var root_path := ProjectSettings.globalize_path("user://v09-invalid-calendar")
	DirAccess.make_dir_recursive_absolute(root_path)
	var path := root_path.path_join("2026.json")
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		failures.append("corrupt calendar fixture must be writable")
		return
	file.store_string("{not-json")
	file.close()
	var invalid_calendar = calendar_script.new(root_path)
	_expect_true(not invalid_calendar.has_year(2026), "corrupt calendar data must be rejected")
	_expect_true(not bool(invalid_calendar.classify({"year": 2026, "month": 1, "day": 1}).get("covered", true)), "corrupt calendar data must fall back as uncovered")
	DirAccess.remove_absolute(path)
	DirAccess.remove_absolute(root_path)


func _finish() -> void:
	if failures.is_empty():
		print("v0.9 schedule verification passed")
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
