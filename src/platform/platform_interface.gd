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


func is_tray_supported() -> bool:
	return false


func get_executable_path() -> String:
	return OS.get_executable_path()


func is_auto_start_supported(_exe_path: String = "") -> bool:
	return false


func is_auto_start_enabled(_exe_path: String = "") -> bool:
	return false


func set_auto_start(_enabled: bool, _exe_path: String = "") -> bool:
	return false
