extends SceneTree

var _failures: Array[String] = []
var _warnings: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	await process_frame
	_check_animation_docs()
	_check_default_pet_resource()
	_check_orange_v1_fallback()
	_check_orange_v2_asset_pipeline()
	_check_orange_v2_godot_builder()
	_check_orange_v2_generated_resource()
	_check_pet_state_model()
	_check_pet_interaction_priority()
	await _check_pet_hit_geometry()
	_check_panel_hover_coordination()
	_check_window_passthrough_debugging()
	_check_panel_edge_positioning()
	await _check_panel_collapsed_layout()
	_check_context_menu_ui_polish()
	_check_icon_polish_assets()
	_check_scale_variant_layout()
	_check_window_recovery_fallbacks()
	_check_settings_information_architecture()
	await _check_wizard_warm_widget_polish()
	await _check_settings_display_status_layout()
	_check_settings_save_feedback()
	_check_settings_restore_and_debug_help()
	_check_settings_single_window_host()
	_check_settings_modal_runtime_reapply_guard()
	_check_logging_performance_boundaries()
	_check_runtime_refresh_throttling()
	_check_v04_automation_coverage()
	_check_prototype_v04_scope()

	if _failures.is_empty():
		for warning in _warnings:
			push_warning(warning)
		print("v0.4 verification passed")
		quit(0)
	else:
		for failure in _failures:
			push_error(failure)
		quit(1)


func _assert(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _warn(condition: bool, message: String) -> void:
	if not condition:
		_warnings.append(message)


func _check_animation_docs() -> void:
	for path in [
		"res://doc/v0.4-animation-spec.md",
		"res://doc/v0.4-animation-assets-log.md",

	]:
		_assert(FileAccess.file_exists(path), "missing v0.4 animation document: %s" % path)

	var spec := FileAccess.get_file_as_string("res://doc/v0.4-animation-spec.md")
	for required_text in [
		"warm companion",
		"clicked_single",
		"clicked_double",
		"clicked_hold",
		"idle_clicked_single",
		"working_clicked_double",
		"cat_orange_v2_<animation>_<frame>.png",
		"Multi-theme",
		"SpriteCook",
		"ComfyUI",
		"Godot cutout",
		"Local sprite editors"
	]:
		_assert(spec.contains(required_text), "animation spec missing text: %s" % required_text)

	var log := FileAccess.get_file_as_string("res://doc/v0.4-animation-assets-log.md")
	_assert(log.contains("cat_orange_v1"), "asset log should record cat_orange_v1 baseline")
	_assert(log.contains("Confirmed creative decisions"), "asset log should record confirmed v0.4 creative decisions")
	_assert(log.contains("keyboard, computer, and coins"), "asset log should record confirmed working props direction")
	for required_text in [
		"Asset Production Routes",
		"Route A: SpriteCook",
		"Route B: ComfyUI local workflow",
		"Route C: Local sprite editing tools",
		"Route D: Godot cutout animation",
		"Current Route Decision",
		"ComfyUI Preflight",
		"scripts/check_comfyui_prereqs.ps1"
	]:
		_assert(log.contains(required_text), "asset log missing production route text: %s" % required_text)


	_check_orange_v2_staging_dirs()


func _check_default_pet_resource() -> void:
	var config_script := FileAccess.get_file_as_string("res://src/autoload/config.gd")
	var pet_manager_script := FileAccess.get_file_as_string("res://src/autoload/pet_manager.gd")
	_assert(config_script.contains("\"pet_id\": \"cat_orange_v2\""), "v0.4 should default to cat_orange_v2 after manual approval")
	_assert(pet_manager_script.contains("const DEFAULT_PET_ID = \"cat_orange_v2\""), "PetManager should prefer cat_orange_v2")
	_assert(pet_manager_script.contains("const FALLBACK_PET_ID = \"cat_orange_v1\""), "PetManager should keep cat_orange_v1 fallback")
	_assert(pet_manager_script.contains("BUILTIN_PET_RESOURCE_PATHS"), "PetManager should keep built-in pet resource paths for exported builds")
	_assert(pet_manager_script.contains("_scan_builtin_pet_resources"), "PetManager should scan built-in pet resources after directory scan")
	_assert(pet_manager_script.contains("_scan_pet_resources_in_dir"), "PetManager should recursively scan nested pet resources")
	_assert(FileAccess.file_exists("res://assets/pets/cat/orange_v2/cat_orange_v2_resource.tres"), "cat_orange_v2 resource missing")
	_assert(FileAccess.file_exists("res://assets/pets/cat/orange_v2/cat_orange_v2_sprite_frames.tres"), "cat_orange_v2 SpriteFrames missing")

	var resource := load("res://assets/pets/cat/orange_v2/cat_orange_v2_resource.tres")
	_assert(resource != null, "cat_orange_v2 resource should load")
	if resource == null:
		return
	_assert(resource.get("pet_id") == "cat_orange_v2", "cat_orange_v2 resource should use pet_id=cat_orange_v2")
	_assert(resource.get("sprite_frames") != null, "cat_orange_v2 should reference SpriteFrames")

	var manager := root.get_node_or_null("/root/PetManager")
	_assert(manager != null, "PetManager autoload should exist for default pet checks")
	if manager != null:
		var pets: Array = manager.get_available_pets()
		_assert(pets.size() >= 2, "PetManager should expose at least v2 and v1 pets")
		var pet_ids: Array[String] = []
		for pet in pets:
			pet_ids.append(String(pet.pet_id))
		_assert(pet_ids.has("cat_orange_v2"), "PetManager available pets should include cat_orange_v2")
		_assert(pet_ids.has("cat_orange_v1"), "PetManager available pets should include cat_orange_v1 fallback")


func _check_orange_v1_fallback() -> void:
	var frames := load("res://assets/pets/cat_orange_v1/cat_orange_v1_sprite_frames.tres") as SpriteFrames
	_assert(frames != null, "cat_orange_v1 SpriteFrames should load")
	if frames == null:
		return

	for anim_name in ["idle", "working", "resting", "clicked_hold"]:
		_assert(frames.has_animation(anim_name), "cat_orange_v1 missing animation: %s" % anim_name)
		if frames.has_animation(anim_name):
			_assert(frames.get_frame_count(anim_name) > 0, "cat_orange_v1 animation has no frames: %s" % anim_name)
			_assert(frames.get_animation_speed(anim_name) > 0.0, "cat_orange_v1 animation speed should be positive: %s" % anim_name)

	for anim_name in [
		"idle_clicked_single",
		"idle_clicked_double",
		"working_clicked_single",
		"working_clicked_double",
		"resting_clicked_single",
		"resting_clicked_double"
	]:
		_assert(frames.has_animation(anim_name), "cat_orange_v1 missing base-specific overlay: %s" % anim_name)
		if frames.has_animation(anim_name):
			_assert(frames.get_frame_count(anim_name) > 0, "cat_orange_v1 overlay has no frames: %s" % anim_name)
			_assert(frames.get_animation_speed(anim_name) > 0.0, "cat_orange_v1 overlay speed should be positive: %s" % anim_name)

	_assert(frames.get_animation_loop("clicked_hold"), "clicked_hold should loop")
	_assert(frames.get_animation_loop("idle"), "idle should loop")
	_assert(frames.get_animation_loop("working"), "working should loop")
	_assert(frames.get_animation_loop("resting"), "resting should loop")


func _check_orange_v2_staging_dirs() -> void:
	for dir_path in [
		"res://assets/pets/cat/orange_v2/idle",
		"res://assets/pets/cat/orange_v2/working",
		"res://assets/pets/cat/orange_v2/resting",
		"res://assets/pets/cat/orange_v2/clicked_hold",
		"res://assets/pets/cat/orange_v2/idle_clicked_single",
		"res://assets/pets/cat/orange_v2/idle_clicked_double",
		"res://assets/pets/cat/orange_v2/working_clicked_single",
		"res://assets/pets/cat/orange_v2/working_clicked_double",
		"res://assets/pets/cat/orange_v2/resting_clicked_single",
		"res://assets/pets/cat/orange_v2/resting_clicked_double"
	]:
		_assert(DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(dir_path)), "missing orange_v2 staging dir: %s" % dir_path)


