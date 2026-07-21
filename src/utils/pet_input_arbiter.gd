extends RefCounted
class_name PetInputArbiter

var _drag_threshold: float
var _hold_threshold_ms: int
var _legacy_double_window_ms: int

var _pressed := false
var _press_time_ms := 0
var _press_position := Vector2.ZERO
var _last_position := Vector2.ZERO
var _running := false
var _moved_beyond_click_tolerance := false


func _init(drag_threshold: float = 5.0, hold_threshold_ms: int = 500, double_window_ms: int = 300) -> void:
	_drag_threshold = drag_threshold
	_hold_threshold_ms = hold_threshold_ms
	_legacy_double_window_ms = double_window_ms


func press(now_ms: int, position: Vector2) -> Array:
	var events: Array = []
	if _pressed:
		return events
	_pressed = true
	_press_time_ms = now_ms
	_press_position = position
	_last_position = position
	_running = false
	_moved_beyond_click_tolerance = false
	return events


func move(now_ms: int, position: Vector2) -> Array:
	var events: Array = []
	var previous_position := _last_position
	_last_position = position
	if not _pressed:
		return events
	var distance := position.distance_to(_press_position)
	if distance > _drag_threshold:
		_moved_beyond_click_tolerance = true
	if _running:
		events.append({
			"type": "run_move",
			"time_ms": now_ms,
			"position": position,
			"delta": position - previous_position,
			"total_delta": position - _press_position,
			"distance": distance
		})
	return events


func release(now_ms: int, position: Vector2) -> Array:
	var events: Array = []
	_last_position = position
	if not _pressed:
		return events
	if _running:
		events.append({"type": "run_settle", "time_ms": now_ms, "position": position, "total_delta": position - _press_position})
	elif not _moved_beyond_click_tolerance:
		events.append({"type": "single", "time_ms": now_ms, "position": position})
	_pressed = false
	_running = false
	_moved_beyond_click_tolerance = false
	return events


func advance(now_ms: int) -> Array:
	var events: Array = []
	if _pressed and not _running and now_ms - _press_time_ms >= _hold_threshold_ms:
		_running = true
		events.append({"type": "run_prepare", "time_ms": now_ms, "position": _last_position, "press_position": _press_position})
	return events


func reset() -> void:
	_pressed = false
	_press_time_ms = 0
	_press_position = Vector2.ZERO
	_last_position = Vector2.ZERO
	_running = false
	_moved_beyond_click_tolerance = false


func is_pressed() -> bool:
	return _pressed


func is_dragging() -> bool:
	return _running


func is_holding() -> bool:
	return _running


func is_running() -> bool:
	return _running
