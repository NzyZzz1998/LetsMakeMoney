# src/autoload/platform.gd
extends Node

signal tray_toggle_requested
signal tray_left_toggle_requested
signal tray_settings_requested
signal tray_about_requested
signal tray_exit_requested

var impl: PlatformInterface = null
var _status_indicator: Node = null
var _tray_menu: PopupMenu = null
var _last_tray_toggle_msec: int = 0

const TRAY_TOGGLE_DEBOUNCE_MSEC := 350
const LOG_MAX_BYTES := 2 * 1024 * 1024
const LOG_FILE_NAME := "debug.log"
const LOG_BACKUP_FILE_NAME := "debug.log.1"


func _ready() -> void:
	write_boot_log("Platform._ready: begin")
	impl = _create_platform_impl()
	write_boot_log("Platform._ready: impl=%s" % impl.get_class())


func _exit_tree() -> void:
	write_boot_log("Platform._exit_tree")
	shutdown_tray()


func write_boot_log(message: String, level: String = "info") -> void:
	_write_log(message, level)


func write_info_log(message: String) -> void:
	_write_log(message, "info")


func write_error_log(message: String) -> void:
	_write_log(message, "error")


func _write_log(message: String, level: String) -> void:
	if level == "debug" and not _should_write_debug_log():
		return
	var appdata := OS.get_environment("APPDATA")
	if appdata.is_empty():
		appdata = OS.get_user_data_dir()
	var dir_path := appdata.path_join("LetsMakeMoney")
	if not DirAccess.dir_exists_absolute(dir_path):
		var mkdir_error := DirAccess.make_dir_recursive_absolute(dir_path)
		if mkdir_error != OK:
			push_warning("LetsMakeMoney log directory unavailable: %s" % error_string(mkdir_error))
			return
	var log_path := dir_path.path_join(LOG_FILE_NAME)
	_rotate_log_if_needed(log_path, dir_path.path_join(LOG_BACKUP_FILE_NAME))
	var mode := FileAccess.READ_WRITE if FileAccess.file_exists(log_path) else FileAccess.WRITE
	var file := FileAccess.open(log_path, mode)
	if file == null:
		push_warning("LetsMakeMoney log file unavailable: %s" % log_path)
		return
	file.seek_end()
	file.store_line("%s | %s | %s" % [Time.get_datetime_string_from_system(), level, message])
	file.close()


func write_debug_log(message: String) -> void:
	_write_log(message, "debug")


func _rotate_log_if_needed(log_path: String, backup_path: String) -> void:
	if not FileAccess.file_exists(log_path):
		return
	var current := FileAccess.open(log_path, FileAccess.READ)
	if current == null:
		return
	var length := current.get_length()
	current.close()
	if length < LOG_MAX_BYTES:
		return
	if FileAccess.file_exists(backup_path):
		var remove_error := DirAccess.remove_absolute(backup_path)
		if remove_error != OK:
			push_warning("LetsMakeMoney log backup could not be replaced: %s" % error_string(remove_error))
			return
	var rename_error := DirAccess.rename_absolute(log_path, backup_path)
	if rename_error != OK:
		push_warning("LetsMakeMoney log rotation skipped: %s" % error_string(rename_error))


func _should_write_debug_log() -> bool:
	var config := get_node_or_null("/root/Config")
	if config != null and config.has_method("get_value"):
		return bool(config.call("get_value", "debug_mode", false))
	return false


func _process(_delta: float) -> void:
	_poll_native_tray()


func _create_platform_impl() -> PlatformInterface:
	var os_name := OS.get_name()
	match os_name:
		"Windows":
			return WindowsPlatform.new()
		_:
			push_warning("Unsupported platform: %s, falling back to WindowsPlatform" % os_name)
			return WindowsPlatform.new()


func get_config_path() -> String:
	return impl.get_config_path()


func setup_window(window: Window, debug_mode: bool = false, transparent_pet_window: bool = false) -> void:
	impl.setup_window(window, debug_mode, transparent_pet_window)


func set_window_topmost(window: Window, topmost: bool) -> void:
	impl.set_window_topmost(window, topmost)


