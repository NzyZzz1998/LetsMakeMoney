# src/platform/windows_platform.gd
class_name WindowsPlatform
extends PlatformInterface

const DEBUG_WINDOW_SIZE := Vector2i(900, 500)
const PET_WINDOW_SIZE := Vector2i(620, 380)
const AUTOSTART_REG_PATH := "HKCU\\Software\\Microsoft\\Windows\\CurrentVersion\\Run"
const AUTOSTART_VALUE_NAME := "LetsMakeMoney"
const CAPABILITY_AVAILABLE := "available"
const CAPABILITY_DEGRADED := "degraded"
const CAPABILITY_UNAVAILABLE := "unavailable"

var _native_bridge: Object = null
var _native_health: Dictionary = {}
var _last_topmost_by_window: Dictionary = {}
var _last_embed_by_window: Dictionary = {}
var _last_taskbar_visibility_by_window: Dictionary = {}


func _init() -> void:
	_load_native_bridge()


func get_config_path() -> String:
	var appdata := OS.get_environment("APPDATA")
	if appdata.is_empty():
		appdata = OS.get_user_data_dir()
	return appdata.path_join("LetsMakeMoney").path_join("config.json")


func setup_window(window: Window, debug_mode: bool = false, transparent_pet_window: bool = false) -> void:
	Platform.write_boot_log("WindowsPlatform.setup_window: begin debug=%s transparent=%s" % [str(debug_mode), str(transparent_pet_window)])
	_invalidate_taskbar_visibility_cache(window, "setup_window")
	var config_path := get_config_path()
	if not DirAccess.dir_exists_absolute(config_path.get_base_dir()):
		DirAccess.make_dir_recursive_absolute(config_path.get_base_dir())

	window.title = "LetsMakeMoney"
	window.unresizable = true
	var native_window_available := bool(_native_health.get("window_supported", false))
	var use_transparent_window := transparent_pet_window and native_window_available

	if debug_mode:
		window.borderless = false
		window.transparent_bg = false
		_set_transparent_window_flag(window, false)
		window.always_on_top = false
		window.min_size = DEBUG_WINDOW_SIZE
		window.size = DEBUG_WINDOW_SIZE
	else:
		window.borderless = use_transparent_window
		window.transparent_bg = use_transparent_window
		_set_transparent_window_flag(window, use_transparent_window)
		window.always_on_top = true
		window.min_size = PET_WINDOW_SIZE
		window.size = PET_WINDOW_SIZE
		if use_transparent_window and _native_bridge != null:
			var hwnd := get_native_window_handle(window)
			Platform.write_boot_log("WindowsPlatform.setup_window: setup_pet_window hwnd=%s" % str(hwnd))
			var ok := bool(_native_bridge.call("setup_pet_window", hwnd, true, true))
			Platform.write_boot_log("WindowsPlatform.setup_window: setup_pet_window ok=%s" % str(ok))
			if not ok:
				_native_health["window_supported"] = false
				_native_health["last_error"] = _read_native_error("setup_pet_window failed")
				window.borderless = false
				window.transparent_bg = false
	Platform.write_boot_log("WindowsPlatform.setup_window: end")


func _set_transparent_window_flag(window: Window, enabled: bool) -> void:
	if window == null or not DisplayServer.has_method("window_set_flag"):
		return
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_TRANSPARENT, enabled, window.get_window_id())


func set_window_topmost(window: Window, topmost: bool) -> void:
	var key := _window_cache_key(window)
	if _last_topmost_by_window.get(key) == topmost:
		return
	window.always_on_top = topmost
	_last_topmost_by_window[key] = topmost


func get_screen_size() -> Vector2i:
	return DisplayServer.screen_get_size()


func set_window_embed_desktop(window: Window, embed: bool) -> void:
	var key := _window_cache_key(window)
	if _last_embed_by_window.get(key) == embed:
		return
	window.always_on_top = not embed
	_last_embed_by_window[key] = embed
	_last_topmost_by_window[key] = not embed


func is_embed_desktop_supported() -> bool:
	return false


