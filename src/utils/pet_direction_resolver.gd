extends RefCounted
class_name PetDirectionResolver

const DIRECTION_STEP := 22.5
const SAMPLE_INTERVAL_MS := 80
const HYSTERESIS_DEGREES := 4.0
const RESTORE_DELAY_MS := 250

var _last_sample_ms := -SAMPLE_INTERVAL_MS
var _current_index := -1


func direction_for_angle(angle_degrees: float) -> String:
	var index := int(floor((fposmod(angle_degrees, 360.0) + DIRECTION_STEP * 0.5) / DIRECTION_STEP)) % 16
	return _label_for_index(index)


func should_sample(now_ms: int, _pointer_id: int = 0) -> bool:
	if now_ms - _last_sample_ms < SAMPLE_INTERVAL_MS: return false
	_last_sample_ms = now_ms
	return true


func resolve_with_hysteresis(angle_degrees: float) -> String:
	var normalized := fposmod(angle_degrees, 360.0)
	if _current_index < 0: _current_index = int(floor((normalized + DIRECTION_STEP * 0.5) / DIRECTION_STEP)) % 16
	elif _angular_distance(normalized, float(_current_index) * DIRECTION_STEP) > DIRECTION_STEP * 0.5 + HYSTERESIS_DEGREES:
		_current_index = int(floor((normalized + DIRECTION_STEP * 0.5) / DIRECTION_STEP)) % 16
	return _label_for_index(_current_index)


func should_restore_after_leave(elapsed_ms: int) -> bool:
	return elapsed_ms >= RESTORE_DELAY_MS


func reset() -> void:
	_current_index = -1
	_last_sample_ms = -SAMPLE_INTERVAL_MS


func _label_for_index(index: int) -> String:
	var angle := float(index % 16) * DIRECTION_STEP
	return "%03d" % int(round(angle)) if is_equal_approx(angle, round(angle)) else "%05.1f" % angle


func _angular_distance(a: float, b: float) -> float:
	return absf(fposmod(a - b + 180.0, 360.0) - 180.0)