func get_screen_size() -> Vector2i:
	return impl.get_screen_size()


func set_window_embed_desktop(window: Window, embed: bool) -> void:
	impl.set_window_embed_desktop(window, embed)


func is_embed_desktop_supported() -> bool:
	return impl.is_embed_desktop_supported()


func set_mouse_passthrough(window: Window, enabled: bool, interactive_rects: Array[Rect2]) -> bool:
	return impl.set_mouse_passthrough(window, enabled, interactive_rects)


func set_window_visible(window: Window, visible: bool) -> bool:
	return impl.set_window_visible(window, visible)


func get_native_health() -> Dictionary:
	return impl.get_native_health()


func get_native_window_handle(window: Window) -> int:
	return impl.get_native_window_handle(window)


func verify_authenticode(file_path: String, expected_publisher: String = "") -> Dictionary:
	return impl.verify_authenticode(file_path, expected_publisher)


func is_tray_supported() -> bool:
	return impl.is_tray_supported()


func setup_tray(icon_path: String) -> bool:
	return impl.setup_tray(icon_path)


func update_tray_menu(window_visible: bool) -> void:
	impl.update_tray_menu(window_visible)


func shutdown_tray() -> void:
	impl.shutdown_tray()
	if _status_indicator != null and is_instance_valid(_status_indicator):
		_status_indicator.visible = false
		_status_indicator.queue_free()
	_status_indicator = null
	if _tray_menu != null and is_instance_valid(_tray_menu):
		_tray_menu.queue_free()
	_tray_menu = null


func poll_tray_command() -> int:
	return impl.poll_tray_command()


func get_executable_path() -> String:
	return impl.get_executable_path()


func is_auto_start_supported(exe_path: String = "") -> bool:
	return impl.is_auto_start_supported(exe_path)


func is_auto_start_enabled(exe_path: String = "") -> bool:
	return impl.is_auto_start_enabled(exe_path)


func set_auto_start(enabled: bool, exe_path: String = "") -> bool:
	return impl.set_auto_start(enabled, exe_path)


func set_taskbar_visible(window: Window, visible: bool) -> bool:
	return impl.set_taskbar_visible(window, visible)


func can_enable_pure_pet_mode(window: Window) -> bool:
	return impl.can_enable_pure_pet_mode(window)


func _poll_native_tray() -> void:
	if impl == null:
		return
	var command := impl.poll_tray_command()
	if command != 0:
		write_debug_log("Platform._poll_native_tray: command=%d" % command)
	match command:
		1:
			var now := Time.get_ticks_msec()
			if now - _last_tray_toggle_msec < TRAY_TOGGLE_DEBOUNCE_MSEC:
				write_boot_log("Platform._poll_native_tray: ignored duplicate toggle")
				return
			_last_tray_toggle_msec = now
			tray_toggle_requested.emit()
		2:
			tray_settings_requested.emit()
		3:
			tray_about_requested.emit()
		4:
			tray_exit_requested.emit()
		5:
			var now_left := Time.get_ticks_msec()
			if now_left - _last_tray_toggle_msec < TRAY_TOGGLE_DEBOUNCE_MSEC:
				write_boot_log("Platform._poll_native_tray: ignored duplicate left toggle")
				return
			_last_tray_toggle_msec = now_left
			tray_left_toggle_requested.emit()


func _on_status_indicator_pressed(_button: int = 0, _position: Vector2i = Vector2i.ZERO) -> void:
	tray_toggle_requested.emit()


func _on_tray_toggle(_tag: Variant = null) -> void:
	tray_toggle_requested.emit()


func _on_tray_settings(_tag: Variant = null) -> void:
	tray_settings_requested.emit()


func _on_tray_about(_tag: Variant = null) -> void:
	tray_about_requested.emit()


func _on_tray_exit(_tag: Variant = null) -> void:
	tray_exit_requested.emit()


func _on_tray_menu_id_pressed(id: int) -> void:
	match id:
		1:
			_on_tray_toggle()
		2:
			_on_tray_settings()
		3:
			_on_tray_about()
		4:
			_on_tray_exit()
