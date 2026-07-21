extends RefCounted
class_name PetBusinessEventTracker

const DEFAULT_MILESTONE_STEP := 100.0

var _milestone_step := DEFAULT_MILESTONE_STEP
var _date_key := ""
var _previous_snapshot: Dictionary = {}
var _emitted_keys: Dictionary = {}
var _last_milestone_bucket := 0


func _init(milestone_step: float = DEFAULT_MILESTONE_STEP) -> void:
	_milestone_step = maxf(milestone_step, 0.01)


func observe(snapshot: Dictionary, date_key: String) -> Array:
	if _date_key != date_key or _previous_snapshot.is_empty():
		_begin_day(snapshot, date_key)
		return []

	var events: Array = []
	var previous_state := String(_previous_snapshot.get("state", ""))
	var previous_reason := String(_previous_snapshot.get("state_reason", ""))
	var current_state := String(snapshot.get("state", ""))
	var current_reason := String(snapshot.get("state_reason", ""))

	if previous_reason == "scheduled_work" and current_reason == "lunch":
		_append_once(events, "lunch_started", "lunch_started", snapshot)
	elif previous_reason == "lunch" and current_reason == "scheduled_work":
		_append_once(events, "work_resumed", "work_resumed", snapshot)
	elif previous_reason in ["scheduled_work", "lunch"] and current_reason not in ["scheduled_work", "lunch"]:
		if previous_state in ["working", "awake_rest"] and current_state != "working" and float(snapshot.get("progress", 0.0)) >= 0.999:
			_append_once(events, "work_finished", "work_finished", snapshot)

	var earnings := maxf(float(snapshot.get("today_earnings", 0.0)), 0.0)
	var milestone_bucket := int(floor(earnings / _milestone_step))
	if current_state == "working" and milestone_bucket > _last_milestone_bucket:
		var amount := float(milestone_bucket) * _milestone_step
		_append_once(events, "income_milestone", "income_milestone:%d" % milestone_bucket, snapshot, amount)
	_last_milestone_bucket = milestone_bucket
	_previous_snapshot = snapshot.duplicate(true)
	return events


func reset() -> void:
	_date_key = ""
	_previous_snapshot.clear()
	_emitted_keys.clear()
	_last_milestone_bucket = 0


func _begin_day(snapshot: Dictionary, date_key: String) -> void:
	_date_key = date_key
	_previous_snapshot = snapshot.duplicate(true)
	_emitted_keys.clear()
	var earnings := maxf(float(snapshot.get("today_earnings", 0.0)), 0.0)
	_last_milestone_bucket = int(floor(earnings / _milestone_step))


func _append_once(events: Array, event_type: String, event_key: String, snapshot: Dictionary, amount: float = 0.0) -> void:
	if _emitted_keys.has(event_key):
		return
	_emitted_keys[event_key] = true
	events.append({
		"type": event_type,
		"event_key": event_key,
		"date": _date_key,
		"amount": amount,
		"state": String(snapshot.get("state", "")),
		"reason": String(snapshot.get("state_reason", ""))
	})
