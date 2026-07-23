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
	_expect_equal(draft_script.LUNCH_DURATION_INPUT_STEP_HOURS, 0.01, "minute-level lunch values must remain visible in hour inputs")

	var today_script = load("res://src/scenes/today/today_detail_window.gd")
	var display_values: Dictionary = today_script.schedule_display_values({
		"work_start_time": "18:00",
		"lunch_start_time": "19:30",
		"lunch_end_time": "19:35",
		"work_end_time": "20:00",
	})
	_expect_equal(display_values.work_start, "18:00", "today timeline uses configured work start")
	_expect_equal(display_values.lunch_start, "19:30", "today timeline uses configured lunch start")
	_expect_equal(display_values.lunch_range, "19:30-19:35", "today timeline preserves a minute-level lunch range")
	_expect_equal(display_values.work_end, "20:00", "today timeline uses configured work end")

	loaded.set_salary(0.0)
	validation = loaded.validate()
	_expect_true(not bool(validation.get("valid", true)), "zero salary is invalid")
	_expect_equal(validation.get("field"), "monthly_salary", "salary validation points to the field")

	await _test_settings_failure_feedback_persistence()
	_finish()


func _test_settings_failure_feedback_persistence() -> void:
	var settings_scene := load("res://src/scenes/settings/settings_dialog.tscn") as PackedScene
	_expect_true(settings_scene != null, "Settings scene loads for failure feedback verification")
	if settings_scene == null:
		return
	var settings := settings_scene.instantiate()
	root.add_child(settings)
	await process_frame
	settings.call("_set_save_status", "保存失败：测试反馈必须保持可见。")
	await create_timer(3.0).timeout
	var feedback := settings.find_child("SaveFeedbackPanel", true, false) as Control
	var label := settings.find_child("SaveStatusLabel", true, false) as Label
	_expect_true(feedback != null and feedback.visible, "save failure feedback remains visible after the normal auto-hide interval")
	_expect_true(label != null and label.text.contains("保存失败"), "save failure feedback is not replaced by a no-change message")
	settings.queue_free()
	await process_frame


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
