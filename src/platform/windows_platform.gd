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
	window.borderless = true
	window.transparent_bg = true
	window.unresizable = true
	window.always_on_top = true
	window.min_size = Vector2i(200, 200)

func set_window_topmost(window: Window, topmost: bool) -> void:
	window.always_on_top = topmost

func get_screen_size() -> Vector2i:
	return DisplayServer.screen_get_size()

func is_embed_desktop_supported() -> bool:
	return false  # v0.1 不实现真嵌入桌面（需要 Progman 父窗口技巧）
