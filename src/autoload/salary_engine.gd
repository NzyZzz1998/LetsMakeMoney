extends Node

const SalaryScheduleCalculatorScript := preload("res://src/utils/salary_schedule_calculator.gd")

var monthly_salary: float = 0.0
var rest_mode: String = "double"
var work_hours_per_day: float = 8.0
var work_start_time: String = "08:00"
var work_end_time: String = "18:00"
var lunch_start_time: String = "12:00"
var lunch_end_time: String = "14:00"
var alternating_anchor_date: String = ""
var alternating_anchor_week_type: String = "big"

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
	if int(today.year) != _last_year or int(today.month) != _last_month or int(today.day) != _last_day:
		_recalculate()


func _load_from_config() -> void:
	monthly_salary = float(Config.get_value("monthly_salary", 0.0))
	rest_mode = String(Config.get_value("rest_mode", "double"))
	work_start_time = String(Config.get_value("work_start_time", "08:00"))
	work_end_time = String(Config.get_value("work_end_time", "18:00"))
	lunch_start_time = String(Config.get_value("lunch_start_time", "12:00"))
	lunch_end_time = String(Config.get_value("lunch_end_time", "14:00"))
	alternating_anchor_date = String(Config.get_value("alternating_anchor_date", ""))
	alternating_anchor_week_type = String(Config.get_value("alternating_anchor_week_type", "big"))
	work_hours_per_day = float(SalaryScheduleCalculatorScript.effective_work_minutes(
		work_start_time,
		work_end_time,
		lunch_start_time,
		lunch_end_time
	)) / 60.0
	_recalculate()


func reload() -> void:
	_load_from_config()


func _recalculate() -> void:
	var today := Time.get_datetime_dict_from_system()
	_last_year = int(today.year)
	_last_month = int(today.month)
	_last_day = int(today.day)
	var snapshot := calculate_for_datetime(today)
	work_days_this_month = int(snapshot.get("workdays", 0))
	hourly_rate = float(snapshot.get("hourly_rate", 0.0))
	rate_per_second = float(snapshot.get("rate_per_second", 0.0))


func calculate_for_datetime(datetime: Dictionary) -> Dictionary:
	return SalaryScheduleCalculatorScript.calculate_snapshot(
		monthly_salary,
		datetime,
		rest_mode,
		work_start_time,
		work_end_time,
		lunch_start_time,
		lunch_end_time,
		alternating_anchor_date,
		alternating_anchor_week_type
	)


func _current_snapshot() -> Dictionary:
	return calculate_for_datetime(Time.get_datetime_dict_from_system())


func _calc_work_days(year: int, month: int, mode: String) -> int:
	return SalaryScheduleCalculatorScript.workday_count(
		year,
		month,
		mode,
		alternating_anchor_date,
		alternating_anchor_week_type
	)


func _days_in_month(year: int, month: int) -> int:
	match month:
		2:
			return 29 if (year % 4 == 0 and year % 100 != 0) or year % 400 == 0 else 28
		4, 6, 9, 11:
			return 30
		_:
			return 31


func is_working_hours() -> bool:
	return String(_current_snapshot().get("state", "")) == "working"


func _time_str_to_minutes(value: String) -> int:
	return SalaryScheduleCalculatorScript.time_to_minutes(value)


func _calc_work_hours_from_times(start_time: String, end_time: String) -> float:
	return float(SalaryScheduleCalculatorScript.effective_work_minutes(
		start_time,
		end_time,
		lunch_start_time,
		lunch_end_time
	)) / 60.0


func get_earnings_today() -> float:
	return float(_current_snapshot().get("today_earnings", 0.0))


func get_earnings_this_month() -> float:
	return float(_current_snapshot().get("month_earnings", 0.0))


func get_work_progress() -> float:
	return float(_current_snapshot().get("progress", 0.0))


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


func get_lunch_time_range_text() -> String:
	return "%s-%s" % [lunch_start_time, lunch_end_time]


func get_state_text() -> String:
	match String(_current_snapshot().get("state", "unset")):
		"working":
			return "努力工作中"
		"lunch":
			return "午休中"
		"before_work":
			return "还没上班"
		"after_work":
			return "已下班休息"
		"rest_day":
			return "今天休息"
		"invalid_schedule":
			return "作息设置有误"
		_:
			return "未设置薪资"
