class_name HolidayCalendar
extends RefCounted

signal dataset_issue(kind: String, year: int)

var _root_path: String
var _years: Dictionary = {}


func _init(root_path: String = "res://assets/calendar/cn") -> void:
	_root_path = root_path.trim_suffix("/")


func has_year(year: int) -> bool:
	return bool(_load_year(year).get("valid", false))


func classify(date: Dictionary) -> Dictionary:
	var year := int(date.get("year", 0))
	var dataset := _load_year(year)
	if not bool(dataset.get("valid", false)):
		return {
			"covered": false,
			"type": "uncovered",
			"name": "",
			"dataset_version": ""
		}
	var key := _date_key(date)
	var entry: Dictionary = dataset.get("entries", {}).get(key, {})
	if entry.is_empty():
		return {
			"covered": true,
			"type": "ordinary",
			"name": "",
			"dataset_version": String(dataset.get("dataset_id", ""))
		}
	return {
		"covered": true,
		"type": String(entry.get("type", "ordinary")),
		"name": String(entry.get("name", "")),
		"dataset_version": String(dataset.get("dataset_id", ""))
	}


func get_dataset_version(year: int) -> String:
	return String(_load_year(year).get("dataset_id", ""))


func _load_year(year: int) -> Dictionary:
	if _years.has(year):
		return _years[year]
	var result := {"valid": false, "dataset_id": "", "entries": {}}
	var path := "%s/%d.json" % [_root_path, year]
	if not FileAccess.file_exists(path):
		dataset_issue.emit("missing", year)
		_years[year] = result
		return result
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		dataset_issue.emit("open_failed", year)
		_years[year] = result
		return result
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if not parsed is Dictionary:
		dataset_issue.emit("invalid_json", year)
		_years[year] = result
		return result
	var document: Dictionary = parsed
	if int(document.get("schema_version", 0)) != 1 or int(document.get("year", 0)) != year:
		dataset_issue.emit("invalid_schema", year)
		_years[year] = result
		return result
	var entries: Dictionary = {}
	for raw_entry in document.get("entries", []):
		if not raw_entry is Dictionary:
			dataset_issue.emit("invalid_entry", year)
			_years[year] = result
			return result
		var entry: Dictionary = raw_entry
		var entry_type := String(entry.get("type", ""))
		var date_text := String(entry.get("date", ""))
		if date_text.length() != 10 or not entry_type in ["official_holiday", "adjusted_workday"]:
			dataset_issue.emit("invalid_entry", year)
			_years[year] = result
			return result
		entries[date_text] = entry.duplicate(true)
	result = {
		"valid": true,
		"dataset_id": String(document.get("dataset_id", "")),
		"entries": entries
	}
	_years[year] = result
	return result


func _date_key(date: Dictionary) -> String:
	return "%04d-%02d-%02d" % [
		int(date.get("year", 0)),
		int(date.get("month", 0)),
		int(date.get("day", 0))
	]
