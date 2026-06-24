# src/autoload/platform.gd
extends Node

var impl: PlatformInterface = null

func _ready() -> void:
	impl = _create_platform_impl()

func _create_platform_impl() -> PlatformInterface:
	var os_name := OS.get_name()
	match os_name:
		"Windows":
			return WindowsPlatform.new()
		_:
			push_warning("Unsupported platform: %s, falling back to WindowsPlatform" % os_name)
			return WindowsPlatform.new()

# 转发接口
func get_config_path() -> String:
	return impl.get_config_path()

func setup_window(window: Window) -> void:
	impl.setup_window(window)

func set_window_topmost(window: Window, topmost: bool) -> void:
	impl.set_window_topmost(window, topmost)

func get_screen_size() -> Vector2i:
	return impl.get_screen_size()

func set_window_embed_desktop(window: Window, embed: bool) -> void:
	impl.set_window_embed_desktop(window, embed)

func is_embed_desktop_supported() -> bool:
	return impl.is_embed_desktop_supported()
