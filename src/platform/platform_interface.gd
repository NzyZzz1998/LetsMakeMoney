# src/platform/platform_interface.gd
class_name PlatformInterface
extends RefCounted

# 所有方法由子类覆盖。基类提供空实现 + push_error。
# 使用 RefCounted 而非 Node——这是纯逻辑对象，不需要进场景树。

func get_config_path() -> String:
	push_error("PlatformInterface.get_config_path() not implemented")
	return ""

func setup_window(_window: Window) -> void:
	push_error("PlatformInterface.setup_window() not implemented")

func set_window_topmost(_window: Window, _topmost: bool) -> void:
	push_error("PlatformInterface.set_window_topmost() not implemented")

func get_screen_size() -> Vector2i:
	push_error("PlatformInterface.get_screen_size() not implemented")
	return Vector2i(1920, 1080)

func is_embed_desktop_supported() -> bool:
	return false  # v0.1 默认不支持真嵌入桌面

func set_window_embed_desktop(_window: Window, _embed: bool) -> void:
	# v0.1 降级：融入桌面退化为普通非置顶窗口
	if _embed:
		set_window_topmost(_window, false)
