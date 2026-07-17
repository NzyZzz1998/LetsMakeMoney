class_name SalaryScheduleCalculator
extends RefCounted


static func time_to_minutes(value: String) -> int:
	var parts := value.split(":")
	if parts.size() != 2:
		return -1
	if not String(parts[0]).is_valid_int() or not String(parts[1]).is_valid_int():
		return -1
	var hour := int(parts[0])
	var minute := int(parts[1])
	if hour < 0 or hour > 23 or minute < 0 or minute > 59:
		return -1
	return hour * 60 + minute


static func effective_work_minutes(
	work_start: String,
	work_end: String,
	lunch_start: String,
	lunch_end: String
) -> int:
	var boundaries := _schedule_boundaries(work_start, work_end, lunch_start, lunch_end)
	if not bool(boundaries.get("valid", false)):
		return 0
	return int(boundaries.end) - int(boundaries.start) - int(boundaries.lunch_duration)


static func effective_elapsed_seconds(
	now_seconds: int,
	work_start: String,
	work_end: String,
	lunch_start: String,
	lunch_end: String
) -> int:
	var boundaries := _schedule_boundaries(work_start, work_end, lunch_start, lunch_end)
	if not bool(boundaries.get("valid", false)):
		return 0
	var start_seconds := int(boundaries.start) * 60
	var end_seconds := int(boundaries.end) * 60
	if now_seconds <= start_seconds:
		return 0
	if int(boundaries.lunch_duration) <= 0:
		return mini(now_seconds, end_seconds) - start_seconds
	var lunch_start_seconds := int(boundaries.lunch_start) * 60
	var lunch_end_seconds := int(boundaries.lunch_end) * 60
	var before_lunch := clampi(now_seconds - start_seconds, 0, lunch_start_seconds - start_seconds)
	var after_lunch := clampi(now_seconds - lunch_end_seconds, 0, end_seconds - lunch_end_seconds)
	return before_lunch + after_lunch


static func is_workday(
	date: Dictionary,
	rest_mode: String,
	alternating_anchor_date: String,
	alternating_anchor_week_type: String
) -> bool:
	var weekday := _weekday(int(date.get("year", 0)), int(date.get("month", 0)), int(date.get("day", 0)))
	if weekday < 0 or weekday == 0:
		return false
	if weekday >= 1 and weekday <= 5:
		return true
	match rest_mode:
		"single":
			return weekday == 6
		"alternating":
			return weekday == 6 and is_big_week(date, alternating_anchor_date, alternating_anchor_week_type)
		_:
			return false


static func workday_count(
	year: int,
	month: int,
	rest_mode: String,
	alternating_anchor_date: String,
	alternating_anchor_week_type: String
) -> int:
	var count := 0
	for day in range(1, _days_in_month(year, month) + 1):
		if is_workday({"year": year, "month": month, "day": day}, rest_mode, alternating_anchor_date, alternating_anchor_week_type):
			count += 1
	return count


static func week_anchor_date(date: Dictionary) -> String:
	var year := int(date.get("year", 0))
	var month := int(date.get("month", 0))
	var day := int(date.get("day", 0))
	var current_unix := _date_unix(year, month, day)
	if current_unix < 0:
		return ""
	var weekday := _weekday(year, month, day)
	var days_since_monday := 6 if weekday == 0 else weekday - 1
	var monday := Time.get_date_dict_from_unix_time(current_unix - days_since_monday * 86400)
	return "%04d-%02d-%02d" % [int(monday.year), int(monday.month), int(monday.day)]


static func calculate_snapshot(
	monthly_salary: float,
	now: Dictionary,
	rest_mode: String,
	work_start: String,
	work_end: String,
	lunch_start: String,
	lunch_end: String,
	alternating_anchor_date: String,
	alternating_anchor_week_type: String
) -> Dictionary:
	var year := int(now.get("year", 0))
	var month := int(now.get("month", 0))
	var day := int(now.get("day", 0))
	var workdays := workday_count(year, month, rest_mode, alternating_anchor_date, alternating_anchor_week_type)
	var work_minutes := effective_work_minutes(work_start, work_end, lunch_start, lunch_end)
	var daily_salary := monthly_salary / float(workdays) if workdays > 0 else 0.0
	var hourly_rate := daily_salary / (float(work_minutes) / 60.0) if work_minutes > 0 else 0.0
	var today_is_workday := is_workday(now, rest_mode, alternating_anchor_date, alternating_anchor_week_type)
	var elapsed_seconds := 0
	if today_is_workday:
		var now_seconds := int(now.get("hour", 0)) * 3600 + int(now.get("minute", 0)) * 60 + int(now.get("second", 0))
		elapsed_seconds = effective_elapsed_seconds(now_seconds, work_start, work_end, lunch_start, lunch_end)
	var total_seconds := work_minutes * 60
	var progress: float = clampf(float(elapsed_seconds) / float(total_seconds), 0.0, 1.0) if total_seconds > 0 else 0.0
	var today_earnings: float = daily_salary * progress
	var completed_workdays := 0
	for previous_day in range(1, day):
		if is_workday({"year": year, "month": month, "day": previous_day}, rest_mode, alternating_anchor_date, alternating_anchor_week_type):
			completed_workdays += 1
	return {
		"workdays": workdays,
		"effective_work_minutes": work_minutes,
		"daily_salary": daily_salary,
		"hourly_rate": hourly_rate,
		"rate_per_second": hourly_rate / 3600.0,
		"today_is_workday": today_is_workday,
		"elapsed_effective_seconds": elapsed_seconds,
		"progress": progress,
		"today_earnings": today_earnings,
		"month_earnings": float(completed_workdays) * daily_salary + today_earnings,
		"state": state_at(now, monthly_salary, rest_mode, work_start, work_end, lunch_start, lunch_end, alternating_anchor_date, alternating_anchor_week_type)
	}


