extends SceneTree


func _init() -> void:
	var source := FileAccess.get_file_as_string("res://main.gd")
	var failures: Array[String] = []
	for required in [
		"const MINI_SIZE := Vector2i(344, 120)",
		"const WORKBENCH_SIZE := Vector2i(820, 620)",
		"const SETTINGS_SIZE := Vector2i(720, 540)",
		"保存失败：配置文件暂时不可写，输入已保留",
		"没有需要保存的更改",
		"已保存到本机",
		"ClassDB.class_exists(\"StatusIndicator\")",
		"_hide_to_tray",
		"_restore_from_tray"
	]:
		if not source.contains(required):
			failures.append(required)
	if failures.is_empty():
		print("GODOT_SPIKE_VERIFY_OK")
		quit(0)
	else:
		for failure in failures:
			push_error("Missing contract: %s" % failure)
		quit(1)

