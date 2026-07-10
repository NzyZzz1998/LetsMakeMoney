extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	await process_frame
	var failures: Array[String] = []
	if String(ProjectSettings.get_setting("application/config/version", "")) != "0.6-beta":
		failures.append("application/config/version must be 0.6-beta")
	_check_source("res://src/autoload/platform.gd", ["func write_info_log", "LOG_MAX_BYTES", "debug.log.1"], failures)
	_check_source("res://src/scenes/pet/pet.gd", ["_should_capture_interaction_snapshots"], failures)
	_check_diagnostics_summary(failures)
	_check_clipboard_result_contract(failures)
	_check_config_persistence(failures)
	_check_transaction_contracts(failures)
	_check_menu_and_passthrough_contracts(failures)
	_check_windows_shell_contracts(failures)
	if not failures.is_empty():
		for failure in failures:
			push_error("V06 verification: %s" % failure)
		quit(1)
		return
	print("v0.6 verification passed")
	quit(0)


func _check_source(path: String, required: Array[String], failures: Array[String]) -> void:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		failures.append("missing %s" % path)
		return
	var text := file.get_as_text()
	for token in required:
		if not text.contains(token):
			failures.append("%s missing %s" % [path, token])


func _check_diagnostics_summary(failures: Array[String]) -> void:
	var service := load("res://src/utils/diagnostics_service.gd")
	if service == null:
		failures.append("diagnostics service unavailable")
		return
	var summary: String = service.build_summary({
		"monthly_salary": 987654.0,
		"window_x": 12345,
		"window_mode": "top",
		"pure_pet_mode": true,
		"pet_id": "cat_orange_v2"
	}, {"tray_supported": true, "passthrough_supported": true})
	for secret in ["987654", "12345", "monthly_salary", "window_x"]:
		if summary.contains(secret):
			failures.append("diagnostics summary leaked forbidden field: %s" % secret)
	if not summary.contains("版本：v0.6-beta"):
		failures.append("diagnostics summary missing shared version")


func _check_clipboard_result_contract(failures: Array[String]) -> void:
	var service := load("res://src/utils/diagnostics_service.gd")
	if service == null:
		failures.append("diagnostics service unavailable for clipboard contract")
		return
	var delayed_readbacks: Array[String] = ["", "expected summary"]
	var delayed: Dictionary = service.classify_clipboard_write_result("expected summary", delayed_readbacks)
	if not bool(delayed.get("ok", false)) or not bool(delayed.get("verified", false)):
		failures.append("delayed clipboard readback must be verified as success")
	var normalized_readbacks: Array[String] = ["line one\r\nline two"]
	var normalized: Dictionary = service.classify_clipboard_write_result("line one\nline two", normalized_readbacks)
	if not bool(normalized.get("ok", false)) or not bool(normalized.get("verified", false)):
		failures.append("Windows clipboard CRLF readback must equal LF summary")
	var unavailable_readbacks: Array[String] = ["", "older clipboard value", ""]
	var uncertain: Dictionary = service.classify_clipboard_write_result("expected summary", unavailable_readbacks)
	if not bool(uncertain.get("ok", false)) or not bool(uncertain.get("verification_uncertain", false)):
		failures.append("unavailable clipboard readback must not become a false write failure")
	var no_readbacks: Array[String] = []
	var failed: Dictionary = service.classify_clipboard_write_result("expected summary", no_readbacks, "剪贴板不可用。")
	if bool(failed.get("ok", true)) or String(failed.get("error", "")).is_empty():
		failures.append("explicit clipboard write failure must remain a readable failure")


