extends RefCounted
class_name PetActionProfile

const ACTION_PRIORITY := {
	"pointer_look": 10,
	"hover": 20,
	"environment": 30,
	"business_event": 40,
	"clicked_single": 50,
	"run_prepare": 80,
	"running_left": 80,
	"running_right": 80,
	"run_settle": 80
}

const ACTION_COOLDOWN_MS := {
	"clicked_single": 180,
	"eating": 120000,
	"celebrating": 180000
}


static func base_candidates(state_name: String) -> Array[String]:
	match state_name:
		"working":
			return ["working_loop", "working", "making-money", "idle"]
		"awake_rest":
			return ["awake_rest", "resting", "idle"]
		"sleeping":
			return ["sleeping", "resting", "idle"]
		_:
			return ["idle"]


static func interaction_candidates(base_state: String, interaction: String) -> Array[String]:
	match interaction:
		"hover":
			return _with_base_candidates(["hover"], base_state)
		"clicked_single":
			var acknowledgement: String = String({
				"working": "working_ack",
				"awake_rest": "rest_ack",
				"sleeping": "sleep_ack",
			}.get(base_state, ""))
			var candidates: Array[String] = []
			if not acknowledgement.is_empty():
				candidates.append(acknowledgement)
			candidates.append_array(["%s_clicked_single" % base_state, "clicked_single", "waving"])
			candidates.append_array(base_candidates(base_state))
			return candidates
		_:
			return base_candidates(base_state)


static func run_candidates(phase: String, direction: String, base_state: String) -> Array[String]:
	match phase:
		"prepare":
			return _with_base_candidates(["run_prepare"], base_state)
		"move":
			var horizontal := "left" if direction == "left" else "right"
			return _with_base_candidates(["running_%s" % horizontal, "running"], base_state)
		"settle":
			return _with_base_candidates(["run_stop", "run_settle"], base_state)
		_:
			return base_candidates(base_state)


static func environment_candidates(context: String, base_state: String) -> Array[String]:
	match context:
		"lunch":
			return _with_base_candidates(["eating"], base_state)
		"holiday":
			return _with_base_candidates(["celebrating"], base_state)
		"after_work":
			return ["awake_rest", "resting", "idle"]
		"night":
			return ["sleeping", "resting", "idle"]
		_:
			return base_candidates(base_state)


static func business_event_candidates(event_type: String, base_state: String) -> Array[String]:
	match event_type:
		"lunch_started":
			return _with_base_candidates(["lunch_relief", "celebrating_light", "celebrating"], base_state)
		"work_resumed":
			return _with_base_candidates(["lunch_return", "work_resumed"], base_state)
		"work_finished":
			return _with_base_candidates(["work_end_celebrate", "celebrating"], base_state)
		"income_milestone":
			return _with_base_candidates(["income_milestone", "making-money", "celebrating"], base_state)
		_:
			return base_candidates(base_state)


static func _with_base_candidates(primary: Array, base_state: String) -> Array[String]:
	var candidates: Array[String] = []
	for candidate in primary:
		candidates.append(String(candidate))
	candidates.append_array(base_candidates(base_state))
	return candidates


static func priority_for(action_name: String) -> int:
	return int(ACTION_PRIORITY.get(action_name, 40))


static func cooldown_for(action_name: String) -> int:
	return int(ACTION_COOLDOWN_MS.get(action_name, 0))


static func first_available(candidates: Array[String], frames: SpriteFrames) -> String:
	if frames == null:
		return candidates[0] if not candidates.is_empty() else "idle"
	for candidate in candidates:
		if frames.has_animation(candidate):
			return candidate
	return "idle" if frames.has_animation("idle") else ""
