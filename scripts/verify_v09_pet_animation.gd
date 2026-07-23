extends SceneTree

const AnimationControllerScript := preload("res://src/utils/pet_animation_controller.gd")
const InputArbiterScript := preload("res://src/utils/pet_input_arbiter.gd")
const ActionProfileScript := preload("res://src/utils/pet_action_profile.gd")
const BusinessEventTrackerScript := preload("res://src/utils/pet_business_event_tracker.gd")

var _failures: Array[String] = []


func _init() -> void:
	_test_animation_lifecycle()
	_test_late_completion_and_state_change()
	_test_timeout_and_cooldown()
	_test_input_arbiter()
	_test_action_profile()
	_test_business_event_tracker()
	if _failures.is_empty():
		print("V09 pet animation verification passed")
		quit(0)
		return
	for failure in _failures:
		push_error(failure)
	quit(1)


func _test_animation_lifecycle() -> void:
	var controller = AnimationControllerScript.new()
	var events: Array[String] = []
	controller.action_requested.connect(func(_token, name, _priority): events.append("requested:%s" % name))
	controller.action_started.connect(func(_token, name): events.append("started:%s" % name))
	controller.action_finished.connect(func(_token, name, _reason): events.append("finished:%s" % name))
	controller.base_animation_resolved.connect(func(name, _reason): events.append("base:%s" % name))
	controller.set_base_animation("awake_rest")
	var token: int = controller.request_action("clicked_single", 1200, 50, 1000, 0)
	_expect(token > 0, "an accepted action must receive a positive request token")
	controller.mark_started(token)
	controller.mark_finished(token)
	_expect(events.has("requested:clicked_single"), "accepted actions must emit requested")
	_expect(events.has("started:clicked_single"), "started actions must emit started")
	_expect(events.has("finished:clicked_single"), "completed actions must emit finished")
	_expect(events.back() == "base:awake_rest", "completion must resolve the latest base animation")


func _test_late_completion_and_state_change() -> void:
	var controller = AnimationControllerScript.new()
	var resolved: Array[String] = []
	controller.base_animation_resolved.connect(func(name, _reason): resolved.append(name))
	controller.set_base_animation("working")
	var first: int = controller.request_action("clicked_single", 900, 50, 0, 0)
	controller.mark_started(first)
	var second: int = controller.request_action("run_settle", 1100, 80, 100, 0)
	controller.mark_started(second)
	controller.set_base_animation("sleeping")
	controller.mark_finished(first)
	_expect(controller.active_token == second, "a late completion event must not finish a newer action")
	controller.mark_finished(second)
	_expect(resolved.back() == "sleeping", "an action must recover to a base state changed during playback")


func _test_timeout_and_cooldown() -> void:
	var controller = AnimationControllerScript.new()
	var timeout_events: Array[String] = []
	controller.action_timeout.connect(func(_token, name): timeout_events.append(name))
	controller.set_base_animation("working")
	var token: int = controller.request_action("run_prepare", 1000, 80, 100, 500)
	controller.mark_started(token)
	controller.tick(1700)
	_expect(timeout_events.has("run_prepare") and controller.active_token == 0, "an action missing its completion event must time out")
	var rejected: int = controller.request_action("run_prepare", 1000, 80, 1800, 500)
	_expect(rejected < 0, "an action inside its cooldown must be rejected")
	var accepted: int = controller.request_action("run_prepare", 1000, 80, 2200, 500)
	_expect(accepted > 0, "an action after its cooldown must be accepted")


func _test_input_arbiter() -> void:
	var arbiter = InputArbiterScript.new(5.0, 500, 300)
	_expect(arbiter.press(0, Vector2.ZERO).is_empty(), "press alone must not emit a click")
	var single: Array = arbiter.release(80, Vector2.ZERO)
	_expect(_contains_type(single, "single"), "a quick release must emit a single click immediately")
	_expect(not _contains_type(arbiter.advance(381), "single"), "an immediate single click must not be emitted twice")

	arbiter.reset()
	arbiter.press(1000, Vector2.ZERO)
	var first_click: Array = arbiter.release(1060, Vector2.ZERO)
	arbiter.press(1140, Vector2.ZERO)
	var second_click: Array = arbiter.release(1200, Vector2.ZERO)
	_expect(_contains_type(first_click, "single") and _contains_type(second_click, "single"), "two quick clicks must remain two state-aware single clicks")
	_expect(not _contains_type(first_click, "double") and not _contains_type(second_click, "double"), "double click must not be a product action")

	arbiter.reset()
	arbiter.press(2000, Vector2.ZERO)
	_expect(arbiter.move(2040, Vector2(8, 0)).is_empty(), "movement before the hold threshold must not move the pet")
	var early_release: Array = arbiter.release(2100, Vector2(8, 0))
	_expect(not _contains_type(early_release, "single"), "a moved pointer released before run entry must not become a click")

	for cycle in 20:
		arbiter.reset()
		var start := 4000 + cycle * 1000
		arbiter.press(start, Vector2.ZERO)
		var prepare_events: Array = arbiter.advance(start + 500)
		_expect(_contains_type(prepare_events, "run_prepare"), "run cycle %d must enter run_prepare at the hold threshold" % cycle)
		var run_events: Array = arbiter.move(start + 540, Vector2(12, 0))
		_expect(_contains_type(run_events, "run_move"), "run cycle %d must move only after run_prepare" % cycle)
		var release_events: Array = arbiter.release(start + 620, Vector2(18, 0))
		_expect(_contains_type(release_events, "run_settle"), "run cycle %d must finish with run_settle" % cycle)
		_expect(not _contains_type(arbiter.advance(start + 500), "single"), "drag cycle %d must not leak into click" % cycle)


