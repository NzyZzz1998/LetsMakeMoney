# src/autoload/platform.gd
extends Node

signal tray_toggle_requested
signal tray_settings_requested
signal tray_about_requested
signal tray_exit_requested

var impl: PlatformInterface = null
var _status_indicator: Node = null
var _tray_menu: PopupMenu = null


func _ready() -> void:
	write_boot_log("Platform._ready: begin")
	impl = _create_platform_impl()
	write_boot_log("Platform._ready: impl=%s" % impl.get_class())


func _exit_tree() -> void:
	write_boot_log("Platform._exit_tree")
	shutdown_tray()


func write_boot_log(message: String) -> void:
	var appdata := OS.get_environment("APPDATA")
	if appdata.is_empty():
		appdata = OS.get_user_data_dir()
	var dir_path := appdata.path_join("LetsMakeMoney")
	if not DirAccess.dir_exists_absolute(dir_path):
		DirAccess.make_dir_recursive_absolute(dir_path)
	var file := FileAccess.open(dir_path.path_join("debug.log"), FileAccess.READ_WRITE)
	if file == null:
		return
	file.seek_end()
	file.store_line("%s | %s" % [Time.get_datetime_string_from_system(), message])
	file.close()


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


func is_tray_supported() -> bool:
	return impl.is_tray_supported()


func setup_tray(icon_path: String) -> bool:
	if not is_tray_supported():
		return false
	shutdown_tray()

	_status_indicator = ClassDB.instantiate("StatusIndicator") as Node
	if _status_indicator == null:
		return false
	_status_indicator.tooltip = "LetsMakeMoney"
	var icon := load(icon_path)
	if icon is Texture2D:
		_status_indicator.icon = icon
	_status_indicator.pressed.connect(_on_status_indicator_pressed)
	add_child(_status_indicator)
	update_tray_menu(true)
	_status_indicator.visible = true
	return true


func update_tray_menu(window_visible: bool) -> void:
	if _status_indicator == null:
		return
	if _tray_menu != null and is_instance_valid(_tray_menu):
		_tray_menu.queue_free()
	_tray_menu = PopupMenu.new()
	_tray_menu.name = "TrayMenu"
	_tray_menu.add_item("隐藏窗口" if window_visible else "显示窗口", 1)
	_tray_menu.add_separator()
	_tray_menu.add_item("设置", 2)
	_tray_menu.add_item("关于 LetsMakeMoney", 3)
	_tray_menu.add_separator()
	_tray_menu.add_item("退出", 4)
	_tray_menu.id_pressed.connect(_on_tray_menu_id_pressed)
	add_child(_tray_menu)
	_status_indicator.menu = _tray_menu.get_path()


func shutdown_tray() -> void:
	if _status_indicator != null and is_instance_valid(_status_indicator):
		_status_indicator.visible = false
		_status_indicator.queue_free()
	_status_indicator = null
	if _tray_menu != null and is_instance_valid(_tray_menu):
		_tray_menu.queue_free()
	_tray_menu = null


func get_executable_path() -> String:
	return impl.get_executable_path()


func is_auto_start_supported(exe_path: String = "") -> bool:
	return impl.is_auto_start_supported(exe_path)


func is_auto_start_enabled(exe_path: String = "") -> bool:
	return impl.is_auto_start_enabled(exe_path)


func set_auto_start(enabled: bool, exe_path: String = "") -> bool:
	return impl.set_auto_start(enabled, exe_path)


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