func _check_orange_v2_asset_pipeline() -> void:
	var prompt_pack_path := "res://doc/v0.4-animation-prompt-pack.md"
	var manifest_path := "res://assets/pets/cat/orange_v2/asset-manifest.json"
	_assert(FileAccess.file_exists(prompt_pack_path), "missing v0.4 animation prompt pack")
	_assert(FileAccess.file_exists(manifest_path), "missing orange_v2 asset manifest")
	if FileAccess.file_exists(prompt_pack_path):
		var prompt_pack := FileAccess.get_file_as_string(prompt_pack_path)
		for required_text in [
			"keyboard",
			"computer",
			"coins",
			"sleepy sitting",
			"lying down",
			"base-state extension"
		]:
			_assert(prompt_pack.contains(required_text), "prompt pack missing confirmed direction: %s" % required_text)
	if FileAccess.file_exists(manifest_path):
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(manifest_path))
		_assert(parsed is Dictionary, "orange_v2 asset manifest should be a JSON object")
		if parsed is Dictionary:
			var manifest: Dictionary = parsed
			_assert(manifest.get("pet_id") == "cat_orange_v2", "orange_v2 manifest should use pet_id=cat_orange_v2")
			_assert(manifest.get("runtime_default") == true, "orange_v2 manifest should record runtime_default=true")
			_assert(manifest.get("fallback_pet_id") == "cat_orange_v1", "orange_v2 manifest should record cat_orange_v1 fallback")
			_assert(manifest.has("animations"), "orange_v2 manifest should define animations")
			var animations: Dictionary = manifest.get("animations", {})
			for anim_name in _required_v04_animation_names():
				_assert(animations.has(anim_name), "orange_v2 manifest missing animation entry: %s" % anim_name)


func _check_orange_v2_godot_builder() -> void:
	var builder_path := "res://scripts/build_cat_orange_v2_resource.gd"
	var cutout_generator_path := "res://scripts/generate_cat_orange_v2_cutout_candidates.py"
	var concept_generator_path := "res://scripts/generate_cat_orange_v2_from_concept_sheet.py"
	_assert(FileAccess.file_exists(builder_path), "missing orange_v2 Godot builder script")
	_assert(FileAccess.file_exists(cutout_generator_path), "missing orange_v2 cutout candidate generator")
	_assert(FileAccess.file_exists(concept_generator_path), "missing orange_v2 concept-sheet candidate generator")
	if not FileAccess.file_exists(builder_path):
		return
	var builder_script := FileAccess.get_file_as_string(builder_path)
	for required_text in [
		"cat_orange_v2_sprite_frames.tres",
		"cat_orange_v2_resource.tres",
		"_required_v04_animation_names",
		"_validate_animation_frames",
		"_build_sprite_frames_resource",
		"_build_pet_resource",
		"minimum_frames",
		"loop",
		"_load_png_texture",
		"cat_orange_v1",
		"remains available as fallback"
	]:
		_assert(builder_script.contains(required_text), "orange_v2 builder missing text: %s" % required_text)


func _check_orange_v2_generated_resource() -> void:
	var frames_path := "res://assets/pets/cat/orange_v2/cat_orange_v2_sprite_frames.tres"
	var resource_path := "res://assets/pets/cat/orange_v2/cat_orange_v2_resource.tres"
	var manifest_path := "res://assets/pets/cat/orange_v2/asset-manifest.json"
	_assert(FileAccess.file_exists(frames_path), "missing generated orange_v2 SpriteFrames resource")
	_assert(FileAccess.file_exists(resource_path), "missing generated orange_v2 PetResource")
	if not FileAccess.file_exists(frames_path) or not FileAccess.file_exists(resource_path):
		return

	_assert(FileAccess.get_file_as_bytes(frames_path).size() < 200000, "orange_v2 SpriteFrames should reference PNGs, not embed large textures")
	_assert(FileAccess.get_file_as_bytes(resource_path).size() < 200000, "orange_v2 PetResource should reference PNGs, not embed large textures")
	var frames_text := FileAccess.get_file_as_string(frames_path)
	_assert(frames_text.contains("[ext_resource type=\"Texture2D\""), "orange_v2 SpriteFrames should use external texture resources")
	_assert(not frames_text.contains("ImageTexture"), "orange_v2 SpriteFrames should not embed ImageTexture data")

	var frames := load(frames_path) as SpriteFrames
	_assert(frames != null, "orange_v2 SpriteFrames should load")
	if frames == null:
		return

	var manifest: Dictionary = {}
	if FileAccess.file_exists(manifest_path):
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(manifest_path))
		if parsed is Dictionary:
			manifest = parsed
	var animations: Dictionary = manifest.get("animations", {})

	for anim_name in _required_v04_animation_names():
		_assert(frames.has_animation(anim_name), "orange_v2 generated resource missing animation: %s" % anim_name)
		if frames.has_animation(anim_name):
			var minimum_frames := int(animations.get(anim_name, {}).get("minimum_frames", 1))
			_assert(frames.get_frame_count(anim_name) >= minimum_frames, "orange_v2 animation has too few frames: %s" % anim_name)
			_assert(frames.get_animation_speed(anim_name) > 0.0, "orange_v2 animation speed should be positive: %s" % anim_name)
			var should_loop := bool(animations.get(anim_name, {}).get("loop", false))
			_assert(frames.get_animation_loop(anim_name) == should_loop, "orange_v2 animation loop mismatch: %s" % anim_name)
			if String(anim_name).contains("_clicked_single") or String(anim_name).contains("_clicked_double"):
				_assert_click_frame_emphasis(frames, anim_name)

	var resource := load(resource_path)
	_assert(resource != null, "orange_v2 PetResource should load")
	if resource != null:
		_assert(resource.get("pet_id") == "cat_orange_v2", "orange_v2 PetResource should use pet_id=cat_orange_v2")
		_assert(resource.get("sprite_frames") != null, "orange_v2 PetResource should reference SpriteFrames")


func _assert_click_frame_emphasis(frames: SpriteFrames, anim_name: String) -> void:
	var frame_count := frames.get_frame_count(anim_name)
	if frame_count < 3:
		return
	var first_duration := frames.get_frame_duration(anim_name, 0)
	var middle_duration := frames.get_frame_duration(anim_name, 1)
	var last_duration := frames.get_frame_duration(anim_name, frame_count - 1)
	_assert(middle_duration > first_duration, "%s should hold action frames longer than the neutral first frame" % anim_name)
	_assert(middle_duration > last_duration, "%s should hold action frames longer than the neutral last frame" % anim_name)


func _required_v04_animation_names() -> Array[String]:
	return [
		"idle",
		"working",
		"resting",
		"clicked_hold",
		"idle_clicked_single",
		"idle_clicked_double",
		"working_clicked_single",
		"working_clicked_double",
		"resting_clicked_single",
		"resting_clicked_double"
	]


func _check_pet_state_model() -> void:
	var script := FileAccess.get_file_as_string("res://src/autoload/pet_manager.gd")
	for required_text in [
		"enum PetBaseState",
		"enum PetInteraction",
		"current_base_state",
		"current_interaction",
		"_interaction_base_state",
		"resolve_animation_name",
		"return_to_interaction_base_state",
		"return_to_auto_state"
	]:
		_assert(script.contains(required_text), "PetManager missing v0.4 state model text: %s" % required_text)

	_assert(script.contains("clicked_single"), "PetManager should resolve clicked_single")
	_assert(script.contains("clicked_double"), "PetManager should resolve clicked_double")
	_assert(script.contains("clicked_hold"), "PetManager should resolve clicked_hold")
	var manager := root.get_node_or_null("/root/PetManager")
	_assert(manager != null, "PetManager autoload should exist")
	if manager != null:
		manager.set_base_state(manager.PetBaseState.WORKING)
		manager.request_interaction(manager.PetInteraction.CLICKED_DOUBLE)
		manager.return_to_interaction_base_state()
		_assert(manager.current_base_state == manager.PetBaseState.WORKING, "interaction return should restore captured WORKING base state")
		_assert(manager.current_interaction == manager.PetInteraction.NONE, "interaction return should clear current interaction")

	var pet_script := FileAccess.get_file_as_string("res://src/scenes/pet/pet.gd")
	var click_return_body := _function_body(pet_script, "_on_click_return")
	_assert(click_return_body.contains("return_to_interaction_base_state"), "click/hold return should restore the base state captured before interaction")
	_assert(not click_return_body.contains("request_interaction(PetManager.PetInteraction.HOVER)"), "click/hold return should not prefer hover over the captured base state")


