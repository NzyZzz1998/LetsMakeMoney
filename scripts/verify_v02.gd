extends SceneTree

var _failures: Array[String] = []
var _config: Node = null
var _platform: Node = null


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	await process_frame
	_config = root.get_node_or_null("/root/Config")
	_platform = root.get_node_or_null("/root/Platform")
	if _config == null or _platform == null:
		push_error("Config or Platform autoload not found")
		quit(1)
		return

	_check_config_defaults()
	_check_platform_api()
	_check_main_scene()
	_check_settings_dialog()
	_check_pet_drag_model()
	_check_context_menu_model()
	_check_auto_start_model()
	_check_settings_save_model()

	if _failures.is_empty():
		print("v0.2 verification passed")
		quit(0)
	else:
		for failure in _failures:
			push_error(failure)
		quit(1)


func _check_config_defaults() -> void:
	_assert(_config.call("get_value", "debug_mode", null) == false, "debug_mode default should be false")
	_assert(_config.call("get_value", "auto_start", null) == false, "auto_start default should be false")
	_assert(_config.call("get_value", "minimize_to_tray", null) == true, "minimize_to_tray default should be true")
	_assert(_config.call("get_value", "system_tray_enabled", null) == false, "system_tray_enabled default should be false while Godot StatusIndicator is unstable")
	_assert(_config.call("get_value", "mouse_passthrough_enabled", null) == false, "mouse_passthrough_enabled default should be false while exported transparent window is being stabilized")
	_assert(_config.call("get_value", "transparent_pet_window_enabled", null) == false, "transparent_pet_window_enabled default should be false while exported transparent window is being stabilized")

	var old_config := {
		"monthly_salary": 12000,
		"panel_items": {
			"earnings_today": false
		}
	}
	_assert(_config.has_method("merge_with_defaults"), "Config.merge_with_defaults missing")
	if not _config.has_method("merge_with_defaults"):
		return
	var merged: Dictionary = _config.call("merge_with_defaults", old_config)
	_assert(merged.get("debug_mode") == false, "old config should merge debug_mode=false")
	_assert(merged.get("auto_start") == false, "old config should merge auto_start=false")
	_assert(merged.get("minimize_to_tray") == true, "old config should merge minimize_to_tray=true")
	_assert(merged.get("system_tray_enabled") == false, "old config should merge system_tray_enabled=false")
	_assert(merged.get("mouse_passthrough_enabled") == false, "old config should merge mouse_passthrough_enabled=false")
	_assert(merged.get("transparent_pet_window_enabled") == false, "old config should merge transparent_pet_window_enabled=false")
	_assert(merged.get("monthly_salary") == 12000, "old config values should be preserved")
	_assert(merged.get("panel_items", {}).get("earnings_today") == false, "nested old config values should be preserved")
	_assert(merged.get("panel_items", {}).has("earnings_month"), "nested defaults should be filled")


func _check_platform_api() -> void:
	for method_name in [
		"setup_window",
		"set_mouse_passthrough",
		"is_tray_supported",
		"setup_tray",
		"update_tray_menu",
		"shutdown_tray",
		"get_executable_path",
		"is_auto_start_supported",
		"is_auto_start_enabled",
		"set_auto_start"
	]:
		_assert(_platform.has_method(method_name), "Platform.%s missing" % method_name)

	for signal_name in [
		"tray_toggle_requested",
		"tray_settings_requested",
		"tray_about_requested",
		"tray_exit_requested"
	]:
		_assert(_platform.has_signal(signal_name), "Platform signal %s missing" % signal_name)

	_assert(ClassDB.class_exists("StatusIndicator"), "Godot StatusIndicator class missing")
	_assert(ClassDB.class_exists("NativeMenu"), "Godot NativeMenu class missing")


