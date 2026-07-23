extends SceneTree

const SelectionPolicyScript := preload("res://src/utils/pet_selection_policy.gd")
const ImporterScript := preload("res://src/utils/pet_package_importer.gd")
const HitRegionScript := preload("res://src/utils/pet_hit_region_service.gd")
const VisualGeometryScript := preload("res://src/utils/pet_visual_geometry.gd")
const ActionProfileScript := preload("res://src/utils/pet_action_profile.gd")

const CLASSIC_PATH := "res://assets/pets/packages/letsmakemoney-classic-pro"
const DUODUO_PATH := "res://assets/pets/packages/duoduo-cat"

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_test_selection_and_fallback_policy()
	_test_runtime_candidates()
	await _test_runtime_interaction_dispatch()
	_test_geometry_and_action_gate()
	_test_runtime_visual_normalization()
	_test_configuration_compatibility_contract()
	_finish()


func _test_selection_and_fallback_policy() -> void:
	var available: Array[String] = [
		SelectionPolicyScript.CLASSIC_PET_ID,
		SelectionPolicyScript.LEGACY_V2_PET_ID,
		SelectionPolicyScript.LEGACY_V1_PET_ID,
		SelectionPolicyScript.PLACEHOLDER_PET_ID
	]
	var missing_target := SelectionPolicyScript.fallback_candidates("missing-pet")
	_expect_equal(SelectionPolicyScript.first_available(missing_target, available), SelectionPolicyScript.CLASSIC_PET_ID, "missing target falls back to Classic")
	var broken_duoduo := SelectionPolicyScript.fallback_candidates(SelectionPolicyScript.DUODUO_PET_ID, [SelectionPolicyScript.CLASSIC_PET_ID])
	_expect_equal(SelectionPolicyScript.first_available(broken_duoduo, available), SelectionPolicyScript.CLASSIC_PET_ID, "broken Duoduo falls back to Classic")
	available.erase(SelectionPolicyScript.CLASSIC_PET_ID)
	_expect_equal(SelectionPolicyScript.first_available(missing_target, available), SelectionPolicyScript.LEGACY_V2_PET_ID, "broken Classic falls back to v2")
	available.erase(SelectionPolicyScript.LEGACY_V2_PET_ID)
	_expect_equal(SelectionPolicyScript.first_available(missing_target, available), SelectionPolicyScript.LEGACY_V1_PET_ID, "broken v2 falls back to v1")
	available.erase(SelectionPolicyScript.LEGACY_V1_PET_ID)
	_expect_equal(SelectionPolicyScript.first_available(missing_target, available), SelectionPolicyScript.PLACEHOLDER_PET_ID, "broken v1 falls back to placeholder")


func _test_runtime_candidates() -> void:
	var pet_manager = root.get_node_or_null("PetManager")
	var config = root.get_node_or_null("Config")
	_expect(pet_manager != null and config != null, "PetManager and Config autoloads must be available")
	if pet_manager == null or config == null:
		return
	var ids: Array[String] = []
	for pet in pet_manager.get_available_pets():
		ids.append(String(pet.pet_id))
	_expect(ids.has(SelectionPolicyScript.CLASSIC_PET_ID), "Classic must be exposed after package gates pass")
	_expect(ids.has(SelectionPolicyScript.DUODUO_PET_ID), "Duoduo must be exposed as a formal candidate")
	var original_config_id := String(config.get_value("pet_id", SelectionPolicyScript.LEGACY_V2_PET_ID))
	pet_manager.switch_pet(SelectionPolicyScript.LEGACY_V2_PET_ID, false)
	_expect_equal(String(pet_manager.get_current_pet().pet_id), SelectionPolicyScript.LEGACY_V2_PET_ID, "an existing v2 selection remains selectable")
	_expect_equal(String(config.get_value("pet_id", "")), original_config_id, "non-persistent startup selection must not rewrite the saved pet")
	pet_manager.switch_pet(original_config_id, false)


func _test_runtime_interaction_dispatch() -> void:
	var pet_manager = root.get_node_or_null("PetManager")
	_expect(pet_manager != null, "PetManager must be available for the real pet interaction dispatch")
	if pet_manager == null:
		return
	var original_pet_id := String(pet_manager.get_current_pet().pet_id) if pet_manager.get_current_pet() != null else SelectionPolicyScript.CLASSIC_PET_ID
	var config = root.get_node_or_null("Config")
	var original_debug_mode := bool(config.get_value("debug_mode", false)) if config != null else false
	if config != null:
		config.set_value("debug_mode", false)
	var packed_scene := load("res://src/scenes/pet/pet.tscn") as PackedScene
	_expect(packed_scene != null, "the real pet scene must load for interaction dispatch verification")
	if packed_scene == null:
		pet_manager.switch_pet(original_pet_id, false)
		return
	var cases := [
		{"pet_id": SelectionPolicyScript.CLASSIC_PET_ID},
		{"pet_id": SelectionPolicyScript.DUODUO_PET_ID},
	]
	for test_case in cases:
		pet_manager.return_to_auto_state()
		pet_manager.switch_pet(String(test_case.pet_id), false)
		var pet = packed_scene.instantiate()
		root.add_child(pet)
		await process_frame
		await process_frame
		pet_manager.set_base_state(pet_manager.PetBaseState.WORKING)
		await process_frame
		var expected_action := ActionProfileScript.first_available(
			ActionProfileScript.interaction_candidates(pet._animation_controller.base_animation, "clicked_single"),
			pet.anim.sprite_frames
		)
		var requested: Array[String] = []
		var started: Array[String] = []
		var finished: Array[String] = []
		pet._animation_controller.action_requested.connect(func(_token: int, animation_name: String, _priority: int) -> void: requested.append(animation_name))
		pet._animation_controller.action_started.connect(func(_token: int, animation_name: String) -> void: started.append(animation_name))
		pet._animation_controller.action_finished.connect(func(_token: int, animation_name: String, _reason: String) -> void: finished.append(animation_name))
		pet.trigger_interaction_from_debug(2)
		await process_frame
		_expect(int(pet._animation_controller.active_token) > 0, "%s single-click reaches the animation controller" % test_case.pet_id)
		_expect(requested.has(expected_action) and started.has(expected_action), "%s requests and starts %s" % [test_case.pet_id, expected_action])
		_expect(String(pet.anim.animation) == expected_action, "%s plays %s" % [test_case.pet_id, expected_action])
		_expect(not pet.anim.sprite_frames.get_animation_loop(expected_action), "%s interaction action is not looping" % test_case.pet_id)
		_expect(is_equal_approx(pet.anim.sprite_frames.get_animation_speed(expected_action), 1000.0), "%s preserves package frame timing" % test_case.pet_id)
		await create_timer(2.0).timeout
		_expect(finished.has(expected_action), "%s interaction action finishes" % test_case.pet_id)
		_expect(int(pet._animation_controller.active_token) == 0, "%s releases its action token" % test_case.pet_id)
		var restored_candidates: Array[String] = ActionProfileScript.base_candidates(pet._animation_controller.base_animation)
		_expect(restored_candidates.has(String(pet.anim.animation)), "%s restores its current schedule base animation" % test_case.pet_id)
		pet.free()
		await process_frame
	pet_manager.return_to_auto_state()
	pet_manager.switch_pet(original_pet_id, false)
	if config != null:
		config.set_value("debug_mode", original_debug_mode)