func _check_pet_interaction_priority() -> void:
	var script := FileAccess.get_file_as_string("res://src/scenes/pet/pet.gd")
	_assert(script.contains("DRAG_THRESHOLD"), "pet.gd should keep an explicit drag threshold")
	_assert(script.contains("DOUBLE_CLICK_WINDOW"), "pet.gd should keep an explicit double-click window")
	_assert(script.contains("LONG_PRESS_THRESHOLD := 0.5"), "long press threshold should be calibrated to about 0.5 seconds")
	_assert(script.contains("CLICK_RETURN_DELAY := 1.55"), "single/double click feedback should stay visible long enough to read")
	_assert(script.contains("CLICK_SNAPSHOT_DELAYS"), "single/double click should save diagnostic snapshots")
	_assert(script.contains("_capture_interaction_snapshots"), "pet.gd should capture click screenshots for debugging")
	_assert(script.contains("Pet: animation_play interaction="), "pet.gd should log resolved click animation playback")
	_assert(not script.contains("_pulse_visual(Vector2(1.18, 0.88)"), "single click visual feedback should not squash/stretch the cat non-uniformly")
	_assert(not script.contains("_pulse_visual(Vector2(1.34, 0.78)"), "double click visual feedback should not squash/stretch the cat non-uniformly")
	_assert(script.contains("_pulse_visual(Vector2(1.06, 1.06)"), "single click visual feedback should use a subtle uniform scale")
	_assert(script.contains("_pulse_visual(Vector2(1.10, 1.10)"), "double click visual feedback should use a clear uniform scale")
	_assert(script.contains("DisplayServer.mouse_get_position() - _drag_start_screen_mouse"), "drag should use absolute screen mouse delta")
	_assert(script.contains("DragResizeSystem.move_window_to(_drag_start_window_pos + delta)"), "drag should move window by the same screen delta")

	var start_drag_body := _function_body(script, "_start_drag")
	var end_drag_body := _function_body(script, "_end_drag")
	var motion_body := _function_body(script, "_handle_mouse_motion")
	var right_button_body := _function_body(script, "_handle_mouse_button")
	var mouse_entered_body := _function_body(script, "_on_mouse_entered")
	var mouse_exited_body := _function_body(script, "_on_mouse_exited")
	var process_body := _function_body(script, "_process")
	_assert(script.contains("_drag_started_from_hold"), "pet drag should remember whether it started after long-press feedback")
	_assert(start_drag_body.contains("_drag_started_from_hold = _long_press_triggered"), "drag start should preserve long-press state before changing drag flags")
	_assert(start_drag_body.contains("PetManager.PetInteraction.CLICKED_HOLD"), "drag after long press should keep clicked_hold feedback instead of restoring hover immediately")
	_assert(end_drag_body.contains("_drag_started_from_hold"), "drag end should branch on whether the drag started from hold")
	_assert(end_drag_body.contains("_schedule_return_after_hold()"), "drag end after hold should use the normal hold return path")
	_assert(not motion_body.contains("CLICKED_HOLD"), "mouse motion during drag must not request clicked_hold directly")
	_assert(script.contains("func _register_click_release"), "click release should be centralized for single/double arbitration")
	_assert(script.contains("func _fire_click_interaction"), "single/double feedback should use one firing helper")
	_assert(right_button_body.contains("MOUSE_BUTTON_RIGHT"), "right-click branch should be explicit")
	_assert(right_button_body.contains("_reset_press_tracking()"), "right-click should clear pending click/hold/drag tracking")
	_assert(right_button_body.contains("DragResizeSystem.show_context_menu()"), "right-click should open the context menu")
	_assert(right_button_body.contains("set_input_as_handled"), "right-click should mark the input as handled")
	_assert(mouse_entered_body.contains("_can_enter_hover()"), "hover should not interrupt stronger click/hold interactions")
	_assert(mouse_exited_body.contains("_can_enter_hover()"), "mouse exit should not return to base state while click/hold feedback is active")
	_assert(process_body.contains("_fire_click_interaction(PetManager.PetInteraction.CLICKED_SINGLE)"), "single click should fire only after the double-click window expires")


func _check_pet_hit_geometry() -> void:
	var pet_script := FileAccess.get_file_as_string("res://src/scenes/pet/pet.gd")
	var main_script := FileAccess.get_file_as_string("res://src/scenes/main/main.gd")
	var pet_scene_text := FileAccess.get_file_as_string("res://src/scenes/pet/pet.tscn")
	_assert(pet_script.contains("func get_interaction_rect"), "Pet should expose runtime interaction rect for v0.4 hit testing")
	_assert(pet_script.contains("_sync_hit_geometry"), "Pet should sync Area2D collision to the current sprite texture")
	_assert(pet_script.contains("_get_current_texture_visible_rect"), "Pet hit geometry should use the current frame alpha-visible bounds")
	_assert(pet_script.contains("image.get_pixel(x, y).a"), "Pet alpha-visible bounds should inspect texture alpha, not just full texture size")
	_assert(pet_script.contains("FALLBACK_TEXTURE_SIZE := Vector2(256, 256)"), "Pet hit geometry should be based on the v2 256px sprite size")
	_assert(not pet_script.contains("HIT_RECT := Rect2(Vector2(62, 80), Vector2(98, 86))"), "Pet should not keep the old tiny 98x86 static hit rect")
	_assert(main_script.contains("PET_HIT_PADDING"), "Main passthrough whitelist should pad the sprite-derived pet hit rect")
	_assert(main_script.contains("_get_pet_interaction_rect_for_passthrough"), "Main passthrough whitelist should use Pet's alpha-visible interaction rect")
	_assert(pet_scene_text.contains("size = Vector2(234, 230)"), "Pet scene default collision should match the v2 visible sprite footprint")

	var scene: PackedScene = load("res://src/scenes/pet/pet.tscn")
	_assert(scene != null, "Pet scene should load for runtime hit geometry check")
	if scene == null:
		return
	var pet_node: Node = scene.instantiate()
	root.add_child(pet_node)
	await process_frame
	if pet_node.has_method("get_interaction_rect"):
		var rect: Rect2 = pet_node.call("get_interaction_rect")
		_assert(rect.size.x >= 170.0 and rect.size.y >= 155.0, "Runtime pet hit rect should cover the v2 alpha-visible cat, got %s" % str(rect))
		_assert(rect.size.x < 230.0 and rect.size.y < 230.0, "Runtime pet hit rect should be tighter than the full transparent texture, got %s" % str(rect))
		_assert(rect.has_point(Vector2(112, 112)), "Runtime pet hit rect should include the sprite visual center")
	pet_node.queue_free()


func _check_panel_hover_coordination() -> void:
	var panel_system_script := FileAccess.get_file_as_string("res://src/autoload/panel_system.gd")
	var pet_script := FileAccess.get_file_as_string("res://src/scenes/pet/pet.gd")
	var panel_script := FileAccess.get_file_as_string("res://src/scenes/panel/panel.gd")
	_assert(panel_system_script.contains("const HOVER_DELAY := 0.3"), "Panel hover should keep a short intentional expand delay")
	_assert(panel_system_script.contains("const LEAVE_DELAY := 0.5"), "Panel leave delay should prevent flicker when moving between pet and panel")
	_assert(panel_system_script.contains("func _is_mouse_over_panel"), "Panel hover should poll mouse position so slow native-window entry cannot miss mouse_entered")
	_assert(panel_system_script.contains("_mouse_over = _is_mouse_over_panel()"), "PanelSystem should refresh hover state every frame")
	_assert(panel_system_script.contains("_panel.expand()"), "PanelSystem should own panel expansion")
	_assert(panel_system_script.contains("_panel.collapse()"), "PanelSystem should own panel collapse")
	_assert(not panel_system_script.contains("PetManager.request_interaction"), "Panel hover should not directly change pet interaction state")
	_assert(not pet_script.contains("PanelSystem"), "Pet hover should not directly control PanelSystem")
	_assert(panel_script.contains("signal layout_changed"), "Panel should notify Main after expand/collapse layout changes")
	_assert(panel_script.contains("mouse_filter = Control.MOUSE_FILTER_STOP"), "Panel root should accept hover instead of passing all mouse handling through")


