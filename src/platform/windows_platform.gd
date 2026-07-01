# src/platform/windows_platform.gd
class_name WindowsPlatform
extends PlatformInterface

const DEBUG_WINDOW_SIZE := Vector2i(900, 500)
const PET_WINDOW_SIZE := Vector2i(620, 380)
const AUTOSTART_REG_PATH := "HKCU\\Software\\Microsoft\\Windows\\CurrentVersion\\Run"
const AUTOSTART_VALUE_NAME := "LetsMakeMoney"


func get_config_path() -> String:
	var appdata := OS.get_environment("APPDATA")
	if appdata.is_empty():
		appdata = OS.get_user_data_dir()
	return appdata.path_join("LetsMakeMoney").path_join("config.json")


func setup_window(window: Window, debug_mode: bool = false, transparent_pet_window: bool = false) -> void:
	var config_path := get_config_path()
	if not DirAccess.dir_exists_absolute(config_path.get_base_dir()):
		DirAccess.make_dir_recursive_absolute(config_path.get_base_dir())

	window.unresizable = true
	if debug_mode:
		window.borderless = false
		window.transparent_bg = false
		window.always_on_top = false
		window.size = DEBUG_WINDOW_SIZE
		window.min_size = DEBUG_WINDOW_SIZE
	else:
		window.borderless = transparent_pet_window
		window.transparent_bg = transparent_pet_window
		window.always_on_top = true
		window.size = PET_WINDOW_SIZE
		window.min_size = PET_WINDOW_SIZE


func set_window_topmost(window: Window, topmost: bool) -> void:
	window.always_on_top = topmost


func get_screen_size() -> Vector2i:
	return DisplayServer.screen_get_size()


func set_window_embed_desktop(window: Window, embed: bool) -> void:
	window.always_on_top = not embed


func is_embed_desktop_supported() -> bool:
	return false


func set_mouse_passthrough(window: Window, enabled: bool, interactive_rects: Array[Rect2]) -> bool:
	if not _window_has_property(window, "mouse_passthrough_polygon"):
		return false
	if not enabled:
		window.mouse_passthrough_polygon = PackedVector2Array()
		return true
	if interactive_rects.is_empty():
		window.mouse_passthrough_polygon = PackedVector2Array()
		return false

	var bounds := interactive_rects[0]
	for rect in interactive_rects:
		bounds = bounds.merge(rect)
	window.mouse_passthrough_polygon = PackedVector2Array([
		bounds.position,
		Vector2(bounds.end.x, bounds.position.y),
		bounds.end,
		Vector2(bounds.position.x, bounds.end.y)
	])
	return true


func _window_has_property(window: Window, property_name: String) -> bool:
	for prop in window.get_property_list():
		if String(prop.get("name", "")) == property_name:
			return true
	return false


func is_tray_supported() -> bool:
	return OS.get_name() == "Windows" and DisplayServer.get_name() == "windows" and ClassDB.class_exists("StatusIndicator") and ClassDB.class_exists("NativeMenu")


func get_executable_path() -> String:
	return OS.get_executable_path()


func is_auto_start_supported(exe_path: String = "") -> bool:
	var path := exe_path if not exe_path.is_empty() else get_executable_path()
	return OS.get_name() == "Windows" and not OS.has_feature("editor") and path.get_file().to_lower() == "letsmakemoney.exe"


func is_auto_start_enabled(exe_path: String = "") -> bool:
	var path := exe_path if not exe_path.is_empty() else get_executable_path()
	if not is_auto_start_supported(path):
		return false
	var output: Array = []
	var exit_code := OS.execute("reg", ["query", AUTOSTART_REG_PATH, "/v", AUTOSTART_VALUE_NAME], output, true, true)
	if exit_code != 0:
		return false
	var expected := path.replace("/", "\\").to_lower()
	var output_text := ""
	for line in output:
		output_text += String(line).replace("/", "\\").to_lower()
	return output_text.contains(expected)


func set_auto_start(enabled: bool, exe_path: String = "") -> bool:
	var path := exe_path if not exe_path.is_empty() else get_executable_path()
	if not is_auto_start_supported(path):
		return false
	var args: Array[String]
	if enabled:
		args = ["add", AUTOSTART_REG_PATH, "/v", AUTOSTART_VALUE_NAME, "/t", "REG_SZ", "/d", "\"%s\"" % path, "/f"]
	else:
		args = ["delete", AUTOSTART_REG_PATH, "/v", AUTOSTART_VALUE_NAME, "/f"]
	var output: Array = []
	var exit_code := OS.execute("reg", args, output, true, true)
	if enabled:
		return exit_code == 0
	return exit_code == 0 or not _has_auto_start_entry()


func _has_auto_start_entry() -> bool:
	var output: Array = []
	return OS.execute("reg", ["query", AUTOSTART_REG_PATH, "/v", AUTOSTART_VALUE_NAME], output, true, true) == 0
