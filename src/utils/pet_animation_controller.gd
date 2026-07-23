extends RefCounted
class_name PetAnimationController

signal action_requested(token: int, animation_name: String, priority: int)
signal action_started(token: int, animation_name: String)
signal action_interrupted(token: int, animation_name: String, reason: String)
signal action_finished(token: int, animation_name: String, reason: String)
signal action_timeout(token: int, animation_name: String)
signal base_animation_resolved(animation_name: String, reason: String)

const MIN_TIMEOUT_GRACE_MS := 500

var active_token: int = 0
var active_animation: String = ""
var active_priority: int = -1
var base_animation: String = "idle"

var _next_token: int = 1
var _deadline_ms: int = 0
var _request_time_ms: int = 0
var _duration_ms: int = 0
var _cooldowns_ms: Dictionary = {}
var _last_completed_ms: Dictionary = {}


func set_base_animation(animation_name: String) -> void:
	if animation_name.is_empty():
		return
	base_animation = animation_name
	if active_token == 0:
		base_animation_resolved.emit(base_animation, "base_changed")


func request_action(animation_name: String, duration_ms: int, priority: int, now_ms: int, cooldown_ms: int = 0) -> int:
	if animation_name.is_empty() or duration_ms <= 0:
		return -1
	var effective_cooldown := maxi(cooldown_ms, int(_cooldowns_ms.get(animation_name, 0)))
	var last_completed := int(_last_completed_ms.get(animation_name, -effective_cooldown - 1))
	if effective_cooldown > 0 and now_ms - last_completed < effective_cooldown:
		return -1
	if active_token != 0 and priority < active_priority:
		return -1
	if active_token != 0:
		_interrupt_active("superseded", now_ms)

	var token := _next_token
	_next_token += 1
	active_token = token
	active_animation = animation_name
	active_priority = priority
	_request_time_ms = now_ms
	_duration_ms = duration_ms
	_cooldowns_ms[animation_name] = effective_cooldown
	_deadline_ms = now_ms + duration_ms + maxi(MIN_TIMEOUT_GRACE_MS, int(ceil(float(duration_ms) * 0.25)))
	action_requested.emit(token, animation_name, priority)
	return token


func mark_started(token: int) -> bool:
	if token != active_token or active_token == 0:
		return false
	action_started.emit(token, active_animation)
	return true


func mark_finished(token: int, now_ms: int = -1) -> bool:
	if token != active_token or active_token == 0:
		return false
	var completed_token := active_token
	var completed_animation := active_animation
	var completed_at := now_ms if now_ms >= 0 else _request_time_ms + _duration_ms
	_clear_active(completed_at)
	action_finished.emit(completed_token, completed_animation, "animation_finished")
	base_animation_resolved.emit(base_animation, "action_finished")
	return true


func interrupt(reason: String, now_ms: int) -> bool:
	if active_token == 0:
		return false
	_interrupt_active(reason, now_ms)
	base_animation_resolved.emit(base_animation, reason)
	return true


func tick(now_ms: int) -> void:
	if active_token == 0 or now_ms < _deadline_ms:
		return
	var timed_out_token := active_token
	var timed_out_animation := active_animation
	_clear_active(now_ms)
	action_timeout.emit(timed_out_token, timed_out_animation)
	action_finished.emit(timed_out_token, timed_out_animation, "timeout")
	base_animation_resolved.emit(base_animation, "timeout")


func is_action_active() -> bool:
	return active_token != 0


func _interrupt_active(reason: String, now_ms: int) -> void:
	var interrupted_token := active_token
	var interrupted_animation := active_animation
	_clear_active(now_ms)
	action_interrupted.emit(interrupted_token, interrupted_animation, reason)


func _clear_active(completed_at_ms: int) -> void:
	if not active_animation.is_empty():
		_last_completed_ms[active_animation] = completed_at_ms
	active_token = 0
	active_animation = ""
	active_priority = -1
	_request_time_ms = 0
	_duration_ms = 0
	_deadline_ms = 0