func _check_window_passthrough_debugging() -> void:
	var main_script := FileAccess.get_file_as_string("res://src/scenes/main/main.gd")
	for required_text in [
		"_hit_debug_layer",
		"_hit_debug_enabled",
		"_create_hit_debug_layer",
		"_sync_hit_debug_layer",
		"_get_hit_debug_rects",
		"_request_mouse_passthrough_refresh",
		"_apply_mouse_passthrough(reason: String",
		"pet_core",
		"pet_context",
		"panel",
		"window_pos",
		"scale"
	]:
		_assert(main_script.contains(required_text), "Main should expose v0.4 passthrough debug text: %s" % required_text)

	_assert(main_script.contains("set_hit_debug_enabled"), "Debug hit areas should be toggleable")
	_assert(main_script.contains("if not _debug_mode"), "Hit debug overlay should be gated behind debug mode")
	_assert(main_script.contains("_last_passthrough_rects_hash"), "Main should keep passthrough rect hash throttling")
	_assert(main_script.contains("reason=%s"), "Passthrough refresh logs should include a reason")
	_assert(main_script.contains("Platform.set_mouse_passthrough(get_window(), false, [])"), "Modal/popup safety paths should clear passthrough")

	var platform_script := FileAccess.get_file_as_string("res://src/platform/windows_platform.gd")
	_assert(platform_script.contains("_read_native_error(\"set_mouse_passthrough failed\")"), "Native passthrough failure should expose readable error")
	_assert(platform_script.contains("_native_health[\"last_error\"]"), "Native passthrough failure should update last_error")


func _check_panel_edge_positioning() -> void:
	var main_script := FileAccess.get_file_as_string("res://src/scenes/main/main.gd")
	for required_text in [
		"_resolve_panel_position",
		"_get_panel_target_size",
		"PET_MODE_PANEL_BOTTOM_RIGHT_POSITION"
	]:
		_assert(main_script.contains(required_text), "Main should expose v0.4 fixed panel positioning text: %s" % required_text)

	var position_body := _function_body(main_script, "_position_panel")
	_assert(position_body.contains("_resolve_panel_position"), "Panel positioning should use the shared edge resolver")
	_assert(not main_script.contains("Panel edge fallback"), "Panel edge auto-reposition fallback should be removed after manual verification feedback")

	var main_scene_script = load("res://src/scenes/main/main.gd")
	_assert(main_scene_script != null, "main.gd should load for panel positioning behavior checks")
	if main_scene_script == null:
		return
	var main_node = main_scene_script.new()
	var screen := Vector2i(1920, 1080)
	var panel_size := Vector2i(310, 220)
	_assert(main_node.call("_resolve_panel_position", Vector2i(1200, 700), screen, panel_size) == Vector2(300, 104), "Panel should keep default right-side position when it fits")
	_assert(main_node.call("_resolve_panel_position", Vector2i(1550, 700), screen, panel_size) == Vector2(300, 104), "Panel should no longer move left near the right edge")
	_assert(main_node.call("_resolve_panel_position", Vector2i(1200, 800), screen, panel_size) == Vector2(300, 104), "Panel should no longer move up near the bottom edge")
	_assert(main_node.call("_resolve_panel_position", Vector2i(1550, 800), screen, panel_size) == Vector2(300, 104), "Panel should keep the same anchor near the bottom-right corner")
	main_node.free()


func _check_panel_collapsed_layout() -> void:
	var panel_scene := load("res://src/scenes/panel/panel.tscn")
	_assert(panel_scene != null, "panel.tscn should load for collapsed layout checks")
	if panel_scene == null:
		return
	var panel = panel_scene.instantiate()
	root.add_child(panel)
	await process_frame
	panel.collapse()
	await process_frame
	var coin_label: Label = panel.get_node("Collapsed/CollapsedContent/CoinMark")
	var label: Label = panel.get_node("Collapsed/CollapsedContent/CollapsedValue/EarningsToday")
	var status_label: Label = panel.get_node("Collapsed/CollapsedContent/CollapsedValue/ShortStatus")
	var content: Control = panel.get_node("Collapsed/CollapsedContent")
	var collapsed: Control = panel.get_node("Collapsed")
	var vertical_center_delta: float = abs((content.position.y + content.size.y * 0.5) - collapsed.size.y * 0.5)
	_assert(collapsed.size.x >= 210.0, "Collapsed panel should keep a comfortable warm-widget width")
	_assert(collapsed.size.y >= 62.0, "Collapsed panel should keep a comfortable warm-widget height")
	_assert(vertical_center_delta <= 2.0, "Collapsed panel coin, amount and short status should stay vertically centered")
	_assert(content.size.x <= collapsed.size.x - 8.0, "Collapsed panel amount and short status should fit inside the collapsed panel")
	_assert(coin_label.text.strip_edges() != "", "Collapsed panel should include a coin counter mark")
	_assert(label.text.strip_edges() != "", "Collapsed panel should keep amount in the value stack")
	_assert(status_label.text.strip_edges() != "", "Collapsed panel should show a short status under the amount")
	panel.expand()
	await process_frame
	var expanded: VBoxContainer = panel.get_node("Expanded")
	var expected_order := ["TodayRow", "StateRow", "MonthRow", "RateRow", "ProgressRow"]
	for i in range(expected_order.size()):
		_assert(expanded.get_child(i).name == expected_order[i], "Expanded panel row %d should be %s, got %s" % [i, expected_order[i], expanded.get_child(i).name])
	var today_value: Label = panel.get_node("Expanded/TodayRow/TodayValue")
	var month_value: Label = panel.get_node("Expanded/MonthRow/MonthValue")
	var today_font_size: int = today_value.get_theme_font_size("font_size")
	var month_font_size: int = month_value.get_theme_font_size("font_size")
	_assert(today_font_size >= 34, "Expanded panel primary amount should be the warm receipt hero value")
	_assert(today_font_size > month_font_size, "Expanded panel should visually prioritize today's earnings")
	var panel_script := FileAccess.get_file_as_string("res://src/scenes/panel/panel.gd")
	for required_text in [
		"SURFACE_PAPER",
		"SURFACE_PAPER_STRONG",
		"TEXT_INK",
		"TEXT_MUTED",
		"ACCENT_COIN",
		"ACCENT_ORANGE",
		"ACCENT_MINT",
		"BORDER_WARM",
		"SHADOW_WARM"
	]:
		_assert(panel_script.contains(required_text), "Panel should define warm-widget design token: %s" % required_text)
	_assert(panel_script.contains("coin_mark_label"), "Collapsed panel should render a coin mark instead of a black capsule only")
	_assert(panel_script.contains("_build_number_font"), "Panel should use a stable numeric font path for money values")
	panel.queue_free()


func _check_scale_variant_layout() -> void:
	var main_script_text := FileAccess.get_file_as_string("res://src/scenes/main/main.gd")
	for required_text in [
		"_pet_window_size_for_scale",
		"_pet_sprite_bounds_for_scale",
		"_panel_target_size_for_scale",
		"PET_TEXTURE_SIZE",
		"PET_CONTENT_MARGIN"
	]:
		_assert(main_script_text.contains(required_text), "Main should expose v0.4 scale layout helper text: %s" % required_text)
	_assert(main_script_text.contains("set_display_scale"), "Display scale should resize Panel using real layout/font sizes instead of scaled canvas text")

	var main_script := load("res://src/scenes/main/main.gd")
	_assert(main_script != null, "main.gd should load for scale variant checks")
	if main_script == null:
		return
	var main_node = main_script.new()
	var margin := 24.0
	var panel_margin := 12.0
	for scale_value in [0.5, 0.75, 1.0, 1.25, 1.5, 2.0]:
		var window_size: Vector2i = main_node.call("_pet_window_size_for_scale", scale_value)
		var pet_bounds: Rect2 = main_node.call("_pet_sprite_bounds_for_scale", scale_value)
		var panel_size: Vector2i = main_node.call("_panel_target_size_for_scale", scale_value)
		var panel_rect := Rect2(Vector2(300, 104), Vector2(panel_size))
		_assert(pet_bounds.position.x >= 0.0, "Pet sprite should not clip left at scale %.2f" % scale_value)
		_assert(pet_bounds.position.y >= 0.0, "Pet sprite should not clip top at scale %.2f" % scale_value)
		_assert(pet_bounds.end.x <= float(window_size.x) - margin, "Pet sprite should not clip right at scale %.2f" % scale_value)
		_assert(pet_bounds.end.y <= float(window_size.y) - margin, "Pet sprite should not clip bottom at scale %.2f" % scale_value)
		_assert(panel_rect.end.x <= float(window_size.x) - panel_margin, "Panel should not overflow right at scale %.2f" % scale_value)
		_assert(panel_rect.end.y <= float(window_size.y) - panel_margin, "Panel should not overflow bottom at scale %.2f" % scale_value)
	main_node.free()