func _check_config_persistence(failures: Array[String]) -> void:
	var config_script := load("res://src/autoload/config.gd")
	if config_script == null:
		failures.append("config script unavailable")
		return
	var test_dir := OS.get_environment("APPDATA").path_join("LetsMakeMoney-v06-config-test")
	DirAccess.make_dir_recursive_absolute(test_dir)
	var config_path := test_dir.path_join("config.json")
	for file_name in DirAccess.get_files_at(test_dir):
		DirAccess.remove_absolute(test_dir.path_join(file_name))
	var config: Node = config_script.new()
	config.set("_config_path", config_path)
	config.set("data", config.call("merge_with_defaults", {"monthly_salary": 1234.0}))
	config.call("set_value", "window_mode", "embed")
	if not bool(config.call("save")):
		failures.append("atomic config save failed: %s" % String(config.call("get_last_save_error")))
	elif FileAccess.file_exists(config_path + ".tmp") or FileAccess.file_exists(config_path + ".previous"):
		failures.append("atomic config save left temporary files")
	var persisted_before_failure := FileAccess.get_file_as_string(config_path)
	DirAccess.make_dir_absolute(config_path + ".tmp")
	config.call("set_value", "monthly_salary", 9999.0)
	if bool(config.call("save")):
		failures.append("config save should fail when temporary path is unavailable")
	if FileAccess.get_file_as_string(config_path) != persisted_before_failure:
		failures.append("failed atomic save damaged previous config")
	DirAccess.remove_absolute(config_path + ".tmp")
	var invalid := FileAccess.open(config_path, FileAccess.WRITE)
	if invalid != null:
		invalid.store_string("{invalid-json")
		invalid.close()
	var recovered: Node = config_script.new()
	recovered.set("_config_path", config_path)
	recovered.call("_load")
	if float(recovered.call("get_value", "monthly_salary", -1.0)) != 0.0:
		failures.append("invalid config did not restore defaults")
	if String(recovered.call("consume_recovery_notice")).is_empty():
		failures.append("invalid config recovery did not expose one-time notice")
	if not String(recovered.call("consume_recovery_notice")).is_empty():
		failures.append("config recovery notice was not consumed exactly once")
	var invalid_backups := 0
	for file_name in DirAccess.get_files_at(test_dir):
		if file_name.contains(".invalid."):
			invalid_backups += 1
	if invalid_backups != 1:
		failures.append("invalid config backup count expected 1, got %d" % invalid_backups)


func _check_transaction_contracts(failures: Array[String]) -> void:
	var settings := FileAccess.get_file_as_string("res://src/scenes/settings/settings_dialog.gd")
	var save_start := settings.find("func _on_save()")
	var save_end := settings.find("\nfunc ", save_start + 1)
	var save_body := settings.substr(save_start, save_end - save_start)
	var persist_index := save_body.find("Config.save()")
	var external_index := save_body.find("_apply_committed_external_state")
	if persist_index < 0 or external_index < 0 or persist_index > external_index:
		failures.append("Settings must persist before applying external state")
	for token in ["_validate_form_values", "_capture_external_state", "settings_transaction_rollback"]:
		if not settings.contains(token):
			failures.append("Settings transaction missing %s" % token)
	var wizard := FileAccess.get_file_as_string("res://src/scenes/wizard/wizard_dialog.gd")
	for token in ["_entry_config_snapshot", "_entry_pet_id", "_restore_entry_state", "wizard_state_restored"]:
		if not wizard.contains(token):
			failures.append("Wizard transaction missing %s" % token)


func _check_menu_and_passthrough_contracts(failures: Array[String]) -> void:
	var menu := FileAccess.get_file_as_string("res://src/autoload/drag_resize_system.gd")
	for token in [
		'popup.add_item("隐藏到托盘", 600)',
		'menu.add_item("设置", 100)',
		'menu.add_item("重新运行向导", 101)',
		'menu.add_submenu_item("窗口模式"',
		'menu.add_submenu_item("选择宠物"',
		'menu.add_item("关于 LetsMakeMoney", 400)',
		'menu.add_item("退出", 500)',
		'popup_opened.emit()',
		'popup_closed.emit()'
	]:
		if not menu.contains(token):
			failures.append("context menu contract missing %s" % token)
	var native_menu := FileAccess.get_file_as_string("res://native/windows/src/tray_controller.cpp")
	if native_menu.contains('L"重新运行向导"') or native_menu.contains('L"选择宠物"') or native_menu.contains('L"窗口模式"'):
		failures.append("native tray menu contains context-only commands")
	var main := FileAccess.get_file_as_string("res://src/scenes/main/main.gd")
	for token in [
		'passthrough_suspended: reason=modal_opened',
		'passthrough_resumed: reason=modal_closed',
		'passthrough_suspended: reason=popup_opened',
		'passthrough_resumed: reason=popup_closed'
	]:
		if not main.contains(token):
			failures.append("passthrough lifecycle missing %s" % token)


func _check_windows_shell_contracts(failures: Array[String]) -> void:
	var native_window := FileAccess.get_file_as_string("res://native/windows/src/window_controller.cpp")
	for token in ["ITaskbarList", "DeleteTab", "AddTab"]:
		if not native_window.contains(token):
			failures.append("native taskbar synchronization missing %s" % token)
	var windows_platform := FileAccess.get_file_as_string("res://src/platform/windows_platform.gd")
	if not windows_platform.contains('var normalized_path := path.replace("/", "\\\\")'):
		failures.append("auto-start path must be normalized to Windows separators before registry write")
	if not windows_platform.contains('var command := "\\\"%s\\\"" % normalized_path'):
		failures.append("auto-start registry command must quote the normalized executable path")
	if not windows_platform.contains("func _read_auto_start_command() -> String:"):
		failures.append("auto-start state must inspect the stored registry command")
	if not windows_platform.contains("stored_command == normalized_path or stored_command == command"):
		failures.append("auto-start state must reject stale or non-normalized registry commands")