func set_mouse_passthrough(window: Window, enabled: bool, interactive_rects: Array[Rect2]) -> bool:
	Platform.write_debug_log("WindowsPlatform.set_mouse_passthrough: begin enabled=%s count=%d" % [str(enabled), interactive_rects.size()])
	if _native_bridge != null and bool(_native_health.get("passthrough_supported", false)):
		var hwnd := get_native_window_handle(window)
		if enabled:
			Platform.write_debug_log("WindowsPlatform.set_mouse_passthrough: native set hwnd=%s" % str(hwnd))
			var set_ok := bool(_native_bridge.call("set_mouse_passthrough", hwnd, interactive_rects))
			Platform.write_debug_log("WindowsPlatform.set_mouse_passthrough: native set ok=%s" % str(set_ok))
			if not set_ok:
				_native_health["last_error"] = _read_native_error("set_mouse_passthrough failed")
				_set_capability_state("passthrough", CAPABILITY_DEGRADED, String(_native_health["last_error"]))
				Platform.write_boot_log("WindowsPlatform.set_mouse_passthrough: error=%s" % str(_native_health["last_error"]))
			return set_ok
		Platform.write_debug_log("WindowsPlatform.set_mouse_passthrough: native clear hwnd=%s" % str(hwnd))
		var clear_ok := bool(_native_bridge.call("clear_mouse_passthrough", hwnd))
		Platform.write_debug_log("WindowsPlatform.set_mouse_passthrough: native clear ok=%s" % str(clear_ok))
		if not clear_ok:
			_native_health["last_error"] = _read_native_error("clear_mouse_passthrough failed")
			_set_capability_state("passthrough", CAPABILITY_DEGRADED, String(_native_health["last_error"]))
			Platform.write_boot_log("WindowsPlatform.set_mouse_passthrough: clear error=%s" % str(_native_health["last_error"]))
		return clear_ok

	Platform.write_debug_log("WindowsPlatform.set_mouse_passthrough: no passthrough backend")
	return false


func set_window_visible(window: Window, visible: bool) -> bool:
	if _native_bridge == null or not bool(_native_health.get("window_supported", false)):
		return false
	var hwnd := get_native_window_handle(window)
	Platform.write_boot_log("WindowsPlatform.set_window_visible: hwnd=%s visible=%s" % [str(hwnd), str(visible)])
	var ok := bool(_native_bridge.call("set_window_visible", hwnd, visible))
	Platform.write_boot_log("WindowsPlatform.set_window_visible: ok=%s" % str(ok))
	if not ok:
		_native_health["last_error"] = _read_native_error("set_window_visible failed")
		_set_capability_state("window", CAPABILITY_DEGRADED, String(_native_health["last_error"]))
	elif visible:
		_invalidate_taskbar_visibility_cache(window, "set_window_visible_show")
	return ok


func is_tray_supported() -> bool:
	return bool(_native_health.get("tray_supported", false))


func get_native_health() -> Dictionary:
	return _native_health.duplicate(true)


func get_native_window_handle(window: Window) -> int:
	var target_window := window
	if target_window == null:
		var main_loop := Engine.get_main_loop()
		if main_loop is SceneTree:
			target_window = main_loop.root
	if target_window == null or not DisplayServer.has_method("window_get_native_handle"):
		return 0
	var handle = DisplayServer.window_get_native_handle(DisplayServer.WINDOW_HANDLE, target_window.get_window_id())
	if typeof(handle) == TYPE_INT:
		return int(handle)
	return 0


func setup_tray(icon_path: String) -> bool:
	if _native_bridge == null or not bool(_native_health.get("tray_supported", false)):
		Platform.write_boot_log("WindowsPlatform.setup_tray: skipped")
		return false
	Platform.write_boot_log("WindowsPlatform.setup_tray: begin icon=%s" % icon_path)
	var ok := bool(_native_bridge.call("setup_tray", icon_path))
	Platform.write_boot_log("WindowsPlatform.setup_tray: native_last_error=%s" % _read_native_error(""))
	Platform.write_boot_log("WindowsPlatform.setup_tray: ok=%s" % str(ok))
	if not ok:
		_native_health["tray_supported"] = false
		_native_health["last_error"] = _read_native_error("setup_tray failed")
		_set_capability_state("tray", CAPABILITY_DEGRADED, String(_native_health["last_error"]))
		Platform.write_boot_log("WindowsPlatform.setup_tray: error=%s" % str(_native_health["last_error"]))
	return ok