func _check_context_menu_ui_polish() -> void:
	var drag_script := FileAccess.get_file_as_string("res://src/autoload/drag_resize_system.gd")
	_assert(drag_script.contains("menu.add_submenu_item"), "Context menu should expose grouped submenus")
	_assert(drag_script.contains("window_submenu.name"), "Context menu should attach the window mode submenu")
	_assert(drag_script.contains("pet_submenu.name"), "Context menu should attach the pet selection submenu")
	_assert(drag_script.contains("_build_window_mode_submenu"), "Context menu should build a dedicated window mode submenu")
	_assert(drag_script.contains("_build_pet_submenu"), "Context menu should build a dedicated pet selection submenu")
	_assert(drag_script.contains(", 300)"), "Window mode submenu should contain top mode")
	_assert(drag_script.contains(", 301)"), "Window mode submenu should contain embed mode")
	_assert(drag_script.contains("200 + i"), "Pet submenu should list available pets")
	_assert(drag_script.contains("func _get_popup_menu_theme"), "Context menu should use a dedicated theme instead of default PopupMenu styling")
	_assert(drag_script.contains("MENU_FONT_NAMES"), "Context menu should use explicit Windows Chinese system fonts")
	_assert(drag_script.contains("TextServer.FONT_ANTIALIASING_LCD"), "Context menu font should use LCD antialiasing for sharper small text")
	_assert(drag_script.contains("menu.transparent_bg = true"), "Context menu should enable transparent popup corners")
	_assert(drag_script.contains("menu.borderless = true"), "Context menu should avoid native window chrome")
	_assert(drag_script.contains("theme.set_stylebox(\"panel\", \"PopupMenu\""), "Context menu should style its popup panel")
	_assert(drag_script.contains("theme.set_stylebox(\"hover\", \"PopupMenu\""), "Context menu should style hover rows")
	_assert(drag_script.contains("SURFACE_PAPER"), "Context menu should share warm paper surface tokens with Panel")
	_assert(drag_script.contains("TEXT_INK"), "Context menu should use warm ink text instead of cold dark UI text")
	_assert(drag_script.contains("ACCENT_COIN"), "Context menu should use coin accent for selected/hover states")
	_assert(drag_script.contains("BORDER_WARM"), "Context menu should use warm paper border")
	_assert(drag_script.contains("SHADOW_WARM"), "Context menu should use warm brown shadow instead of pure black glass shadow")
	_assert(drag_script.contains("theme.set_constant(\"item_min_height\", \"PopupMenu\", 34)"), "Context menu should keep comfortable warm-widget item height")
	_assert(drag_script.contains("panel_style.set_corner_radius_all(14)"), "Context menu should use rounded paper-widget corners")


func _check_icon_polish_assets() -> void:
	for size in [16, 24, 32, 48, 64, 128, 256]:
		_assert(FileAccess.file_exists("res://icons/app_icon_%d.png" % size), "v0.4 icon polish missing %dpx png" % size)
		_assert(_png_has_clean_transparent_edge("res://icons/app_icon_%d.png" % size), "v0.4 icon %dpx should not carry black RGB in transparent edge pixels" % size)
		_assert(_png_has_antialiased_alpha("res://icons/app_icon_%d.png" % size), "v0.4 icon %dpx should keep antialiased rounded alpha instead of hard black/transparent corners" % size)
	_assert(FileAccess.file_exists("res://icons/app_icon.png"), "v0.4 icon polish should keep app_icon.png for docs/prototypes")
	_assert(_png_has_clean_transparent_edge("res://icons/app_icon.png"), "v0.4 app_icon.png should not carry black RGB in transparent edge pixels")
	_assert(_png_has_antialiased_alpha("res://icons/app_icon.png"), "v0.4 app_icon.png should keep antialiased rounded alpha")
	_assert(FileAccess.file_exists("res://icons/app_icon.ico"), "v0.4 icon polish should generate app_icon.ico")
	var export_preset := FileAccess.get_file_as_string("res://export_presets.cfg")
	_assert(export_preset.contains("application/icon=\"res://icons/app_icon.ico\""), "Export preset should use v0.4 app_icon.ico")
	var project_settings := FileAccess.get_file_as_string("res://project.godot")
	_assert(project_settings.contains("config/icon=\"res://icons/app_icon.png\""), "Project runtime icon should use the v0.4 app icon instead of Godot's default icon")
	var main_script := FileAccess.get_file_as_string("res://src/scenes/main/main.gd")
	_assert(main_script.contains("_get_tray_icon_path"), "Native tray should resolve a real filesystem icon path")
	_assert(main_script.contains("OS.get_executable_path().get_base_dir().path_join(\"app_icon.ico\")"), "Native tray should prefer app_icon.ico beside the exported exe")
	_assert(main_script.contains("_ensure_tray_icon_file"), "Native tray should copy an ico fallback out of res:// when needed")
	_assert(not main_script.contains("Platform.setup_tray(ProjectSettings.globalize_path(\"res://icons/app_icon.ico\"))"), "Native tray should not receive only a raw res:// globalized path")
	_assert(main_script.contains("DisplayServer.set_icon"), "Runtime window/taskbar icon should be set explicitly")
	var drag_script := FileAccess.get_file_as_string("res://src/autoload/drag_resize_system.gd")
	_assert(drag_script.contains("AcceptDialog.new()"), "About window should use an in-app dialog instead of a system alert")
	_assert(drag_script.contains("res://icons/app_icon.png"), "About window should show the high resolution app icon")
	_assert(drag_script.contains("AppVersionScript.get_display_version"), "About window should use the shared current version label")
	_assert(drag_script.contains("MODAL_WINDOW_SIZE := Vector2i(700, 530)"), "Settings/modal host should use the compact preferences baseline")
	_assert(drag_script.contains("_window.borderless = true"), "Settings/modal host should not show the native Windows title bar")
	_assert(drag_script.contains("_window.transparent_bg = true"), "Settings/modal host should keep transparent corners instead of a black rectangular background")
	_assert(drag_script.contains("WINDOW_FLAG_TRANSPARENT"), "Settings/modal host should enable the transparent window flag for rounded corners")
	_assert(main_script.contains("_apply_viewport_transparency(true)"), "Modal settings should keep viewport alpha transparent so rounded corners do not reveal black")


func _check_window_recovery_fallbacks() -> void:
	var main_script := FileAccess.get_file_as_string("res://src/scenes/main/main.gd")
	var pure_pet_body := _function_body(main_script, "_apply_pure_pet_mode")
	var hide_body := _function_body(main_script, "can_hide_to_tray")
	_assert(hide_body.contains("_tray_ready"), "Tray hide should require a ready tray so taskbar remains available when tray is missing")
	_assert(hide_body.contains("minimize_to_tray"), "Tray hide should obey minimize_to_tray config")
	for required_text in [
		"not _tray_ready",
		"Platform.can_enable_pure_pet_mode",
		"Config.set_value(\"pure_pet_mode\", false)",
		"_set_taskbar_visible_cached(true)"
	]:
		_assert(pure_pet_body.contains(required_text), "Pure pet fallback missing text: %s" % required_text)

	var platform_script := FileAccess.get_file_as_string("res://src/platform/windows_platform.gd")
	var setup_body := _function_body(platform_script, "setup_window")
	for required_text in [
		"_native_health[\"window_supported\"] = false",
		"window.borderless = false",
		"window.transparent_bg = false",
		"_set_transparent_window_flag(window, false)"
	]:
		_assert(setup_body.contains(required_text), "Native window setup fallback missing text: %s" % required_text)

	var config_script := FileAccess.get_file_as_string("res://src/autoload/config.gd")
	_assert(config_script.contains("JSON.parse_string"), "Config should parse JSON rather than use ad hoc string handling")
	_assert(config_script.contains("merge_with_defaults(parsed)"), "Config should merge partial configs with defaults")
	_assert(config_script.contains("data = _defaults().duplicate(true)"), "Config should fall back to defaults when file is missing or corrupt")

	var config := root.get_node_or_null("/root/Config")
	_assert(config != null, "Config autoload should exist")
	if config != null:
		var merged: Dictionary = config.call("merge_with_defaults", {"panel_items": {"status": false}})
		_assert(merged.get("debug_mode") == false, "Merged config should provide missing debug_mode default")
		_assert(merged.get("pure_pet_mode") == false, "Merged config should provide missing pure_pet_mode default")
		_assert(merged.get("panel_items", {}).get("status") == false, "Merged config should preserve provided nested values")
		_assert(merged.get("panel_items", {}).has("earnings_today"), "Merged config should fill missing nested panel defaults")


