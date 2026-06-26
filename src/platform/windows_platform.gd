# src/platform/windows_platform.gd
class_name WindowsPlatform
extends PlatformInterface

func get_config_path() -> String:
	var appdata := OS.get_environment("APPDATA")
	if appdata.is_empty():
		appdata = OS.get_user_data_dir()
	return appdata.path_join("LetsMakeMoney").path_join("config.json")

func setup_window(window: Window) -> void:
	# 确保配置目录存在
	var config_path := get_config_path()
	var dir := DirAccess.open(config_path.get_base_dir())
	if dir == null:
		DirAccess.make_dir_recursive_absolute(config_path.get_base_dir())
	# 窗口样式
	# 调试阶段先使用普通有边框窗口，确保鼠标/键盘焦点行为可观察。
	window.borderless = false
	# 调试阶段先关闭透明背景，避免 Windows 透明窗口按像素命中导致鼠标事件不稳定。
	window.transparent_bg = false
	window.unresizable = true
	window.always_on_top = false
	window.size = Vector2i(720, 360)
	window.min_size = Vector2i(720, 360)

func set_window_topmost(window: Window, topmost: bool) -> void:
	window.always_on_top = topmost

func get_screen_size() -> Vector2i:
	return DisplayServer.screen_get_size()


func set_window_embed_desktop(window: Window, embed: bool) -> void:
	# v0.1 降级：不做 Progman 嵌入，只切换置顶状态。
	window.always_on_top = not embed


func is_embed_desktop_supported() -> bool:
	return false  # v0.1 不实现真嵌入桌面（需要 Progman 父窗口技巧）
