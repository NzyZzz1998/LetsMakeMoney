# src/autoload/salary_engine.gd
extends Node

var monthly_salary: float = 0.0
var rest_mode: String = "double"
var work_hours_per_day: float = 8.0
var work_start_time: String = "09:00"
var work_end_time: String = "18:00"

var rate_per_second: float = 0.0
var hourly_rate: float = 0.0
var work_days_this_month: int = 0

var _last_year: int = 0
var _last_month: int = 0
var _last_day: int = 0


func _ready() -> void:
	_load_from_config()


func _process(_delta: float) -> void:
	var today := Time.get_datetime_dict_from_system()
	var t_year: int = int(today.year)
	var t_month: int = int(today.month)
	var t_day: int = int(today.day)
	if t_year != _last_year or t_month != _last_month or t_day != _last_day:
		_recalculate()


func _load_from_config() -> void:
	monthly_salary = float(Config.get_value("monthly_salary", 0))
	rest_mode = String(Config.get_value("rest_mode", "double"))
	work_start_time = String(Config.get_value("work_start_time", "09:00"))
	work_end_time = String(Config.get_value("work_end_time", "18:00"))
	work_hours_per_day = _calc_work_hours_from_times(work_start_time, work_end_time)
	_recalculate()


func reload() -> void:
	_load_from_config()


func _recalculate() -> void:
	var today := Time.get_datetime_dict_from_system()
	_last_year = int(today.year)
	_last_month = int(today.month)
	_last_day = int(today.day)
	work_days_this_month = _calc_work_days(_last_year, _last_month, rest_mode)
	if work_days_this_month > 0 and work_hours_per_day > 0:
		hourly_rate = monthly_salary / float(work_days_this_month * work_hours_per_day)
		rate_per_second = hourly_rate / 3600.0
	else:
		hourly_rate = 0.0
		rate_per_second = 0.0


func _calc_work_days(year: int, month: int, mode: String) -> int:
	var days := _days_in_month(year, month)
	var count := 0
	for d in range(1, days + 1):
		var date_str := "%04d-%02d-%02dT12:00:00" % [year, month, d]
		var unix_time := Time.get_unix_time_from_datetime_string(date_str)
		var dt := Time.get_date_dict_from_unix_time(int(unix_time))
		var weekday: int = int(dt.weekday)
		match mode:
			"double":
				if weekday != 0 and weekday != 6:
					count += 1
			"single":
				if weekday != 0:
					count += 1
			_:
				count += 1
	return count


func _days_in_month(year: int, month: int) -> int:
	match month:
		2:
			if (year % 4 == 0 and year % 100 != 0) or (year % 400 == 0):
				return 29
			return 28
		4, 6, 9, 11:
			return 30
		_:
			return 31


func is_working_hours() -> bool:
	if monthly_salary <= 0:
		return false
	var start_min := _time_str_to_minutes(work_start_time)
	var end_min := _time_str_to_minutes(work_end_time)
	if start_min < 0 or end_min < 0 or end_min <= start_min:
		return false
	var now := Time.get_datetime_dict_from_system()
	var now_min: int = int(now.hour) * 60 + int(now.minute)
	return now_min >= start_min and now_min < end_min


func _time_str_to_minutes(s: String) -> int:
	var parts := s.split(":")
	if parts.size() < 2:
		return -1
	return int(parts[0]) * 60 + int(parts[1])


func _calc_work_hours_from_times(start_time: String, end_time: String) -> float:
	var start_min := _time_str_to_minutes(start_time)
	var end_min := _time_str_to_minutes(end_time)
	if start_min < 0 or end_min < 0 or end_min <= start_min:
		return 0.0
	return float(end_min - start_min) / 60.0


func get_earnings_today() -> float:
	if monthly_salary <= 0:
		return 0.0
	var start_min := _time_str_to_minutes(work_start_time)
	var end_min := _time_str_to_minutes(work_end_time)
	if start_min < 0 or end_min < 0 or end_min <= start_min:
		return 0.0
	var now := Time.get_datetime_dict_from_system()
	var now_seconds: int = int(now.hour) * 3600 + int(now.minute) * 60 + int(now.second)
	var start_seconds := start_min * 60
	var end_seconds := end_min * 60

	if now_seconds < start_seconds:
		return 0.0
	if now_seconds >= end_seconds:
		return float(end_seconds - start_seconds) * rate_per_second
	var elapsed: int = now_seconds - start_seconds
	return float(elapsed) * rate_per_second


func get_earnings_this_month() -> float:
	if monthly_salary <= 0:
		return 0.0
	var now := Time.get_datetime_dict_from_system()
	var days_in_month := _days_in_month(int(now.year), int(now.month))
	return monthly_salary * (float(int(now.day)) / float(days_in_month))


func get_work_progress() -> float:
	if monthly_salary <= 0:
		return 0.0
	var start_min := _time_str_to_minutes(work_start_time)
	var end_min := _time_str_to_minutes(work_end_time)
	if start_min < 0 or end_min < 0 or end_min <= start_min:
		return 0.0
	var now := Time.get_datetime_dict_from_system()
	var now_seconds: int = int(now.hour) * 3600 + int(now.minute) * 60 + int(now.second)
	var start_seconds := start_min * 60
	var end_seconds := end_min * 60
	if now_seconds < start_seconds:
		return 0.0
	if now_seconds >= end_seconds:
		return 1.0
	return clamp(float(now_seconds - start_seconds) / float(end_seconds - start_seconds), 0.0, 1.0)


func get_rate_per_second() -> float:
	return rate_per_second


func get_hourly_rate() -> float:
	return hourly_rate


func get_work_days_this_month() -> int:
	return work_days_this_month


func get_work_hours_per_day() -> float:
	return work_hours_per_day


func get_work_time_range_text() -> String:
	return "%s-%s" % [work_start_time, work_end_time]


func get_state_text() -> String:
	if monthly_salary <= 0:
		return "未设置薪资"
	if is_working_hours():
		return "努力工作中"
	var now := Time.get_datetime_dict_from_system()
	var now_min: int = int(now.hour) * 60 + int(now.minute)
	var start_min := _time_str_to_minutes(work_start_time)
	var end_min := _time_str_to_minutes(work_end_time)
	if now_min < start_min:
		return "还没上班"
	if now_min >= end_min:
		return "已下班休息"
	return "休息中"