func _check_settings_information_architecture() -> void:
	var settings_script := FileAccess.get_file_as_string("res://src/scenes/settings/settings_dialog.gd")
	for tab_name in [
		"_build_salary_tab",
		"_build_pet_tab",
		"_build_display_tab",
		"_build_panel_tab",
		"_build_general_tab"
	]:
		_assert(settings_script.contains(tab_name), "Settings should keep v0.4 section builder: %s" % tab_name)
	_assert(not settings_script.contains("_build_theme_tab"), "Settings should not add Theme as a v0.4 tab")
	_assert(not settings_script.contains("\"Theme\""), "Settings should not expose Theme as a v0.4 tab")
	_assert(settings_script.contains("_build_compact_ui"), "Settings should build the compact single-shell preferences UI")
	_assert(settings_script.contains("SettingsTopBar"), "Settings should keep a compact draggable top bar inside the shell")
	_assert(settings_script.contains("SettingsSurface"), "Settings should draw its own warm paper surface instead of relying on the native window frame")
	for required_token in [
		"SURFACE_APP",
		"SURFACE_CARD",
		"SURFACE_SELECTED",
		"TEXT_INK",
		"TEXT_MUTED",
		"ACCENT_COIN",
		"ACCENT_ORANGE",
		"BORDER_WARM",
		"SHADOW_WARM"
	]:
		_assert(settings_script.contains(required_token), "Settings should share warm-widget design token: %s" % required_token)
	_assert(settings_script.contains("_on_header_gui_input"), "Borderless settings should keep a draggable custom header")
	_assert(settings_script.contains("custom_minimum_size = Vector2(700, 530)"), "Settings should use the compact v0.4 preferences size")
	_assert(settings_script.contains("CloseButton"), "Settings header should expose a top-right close button")
	_assert(settings_script.contains("ActionRow"), "Settings should keep save/cancel in a dedicated bottom action row")
	_assert(settings_script.contains("ScrollContainer.new()"), "Settings pages should scroll independently so Display can contain long content")
	_assert(not settings_script.contains("top_save_button"), "Settings header should not contain the primary Save action")
	_assert(not settings_script.contains("top_cancel_button"), "Settings header should not contain the Cancel action")
	_assert(settings_script.contains("SettingsShell"), "Settings should collect header, tabs, content, and actions inside one preferences shell")
	_assert(settings_script.contains("SettingsNav"), "Settings should use warm segmented navigation")
	_assert(settings_script.contains("SettingsNavSegment"), "Settings navigation should sit inside the single shell")
	_assert(settings_script.contains("SettingsContentPages"), "Settings should keep an in-shell content page holder")
	_assert(settings_script.contains("_select_settings_section"), "Settings should switch pages through the segmented navigation")
	_assert(not settings_script.contains("TabContainer.new()"), "Settings should not use the old top TabContainer layout")
	_assert(settings_script.contains("func _add_setting_card"), "Settings should build card-style setting rows")
	_assert(settings_script.contains("SettingCardTitle"), "Setting cards should keep a title")
	_assert(settings_script.contains("SettingCardDescription"), "Setting cards should keep explanatory text")
	_assert(settings_script.contains("func _add_control_card"), "Settings should place controls inside compact setting rows")
	_assert(settings_script.contains("func _style_button"), "Settings should style buttons instead of relying on default Godot controls")
	_assert(settings_script.contains("func _style_window_button"), "Settings should give the shell close button a refined custom style")
	_assert(settings_script.contains("_style_window_button(close_button, true)"), "Settings close button should use a quiet destructive hover style")
	_assert(settings_script.contains("close_button.custom_minimum_size = Vector2(28, 28)"), "Settings close button should stay compact instead of being oversized")
	_assert(settings_script.contains("TextServer.FONT_ANTIALIASING_LCD"), "Settings should use sharper LCD font antialiasing")
	_assert(settings_script.contains("func _style_nav_button"), "Settings should style warm segmented navigation")
	_assert(settings_script.contains("func _style_form_control"), "Settings should style form controls for better readability")

	var pet_body := _function_body(settings_script, "_build_pet_tab")
	var display_body := _function_body(settings_script, "_build_display_tab")
	var general_body := _function_body(settings_script, "_build_general_tab")
	_assert(not pet_body.contains("scale_slider"), "Scale control should move out of Pet tab in v0.4")
	for required_text in [
		"opacity_slider",
		"scale_slider",
		"window_mode_option",
		"pure_pet_mode_toggle",
		"Alt+Tab"
	]:
		_assert(display_body.contains(required_text), "Display tab should explain/manage window experience: %s" % required_text)
	for required_text in [
		"debug_mode_toggle",
		"auto_start_toggle",
		"minimize_to_tray_toggle",
		"reset_position_button",
		"restore_defaults_button"
	]:
		_assert(general_body.contains(required_text), "General tab should manage app-level setting: %s" % required_text)
	_assert(settings_script.contains("last_error"), "Native status should show a readable unavailable reason")
	_assert(settings_script.contains("SettingsRoot"), "Settings should render as a single in-window content root")
	_assert(not settings_script.contains("TextureRect.new()"), "Settings should not turn into a decorative pet/image page")
	for forbidden_marketing_text in ["鏋佺畝鐢熶骇鍔涘皬宸ュ叿", "瀹犵墿闄即", "涓婚鍟嗗簵", "閫夋嫨涓婚"]:
		_assert(not settings_script.contains(forbidden_marketing_text), "Settings should not contain marketing/theme text: %s" % forbidden_marketing_text)
	_assert(settings_script.contains("SystemFont.new()"), "Settings should use an explicit system CJK font for readable Chinese text")
	_assert(settings_script.contains("Microsoft YaHei UI"), "Settings font fallback should include Microsoft YaHei UI")
	_assert(settings_script.contains("_add_note_label"), "Display status labels should use a full-width low-weight note region instead of narrow right-side controls")


