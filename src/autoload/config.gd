# src/autoload/config.gd
extends Node

signal config_changed

var data: Dictionary = {}
var _config_path: String = ""
var _defaults_cache: Dictionary = {}


func _ready() -> void:
	Platform.write_boot_log("Config._ready: begin")
	_config_path = Platform.get_config_path()
	_ensure_dir()
	_load()
	Platform.write_boot_log("Config._ready: loaded debug_mode=%s transparent=%s passthrough=%s tray=%s" % [
		str(get_value("debug_mode", false)),
		str(get_value("transparent_pet_window_enabled", false)),
		str(get_value("mouse_passthrough_enabled", false)),
		str(get_value("system_tray_enabled", false))
	])


func _ensure_dir() -> void:
	var dir_path := _config_path.get_base_dir()
	if not DirAccess.dir_exists_absolute(dir_path):
		DirAccess.make_dir_recursive_absolute(dir_path)


func _load() -> void:
	if not FileAccess.file_exists(_config_path):
		data = _defaults().duplicate(true)
		return

	var file := FileAccess.open(_config_path, FileAccess.READ)
	if file == null:
		data = _defaults().duplicate(true)
		return

	var json_string := file.get_as_text()
	file.close()
	var parsed = JSON.parse_string(json_string)
	if parsed is Dictionary:
		data = merge_with_defaults(parsed)
	else:
		data = _defaults().duplicate(true)


func merge_with_defaults(source: Dictionary) -> Dictionary:
	var merged := _defaults().duplicate(true)
	_merge_dict(merged, source)
	return merged


func _merge_dict(target: Dictionary, source: Dictionary) -> void:
	for key in source:
		if target.has(key) and typeof(target[key]) == TYPE_DICTIONARY and typeof(source[key]) == TYPE_DICTIONARY:
			_merge_dict(target[key], source[key])
		else:
			target[key] = source[key]


func _defaults() -> Dictionary:
	if _defaults_cache.is_empty():
		_defaults_cache = {
			"monthly_salary": 0,
			"rest_mode": "double",
			"work_hours_per_day": 8.0,
			"work_start_time": "09:00",
			"work_end_time": "18:00",
			"pet_id": "cat",
			"window_x": -1,
			"window_y": -1,
			"window_mode": "top",
			"debug_mode": false,
			"auto_start": false,
			"minimize_to_tray": true,
			"system_tray_enabled": false,
			"mouse_passthrough_enabled": false,
			"transparent_pet_window_enabled": false,
			"opacity": 1.0,
			"scale": 1.0,
			"panel_items": {
				"earnings_today": true,
				"earnings_month": true,
				"hourly_rate": true,
				"work_progress": true,
				"status": true
			}
		}
	return _defaults_cache


func save() -> void:
	var file := FileAccess.open(_config_path, FileAccess.WRITE)
	if file == null:
		push_error("Failed to save config to: %s" % _config_path)
		return
	file.store_string(JSON.stringify(data, "\t"))
	file.close()
	config_changed.emit()


func get_value(key: String, default: Variant = null) -> Variant:
	if data.has(key):
		return data[key]
	var def := _defaults()
	if def.has(key):
		return def[key]
	return default


func set_value(key: String, value: Variant) -> void:
	data[key] = value


func has_config() -> bool:
	return FileAccess.file_exists(_config_path)


func get_panel_item(key: String) -> bool:
	var items: Dictionary = data.get("panel_items", {})
	return bool(items.get(key, true))


func set_panel_item(key: String, visible: bool) -> void:
	if not data.has("panel_items"):
		data["panel_items"] = {}
	data["panel_items"][key] = visible


func reset_display_defaults() -> void:
	var defaults := _defaults()
	for key in [
		"window_x",
		"window_y",
		"window_mode",
		"debug_mode",
		"auto_start",
		"minimize_to_tray",
		"system_tray_enabled",
		"mouse_passthrough_enabled",
		"transparent_pet_window_enabled",
		"opacity",
		"scale"
	]:
		data[key] = defaults[key]
