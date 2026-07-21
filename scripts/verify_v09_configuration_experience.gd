extends SceneTree

var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var draft_script = load("res://src/utils/configuration_draft.gd")
	if draft_script == null:
		push_error("v0.9 configuration draft is missing")
		quit(1)
		return

	var draft = draft_script.new()
	_expect_equal(draft.monthly_salary, 0.0, "new draft salary")
	_expect_equal(draft.rest_mode, "double", "new draft rest mode")
	_expect_equal(draft.work_start_time, "08:00", "new draft work start")
	_expect_equal(draft.lunch_start_time, "12:00", "new draft lunch start")
	_expect_equal(draft.lunch_end_time, "14:00", "new draft lunch end")
	_expect_equal(draft.work_end_time, "18:00", "new draft inferred work end")
	_expect_equal(draft.work_duration_minutes, 480, "new draft work duration")
	_expect_equal(draft.lunch_duration_minutes, 120, "new draft lunch duration")
	_expect_true(not draft.can_reveal_schedule(), "schedule stays hidden before salary is valid")

	draft.set_salary(10000.0)
	_expect_true(draft.can_reveal_schedule(), "valid salary and rest mode reveal schedule")
	_expect_true(draft.can_reveal_lunch(), "work start reveals lunch controls")

	draft.set_lunch_duration_minutes(60)
	draft.set_work_start_time("09:00")
	_expect_equal(draft.lunch_start_time, "12:00", "default lunch start is stable")
	_expect_equal(draft.lunch_end_time, "13:00", "lunch end follows duration")
	_expect_equal(draft.work_end_time, "18:00", "work end includes lunch and eight work hours")

	draft.set_lunch_start_time("12:30")
	_expect_equal(draft.lunch_end_time, "13:30", "editing lunch start preserves duration")
	_expect_equal(draft.work_end_time, "18:00", "moving lunch within shift does not change total span")
	draft.set_lunch_end_time("14:00")
	_expect_equal(draft.lunch_start_time, "13:00", "editing lunch end preserves duration")

	var validation: Dictionary = draft.validate()
	_expect_true(bool(validation.get("valid", false)), "complete draft validates")
	var config: Dictionary = draft.to_config()
	_expect_equal(config.get("monthly_salary"), 10000.0, "draft maps salary")
	_expect_equal(config.get("work_hours_per_day"), 8.0, "draft maps effective work hours")
	_expect_equal(config.get("lunch_start_time"), "13:00", "draft maps linked lunch start")
	_expect_equal(config.get("lunch_end_time"), "14:00", "draft maps linked lunch end")

	var loaded = draft_script.new().load_config({
		"monthly_salary": 13500.0,
		"rest_mode": "alternating",
		"alternating_anchor_date": "2026-07-13",
		"alternating_anchor_week_type": "small",
		"work_start_time": "10:00",
		"lunch_start_time": "13:00",
		"lunch_end_time": "14:30",
		"work_end_time": "19:30"
	})
	_expect_equal(loaded.monthly_salary, 13500.0, "load salary")
	_expect_equal(loaded.rest_mode, "alternating", "load rest mode")
	_expect_equal(loaded.lunch_duration_minutes, 90, "load lunch duration")
	_expect_equal(loaded.work_duration_minutes, 480, "load effective work duration")
	_expect_equal(loaded.work_end_time, "19:30", "load work end")

	loaded.set_salary(0.0)
	validation = loaded.validate()
	_expect_true(not bool(validation.get("valid", true)), "zero salary is invalid")
	_expect_equal(validation.get("field"), "monthly_salary", "salary validation points to the field")

	_finish()


func _expect_true(value: bool, message: String) -> void:
	if not value:
		failures.append(message)


func _expect_equal(actual: Variant, expected: Variant, message: String) -> void:
	if actual != expected:
		failures.append("%s: expected=%s actual=%s" % [message, str(expected), str(actual)])


func _finish() -> void:
	if failures.is_empty():
		print("v0.9 configuration experience verification passed")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)