func _check_wizard_warm_widget_polish() -> void:
	var wizard_script := FileAccess.get_file_as_string("res://src/scenes/wizard/wizard_dialog.gd")
	var wizard_scene := FileAccess.get_file_as_string("res://src/scenes/wizard/wizard_dialog.tscn")
	var drag_script := FileAccess.get_file_as_string("res://src/autoload/drag_resize_system.gd")
	var main_script := FileAccess.get_file_as_string("res://src/scenes/main/main.gd")
	for required_text in [
		"WizardSurface",
		"WizardRoot",
		"SURFACE_APP",
		"SURFACE_CARD",
		"TEXT_INK",
		"TEXT_MUTED",
		"ACCENT_COIN",
		"BORDER_WARM",
		"SHADOW_WARM",
		"_build_wizard_theme",
		"_style_button",
		"_style_form_control",
		"TextServer.FONT_ANTIALIASING_LCD",
		"Microsoft YaHei UI"
	]:
		_assert(wizard_script.contains(required_text), "Wizard should share warm-widget visual system: %s" % required_text)
	_assert(wizard_script.contains("extends Control"), "Wizard should be hosted as a single-window Control content view")
	_assert(not wizard_script.contains("extends ConfirmationDialog"), "Wizard should not open as a nested ConfirmationDialog")
	_assert(wizard_scene.contains("type=\"Control\""), "Wizard scene root should be Control")
	_assert(wizard_script.contains("WizardActionRow"), "Wizard should keep visible custom navigation buttons")
	_assert(drag_script.contains("const WIZARD_DIALOG_SIZE := Vector2i(620, 460)"), "Wizard modal host should be further compact for v0.4 reconfiguration")
	_assert(wizard_script.contains("custom_minimum_size = Vector2(620, 460)"), "Wizard content should match the compact modal host size")
	_assert(wizard_script.contains("WizardSalaryRows"), "Wizard salary page should use compact setting rows instead of sparse stacked controls")
	_assert(wizard_script.contains("WizardConfirmRows"), "Wizard confirm page should use compact summary rows instead of one sparse text block")
	_assert(wizard_script.contains("func _add_field_row"), "Wizard should have reusable compact row layout for form fields")
	_assert(wizard_script.contains("func _add_summary_row"), "Wizard should have reusable compact row layout for summary fields")
	_assert(wizard_script.contains("func _style_option_popup"), "Wizard OptionButton popups should be themed to warm paper style")
	_assert(wizard_script.contains("func _style_option_button"), "Wizard OptionButton should use the same compact warm body styling as Settings")
	_assert(wizard_script.contains("option.get_popup()"), "Wizard OptionButton should style its popup menu instead of using the dark default")
	_assert(wizard_script.contains("popup.transparent_bg = true"), "Wizard OptionButton popup should avoid dark system popup corners")
	_assert(wizard_script.contains("popup.add_theme_icon_override(\"radio_checked\", _make_popup_check_icon(true))"), "Wizard OptionButton popup should replace default radio dots with warm check icons")
	_assert(wizard_script.contains("option.add_theme_icon_override(\"arrow\", _make_dropdown_arrow())"), "Wizard OptionButton should use a warm dropdown arrow instead of the default icon")
	_assert(wizard_script.contains("line_edit.add_theme_stylebox_override(\"read_only\""), "Wizard read-only work-hours SpinBox should be styled like Settings")
	_assert(wizard_script.contains("WizardPetRows"), "Wizard pet selection should expose a compact Settings-like pet selection block")
	_assert(wizard_script.contains("item_list.add_theme_stylebox_override(\"selected\""), "Wizard pet ItemList should use Settings-like selected styling")
	_assert(not wizard_script.contains("summary_label.text = \"月薪 ¥%d\\n"), "Wizard confirm page should not rely on a multiline sparse summary label")
	_assert(wizard_script.contains("Config.set_value(\"monthly_salary\""), "Wizard should keep existing salary save flow")
	_assert(wizard_script.contains("PetManager.get_available_pets"), "Wizard should keep existing pet selection flow")
	var open_wizard_body := _function_body(drag_script, "_open_wizard")
	_assert(open_wizard_body.contains("var wizard_view: Control"), "Menu wizard should be hosted as a Control content view")
	_assert(open_wizard_body.contains("wizard_view.set_anchors_preset(Control.PRESET_FULL_RECT)"), "Menu wizard should fill the host window")
	_assert(not open_wizard_body.contains("popup_centered"), "Menu wizard should not open as a nested popup")
	var first_run_body := _function_body(main_script, "_show_wizard")
	_assert(first_run_body.contains("var wizard_view: Control"), "First-run wizard should be hosted as a Control content view")
	_assert(first_run_body.contains("wizard_view.set_anchors_preset(Control.PRESET_FULL_RECT)"), "First-run wizard should fill the host window")
	_assert(not first_run_body.contains("popup_centered"), "First-run wizard should not open as a nested popup")

	var scene := load("res://src/scenes/wizard/wizard_dialog.tscn")
	_assert(scene != null, "wizard_dialog.tscn should load for layout check")
	if scene == null:
		return
	var wizard: Control = scene.instantiate()
	wizard.set_anchors_preset(Control.PRESET_TOP_LEFT)
	wizard.size = Vector2(620, 460)
	root.add_child(wizard)
	await process_frame
	await process_frame
	var action_row := wizard.find_child("WizardActionRow", true, false) as Control
	var salary_rows := wizard.find_child("WizardSalaryRows", true, false) as Control
	var pet_rows := wizard.find_child("WizardPetRows", true, false) as Control
	var confirm_rows := wizard.find_child("WizardConfirmRows", true, false) as Control
	var next_button := wizard.get("next_btn") as Button
	_assert(action_row != null and action_row.visible, "Wizard action row should be visible in the host window")
	_assert(salary_rows != null, "Wizard salary page should expose compact salary rows for layout verification")
	_assert(pet_rows != null, "Wizard pet page should expose compact pet rows for layout verification")
	_assert(confirm_rows != null, "Wizard confirm page should expose compact summary rows for layout verification")
	_assert(next_button != null and next_button.visible, "Wizard Next button should be visible on the welcome step")
	if action_row != null:
		_assert(action_row.position.y + action_row.size.y <= wizard.size.y, "Wizard action row should fit inside the compact host window")
	wizard.queue_free()


func _check_settings_display_status_layout() -> void:
	var scene := load("res://src/scenes/settings/settings_dialog.gd")
	_assert(scene != null, "settings_dialog.gd should load for Display layout check")
	if scene == null:
		return
	var settings = scene.new()
	root.add_child(settings)
	settings.size = Vector2(880, 640)
	settings.call("_select_settings_section", "Display")
	await process_frame
	await process_frame
	var status_label := settings.find_child("NativeStatusLabel", true, false) as Label
	_assert(status_label != null, "Display tab should expose NativeStatusLabel for native capability status")
	if status_label != null:
		_assert(status_label.size.x >= 520.0, "NativeStatusLabel should be full-width and must not collapse into vertical text")
		_assert(status_label.autowrap_mode != TextServer.AUTOWRAP_OFF, "NativeStatusLabel should wrap normally inside its full-width card")
	settings.queue_free()


func _check_settings_save_feedback() -> void:
	var settings_script := FileAccess.get_file_as_string("res://src/scenes/settings/settings_dialog.gd")
	for required_text in [
		"save_status_label",
		"_collect_form_values",
		"_current_settings_snapshot",
		"_has_form_changes",
		"_apply_form_values",
		"_set_save_status",
	]:
		_assert(settings_script.contains(required_text), "Settings save feedback missing text: %s" % required_text)

	var save_body := _function_body(settings_script, "_on_save")
	_assert(save_body.contains("_has_form_changes"), "Save should compare form values before writing config")
	_assert(save_body.contains("_apply_form_values"), "Save should apply only after change detection")
	_assert(save_body.contains("_set_save_status"), "Save should show status feedback")
	_assert(save_body.contains("return"), "No-change or failed save paths should keep the settings window open")

	var auto_start_body := _function_body(settings_script, "_apply_auto_start_setting")
	_assert(auto_start_body.contains("desired == actual"), "Auto start should skip registry writes when unchanged")


func _check_settings_restore_and_debug_help() -> void:
	var settings_script := FileAccess.get_file_as_string("res://src/scenes/settings/settings_dialog.gd")
	for required_text in [
		"restore_defaults_confirm_dialog",
		"_show_restore_defaults_confirm",
		"_restore_display_defaults",
		"confirmed.connect",
		"%APPDATA%\\\\LetsMakeMoney\\\\config.json",
	]:
		_assert(settings_script.contains(required_text), "Settings restore/debug help missing text: %s" % required_text)

	var restore_pressed_body := _function_body(settings_script, "_on_restore_defaults_pressed")
	_assert(restore_pressed_body.contains("_show_restore_defaults_confirm"), "Restore defaults button should ask for confirmation first")
	var restore_body := _function_body(settings_script, "_restore_display_defaults")
	_assert(restore_body.contains("Config.reset_display_defaults"), "Confirmed restore should reset display/window settings")
	_assert(restore_body.contains("Platform.set_auto_start(false)"), "Confirmed restore should disable auto-start")


func _check_settings_single_window_host() -> void:
	var drag_script := FileAccess.get_file_as_string("res://src/autoload/drag_resize_system.gd")
	var open_settings_body := _function_body(drag_script, "open_settings")
	_assert(open_settings_body.contains("var settings_view: Control"), "Settings should be hosted as a Control content view")
	_assert(open_settings_body.contains("_window.add_child(settings_view)"), "Settings should be attached to the existing host window")
	_assert(open_settings_body.contains("settings_view.set_anchors_preset(Control.PRESET_FULL_RECT)"), "Settings should fill the host window instead of floating inside it")
	_assert(not open_settings_body.contains("popup_centered"), "Settings should not open as a nested popup window")


func _check_settings_modal_runtime_reapply_guard() -> void:
	var main_script := FileAccess.get_file_as_string("res://src/scenes/main/main.gd")
	_assert(main_script.contains("_runtime_mode_reapply_deferred_until_modal_close"), "Main should track runtime reapply deferred while settings modal is open")

	var config_scope_body := _function_body(main_script, "_apply_config_change_scope")
	_assert(config_scope_body.contains("if _modal_open:"), "Config changes should check whether a modal is open")
	_assert(config_scope_body.contains("deferred debug mode runtime apply until modal closes"), "Debug mode changes should be deferred while settings is open")
	_assert(config_scope_body.contains("deferred window policy apply until modal closes"), "Window policy changes should be deferred while settings is open")

	var schedule_body := _function_body(main_script, "_schedule_runtime_mode_reapply")
	_assert(schedule_body.contains("if _modal_open:"), "Runtime reapply scheduling should defer while settings is open")
	_assert(schedule_body.contains("deferred until modal closes"), "Runtime reapply scheduling should log modal deferral")

	var reapply_body := _function_body(main_script, "_reapply_runtime_mode_after_popups")
	_assert(reapply_body.contains("if _modal_open:"), "Runtime reapply should re-check modal state after the deferred frame")
	_assert(not reapply_body.contains("_modal_open = false"), "Runtime reapply must not mark a modal as closed by itself")

	var modal_closed_body := _function_body(main_script, "_on_modal_closed")
	_assert(modal_closed_body.contains("_modal_open = false"), "Only modal close handling should clear modal-open state")
	_assert(modal_closed_body.contains("_schedule_runtime_mode_reapply"), "Closing a modal should restore the runtime window mode")


