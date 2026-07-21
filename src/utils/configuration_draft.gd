class_name ConfigurationDraft
extends RefCounted

const DEFAULT_WORK_MINUTES := 8 * 60
const DEFAULT_LUNCH_MINUTES := 2 * 60

var monthly_salary: float = 0.0
var rest_mode: String = "double"
var alternating_anchor_date: String = ""
var alternating_anchor_week_type: String = "big"
var work_start_time: String = "08:00"
var lunch_start_time: String = "12:00"
var lunch_end_time: String = "14:00"
var work_end_time: String = "18:00"
var work_duration_minutes: int = DEFAULT_WORK_MINUTES
var lunch_duration_minutes: int = DEFAULT_LUNCH_MINUTES


func load_config(source: Dictionary):
	monthly_salary = float(source.get("monthly_salary", 0.0))
	rest_mode = _normalized_rest_mode(String(source.get("rest_mode", "double")))
	alternating_anchor_date = String(source.get("alternating_anchor_date", ""))
	alternating_anchor_week_type = "small" if String(source.get("alternating_anchor_week_type", "big")) == "small" else "big"
	work_start_time = _normalized_time(String(source.get("work_start_time", "08:00")), "08:00")
	lunch_start_time = _normalized_time(String(source.get("lunch_start_time", "12:00")), "12:00")
	lunch_end_time = _normalized_time(String(source.get("lunch_end_time", "14:00")), "14:00")
	work_end_time = _normalized_time(String(source.get("work_end_time", "18:00")), "18:00")
	lunch_duration_minutes = maxi(0, _forward_minutes(lunch_start_time, lunch_end_time))
	var total_span := _forward_minutes(work_start_time, work_end_time)
	work_duration_minutes = maxi(0, total_span - lunch_duration_minutes)
	if work_duration_minutes <= 0:
		work_duration_minutes = DEFAULT_WORK_MINUTES
		_infer_work_end()
	return self


func set_salary(value: float) -> void:
	monthly_salary = maxf(0.0, value)


func set_rest_mode(value: String) -> void:
	rest_mode = _normalized_rest_mode(value)


func set_work_start_time(value: String) -> void:
	work_start_time = _normalized_time(value, work_start_time)
	_infer_work_end()


func set_work_duration_minutes(value: int) -> void:
	work_duration_minutes = clampi(value, 1, 24 * 60)
	_infer_work_end()


func set_lunch_duration_minutes(value: int) -> void:
	lunch_duration_minutes = clampi(value, 0, 8 * 60)
	lunch_end_time = _add_minutes(lunch_start_time, lunch_duration_minutes)
	_infer_work_end()


func set_lunch_start_time(value: String) -> void:
	lunch_start_time = _normalized_time(value, lunch_start_time)
	lunch_end_time = _add_minutes(lunch_start_time, lunch_duration_minutes)


func set_lunch_end_time(value: String) -> void:
	lunch_end_time = _normalized_time(value, lunch_end_time)
	lunch_start_time = _add_minutes(lunch_end_time, -lunch_duration_minutes)


func can_reveal_schedule() -> bool:
	return monthly_salary > 0.0 and rest_mode in ["double", "single", "alternating"]


func can_reveal_lunch() -> bool:
	return can_reveal_schedule() and not work_start_time.is_empty()


func validate() -> Dictionary:
	if monthly_salary <= 0.0:
		return {"valid": false, "field": "monthly_salary", "message": "请输入大于 0 的月薪。"}
	if not rest_mode in ["double", "single", "alternating"]:
		return {"valid": false, "field": "rest_mode", "message": "请选择休息模式。"}
	if work_duration_minutes <= 0:
		return {"valid": false, "field": "work_duration_minutes", "message": "有效工作时长必须大于 0。"}
	if lunch_duration_minutes < 0:
		return {"valid": false, "field": "lunch_duration_minutes", "message": "午休时长不能为负数。"}
	return {"valid": true, "field": "", "message": ""}


func to_config() -> Dictionary:
	return {
		"monthly_salary": monthly_salary,
		"rest_mode": rest_mode,
		"alternating_anchor_date": alternating_anchor_date,
		"alternating_anchor_week_type": alternating_anchor_week_type,
		"work_start_time": work_start_time,
		"lunch_start_time": lunch_start_time,
		"lunch_end_time": lunch_end_time,
		"work_end_time": work_end_time,
		"work_hours_per_day": float(work_duration_minutes) / 60.0
	}


func _infer_work_end() -> void:
	work_end_time = _add_minutes(work_start_time, work_duration_minutes + lunch_duration_minutes)


static func _normalized_rest_mode(value: String) -> String:
	return value if value in ["double", "single", "alternating"] else "double"


static func _normalized_time(value: String, fallback: String) -> String:
	var parts := value.split(":")
	if parts.size() != 2 or not String(parts[0]).is_valid_int() or not String(parts[1]).is_valid_int():
		return fallback
	var hour := int(parts[0])
	var minute := int(parts[1])
	if hour < 0 or hour > 23 or minute < 0 or minute > 59:
		return fallback
	return "%02d:%02d" % [hour, minute]


static func _time_to_minutes(value: String) -> int:
	var normalized := _normalized_time(value, "00:00")
	var parts := normalized.split(":")
	return int(parts[0]) * 60 + int(parts[1])


static func _forward_minutes(start: String, finish: String) -> int:
	var result := _time_to_minutes(finish) - _time_to_minutes(start)
	if result < 0:
		result += 24 * 60
	return result


static func _add_minutes(value: String, delta: int) -> String:
	var total := posmod(_time_to_minutes(value) + delta, 24 * 60)
	return "%02d:%02d" % [total / 60, total % 60]
