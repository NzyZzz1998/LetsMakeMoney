extends SceneTree

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	await process_frame
	_check_warm_control_helper_contract()
	_check_settings_shared_control_usage()
	_check_wizard_shared_control_usage()
	_check_settings_save_logging_contract()
	_check_wizard_semantic_logging_contract()
	_check_window_policy_logging_contract()
	_check_config_field_compatibility()

	if _failures.is_empty():
		print("v0.5 verification passed")
		quit(0)
	else:
		for failure in _failures:
			push_error(failure)
		quit(1)


func _assert(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _check_warm_control_helper_contract() -> void:
	var helper_path := "res://src/ui/warm_control_theme.gd"
	_assert(FileAccess.file_exists(helper_path), "missing shared warm control helper: %s" % helper_path)
	if not FileAccess.file_exists(helper_path):
		return

	var source := FileAccess.get_file_as_string(helper_path)
	for required_text in [
		"class_name WarmControlTheme",
		"SURFACE_APP",
		"SURFACE_PAPER",
		"SURFACE_CARD",
		"SURFACE_SELECTED",
		"TEXT_INK",
		"TEXT_MUTED",
		"ACCENT_COIN",
		"ACCENT_ORANGE",
		"ACCENT_MINT",
		"DANGER_SOFT",
		"BORDER_WARM",
		"SHADOW_WARM",
		"ROW_HEIGHT",
		"INPUT_HEIGHT",
		"BUTTON_HEIGHT",
		"TAB_HEIGHT",
		"SWITCH_SIZE",
		"SLIDER_TRACK_HEIGHT",
		"SCROLLBAR_WIDTH",
		"func stylebox",
		"func style_button",
		"func style_line_edit",
		"func style_spin_box",
		"func style_option_button",
		"func style_option_popup",
		"func style_switch",
		"func style_slider",
		"func style_scrollbar",
		"func style_compact_row",
		"func style_section_divider",
		"func style_inline_status"
	]:
		_assert(source.contains(required_text), "warm control helper missing contract text: %s" % required_text)

	var script: Resource = load(helper_path)
	_assert(script != null, "warm control helper should load as a script")
	if script == null:
		return

	var helper: Object = script.new()
	_assert(helper != null, "warm control helper should be instantiable")
	if helper == null:
		return

	_assert(helper.has_method("stylebox"), "helper should expose stylebox")
	_assert(helper.has_method("style_button"), "helper should expose style_button")
	_assert(helper.has_method("style_line_edit"), "helper should expose style_line_edit")
	_assert(helper.has_method("style_spin_box"), "helper should expose style_spin_box")
	_assert(helper.has_method("style_option_button"), "helper should expose style_option_button")
	_assert(helper.has_method("style_option_popup"), "helper should expose style_option_popup")
	_assert(helper.has_method("style_switch"), "helper should expose style_switch")
	_assert(helper.has_method("style_slider"), "helper should expose style_slider")
	_assert(helper.has_method("style_scrollbar"), "helper should expose style_scrollbar")
	_assert(helper.has_method("style_compact_row"), "helper should expose style_compact_row")
	_assert(helper.has_method("style_section_divider"), "helper should expose style_section_divider")
	_assert(helper.has_method("style_inline_status"), "helper should expose style_inline_status")


func _check_settings_shared_control_usage() -> void:
	var settings_path := "res://src/scenes/settings/settings_dialog.gd"
	_assert(FileAccess.file_exists(settings_path), "missing Settings script: %s" % settings_path)
	if not FileAccess.file_exists(settings_path):
		return

	var source := FileAccess.get_file_as_string(settings_path)
	for required_text in [
		"preload(\"res://src/ui/warm_control_theme.gd\")",
		"_warm_theme.stylebox",
		"_warm_theme.style_button",
		"_warm_theme.style_line_edit",
		"_warm_theme.style_spin_box",
		"_warm_theme.style_option_button",
		"_warm_theme.style_option_popup",
		"_warm_theme.style_switch",
		"_warm_theme.style_slider"
	]:
		_assert(source.contains(required_text), "Settings should use shared warm control helper: %s" % required_text)


func _check_wizard_shared_control_usage() -> void:
	var wizard_path := "res://src/scenes/wizard/wizard_dialog.gd"
	_assert(FileAccess.file_exists(wizard_path), "missing Wizard script: %s" % wizard_path)
	if not FileAccess.file_exists(wizard_path):
		return

	var source := FileAccess.get_file_as_string(wizard_path)
	for required_text in [
		"preload(\"res://src/ui/warm_control_theme.gd\")",
		"_warm_theme.stylebox",
		"_warm_theme.style_button",
		"_warm_theme.style_option_button",
		"_warm_theme.style_option_popup",
		"_warm_theme.style_spin_box"
	]:
		_assert(source.contains(required_text), "Wizard should use shared warm control helper: %s" % required_text)

	for required_text in [
		"salary_input",
		"rest_mode_option",
		"pet_list",
		"_on_next",
		"_on_prev",
		"_finish"
	]:
		_assert(source.contains(required_text), "Wizard should keep existing flow/control contract: %s" % required_text)


func _check_settings_save_logging_contract() -> void:
	var config_path := "res://src/autoload/config.gd"
	var settings_path := "res://src/scenes/settings/settings_dialog.gd"
	_assert(FileAccess.file_exists(config_path), "missing Config script: %s" % config_path)
	_assert(FileAccess.file_exists(settings_path), "missing Settings script: %s" % settings_path)
	if not FileAccess.file_exists(config_path) or not FileAccess.file_exists(settings_path):
		return

	var config_source := FileAccess.get_file_as_string(config_path)
	for required_text in [
		"func save() -> bool",
		"config_save_success",
		"config_save_failed",
		"get_last_save_error",
		"get_data_snapshot",
		"restore_data_snapshot",
		"verify_mismatch"
	]:
		_assert(config_source.contains(required_text), "Config should expose reliable save result contract: %s" % required_text)

	var settings_source := FileAccess.get_file_as_string(settings_path)
	for required_text in [
		"settings_save_success",
		"settings_save_no_change",
		"settings_save_failed",
		"Config.get_data_snapshot()",
		"Config.restore_data_snapshot(previous_config)",
		"Config.get_last_save_error()"
	]:
		_assert(settings_source.contains(required_text), "Settings should expose stable v0.5 save log event: %s" % required_text)


func _check_wizard_semantic_logging_contract() -> void:
	var wizard_path := "res://src/scenes/wizard/wizard_dialog.gd"
	_assert(FileAccess.file_exists(wizard_path), "missing Wizard script: %s" % wizard_path)
	if not FileAccess.file_exists(wizard_path):
		return

	var source := FileAccess.get_file_as_string(wizard_path)
	for required_text in [
		"wizard_opened",
		"wizard_step_changed",
		"wizard_finished",
		"wizard_finish_failed",
		"wizard_cancelled",
		"wizard_closed",
		"Config.get_data_snapshot()",
		"Config.restore_data_snapshot(previous_config)",
		"Config.get_last_save_error()"
	]:
		_assert(source.contains(required_text), "Wizard should expose stable v0.5 semantic log event: %s" % required_text)


func _check_window_policy_logging_contract() -> void:
	var main_path := "res://src/scenes/main/main.gd"
	_assert(FileAccess.file_exists(main_path), "missing Main script: %s" % main_path)
	if not FileAccess.file_exists(main_path):
		return

	var source := FileAccess.get_file_as_string(main_path)
	for required_text in [
		"_reapply_tray_restore_window_policy",
		"window_policy_reapplied",
		"passthrough_suspended",
		"passthrough_resumed",
		"pure_pet_mode_apply",
		"pure_pet_mode_fallback",
		"tray_toggle_requested",
		"tray_left_toggle_requested",
		"tray_left_toggle_result"
	]:
		_assert(source.contains(required_text), "Main should expose stable v0.5 window policy log event: %s" % required_text)

	for required_text in [
		"_invalidate_taskbar_visibility_cache",
		"_apply_pure_pet_mode()",
		"_request_mouse_passthrough_refresh(\"tray_restore\")",
		"_request_mouse_passthrough_refresh(\"tray_restore_post_frame\")",
		"Platform.set_mouse_passthrough(get_window(), false, [])"
	]:
		_assert(source.contains(required_text), "Main should keep restore/passthrough policy behavior: %s" % required_text)
	_assert(source.contains("_on_tray_left_toggle_requested"), "Main should handle native tray icon left-clicks")
	_assert(source.contains("if visible_after:\n\t\t_reapply_tray_restore_window_policy()"), "Tray left-click restore should reapply pure-pet/window policy after showing")

	var platform_path := "res://src/autoload/platform.gd"
	_assert(FileAccess.file_exists(platform_path), "missing Platform script: %s" % platform_path)
	if FileAccess.file_exists(platform_path):
		var platform_source := FileAccess.get_file_as_string(platform_path)
		_assert(platform_source.contains("signal tray_left_toggle_requested"), "Platform should expose a distinct tray left-click signal")
		_assert(platform_source.contains("tray_left_toggle_requested.emit()"), "Platform should emit the tray left-click signal for native command 5")

	var windows_platform_path := "res://src/platform/windows_platform.gd"
	_assert(FileAccess.file_exists(windows_platform_path), "missing WindowsPlatform script: %s" % windows_platform_path)
	if FileAccess.file_exists(windows_platform_path):
		var windows_platform_source := FileAccess.get_file_as_string(windows_platform_path)
		_assert(windows_platform_source.contains("_invalidate_taskbar_visibility_cache(window, \"set_window_visible_show\")"), "WindowsPlatform should invalidate taskbar cache after native show")
		_assert(windows_platform_source.contains("_invalidate_taskbar_visibility_cache(window, \"setup_window\")"), "WindowsPlatform should invalidate taskbar cache after window setup")
		_assert(windows_platform_source.contains("WindowsPlatform.set_taskbar_visible: hwnd=%s visible=%s"), "WindowsPlatform should log native taskbar visibility calls")

	var tray_header_path := "res://native/windows/src/tray_controller.h"
	var tray_cpp_path := "res://native/windows/src/tray_controller.cpp"
	if FileAccess.file_exists(tray_header_path) and FileAccess.file_exists(tray_cpp_path):
		var tray_header := FileAccess.get_file_as_string(tray_header_path)
		var tray_cpp := FileAccess.get_file_as_string(tray_cpp_path)
		_assert(tray_header.contains("COMMAND_LEFT_TOGGLE = 5"), "Native tray should distinguish icon left-click from menu toggle")
		_assert(tray_cpp.contains("set_left_toggle_command"), "Native tray should route icon left-clicks through the left-toggle command")


func _check_config_field_compatibility() -> void:
	var config_path := "res://src/autoload/config.gd"
	_assert(FileAccess.file_exists(config_path), "missing Config script: %s" % config_path)
	if not FileAccess.file_exists(config_path):
		return

	var source := FileAccess.get_file_as_string(config_path)
	for required_text in [
		"monthly_salary",
		"rest_mode",
		"work_start_time",
		"work_end_time",
		"opacity",
		"scale",
		"window_mode",
		"pure_pet_mode",
		"mouse_passthrough_enabled",
		"minimize_to_tray",
		"system_tray_enabled",
		"auto_start",
		"panel_items",
		"debug_mode"
	]:
		_assert(source.contains(required_text), "Config should keep v0.5-compatible field: %s" % required_text)

	_assert(
		source.contains("pet_id") or source.contains("current_pet_id"),
		"Config should keep a v0.5-compatible pet selection field"
	)

	for forbidden_text in [
		"theme_id",
		"installer",
		"auto_update",
		"comfyui_enabled"
	]:
		_assert(not source.contains(forbidden_text), "Config should not add out-of-scope v0.5 field: %s" % forbidden_text)
