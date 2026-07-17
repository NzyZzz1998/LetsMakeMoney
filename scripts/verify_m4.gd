extends SceneTree

var _original_config_path: String = ""
var _original_config_data: Dictionary = {}
var _test_config_path: String = ""
var _config: Node = null


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	await process_frame
	_config = root.get_node_or_null("/root/Config")
	if _config == null:
		push_error("Config autoload not found")
		quit(1)
		return
	_original_config_path = String(_config.get("_config_path"))
	_original_config_data = (_config.get("data") as Dictionary).duplicate(true)
	_test_config_path = ProjectSettings.globalize_path("res://.verify_m4_config.json")
	DirAccess.make_dir_recursive_absolute(_test_config_path.get_base_dir())
	_config.set("_config_path", _test_config_path)
	_config.set("data", (_config.call("_defaults") as Dictionary).duplicate(true))

	var auto_wizard_ok: bool = await _verify_auto_wizard_from_main()
	var panel_layout_ok: bool = await _verify_panel_collapsed_layout()
	var settings_ok: bool = await _verify_settings_dialog()
	var wizard_ok: bool = await _verify_wizard_dialog()
	var ok := auto_wizard_ok and panel_layout_ok and settings_ok and wizard_ok
	_cleanup()
	if ok:
		print("M4 automated verification passed.")
		quit(0)
	else:
		quit(1)


func _verify_settings_dialog() -> bool:
	var scene := load("res://src/scenes/settings/settings_dialog.tscn")
	if scene == null:
		push_error("settings_dialog.tscn failed to load")
		return false
	var dlg = scene.instantiate()
	root.add_child(dlg)
	await process_frame

	dlg.salary_input.value = 23456
	dlg.rest_mode_option.select(1)
	dlg.start_hour_input.value = 10
	dlg.start_min_input.value = 15
	dlg.lunch_start_hour_input.value = 12
	dlg.lunch_start_min_input.value = 0
	dlg.lunch_end_hour_input.value = 13
	dlg.lunch_end_min_input.value = 0
	dlg.end_hour_input.value = 19
	dlg.end_min_input.value = 30
	dlg.scale_slider.value = 125
	dlg.opacity_slider.value = 80
	dlg.window_mode_option.select(1)
	dlg._update_slider_labels()
	await process_frame
	var scale_label_ok := _expect("settings scale label", dlg.scale_value_label.text, "125%")
	var opacity_label_ok := _expect("settings opacity label", dlg.opacity_value_label.text, "80%")
	dlg.show_today.button_pressed = false
	dlg.show_month.button_pressed = true
	dlg.show_rate.button_pressed = false
	dlg.show_progress.button_pressed = true
	dlg.show_state.button_pressed = false
	dlg._on_save()
	await process_frame

	return scale_label_ok and opacity_label_ok and \
		_expect("settings monthly_salary", _config.call("get_value", "monthly_salary"), 23456.0) and \
		_expect("settings rest_mode", _config.call("get_value", "rest_mode"), "single") and \
		_expect("settings work_hours_per_day", _config.call("get_value", "work_hours_per_day"), 8.25) and \
		_expect("settings work_start_time", _config.call("get_value", "work_start_time"), "10:15") and \
		_expect("settings lunch_start_time", _config.call("get_value", "lunch_start_time"), "12:00") and \
		_expect("settings lunch_end_time", _config.call("get_value", "lunch_end_time"), "13:00") and \
		_expect("settings work_end_time", _config.call("get_value", "work_end_time"), "19:30") and \
		_expect("settings scale", _config.call("get_value", "scale"), 1.25) and \
		_expect("settings opacity", _config.call("get_value", "opacity"), 0.8) and \
		_expect("settings window_mode", _config.call("get_value", "window_mode"), "embed") and \
		_expect("settings panel today", _config.call("get_panel_item", "earnings_today"), false) and \
		_expect("settings panel state", _config.call("get_panel_item", "status"), false)