func _check_logging_performance_boundaries() -> void:
	var platform_script := FileAccess.get_file_as_string("res://src/autoload/platform.gd")
	for required_text in [
		"func write_boot_log(message: String, level: String = \"info\")",
		"func write_debug_log",
		"_should_write_debug_log",
		"level == \"debug\""
	]:
		_assert(platform_script.contains(required_text), "Platform logging should expose level boundary: %s" % required_text)

	var main_script := FileAccess.get_file_as_string("res://src/scenes/main/main.gd")
	_assert(main_script.contains("Platform.write_debug_log(\"Main._apply_mouse_passthrough"), "Passthrough rect refresh details should be debug-only logs")
	_assert(not main_script.contains("Platform.write_boot_log(\"Main._apply_mouse_passthrough: reason=%s unchanged"), "Unchanged passthrough refresh should not write ordinary logs")

	var windows_platform_script := FileAccess.get_file_as_string("res://src/platform/windows_platform.gd")
	_assert(windows_platform_script.contains("Platform.write_debug_log(\"WindowsPlatform.set_mouse_passthrough"), "Native passthrough call details should be debug-only logs")

	var poll_body := _function_body(platform_script, "_poll_native_tray")
	_assert(poll_body.contains("write_debug_log(\"Platform._poll_native_tray: command=%d\""), "Tray polling command logs should be debug-only")


func _check_runtime_refresh_throttling() -> void:
	var main_script := FileAccess.get_file_as_string("res://src/scenes/main/main.gd")
	for required_text in [
		"_passthrough_refresh_pending",
		"_pending_passthrough_reason",
		"_last_window_position",
		"_last_scale",
		"_last_opacity",
		"_last_taskbar_visible",
		"_last_topmost",
		"_invalidate_taskbar_visibility_cache",
		"_reapply_tray_restore_window_policy",
		"_queue_mouse_passthrough_refresh",
		"_flush_mouse_passthrough_refresh",
		"_apply_config_change_scope",
		"_config_scope_requires_window_policy",
		"_config_scope_requires_salary_refresh"
	]:
		_assert(main_script.contains(required_text), "Main runtime throttling missing text: %s" % required_text)

	var config_changed_body := _function_body(main_script, "_on_config_changed")
	var tray_toggle_body := _function_body(main_script, "_on_tray_toggle_requested")
	var invalidate_body := _function_body(main_script, "_invalidate_taskbar_visibility_cache")
	var tray_restore_body := _function_body(main_script, "_reapply_tray_restore_window_policy")
	_assert(config_changed_body.contains("_apply_config_change_scope"), "Config changes should be routed through a scope-aware handler")
	_assert(invalidate_body.contains("_last_taskbar_visible = null"), "Taskbar visibility cache should be invalidated when native window state may have changed")
	_assert(tray_toggle_body.contains("_reapply_tray_restore_window_policy()"), "Tray restore should run a dedicated native window policy reapply")
	_assert(tray_restore_body.contains("_invalidate_taskbar_visibility_cache(\"tray_restore\")"), "Tray restore should invalidate taskbar cache before reapplying pure pet mode")
	_assert(tray_restore_body.contains("_setup_window()"), "Tray restore should reapply native pet window policy after native show")
	_assert(tray_restore_body.contains("_apply_pure_pet_mode()"), "Tray restore should reapply pure pet mode after native show")
	_assert(tray_restore_body.contains("_invalidate_taskbar_visibility_cache(\"tray_restore_post_frame\")"), "Tray restore should re-check taskbar policy after one frame")
	_assert(tray_restore_body.contains("pure_pet_mode=%s"), "Tray restore should log pure_pet_mode state for manual diagnosis")
	_assert(not config_changed_body.contains("SalaryEngine.reload()\n\t_apply_scale_opacity()"), "Salary changes should not always run full window refresh pipeline")
	_assert(main_script.contains("_queue_mouse_passthrough_refresh(\"panel_layout_changed\")"), "Panel layout changes should queue passthrough refresh")
	_assert(main_script.contains("_queue_mouse_passthrough_refresh(\"panel_reposition\")"), "Panel reposition should queue passthrough refresh")
	_assert(main_script.contains("if window.position != _last_window_position"), "Window move polling should only refresh after actual movement")

	var platform_script := FileAccess.get_file_as_string("res://src/platform/windows_platform.gd")
	for required_text in [
		"_last_topmost_by_window",
		"_last_embed_by_window",
		"_last_taskbar_visibility_by_window",
		"if _last_topmost_by_window.get",
		"if _last_taskbar_visibility_by_window.get"
	]:
		_assert(platform_script.contains(required_text), "WindowsPlatform should cache no-op window calls: %s" % required_text)

	var panel_system_script := FileAccess.get_file_as_string("res://src/autoload/panel_system.gd")
	_assert(panel_system_script.contains("const REFRESH_INTERVAL := 0.5"), "Panel values should remain interval-throttled")
	_assert(panel_system_script.contains("_refresh_timer += delta"), "Panel values should refresh via timer, not debug/window events")


func _check_v04_automation_coverage() -> void:
	_assert(load("res://src/scenes/main/main.tscn") != null, "v0.4 verification should load Main scene")
	_assert(load("res://src/scenes/settings/settings_dialog.tscn") != null, "v0.4 verification should load Settings scene")
	var config := root.get_node_or_null("/root/Config")
	_assert(config != null, "Config autoload should exist for v0.4 default checks")
	if config != null:
		for key in [
			"debug_mode",
			"transparent_pet_window_enabled",
			"mouse_passthrough_enabled",
			"system_tray_enabled",
			"pure_pet_mode",
			"scale",
			"opacity"
		]:
			_assert(config.call("merge_with_defaults", {}).has(key), "v0.4 config defaults should include key: %s" % key)

	var verify_ps1 := FileAccess.get_file_as_string("res://scripts/verify_v04.ps1")
	_assert(verify_ps1.contains("verify_v04.gd"), "verify_v04.ps1 should run verify_v04.gd")
	_assert(verify_ps1.contains("v0.4 verification passed"), "verify_v04.ps1 should print an explicit success message")


func _check_prototype_v04_scope() -> void:
	var prototype := FileAccess.get_file_as_string("res://doc/prototypes/index.html")
	for screen_id in [
		"id=\"overview\"",
		"id=\"desktop\"",
		"id=\"panel\"",
		"id=\"menu\"",
		"id=\"settings\"",
		"id=\"wizard\"",
		"id=\"debug\"",
		"id=\"release\""
	]:
		_assert(prototype.contains(screen_id), "prototype missing current product screen: %s" % screen_id)

	_assert(prototype.contains("按当前真实能力组织"), "prototype should explain the current product-oriented structure")
	_assert(not prototype.contains("screen-v04-theme"), "prototype should not expose v0.4 theme entry")


func _png_has_clean_transparent_edge(path: String) -> bool:
	var image := _load_png_image(path)
	if image == null:
		return false
	for y in range(image.get_height()):
		for x in range(image.get_width()):
			var color := image.get_pixel(x, y)
			if color.a <= 0.001 and color.r < 0.02 and color.g < 0.02 and color.b < 0.02:
				return false
	return true


func _png_has_antialiased_alpha(path: String) -> bool:
	var image := _load_png_image(path)
	if image == null:
		return false
	for y in range(image.get_height()):
		for x in range(image.get_width()):
			var alpha := image.get_pixel(x, y).a
			if alpha > 0.001 and alpha < 0.999:
				return true
	return false


func _load_png_image(path: String) -> Image:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return null
	var bytes := file.get_buffer(file.get_length())
	var image := Image.new()
	if image.load_png_from_buffer(bytes) != OK:
		return null
	return image


func _function_body(script: String, function_name: String) -> String:
	var marker := "func %s" % function_name
	var start := script.find(marker)
	if start < 0:
		_failures.append("missing function in script: %s" % function_name)
		return ""
	var next := script.find("\nfunc ", start + marker.length())
	if next < 0:
		return script.substr(start)
	return script.substr(start, next - start)
