extends SceneTree

const ValidatorScript := preload("res://src/utils/pet_package_validator.gd")
const ImporterScript := preload("res://src/utils/pet_package_importer.gd")
const HitRegionScript := preload("res://src/utils/pet_hit_region_service.gd")
const DirectionScript := preload("res://src/utils/pet_direction_resolver.gd")

const CLASSIC_PATH := "res://assets/pets/packages/letsmakemoney-classic-pro"
const DUODUO_PATH := "res://assets/pets/packages/duoduo-cat"

var _failures: Array[String] = []


func _init() -> void:
	_test_contract_and_sanitized_boundary()
	_test_generic_import_and_cache()
	_test_transparent_frame_rect_is_empty()
	_test_declared_frames_are_visible()
	_test_hit_region_strategies()
	_test_pointer_direction_contract()
	if _failures.is_empty():
		print("V09 pet package verification passed")
		quit(0)
		return
	for failure in _failures:
		push_error(failure)
	quit(1)


func _test_contract_and_sanitized_boundary() -> void:
	for package_path in [CLASSIC_PATH, DUODUO_PATH]:
		var result: Dictionary = ValidatorScript.validate_package(package_path)
		_expect(bool(result.get("ok", false)), "%s should satisfy the v1 runtime package contract: %s" % [package_path, str(result.get("errors", []))])
		var manifest: Dictionary = result.get("manifest", {})
		_expect(String(manifest.get("schema_version", "")).begins_with("1."), "runtime package schema must use major version 1")
		_expect(not String(manifest.get("source", {}).get("statement", "")).contains(":\\"), "source statement must not contain a Windows absolute path")
		_expect(not String(manifest.get("source", {}).get("statement", "")).contains("/Users/"), "source statement must not contain a macOS user path")
		_expect(Array(manifest.get("files", [])).size() >= 4, "runtime package must list every distributable file")

	var classic_manifest := _read_manifest(CLASSIC_PATH)
	classic_manifest["schema_version"] = "2.0"
	var unknown_major: Dictionary = ValidatorScript.validate_manifest(classic_manifest, CLASSIC_PATH, false)
	_expect(not bool(unknown_major.get("ok", true)), "unknown schema major must be rejected")

	classic_manifest = _read_manifest(CLASSIC_PATH)
	classic_manifest["files"][0]["sha256"] = "00"
	var corrupt_hash: Dictionary = ValidatorScript.validate_manifest(classic_manifest, CLASSIC_PATH, true)
	_expect(not bool(corrupt_hash.get("ok", true)), "atlas hash mismatch must be rejected")

	var duoduo_manifest := _read_manifest(DUODUO_PATH)
	duoduo_manifest["motion"]["review"]["ready"] = false
	var unapproved_motion: Dictionary = ValidatorScript.validate_manifest(duoduo_manifest, DUODUO_PATH, false)
	_expect(not bool(unapproved_motion.get("ok", true)), "motion payload without an approved ready review must be rejected")

	duoduo_manifest = _read_manifest(DUODUO_PATH)
	duoduo_manifest["motion"]["profile_id"] = "unexpected.profile"
	var mismatched_profile: Dictionary = ValidatorScript.validate_manifest(duoduo_manifest, DUODUO_PATH, false)
	_expect(not bool(mismatched_profile.get("ok", true)), "motion profile identity mismatch must be rejected")

	duoduo_manifest = _read_manifest(DUODUO_PATH)
	for file_entry in Array(duoduo_manifest.get("files", [])):
		if String(file_entry.get("path", "")) == "atlas-00.webp":
			file_entry["sha256"] = "0".repeat(64)
	var mismatched_atlas: Dictionary = ValidatorScript.validate_manifest(duoduo_manifest, DUODUO_PATH, false)
	_expect(not bool(mismatched_atlas.get("ok", true)), "motion atlas identity must match the distributable file manifest")