func _verify_auto_wizard_from_main() -> bool:
	_config.set("data", (_config.call("_defaults") as Dictionary).duplicate(true))
	if FileAccess.file_exists(_test_config_path):
		DirAccess.remove_absolute(_test_config_path)
	var scene := load("res://src/scenes/main/main.tscn")
	if scene == null:
		push_error("main.tscn failed to load")
		return false
	var main = scene.instantiate()
	root.add_child(main)
	await process_frame
	await process_frame
	var wizard := root.find_child("WizardDialog", true, false)
	var ok: bool = wizard != null and bool(wizard.visible)
	if wizard != null:
		wizard.queue_free()
	main.queue_free()
	if not ok:
		push_error("WizardDialog did not appear when config file was missing")
	return ok


func _verify_panel_collapsed_layout() -> bool:
	var scene := load("res://src/scenes/panel/panel.tscn")
	if scene == null:
		push_error("panel.tscn failed to load")
		return false
	var panel = scene.instantiate()
	root.add_child(panel)
	await process_frame
	panel.collapse()
	await process_frame
	var coin_label: Label = panel.get_node("Collapsed/CollapsedContent/CoinMark")
	var label: Label = panel.get_node("Collapsed/CollapsedContent/CollapsedValue/EarningsToday")
	var status_label: Label = panel.get_node("Collapsed/CollapsedContent/CollapsedValue/ShortStatus")
	var content: Control = panel.get_node("Collapsed/CollapsedContent")
	var collapsed: Control = panel.get_node("Collapsed")
	var vertical_center_delta: float = abs((content.position.y + content.size.y * 0.5) - collapsed.size.y * 0.5)
	var ok := int(label.vertical_alignment) == 1 and \
		int(status_label.vertical_alignment) == 1 and \
		coin_label.text == "¥" and \
		collapsed.position == Vector2.ZERO and \
		collapsed.size.x >= 210.0 and \
		collapsed.size.y >= 62.0 and \
		vertical_center_delta <= 2.0 and \
		status_label.text.strip_edges() != ""
	panel.queue_free()
	if not ok:
		push_error("Collapsed panel amount and short status must stay centered inside the full collapsed panel")
	return ok


func _verify_wizard_dialog() -> bool:
	_config.set("data", (_config.call("_defaults") as Dictionary).duplicate(true))
	var scene := load("res://src/scenes/wizard/wizard_dialog.tscn")
	if scene == null:
		push_error("wizard_dialog.tscn failed to load")
		return false
	var dlg = scene.instantiate()
	root.add_child(dlg)
	await process_frame

	dlg.salary_input.value = 34567
	dlg.rest_mode_option.select(0)
	dlg.start_hour_input.value = 8
	dlg.start_min_input.value = 45
	dlg.lunch_start_hour_input.value = 12
	dlg.lunch_start_min_input.value = 0
	dlg.lunch_end_hour_input.value = 13
	dlg.lunch_end_min_input.value = 0
	dlg.end_hour_input.value = 17
	dlg.end_min_input.value = 15
	dlg._finish()
	await process_frame

	return _expect("wizard monthly_salary", _config.call("get_value", "monthly_salary"), 34567.0) and \
		_expect("wizard rest_mode", _config.call("get_value", "rest_mode"), "double") and \
		_expect("wizard work_hours_per_day", _config.call("get_value", "work_hours_per_day"), 7.5) and \
		_expect("wizard work_start_time", _config.call("get_value", "work_start_time"), "08:45") and \
		_expect("wizard lunch_start_time", _config.call("get_value", "lunch_start_time"), "12:00") and \
		_expect("wizard lunch_end_time", _config.call("get_value", "lunch_end_time"), "13:00") and \
		_expect("wizard work_end_time", _config.call("get_value", "work_end_time"), "17:15") and \
		bool(_config.call("has_config"))


func _expect(label: String, actual: Variant, expected: Variant) -> bool:
	if actual != expected:
		push_error("%s expected %s but got %s" % [label, expected, actual])
		return false
	return true


func _cleanup() -> void:
	if not _test_config_path.is_empty() and FileAccess.file_exists(_test_config_path):
		DirAccess.remove_absolute(_test_config_path)
	if _config != null:
		_config.set("_config_path", _original_config_path)
		_config.set("data", _original_config_data)
