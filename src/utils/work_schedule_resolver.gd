class_name WorkScheduleResolver
extends RefCounted

const SalaryScheduleCalculatorScript := preload("res://src/utils/salary_schedule_calculator.gd")

var _calendar: RefCounted


func _init(calendar: RefCounted) -> void:
	_calendar = calendar


func resolve_state(config: Dictionary, now: Dictionary) -> Dictionary:
	if float(config.get("monthly_salary", 0.0)) <= 0.0:
		return {"state": "setup_required", "reason": "salary_unset"}
	var schedule := _schedule(config)
	if not bool(schedule.get("valid", false)):
		return {"state": "setup_required", "reason": "invalid_schedule"}
	var active := _active_shift(config, now, schedule)
	if bool(active.get("inside", false)):
		if bool(active.get("in_lunch", false)):
			return {"state": "awake_rest", "reason": "lunch"}
		return {"state": "working", "reason": "scheduled_work"}
	var now_minutes := int(now.get("hour", 0)) * 60 + int(now.get("minute", 0))
	if now_minutes >= 23 * 60 or now_minutes < 7 * 60 + 30:
		return {"state": "sleeping", "reason": "night"}
	var today_is_workday := is_workday(now, config)
	return {
		"state": "awake_rest",
		"reason": "outside_work" if today_is_workday else "rest_day"
	}


func calculate_snapshot(config: Dictionary, now: Dictionary) -> Dictionary:
	var year := int(now.get("year", 0))
	var month := int(now.get("month", 0))
	var day := int(now.get("day", 0))
	var schedule := _schedule(config)
	var workdays := workday_count(year, month, config)
	var work_minutes := int(schedule.get("effective_minutes", 0))
	var monthly_salary := float(config.get("monthly_salary", 0.0))
	var monthly_minor := roundi(monthly_salary * 100.0)
	var daily_minor := roundi(float(monthly_minor) / float(workdays)) if workdays > 0 else 0
	var hourly_minor := roundi(float(daily_minor) / (float(work_minutes) / 60.0)) if work_minutes > 0 else 0
	var daily_salary := float(daily_minor) / 100.0
	var hourly_rate := float(hourly_minor) / 100.0
	var active := _active_shift(config, now, schedule)
	var elapsed_seconds := _elapsed_for_snapshot(config, now, schedule, active)
	var progress := clampf(float(elapsed_seconds) / float(work_minutes * 60), 0.0, 1.0) if work_minutes > 0 else 0.0
	var completed_workdays := 0
	for previous_day in range(1, day):
		if is_workday({"year": year, "month": month, "day": previous_day}, config):
			completed_workdays += 1
	var today_minor := roundi(float(daily_minor) * progress)
	var today_earnings := float(today_minor) / 100.0
	var state := resolve_state(config, now)
	return {
		"workdays": workdays,
		"effective_work_minutes": work_minutes,
		"daily_salary": daily_salary,
		"hourly_rate": hourly_rate,
		"rate_per_second": hourly_rate / 3600.0,
		"today_is_workday": bool(active.get("owner_is_workday", is_workday(now, config))),
		"elapsed_effective_seconds": elapsed_seconds,
		"progress": progress,
		"today_earnings": today_earnings,
		"month_earnings": float(completed_workdays * daily_minor + today_minor) / 100.0,
		"state": String(state.get("state", "setup_required")),
		"state_reason": String(state.get("reason", "")),
		"calendar_dataset_version": _calendar.get_dataset_version(year)
	}


func effective_work_minutes(config: Dictionary) -> int:
	return int(_schedule(config).get("effective_minutes", 0))


func is_workday(date: Dictionary, config: Dictionary) -> bool:
	var date_key := "%04d-%02d-%02d" % [
		int(date.get("year", 0)),
		int(date.get("month", 0)),
		int(date.get("day", 0))
	]
	for raw_override in config.get("date_overrides", []):
		if raw_override is Dictionary and String(raw_override.get("date", "")) == date_key:
			return bool(raw_override.get("is_workday", raw_override.get("isWorkday", false)))
	var official: Dictionary = _calendar.classify(date)
	match String(official.get("type", "ordinary")):
		"adjusted_workday":
			return true
		"official_holiday":
			return false
	return SalaryScheduleCalculatorScript.is_workday(
		date,
		String(config.get("rest_mode", "double")),
		String(config.get("alternating_anchor_date", "")),
		String(config.get("alternating_anchor_week_type", "big"))
	)


func workday_count(year: int, month: int, config: Dictionary) -> int:
	var count := 0
	for day in range(1, _days_in_month(year, month) + 1):
		if is_workday({"year": year, "month": month, "day": day}, config):
			count += 1
	return count


