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
	if not manager.has_method("resolve_animation_name") or not manager.has_method("request_interaction"):
		push_error("PetManager is missing the base-state + interaction animation API")
		quit(1)
		return

	var ok := true
	ok = _expect("idle single animation", manager.resolve_animation_name(manager.PetBaseState.IDLE, manager.PetInteraction.CLICKED_SINGLE), "idle_clicked_single") and ok
	ok = _expect("working single animation", manager.resolve_animation_name(manager.PetBaseState.WORKING, manager.PetInteraction.CLICKED_SINGLE), "working_clicked_single") and ok
	ok = _expect("resting double animation", manager.resolve_animation_name(manager.PetBaseState.RESTING, manager.PetInteraction.CLICKED_DOUBLE), "resting_clicked_double") and ok
	ok = _expect("hold animation", manager.resolve_animation_name(manager.PetBaseState.WORKING, manager.PetInteraction.CLICKED_HOLD), "clicked_hold") and ok
	ok = _expect("base animation", manager.resolve_animation_name(manager.PetBaseState.RESTING, manager.PetInteraction.NONE), "resting") and ok

	var frames := SpriteFrames.new()
	frames.add_animation("idle")
	frames.add_animation("clicked_single")
	ok = _expect("generic fallback when state-aware animation missing", manager.resolve_animation_name(manager.PetBaseState.IDLE, manager.PetInteraction.CLICKED_SINGLE, frames), "clicked_single") and ok

	frames.add_animation("idle_clicked_single")
	ok = _expect("state-aware animation preferred", manager.resolve_animation_name(manager.PetBaseState.IDLE, manager.PetInteraction.CLICKED_SINGLE, frames), "idle_clicked_single") and ok
	frames.add_animation("working_clicked_double")
	ok = _expect("working state-aware animation preferred", manager.resolve_animation_name(manager.PetBaseState.WORKING, manager.PetInteraction.CLICKED_DOUBLE, frames), "working_clicked_double") and ok

	manager.set_base_state(manager.PetBaseState.WORKING)
	manager.request_interaction(manager.PetInteraction.CLICKED_DOUBLE)
	ok = _expect("current base state preserved", manager.current_base_state, manager.PetBaseState.WORKING) and ok
	ok = _expect("current interaction stored", manager.current_interaction, manager.PetInteraction.CLICKED_DOUBLE) and ok
	manager.return_to_auto_state()

	if ok:
		print("Pet animation state model verification passed.")
		quit(0)
	else:
		quit(1)


func _expect(label: String, actual: Variant, expected: Variant) -> bool:
	if actual != expected:
		push_error("%s expected %s but got %s" % [label, expected, actual])
		return false
	return true