func _test_generic_import_and_cache() -> void:
	var importer = ImporterScript.new()
	var classic: Dictionary = importer.import_package(CLASSIC_PATH)
	var duoduo: Dictionary = importer.import_package(DUODUO_PATH)
	_expect(bool(classic.get("ok", false)), "Classic Pro must import through the generic importer")
	_expect(bool(duoduo.get("ok", false)), "Duoduo must import through the same generic importer")
	if bool(classic.get("ok", false)):
		var pet = classic.get("pet")
		_expect(pet != null and pet.sprite_frames != null, "imported Classic must expose SpriteFrames")
		_expect(pet.sprite_frames.has_animation("working"), "making-money must map to working")
		_expect(pet.sprite_frames.has_animation("sleeping"), "sleeping extension must remain available")
		_expect(pet.sprite_frames.has_animation("clicked_double"), "celebrating must map to double click")
		var duration_ms := importer.animation_duration_ms(pet.sprite_frames, "working")
		_expect(absf(duration_ms - 1240.0) <= 1.0, "working must preserve manifest frame durations")
	if bool(duoduo.get("ok", false)):
		var duoduo_pet = duoduo.get("pet")
		var motion_actions := [
			"working_loop",
			"working_ack",
			"rest_ack",
			"sleep_ack",
			"run_prepare",
			"run_stop",
			"lunch_relief",
			"lunch_return",
		]
		for action_name in motion_actions:
			_expect(
				duoduo_pet.sprite_frames.has_animation(action_name),
				"Duoduo S5.5 motion payload must expose %s" % action_name
			)
		_expect(
			absf(importer.animation_duration_ms(duoduo_pet.sprite_frames, "working_loop") - 1520.0) <= 1.0,
			"Duoduo working_loop must preserve the approved S5.5 frame durations"
		)
		var motion_metadata: Dictionary = duoduo_pet.runtime_profile.animation_metadata.get("working_loop", {})
		_expect(String(motion_metadata.get("semantic_role", "")) == "base", "motion semantic role must survive import")
		_expect(String(motion_metadata.get("source_profile", "")) == "duoduo.s5", "motion profile identity must survive import")
	var first_key := importer.cache_key_for_path(CLASSIC_PATH)
	var second_key := importer.cache_key_for_path(CLASSIC_PATH)
	_expect(not first_key.is_empty() and first_key == second_key, "unchanged package must have a stable cache key")
	var mutated := _read_manifest(CLASSIC_PATH)
	mutated["package_version"] = "1.0.1"
	_expect(importer.cache_key_for_manifest(mutated) != first_key, "manifest changes must invalidate the cache key")


func _test_declared_frames_are_visible() -> void:
	var importer = ImporterScript.new()
	for package_path in [CLASSIC_PATH, DUODUO_PATH]:
		var result: Dictionary = importer.import_package(package_path)
		if not bool(result.get("ok", false)):
			continue
		var pet = result.get("pet")
		for animation_name in pet.sprite_frames.get_animation_names():
			var frame_rects: Array[Rect2i] = HitRegionScript.animation_frame_rects(
				pet.sprite_frames,
				animation_name,
				0.01
			)
			for frame_index in frame_rects.size():
				_expect(
					frame_rects[frame_index].has_area(),
					"%s animation %s frame %d must contain visible pixels" % [
						package_path,
						animation_name,
						frame_index,
					]
				)


func _test_transparent_frame_rect_is_empty() -> void:
	var image := Image.create(16, 16, false, Image.FORMAT_RGBA8)
	image.fill(Color(0.0, 0.0, 0.0, 0.0))
	var texture := ImageTexture.create_from_image(image)
	_expect(
		not HitRegionScript.texture_alpha_rect(texture, 0.01).has_area(),
		"a fully transparent frame must not become a full-window hit region"
	)


func _test_hit_region_strategies() -> void:
	var importer = ImporterScript.new()
	var result: Dictionary = importer.import_package(CLASSIC_PATH)
	if not bool(result.get("ok", false)):
		return
	var pet = result.get("pet")
	var frame_rects: Array[Rect2i] = HitRegionScript.animation_frame_rects(pet.sprite_frames, "working", 0.05)
	_expect(frame_rects.size() == 8, "working must produce one alpha rect per frame")
	var union_rect: Rect2i = HitRegionScript.union_rect(frame_rects)
	_expect(union_rect.size.x > 0 and union_rect.size.y > 0, "action union hit region must be non-empty")
	for rect in frame_rects:
		_expect(union_rect.encloses(rect), "action union must enclose every frame region")
	var metrics: Dictionary = HitRegionScript.benchmark_animation(pet.sprite_frames, "working", 0.05)
	print("V09 hit-region spike: frames=%d union=1 elapsed_ms=%.3f" % [int(metrics.get("frame_count", 0)), float(metrics.get("elapsed_ms", 0.0))])
	_expect(int(metrics.get("frame_count", 0)) == 8, "hit-region benchmark must inspect every frame")
	_expect(float(metrics.get("elapsed_ms", 9999.0)) < 250.0, "hit-region extraction must stay inside the desktop budget")


func _test_pointer_direction_contract() -> void:
	var resolver = DirectionScript.new()
	var directions: Array[String] = []
	for index in 16:
		var angle := float(index) * 22.5
		directions.append(resolver.direction_for_angle(angle))
	var unique: Dictionary = {}
	for direction in directions:
		unique[direction] = true
	_expect(unique.size() == 16, "direction resolver must expose 16 clockwise directions")
	_expect(resolver.should_sample(0, 0), "first pointer sample must be accepted")
	_expect(not resolver.should_sample(40, 0), "pointer samples faster than 12.5Hz must be throttled")
	_expect(resolver.should_sample(80, 0), "pointer sample at 80ms must be accepted")
	var before := resolver.resolve_with_hysteresis(10.0)
	var near_boundary := resolver.resolve_with_hysteresis(12.0)
	_expect(before == near_boundary, "small angle changes near a boundary must not flicker")
	_expect(resolver.should_restore_after_leave(250), "pointer look must restore after 250ms outside")


func _read_manifest(package_path: String) -> Dictionary:
	var file := FileAccess.open(package_path.path_join("pet-package.json"), FileAccess.READ)
	if file == null:
		return {}
	var parsed = JSON.parse_string(file.get_as_text())
	return parsed if parsed is Dictionary else {}


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
