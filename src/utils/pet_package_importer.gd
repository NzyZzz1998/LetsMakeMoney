extends RefCounted
class_name PetPackageImporter

const ValidatorScript := preload("res://src/utils/pet_package_validator.gd")
const ProfileScript := preload("res://src/resources/pet_runtime_profile.gd")

var _cache: Dictionary = {}


func import_package(package_root: String) -> Dictionary:
	var validation: Dictionary = ValidatorScript.validate_package(package_root)
	if not bool(validation.get("ok", false)): return validation
	var manifest: Dictionary = validation.manifest
	var key := cache_key_for_manifest(manifest)
	if _cache.has(key): return {"ok": true, "pet": _cache[key], "cache_hit": true, "manifest": manifest}
	var pet := _build_pet(manifest, package_root, key)
	if pet == null: return {"ok": false, "errors": ["failed to build SpriteFrames"], "manifest": manifest}
	_cache.clear()
	_cache[key] = pet
	return {"ok": true, "pet": pet, "cache_hit": false, "manifest": manifest}


func cache_key_for_path(package_root: String) -> String:
	var validation: Dictionary = ValidatorScript.validate_package(package_root)
	return cache_key_for_manifest(validation.manifest) if bool(validation.get("ok", false)) else ""


func cache_key_for_manifest(manifest: Dictionary) -> String:
	return JSON.stringify(manifest, "", true).sha256_text()


func animation_duration_ms(frames: SpriteFrames, animation_name: String) -> float:
	if frames == null or not frames.has_animation(animation_name): return 0.0
	var speed := frames.get_animation_speed(animation_name)
	if speed <= 0.0: return 0.0
	var total := 0.0
	for index in frames.get_frame_count(animation_name): total += frames.get_frame_duration(animation_name, index) / speed * 1000.0
	return total


func _build_pet(manifest: Dictionary, package_root: String, package_hash: String) -> PetResource:
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	var textures: Dictionary = {}
	var animation_metadata: Dictionary = manifest.animations.duplicate(true)
	for animation_name in manifest.animations:
		var definition: Dictionary = manifest.animations[animation_name]
		var atlas_path := String(definition.atlas)
		if not textures.has(atlas_path): textures[atlas_path] = _load_texture(package_root.path_join(atlas_path))
		var atlas_texture: Texture2D = textures[atlas_path]
		if atlas_texture == null: return null
		var name := String(animation_name)
		frames.add_animation(name)
		frames.set_animation_loop(name, bool(definition.get("loop", true)))
		frames.set_animation_speed(name, 1000.0)
		var cell_width := int(definition.get("cell_width", manifest.geometry.cell_width))
		var cell_height := int(definition.get("cell_height", manifest.geometry.cell_height))
		var row := int(definition.get("row", 0))
		var start_column := int(definition.get("start_column", 0))
		var durations := Array(definition.durations_ms)
		for frame_index in int(definition.frame_count):
			var region := AtlasTexture.new()
			region.atlas = atlas_texture
			region.region = Rect2((start_column + frame_index) * cell_width, row * cell_height, cell_width, cell_height)
			frames.add_frame(name, region, float(durations[frame_index]))
	if manifest.has("motion"):
		var motion_path := package_root.path_join(String(manifest.motion.get("manifest", "")))
		var motion_manifest := _read_json_object(motion_path)
		if motion_manifest.is_empty() or not _append_motion_actions(frames, animation_metadata, package_root, motion_manifest):
			return null

	var profile = ProfileScript.new()
	profile.package_id = String(manifest.pet_id)
	profile.package_version = String(manifest.package_version)
	profile.package_hash = package_hash
	profile.package_root = package_root
	profile.logical_size = Vector2(float(manifest.geometry.logical_width), float(manifest.geometry.logical_height))
	profile.pivot = Vector2(float(manifest.geometry.pivot_x), float(manifest.geometry.pivot_y))
	profile.foot_baseline = float(manifest.geometry.foot_baseline)
	profile.hit_strategy = String(manifest.geometry.hit_strategy)
	profile.animation_metadata = animation_metadata
	for fallback in Array(manifest.get("fallback_ids", [])): profile.fallback_ids.append(String(fallback))

	var pet := PetResource.new()
	pet.pet_id = String(manifest.pet_id)
	pet.display_name = String(manifest.display_name)
	pet.description = String(manifest.get("description", ""))
	pet.sprite_frames = frames
	pet.runtime_profile = profile
	if frames.has_animation("idle") and frames.get_frame_count("idle") > 0: pet.thumbnail = frames.get_frame_texture("idle", 0)
	return pet


func _load_texture(path: String) -> Texture2D:
	var image := Image.new()
	var error := image.load(ProjectSettings.globalize_path(path))
	return ImageTexture.create_from_image(image) if error == OK and not image.is_empty() else null


func _append_motion_actions(frames: SpriteFrames, metadata: Dictionary, package_root: String, motion_manifest: Dictionary) -> bool:
	var atlas_textures: Dictionary = {}
	for atlas_value in Array(motion_manifest.get("atlases", [])):
		var atlas: Dictionary = atlas_value
		var atlas_id := String(atlas.get("id", ""))
		atlas_textures[atlas_id] = _load_texture(package_root.path_join(String(atlas.get("path", ""))))
		if atlas_textures[atlas_id] == null:
			return false
	var geometry: Dictionary = motion_manifest.get("geometry", {})
	var cell_width := int(geometry.get("cellWidth", 0))
	var cell_height := int(geometry.get("cellHeight", 0))
	var source_profile := String(motion_manifest.get("profileId", ""))
	for action_value in Array(motion_manifest.get("actions", [])):
		var action: Dictionary = action_value
		var action_id := String(action.get("id", ""))
		if frames.has_animation(action_id):
			frames.remove_animation(action_id)
		frames.add_animation(action_id)
		frames.set_animation_loop(action_id, String(action.get("playbackKind", "")) in ["loop", "hold_loop"])
		frames.set_animation_speed(action_id, 1000.0)
		for frame_value in Array(action.get("frames", [])):
			var frame: Dictionary = frame_value
			var atlas_id := String(frame.get("atlas", ""))
			var region := AtlasTexture.new()
			region.atlas = atlas_textures[atlas_id]
			region.region = Rect2(
				int(frame.get("column", 0)) * cell_width,
				int(frame.get("row", 0)) * cell_height,
				cell_width,
				cell_height
			)
			frames.add_frame(action_id, region, float(frame.get("durationMs", 0.0)))
		metadata[action_id] = {
			"semantic_role": String(action.get("semanticRole", "")),
			"source_profile": source_profile,
			"applicable_states": Array(action.get("applicableStates", [])).duplicate(),
			"fallback": String(action.get("fallback", "")),
			"interrupt_policy": String(action.get("interruptPolicy", "")),
			"mirror_policy": String(action.get("mirrorPolicy", "")),
		}
	return true


func _read_json_object(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed = JSON.parse_string(file.get_as_text())
	return parsed if parsed is Dictionary else {}
