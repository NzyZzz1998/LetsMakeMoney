extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	await process_frame
	var manager := root.get_node_or_null("/root/PetManager")
	if manager == null:
		push_error("PetManager autoload not found")
		quit(1)
		return

	var ok := true
	ok = _expect("legacy idle base", manager.base_state_to_anim_name(manager.PetBaseState.IDLE), "idle") and ok
	ok = _expect("legacy working base", manager.base_state_to_anim_name(manager.PetBaseState.WORKING), "working") and ok
	ok = _expect("legacy resting base", manager.base_state_to_anim_name(manager.PetBaseState.RESTING), "resting") and ok

	var frames := SpriteFrames.new()
	for animation_name in ["idle", "working", "resting", "clicked_single", "clicked_hold"]:
		frames.add_animation(animation_name)
	ok = _expect("state-aware single falls back to generic", manager.resolve_animation_name(manager.PetBaseState.WORKING, manager.PetInteraction.CLICKED_SINGLE, frames), "clicked_single") and ok
	ok = _expect("missing double falls back to base", manager.resolve_animation_name(manager.PetBaseState.RESTING, manager.PetInteraction.CLICKED_DOUBLE, frames), "resting") and ok
	ok = _expect("hold uses generic legacy action", manager.resolve_animation_name(manager.PetBaseState.IDLE, manager.PetInteraction.CLICKED_HOLD, frames), "clicked_hold") and ok

	frames.add_animation("working_clicked_single")
	ok = _expect("state-aware action wins", manager.resolve_animation_name(manager.PetBaseState.WORKING, manager.PetInteraction.CLICKED_SINGLE, frames), "working_clicked_single") and ok

	manager.set_base_state(manager.PetBaseState.WORKING)
	manager.request_interaction(manager.PetInteraction.CLICKED_SINGLE)
	ok = _expect("interaction keeps base state", manager.current_base_state, manager.PetBaseState.WORKING) and ok
	manager.return_to_interaction_base_state()
	ok = _expect("return restores interaction base", manager.current_base_state, manager.PetBaseState.WORKING) and ok
	ok = _expect("return clears interaction", manager.current_interaction, manager.PetInteraction.NONE) and ok

	if ok:
		print("v0.9 behavior baseline verification passed")
		quit(0)
	else:
		quit(1)


func _expect(label: String, actual: Variant, expected: Variant) -> bool:
	if actual != expected:
		push_error("%s expected %s but got %s" % [label, expected, actual])
		return false
	return true