func _test_action_profile() -> void:
	_expect(ActionProfileScript.base_candidates("working")[0] == "working_loop", "working must prefer the approved motion loop")
	_expect(ActionProfileScript.base_candidates("awake_rest").has("resting"), "awake rest must preserve the legacy resting fallback")
	_expect(ActionProfileScript.base_candidates("sleeping").has("resting"), "sleeping must fall back to resting on old pets")
	_expect(ActionProfileScript.interaction_candidates("working", "clicked_single")[0] == "working_ack", "working click must prefer the state-aware acknowledgement")
	_expect(ActionProfileScript.interaction_candidates("awake_rest", "clicked_single")[0] == "rest_ack", "awake rest click must prefer the gentle acknowledgement")
	_expect(ActionProfileScript.interaction_candidates("sleeping", "clicked_single")[0] == "sleep_ack", "sleep click must prefer the sleep acknowledgement")
	_expect(ActionProfileScript.interaction_candidates("working", "clicked_double")[0] == "working_loop", "double click must not expose an independent product action")
	_expect(ActionProfileScript.run_candidates("prepare", "right", "awake_rest")[0] == "run_prepare", "run prepare must prefer its dedicated animation")
	_expect(ActionProfileScript.run_candidates("move", "left", "awake_rest")[0] == "running_left", "run movement must prefer its horizontal direction")
	_expect(ActionProfileScript.run_candidates("settle", "right", "working")[0] == "run_stop", "run release must prefer the approved stop animation")
	_expect(ActionProfileScript.environment_candidates("lunch", "awake_rest").has("eating"), "lunch must expose the eating environment action")
	_expect(ActionProfileScript.business_event_candidates("lunch_started", "awake_rest")[0] == "lunch_relief", "lunch start must prefer its dedicated light event action")
	_expect(ActionProfileScript.business_event_candidates("work_resumed", "working")[0] == "lunch_return", "work resume must prefer the approved lunch return action")
	_expect(ActionProfileScript.business_event_candidates("work_finished", "awake_rest")[0] == "work_end_celebrate", "work finish must prefer its dedicated celebration")
	_expect(ActionProfileScript.business_event_candidates("income_milestone", "working")[0] == "income_milestone", "income milestones must prefer their dedicated coin feedback")
	_expect(ActionProfileScript.business_event_candidates("unknown", "working")[0] == "working_loop", "unknown business events must safely fall back to the current base")


func _test_business_event_tracker() -> void:
	var tracker = BusinessEventTrackerScript.new(100.0)
	var startup: Array = tracker.observe(_schedule_snapshot("working", "scheduled_work", 99.0, 0.40), "2026-07-18")
	_expect(startup.is_empty(), "startup must establish the business-event baseline without replaying old events")

	var milestone: Array = tracker.observe(_schedule_snapshot("working", "scheduled_work", 101.0, 0.41), "2026-07-18")
	_expect(_contains_event(milestone, "income_milestone"), "crossing an income milestone during work must emit one event")
	var same_bucket: Array = tracker.observe(_schedule_snapshot("working", "scheduled_work", 150.0, 0.50), "2026-07-18")
	_expect(not _contains_event(same_bucket, "income_milestone"), "remaining inside the same income bucket must not repeat the milestone")

	var lunch: Array = tracker.observe(_schedule_snapshot("awake_rest", "lunch", 180.0, 0.55), "2026-07-18")
	_expect(_contains_event(lunch, "lunch_started"), "working to lunch must emit lunch_started")
	var lunch_repeat: Array = tracker.observe(_schedule_snapshot("awake_rest", "lunch", 180.0, 0.55), "2026-07-18")
	_expect(not _contains_event(lunch_repeat, "lunch_started"), "the same lunch state must not repeat its event")

	var resumed: Array = tracker.observe(_schedule_snapshot("working", "scheduled_work", 181.0, 0.56), "2026-07-18")
	_expect(_contains_event(resumed, "work_resumed"), "lunch to working must emit work_resumed")
	var finished: Array = tracker.observe(_schedule_snapshot("awake_rest", "outside_work", 500.0, 1.0), "2026-07-18")
	_expect(_contains_event(finished, "work_finished"), "the completed work boundary must emit work_finished")

	var next_day: Array = tracker.observe(_schedule_snapshot("working", "scheduled_work", 15.0, 0.03), "2026-07-19")
	_expect(next_day.is_empty(), "a date change must reset event dedupe without replaying a transition")


func _schedule_snapshot(state: String, reason: String, earnings: float, progress: float) -> Dictionary:
	return {
		"state": state,
		"state_reason": reason,
		"today_earnings": earnings,
		"progress": progress
	}


func _contains_event(events: Array, expected: String) -> bool:
	for event in events:
		if event is Dictionary and String(event.get("type", "")) == expected:
			return true
	return false


func _contains_type(events: Array, expected: String) -> bool:
	for event in events:
		if event is Dictionary and String(event.get("type", "")) == expected:
			return true
	return false


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