func _check_main_scene() -> void:
	var scene := load("res://src/scenes/main/main.tscn")
	_assert(scene != null, "main.tscn should load")
	if scene == null:
		return
	var root: Node = scene.instantiate()
	_assert(root.has_node("Pet"), "main scene missing Pet")
	_assert(root.has_node("Panel"), "main scene missing Panel")
	_assert(root.has_node("DebugInputArea"), "main scene missing DebugInputArea")
	_assert(root.has_node("DebugStatus"), "main scene missing DebugStatus")
	_assert(root.has_method("apply_runtime_mode"), "main.gd should expose apply_runtime_mode()")
	_assert(root.has_method("get_pet_window_size"), "main.gd should expose get_pet_window_size()")
	_assert(root.has_method("get_debug_window_size"), "main.gd should expose get_debug_window_size()")
	_assert(root.has_method("_reapply_runtime_mode_after_popups"), "main.gd should defer runtime mode reapply after settings popups close")
	if root.has_method("get_pet_window_size"):
		_assert(root.call("get_pet_window_size") == Vector2i(620, 380), "pet window should fit orange cat v1 and expanded panel")
	if root.has_method("get_debug_window_size"):
		_assert(root.call("get_debug_window_size") == Vector2i(900, 500), "debug window should remain 900x500")
	root.queue_free()


func _check_settings_dialog() -> void:
	var scene := load("res://src/scenes/settings/settings_dialog.tscn")
	_assert(scene != null, "settings_dialog.tscn should load")
	if scene == null:
		return
	var dlg: Node = scene.instantiate()
	_assert(dlg.has_method("get_v02_control_names"), "SettingsDialog.get_v02_control_names() missing")
	if dlg.has_method("get_v02_control_names"):
		var controls: Array = dlg.get_v02_control_names()
		for control_name in [
			"debug_mode_toggle",
			"auto_start_toggle",
			"minimize_to_tray_toggle",
			"reset_position_button",
			"restore_defaults_button"
		]:
			_assert(controls.has(control_name), "SettingsDialog missing %s" % control_name)
	dlg.queue_free()


func _check_pet_drag_model() -> void:
	var script := FileAccess.get_file_as_string("res://src/scenes/pet/pet.gd")
	_assert(script.contains("_drag_start_window_pos"), "pet drag should remember start window position")
	_assert(script.contains("DisplayServer.mouse_get_position() - _drag_start_screen_mouse"), "pet drag should use absolute screen mouse delta")
	_assert(script.contains("LONG_PRESS_THRESHOLD := 0.35"), "long press feedback should be quick enough to notice")


func _check_context_menu_model() -> void:
	var script := FileAccess.get_file_as_string("res://src/autoload/drag_resize_system.gd")
	_assert(not script.contains("add_submenu_item"), "context menu should avoid slow native PopupMenu submenus")
	_assert(script.contains("窗口模式：置顶悬浮"), "context menu should expose topmost mode as a direct item")
	_assert(script.contains("角色：%s"), "context menu should expose pet switch as direct items")


func _check_auto_start_model() -> void:
	var script := FileAccess.get_file_as_string("res://src/platform/windows_platform.gd")
	_assert(script.contains("delete\", AUTOSTART_REG_PATH"), "auto-start disable should call reg delete")
	_assert(script.contains("or not _has_auto_start_entry()"), "auto-start disable should treat missing registry value as success")
	_assert(not script.contains("if not is_auto_start_enabled(path):\n\t\t\treturn true"), "auto-start disable should not skip deletion because of path mismatch")


func _check_settings_save_model() -> void:
	var script := FileAccess.get_file_as_string("res://src/scenes/settings/settings_dialog.gd")
	var actual_pos := script.find("var actual := bool(Config.get_value(\"auto_start\", false))")
	var no_change_pos := script.find("if desired == actual:")
	var set_auto_start_pos := script.find("Platform.set_auto_start(false)")
	_assert(actual_pos >= 0 and no_change_pos > actual_pos, "settings save should compare desired auto-start state before platform calls")
	_assert(set_auto_start_pos > no_change_pos, "settings save should not call reg delete when auto-start state is unchanged")


func _assert(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