func update_tray_menu(window_visible: bool) -> void:
	if _native_bridge != null and bool(_native_health.get("tray_supported", false)):
		_native_bridge.call("update_tray_menu", window_visible)


func shutdown_tray() -> void:
	if _native_bridge != null:
		_native_bridge.call("shutdown_tray")


func poll_tray_command() -> int:
	if _native_bridge == null or not _native_bridge.has_method("poll_tray_command"):
		return 0
	return int(_native_bridge.call("poll_tray_command"))


func set_taskbar_visible(window: Window, visible: bool) -> bool:
	if _native_bridge == null or not bool(_native_health.get("taskbar_supported", false)):
		return false
	var key := _window_cache_key(window)
	if _last_taskbar_visibility_by_window.get(key) == visible:
		Platform.write_debug_log("WindowsPlatform.set_taskbar_visible: cached visible=%s key=%d" % [str(visible), key])
		return true
	var hwnd := get_native_window_handle(window)
	Platform.write_boot_log("WindowsPlatform.set_taskbar_visible: hwnd=%s visible=%s" % [str(hwnd), str(visible)])
	var ok := bool(_native_bridge.call("set_taskbar_visible", hwnd, visible))
	Platform.write_boot_log("WindowsPlatform.set_taskbar_visible: ok=%s" % str(ok))
	if not ok:
		_native_health["taskbar_supported"] = false
		_native_health["last_error"] = _read_native_error("set_taskbar_visible failed")
		_set_capability_state("taskbar", CAPABILITY_DEGRADED, String(_native_health["last_error"]))
	else:
		_last_taskbar_visibility_by_window[key] = visible
	return ok


func can_enable_pure_pet_mode(window: Window) -> bool:
	return _native_bridge != null \
		and bool(_native_health.get("tray_supported", false)) \
		and bool(_native_health.get("taskbar_supported", false)) \
		and get_native_window_handle(window) != 0


func get_executable_path() -> String:
	return OS.get_executable_path()


func is_auto_start_supported(exe_path: String = "") -> bool:
	var path := exe_path if not exe_path.is_empty() else get_executable_path()
	return OS.get_name() == "Windows" and not OS.has_feature("editor") and path.get_file().to_lower() == "letsmakemoney.exe"


func is_auto_start_enabled(exe_path: String = "") -> bool:
	var path := exe_path if not exe_path.is_empty() else get_executable_path()
	if not is_auto_start_supported(path):
		return false
	var normalized_path := path.replace("/", "\\").to_lower()
	var command := "\"%s\"" % normalized_path
	var stored_command := _read_auto_start_command().to_lower()
	return stored_command == normalized_path or stored_command == command


func _read_auto_start_command() -> String:
	var output: Array = []
	var exit_code := OS.execute("reg", ["query", AUTOSTART_REG_PATH, "/v", AUTOSTART_VALUE_NAME], output, true, true)
	if exit_code != 0:
		return ""
	for block in output:
		for line in String(block).split("\n"):
			var marker_index := line.find("REG_SZ")
			if marker_index >= 0:
				return line.substr(marker_index + 6).strip_edges()
	return ""