func _test_geometry_and_action_gate() -> void:
	var importer = ImporterScript.new()
	for package_path in [CLASSIC_PATH, DUODUO_PATH]:
		var result: Dictionary = importer.import_package(package_path)
		_expect(bool(result.get("ok", false)), "%s imports for the release gate" % package_path)
		if not bool(result.get("ok", false)):
			continue
		var pet = result.get("pet")
		var minimum_frames := {
			"working": 8,
			"awake_rest": 7,
			"sleeping": 8,
			"clicked_single": 4,
			"clicked_double": 8,
			"clicked_hold": 8,
		}
		for animation_name in minimum_frames:
			_expect(pet.sprite_frames.has_animation(animation_name), "%s provides %s" % [pet.pet_id, animation_name])
			_expect(
				pet.sprite_frames.get_frame_count(animation_name) >= int(minimum_frames[animation_name]),
				"%s %s has enough visible transition frames" % [pet.pet_id, animation_name]
			)
		var rects: Array[Rect2i] = HitRegionScript.animation_frame_rects(pet.sprite_frames, "awake_rest")
		var union := HitRegionScript.union_rect(rects)
		_expect(union.size.x >= 96 and union.size.y >= 104, "%s keeps a readable visible footprint" % pet.pet_id)
		_expect(absf(float(pet.runtime_profile.foot_baseline) - float(pet.runtime_profile.pivot.y)) <= 1.0, "%s pivot remains on the foot baseline" % pet.pet_id)
		var duration := importer.animation_duration_ms(pet.sprite_frames, "clicked_single")
		_expect(duration >= 900.0 and duration <= 1800.0, "%s single click remains visible without overstaying" % pet.pet_id)


func _test_configuration_compatibility_contract() -> void:
	var config = root.get_node_or_null("Config")
	_expect(config != null, "Config autoload must be available for compatibility checks")
	if config == null:
		return
	var new_config: Dictionary = config.merge_with_defaults({})
	_expect_equal(String(new_config.get("pet_id", "")), SelectionPolicyScript.CLASSIC_PET_ID, "new configurations must default to Classic")
	var existing_config: Dictionary = config.merge_with_defaults({"config_version": 5, "pet_id": SelectionPolicyScript.LEGACY_V2_PET_ID})
	_expect_equal(String(existing_config.get("pet_id", "")), SelectionPolicyScript.LEGACY_V2_PET_ID, "migration must preserve an existing pet selection")


func _test_runtime_visual_normalization() -> void:
	var transform: Dictionary = VisualGeometryScript.normalized_transform(
		Vector2(192.0, 208.0),
		Vector2(96.0, 196.0),
		Vector2(112.0, 112.0),
		Vector2(0.82, 0.82),
		Vector2(256.0, 256.0)
	)
	_expect(absf(float(transform.scale_factor) - 256.0 / 208.0) < 0.001, "package scale is normalized against the v0.8 visual height")
	var pivot_world: Vector2 = transform.position + (Vector2(96.0, 196.0) - Vector2(96.0, 104.0)) * transform.scale
	_expect(pivot_world.distance_to(Vector2(112.0, 216.96)) < 0.1, "package foot pivot remains on the v0.8 baseline")
	var invalid: Dictionary = VisualGeometryScript.normalized_transform(Vector2.ZERO, Vector2.ZERO, Vector2(10.0, 20.0), Vector2.ONE, Vector2(256.0, 256.0))
	_expect_equal(invalid.position, Vector2(10.0, 20.0), "invalid package geometry falls back without moving the pet")


func _expect(value: bool, message: String) -> void:
	if not value:
		_failures.append(message)


func _expect_equal(actual: Variant, expected: Variant, message: String) -> void:
	if actual != expected:
		_failures.append("%s: expected=%s actual=%s" % [message, str(expected), str(actual)])


func _finish() -> void:
	if _failures.is_empty():
		print("V09 pet integration verification passed")
		quit(0)
		return
	for failure in _failures:
		push_error(failure)
	quit(1)
