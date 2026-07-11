# src/platform/platform_interface.gd
class_name PlatformInterface
extends RefCounted


func get_config_path() -> String:
	push_error("PlatformInterface.get_config_path() not implemented")
	return ""


func setup_window(_window: Window, _debug_mode: bool = false, _transparent_pet_window: bool = false) -> void:
	push_error("PlatformInterface.setup_window() not implemented")


func set_window_topmost(_window: Window, _topmost: bool) -> void:
	push_error("PlatformInterface.set_window_topmost() not implemented")


func get_screen_size() -> Vector2i:
	push_error("PlatformInterface.get_screen_size() not implemented")
	return Vector2i(1920, 1080)


func is_embed_desktop_supported() -> bool:
	return false


func set_window_embed_desktop(_window: Window, _embed: bool) -> void:
	if _embed:
		set_window_topmost(_window, false)


func set_mouse_passthrough(_window: Window, _enabled: bool, _interactive_rects: Array[Rect2]) -> bool:
	return false


func set_window_visible(_window: Window, _visible: bool) -> bool:
	return false


func get_native_health() -> Dictionary:
	return {
		"native_loaded": false,
		"tray_supported": false,
		"window_supported": false,
		"passthrough_supported": false,
		"taskbar_supported": false,
		"capabilities": {
			"tray": {"state": "unavailable", "last_error": "Native bridge is not available on this platform."},
			"window": {"state": "unavailable", "last_error": "Native bridge is not available on this platform."},
			"passthrough": {"state": "unavailable", "last_error": "Native bridge is not available on this platform."},
			"taskbar": {"state": "unavailable", "last_error": "Native bridge is not available on this platform."}
		},
		"last_error": "Native bridge is not available on this platform."
	}


func get_native_window_handle(_window: Window) -> int:
	return 0


func is_tray_supported() -> bool:
	return false


func setup_tray(_icon_path: String) -> bool:
	return false


func update_tray_menu(_window_visible: bool) -> void:
	pass


func shutdown_tray() -> void:
	pass


func poll_tray_command() -> int:
	return 0


func set_taskbar_visible(_window: Window, _visible: bool) -> bool:
	return false


func can_enable_pure_pet_mode(_window: Window) -> bool:
	return false


func get_executable_path() -> String:
	return OS.get_executable_path()


func is_auto_start_supported(_exe_path: String = "") -> bool:
	return false


func is_auto_start_enabled(_exe_path: String = "") -> bool:
	return false


func set_auto_start(_enabled: bool, _exe_path: String = "") -> bool:
	return false