func set_auto_start(enabled: bool, exe_path: String = "") -> bool:
	var path := exe_path if not exe_path.is_empty() else get_executable_path()
	if not is_auto_start_supported(path):
		return false
	var normalized_path := path.replace("/", "\\")
	var command := "\"%s\"" % normalized_path
	var args: Array[String]
	if enabled:
		args = ["add", AUTOSTART_REG_PATH, "/v", AUTOSTART_VALUE_NAME, "/t", "REG_SZ", "/d", command, "/f"]
	else:
		args = ["delete", AUTOSTART_REG_PATH, "/v", AUTOSTART_VALUE_NAME, "/f"]
	var output: Array = []
	var exit_code := OS.execute("reg", args, output, true, true)
	if enabled:
		var enabled_ok := exit_code == 0 and is_auto_start_enabled(normalized_path)
		if enabled_ok:
			Platform.write_info_log("auto_start_apply_success: enabled=true")
		else:
			Platform.write_error_log("auto_start_apply_failed: enabled=true exit_code=%d stored_command_valid=%s" % [exit_code, str(is_auto_start_enabled(normalized_path))])
		return enabled_ok
	var disabled_ok := exit_code == 0 or not _has_auto_start_entry()
	if disabled_ok:
		Platform.write_info_log("auto_start_apply_success: enabled=false")
	else:
		Platform.write_error_log("auto_start_apply_failed: enabled=false exit_code=%d" % exit_code)
	return disabled_ok


func _has_auto_start_entry() -> bool:
	var output: Array = []
	return OS.execute("reg", ["query", AUTOSTART_REG_PATH, "/v", AUTOSTART_VALUE_NAME], output, true, true) == 0


func _load_native_bridge() -> void:
	Platform.write_boot_log("WindowsPlatform._load_native_bridge: begin")
	_native_health = {
		"native_loaded": false,
		"tray_supported": false,
		"window_supported": false,
		"passthrough_supported": false,
		"taskbar_supported": false,
		"capabilities": {},
		"last_error": "LMMNativeBridge class is not loaded."
	}
	for capability in ["tray", "window", "passthrough", "taskbar"]:
		_set_capability_state(capability, CAPABILITY_UNAVAILABLE, String(_native_health["last_error"]))
	if not ClassDB.class_exists("LMMNativeBridge"):
		Platform.write_boot_log("WindowsPlatform._load_native_bridge: class missing")
		return
	_native_bridge = ClassDB.instantiate("LMMNativeBridge")
	if _native_bridge == null:
		_native_health["last_error"] = "Failed to instantiate LMMNativeBridge."
		Platform.write_boot_log("WindowsPlatform._load_native_bridge: instantiate failed")
		return
	if _native_bridge.has_method("get_health"):
		var health = _native_bridge.call("get_health")
		if health is Dictionary:
			_native_health = health
			_native_health["capabilities"] = {}
			for capability in ["tray", "window", "passthrough", "taskbar"]:
				var supported_key := "%s_supported" % capability
				_set_capability_state(capability, CAPABILITY_AVAILABLE if bool(_native_health.get(supported_key, false)) else CAPABILITY_UNAVAILABLE, "" if bool(_native_health.get(supported_key, false)) else String(_native_health.get("last_error", "unsupported")))
			Platform.write_boot_log("WindowsPlatform._load_native_bridge: health=%s" % str(_native_health))
			return
	_native_health["native_loaded"] = true
	_native_health["last_error"] = "LMMNativeBridge loaded but get_health returned invalid data."
	Platform.write_boot_log("WindowsPlatform._load_native_bridge: health invalid")


func _read_native_error(fallback: String) -> String:
	if _native_bridge != null and _native_bridge.has_method("get_last_error"):
		var err := String(_native_bridge.call("get_last_error"))
		if not err.is_empty():
			return err
	return fallback


func _set_capability_state(capability: String, state: String, error: String = "") -> void:
	var capabilities: Dictionary = _native_health.get("capabilities", {})
	capabilities[capability] = {"state": state, "last_error": error}
	_native_health["capabilities"] = capabilities


func _window_cache_key(window: Window) -> int:
	if window == null:
		return 0
	return window.get_window_id()


func _invalidate_taskbar_visibility_cache(window: Window, reason: String) -> void:
	var key := _window_cache_key(window)
	_last_taskbar_visibility_by_window.erase(key)
	Platform.write_debug_log("WindowsPlatform._invalidate_taskbar_visibility_cache: reason=%s key=%d" % [reason, key])