func _active_shift(config: Dictionary, now: Dictionary, schedule: Dictionary) -> Dictionary:
	if not bool(schedule.get("valid", false)):
		return {"inside": false, "elapsed_seconds": 0}
	var start := int(schedule.start)
	var end := int(schedule.end)
	var now_minutes := int(now.get("hour", 0)) * 60 + int(now.get("minute", 0))
	var now_seconds_remainder := int(now.get("second", 0))
	var owner := _date_only(now)
	var relative_minutes := now_minutes
	if end > 1440:
		if now_minutes < end - 1440:
			owner = _shift_date(owner, -1)
			relative_minutes += 1440
		elif now_minutes < start:
			return {"inside": false, "elapsed_seconds": 0, "owner_is_workday": is_workday(now, config)}
	var owner_is_workday := is_workday(owner, config)
	if not owner_is_workday or relative_minutes < start or relative_minutes >= end:
		return {"inside": false, "elapsed_seconds": 0, "owner_is_workday": owner_is_workday}
	var lunch_start := int(schedule.lunch_start)
	var lunch_end := int(schedule.lunch_end)
	var in_lunch := relative_minutes >= lunch_start and relative_minutes < lunch_end
	var elapsed_minutes := relative_minutes - start
	if relative_minutes >= lunch_end:
		elapsed_minutes -= lunch_end - lunch_start
	elif relative_minutes > lunch_start:
		elapsed_minutes -= relative_minutes - lunch_start
	return {
		"inside": true,
		"in_lunch": in_lunch,
		"owner_is_workday": true,
		"elapsed_seconds": maxi(0, elapsed_minutes * 60 + (0 if in_lunch else now_seconds_remainder))
	}


func _elapsed_for_snapshot(config: Dictionary, now: Dictionary, schedule: Dictionary, active: Dictionary) -> int:
	if bool(active.get("inside", false)):
		return int(active.get("elapsed_seconds", 0))
	if not bool(schedule.get("valid", false)):
		return 0
	var now_minutes := int(now.get("hour", 0)) * 60 + int(now.get("minute", 0))
	var start := int(schedule.start)
	var end := int(schedule.end)
	if end <= 1440:
		return int(schedule.effective_minutes) * 60 if is_workday(now, config) and now_minutes >= end else 0
	var overnight_end := end - 1440
	if now_minutes >= overnight_end and now_minutes < start:
		var owner := _shift_date(_date_only(now), -1)
		return int(schedule.effective_minutes) * 60 if is_workday(owner, config) else 0
	return 0


func _schedule(config: Dictionary) -> Dictionary:
	var start := SalaryScheduleCalculatorScript.time_to_minutes(String(config.get("work_start_time", "08:00")))
	var end := SalaryScheduleCalculatorScript.time_to_minutes(String(config.get("work_end_time", "18:00")))
	var lunch_start := SalaryScheduleCalculatorScript.time_to_minutes(String(config.get("lunch_start_time", "12:00")))
	var lunch_end := SalaryScheduleCalculatorScript.time_to_minutes(String(config.get("lunch_end_time", "14:00")))
	if start < 0 or end < 0 or lunch_start < 0 or lunch_end < 0:
		return {"valid": false}
	if end <= start:
		end += 1440
	while lunch_start < start:
		lunch_start += 1440
	while lunch_end <= lunch_start:
		lunch_end += 1440
	if lunch_start < start or lunch_end > end:
		return {"valid": false}
	var effective_minutes := end - start - (lunch_end - lunch_start)
	if effective_minutes <= 0:
		return {"valid": false}
	return {
		"valid": true,
		"start": start,
		"end": end,
		"lunch_start": lunch_start,
		"lunch_end": lunch_end,
		"effective_minutes": effective_minutes
	}


func _date_only(value: Dictionary) -> Dictionary:
	return {
		"year": int(value.get("year", 0)),
		"month": int(value.get("month", 0)),
		"day": int(value.get("day", 0))
	}


func _shift_date(date: Dictionary, days: int) -> Dictionary:
	var unix := Time.get_unix_time_from_datetime_string("%04d-%02d-%02dT12:00:00" % [date.year, date.month, date.day])
	var shifted := Time.get_date_dict_from_unix_time(int(unix) + days * 86400)
	return {"year": int(shifted.year), "month": int(shifted.month), "day": int(shifted.day)}


func _days_in_month(year: int, month: int) -> int:
	match month:
		2:
			return 29 if (year % 4 == 0 and year % 100 != 0) or year % 400 == 0 else 28
		4, 6, 9, 11:
			return 30
		_:
			return 31
