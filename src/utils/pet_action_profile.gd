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
			return ["working", "making-money", "idle"]
		"awake_rest":
			return ["awake_rest", "resting", "idle"]
		"sleeping":
			return ["sleeping", "resting", "idle"]
		_:
			return ["idle"]


static func interaction_candidates(base_state: String, interaction: String) -> Array[String]:
	match interaction:
		"hover":
			return ["hover"] + base_candidates(base_state)
		"clicked_single":
			return ["%s_clicked_single" % base_state, "clicked_single", "waving"] + base_candidates(base_state)
		_:
			return base_candidates(base_state)


static func run_candidates(phase: String, direction: String, base_state: String) -> Array[String]:
	match phase:
		"prepare":
			return ["run_prepare"] + base_candidates(base_state)
		"move":
			var horizontal := "left" if direction == "left" else "right"
			return ["running_%s" % horizontal, "running"] + base_candidates(base_state)
		"settle":
			return ["run_settle"] + base_candidates(base_state)
		_:
			return base_candidates(base_state)


static func environment_candidates(context: String, base_state: String) -> Array[String]:
	match context:
		"lunch":
			return ["eating"] + base_candidates(base_state)
		"holiday":
			return ["celebrating"] + base_candidates(base_state)
		"after_work":
			return ["awake_rest", "resting", "idle"]
		"night":
			return ["sleeping", "resting", "idle"]
		_:
			return base_candidates(base_state)


static func business_event_candidates(event_type: String, base_state: String) -> Array[String]:
	match event_type:
		"lunch_started":
			return ["lunch_relief", "celebrating_light", "celebrating"] + base_candidates(base_state)
		"work_resumed":
			return ["work_resumed"] + base_candidates(base_state)
		"work_finished":
			return ["work_end_celebrate", "celebrating"] + base_candidates(base_state)
		"income_milestone":
			return ["income_milestone", "making-money", "celebrating"] + base_candidates(base_state)
		_:
			return base_candidates(base_state)


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