static func state_at(
	now: Dictionary,
	monthly_salary: float,
	rest_mode: String,
	work_start: String,
	work_end: String,
	lunch_start: String,
	lunch_end: String,
	alternating_anchor_date: String,
	alternating_anchor_week_type: String
) -> String:
	if monthly_salary <= 0.0:
		return "unset"
	if not is_workday(now, rest_mode, alternating_anchor_date, alternating_anchor_week_type):
		return "rest_day"
	var boundaries := _schedule_boundaries(work_start, work_end, lunch_start, lunch_end)
	if not bool(boundaries.get("valid", false)):
		return "invalid_schedule"
	var now_minutes := int(now.get("hour", 0)) * 60 + int(now.get("minute", 0))
	if now_minutes < int(boundaries.start):
		return "before_work"
	if now_minutes >= int(boundaries.end):
		return "after_work"
	if int(boundaries.lunch_duration) > 0 and now_minutes >= int(boundaries.lunch_start) and now_minutes < int(boundaries.lunch_end):
		return "lunch"
	return "working"


static func _schedule_boundaries(work_start: String, work_end: String, lunch_start: String, lunch_end: String) -> Dictionary:
	var start := time_to_minutes(work_start)
	var end := time_to_minutes(work_end)
	var lunch_from := time_to_minutes(lunch_start)
	var lunch_to := time_to_minutes(lunch_end)
	if start < 0 or end <= start:
		return {"valid": false}
	var valid_lunch := lunch_from >= start and lunch_to >= lunch_from and lunch_to <= end
	if not valid_lunch:
		return {"valid": false}
	return {
		"valid": true,
		"start": start,
		"end": end,
		"lunch_start": lunch_from,
		"lunch_end": lunch_to,
		"lunch_duration": lunch_to - lunch_from
	}


static func is_big_week(date: Dictionary, anchor_date: String, anchor_week_type: String) -> bool:
	var anchor := _parse_date(anchor_date)
	if anchor.is_empty():
		return false
	var current_unix := _date_unix(int(date.year), int(date.month), int(date.day))
	var anchor_unix := _date_unix(int(anchor.year), int(anchor.month), int(anchor.day))
	if current_unix < 0 or anchor_unix < 0:
		return false
	var week_offset := floori(float(current_unix - anchor_unix) / 604800.0)
	var anchor_is_big := anchor_week_type == "big"
	return anchor_is_big if posmod(week_offset, 2) == 0 else not anchor_is_big


static func _parse_date(value: String) -> Dictionary:
	var parts := value.split("-")
	if parts.size() != 3:
		return {}
	if not String(parts[0]).is_valid_int() or not String(parts[1]).is_valid_int() or not String(parts[2]).is_valid_int():
		return {}
	return {"year": int(parts[0]), "month": int(parts[1]), "day": int(parts[2])}


static func _weekday(year: int, month: int, day: int) -> int:
	var unix_time := _date_unix(year, month, day)
	if unix_time < 0:
		return -1
	return int(Time.get_date_dict_from_unix_time(unix_time).weekday)


static func _date_unix(year: int, month: int, day: int) -> int:
	if year <= 0 or month < 1 or month > 12 or day < 1 or day > _days_in_month(year, month):
		return -1
	return int(Time.get_unix_time_from_datetime_string("%04d-%02d-%02dT12:00:00" % [year, month, day]))


static func _days_in_month(year: int, month: int) -> int:
	match month:
		2:
			return 29 if (year % 4 == 0 and year % 100 != 0) or year % 400 == 0 else 28
		4, 6, 9, 11:
			return 30
		_:
			return 31
