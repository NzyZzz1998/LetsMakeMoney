extends RefCounted

const AppVersionScript := preload("res://src/utils/app_version.gd")
const MAX_LOG_SCAN_BYTES := 64 * 1024
const CLIPBOARD_READBACK_ATTEMPTS := 3
const CLIPBOARD_READBACK_DELAY_SECONDS := 0.04
const SEMANTIC_MARKERS := [
	"settings_", "wizard_", "tray_", "window_policy_", "passthrough_",
	"config_", "app_started", "pure_pet_mode_"
]


static func get_app_data_directory() -> String:
	var appdata := OS.get_environment("APPDATA")
	if appdata.is_empty():
		appdata = OS.get_user_data_dir()
	return appdata.path_join("LetsMakeMoney")


static func open_app_data_directory() -> Dictionary:
	var path := get_app_data_directory()
	if not DirAccess.dir_exists_absolute(path):
		var mkdir_error := DirAccess.make_dir_recursive_absolute(path)
		if mkdir_error != OK:
			return {"ok": false, "error": "无法创建应用数据目录：%s" % error_string(mkdir_error)}
	var open_error := OS.shell_open(path)
	if open_error != OK:
		return {"ok": false, "error": "无法打开应用数据目录：%s" % error_string(open_error)}
	return {"ok": true, "path": path}


static func build_summary(config: Dictionary, native_health: Dictionary) -> String:
	var data_dir := get_app_data_directory()
	var log_path := data_dir.path_join("debug.log")
	var backup_path := data_dir.path_join("debug.log.1")
	var screenshot_meta := _directory_metadata(data_dir.path_join("interaction-screenshots"))
	var lines: Array[String] = [
		"LetsMakeMoney 诊断摘要",
		"版本：%s" % AppVersionScript.get_display_version(),
		"系统：%s" % OS.get_name(),
		"窗口模式：%s" % String(config.get("window_mode", "top")),
		"纯桌宠：%s" % _yes_no(bool(config.get("pure_pet_mode", false))),
		"关闭隐藏到托盘：%s" % _yes_no(bool(config.get("minimize_to_tray", true))),
		"Debug：%s" % _yes_no(bool(config.get("debug_mode", false))),
		"开机自启配置：%s" % _yes_no(bool(config.get("auto_start", false))),
		"桌宠：%s" % String(config.get("pet_id", "unknown")),
		"托盘能力：%s" % _available(native_health, "tray_supported"),
		"点击穿透能力：%s" % _available(native_health, "passthrough_supported"),
		"日志：current=%s, backup=%s" % [_file_metadata(log_path), _file_metadata(backup_path)],
		"交互截图：count=%d, bytes=%d" % [int(screenshot_meta.get("count", 0)), int(screenshot_meta.get("bytes", 0))],
		"最近语义事件：%s" % _find_latest_semantic_event([log_path, backup_path])
	]
	return "\n".join(lines)


static func copy_summary_to_clipboard(summary: String) -> Dictionary:
	if summary.is_empty():
		return {"ok": false, "error": "诊断摘要为空。"}
	if DisplayServer.get_name().to_lower() == "headless":
		return {"ok": false, "error": "当前运行环境不支持剪贴板。"}
	DisplayServer.clipboard_set(summary)
	var readbacks: Array[String] = []
	for attempt in range(CLIPBOARD_READBACK_ATTEMPTS):
		readbacks.append(DisplayServer.clipboard_get())
		if _normalize_clipboard_text(readbacks[-1]) == _normalize_clipboard_text(summary):
			break
		if attempt + 1 < CLIPBOARD_READBACK_ATTEMPTS:
			await Engine.get_main_loop().create_timer(CLIPBOARD_READBACK_DELAY_SECONDS).timeout
	return classify_clipboard_write_result(summary, readbacks)


static func classify_clipboard_write_result(summary: String, readbacks: Array[String], write_error: String = "") -> Dictionary:
	if not write_error.is_empty():
		return {"ok": false, "error": write_error}
	var normalized_summary := _normalize_clipboard_text(summary)
	for read_back in readbacks:
		if _normalize_clipboard_text(read_back) == normalized_summary:
			return {"ok": true, "verified": true, "verification_uncertain": false}
	return {
		"ok": true,
		"verified": false,
		"verification_uncertain": true,
		"warning": "剪贴板写入已请求，但系统暂未返回可校验内容。"
	}


static func _normalize_clipboard_text(value: String) -> String:
	return value.replace("\r\n", "\n").replace("\r", "\n")


static func _find_latest_semantic_event(paths: Array[String]) -> String:
	for path in paths:
		var text := _read_bounded_tail(path)
		if text.is_empty():
			continue
		var lines := text.split("\n", false)
		for index in range(lines.size() - 1, -1, -1):
			var line := String(lines[index]).strip_edges()
			for marker in SEMANTIC_MARKERS:
				if line.contains(marker):
					return _redact_event(line)
	return "无可用语义事件"


static func _read_bounded_tail(path: String) -> String:
	if not FileAccess.file_exists(path):
		return ""
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return ""
	var length := file.get_length()
	file.seek(maxi(0, length - MAX_LOG_SCAN_BYTES))
	var text := file.get_buffer(mini(MAX_LOG_SCAN_BYTES, length)).get_string_from_utf8()
	file.close()
	return text


static func _redact_event(line: String) -> String:
	var parts := line.split(" | ", false, 3)
	return String(parts[parts.size() - 1]) if not parts.is_empty() else "无可用语义事件"


static func _file_metadata(path: String) -> String:
	if not FileAccess.file_exists(path):
		return "missing"
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return "unavailable"
	var length := file.get_length()
	file.close()
	return "%d bytes" % length


static func _directory_metadata(path: String) -> Dictionary:
	var result := {"count": 0, "bytes": 0}
	var dir := DirAccess.open(path)
	if dir == null:
		return result
	dir.list_dir_begin()
	var name := dir.get_next()
	while not name.is_empty():
		if not dir.current_is_dir():
			result["count"] = int(result["count"]) + 1
			var file := FileAccess.open(path.path_join(name), FileAccess.READ)
			if file != null:
				result["bytes"] = int(result["bytes"]) + file.get_length()
				file.close()
		name = dir.get_next()
	dir.list_dir_end()
	return result


static func _yes_no(value: bool) -> String:
	return "是" if value else "否"


static func _available(health: Dictionary, key: String) -> String:
	return "可用" if bool(health.get(key, false)) else "不可用"
