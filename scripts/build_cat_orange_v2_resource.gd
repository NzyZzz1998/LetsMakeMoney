@tool
extends SceneTree

const PET_ID := "cat_orange_v2"
const DISPLAY_NAME := "橘猫 v2"
const V2_ROOT := "res://assets/pets/cat/orange_v2"
const MANIFEST_PATH := V2_ROOT + "/asset-manifest.json"
const SPRITE_FRAMES_PATH := V2_ROOT + "/cat_orange_v2_sprite_frames.tres"
const PET_RESOURCE_PATH := V2_ROOT + "/cat_orange_v2_resource.tres"
const PET_RESOURCE_SCRIPT := "res://src/resources/pet_resource.gd"
const FALLBACK_PET_ID := "cat_orange_v1"

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var manifest := _load_manifest()
	if manifest.is_empty():
		_quit_with_failures()
		return

	var animations: Dictionary = manifest.get("animations", {})
	var frame_paths_by_animation := _validate_animation_frames(animations)
	if not _failures.is_empty():
		_quit_with_failures()
		return

	var sprite_frames := _build_sprite_frames_resource(frame_paths_by_animation, animations)
	if not _failures.is_empty():
		_quit_with_failures()
		return
	var save_frames_result := ResourceSaver.save(sprite_frames, SPRITE_FRAMES_PATH)
	if save_frames_result != OK:
		_failures.append("Failed to save SpriteFrames: %s" % error_string(save_frames_result))
		_quit_with_failures()
		return

	var pet_resource := _build_pet_resource(sprite_frames, frame_paths_by_animation)
	if not _failures.is_empty():
		_quit_with_failures()
		return
	var save_pet_result := ResourceSaver.save(pet_resource, PET_RESOURCE_PATH)
	if save_pet_result != OK:
		_failures.append("Failed to save PetResource: %s" % error_string(save_pet_result))
		_quit_with_failures()
		return

	print("cat_orange_v2 Godot resources built. %s remains available as fallback." % FALLBACK_PET_ID)
	quit(0)


func _load_manifest() -> Dictionary:
	if not FileAccess.file_exists(MANIFEST_PATH):
		_failures.append("Missing manifest: %s" % MANIFEST_PATH)
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(MANIFEST_PATH))
	if not parsed is Dictionary:
		_failures.append("Manifest is not a JSON object: %s" % MANIFEST_PATH)
		return {}
	var manifest: Dictionary = parsed
	if manifest.get("pet_id") != PET_ID:
		_failures.append("Manifest pet_id must be %s" % PET_ID)
	return manifest


func _validate_animation_frames(animations: Dictionary) -> Dictionary:
	var frame_paths_by_animation: Dictionary = {}
	for anim_name in _required_v04_animation_names():
		if not animations.has(anim_name):
			_failures.append("Manifest missing animation: %s" % anim_name)
			continue
		var anim_spec: Dictionary = animations[anim_name]
		var directory := String(anim_spec.get("directory", ""))
		var minimum_frames := int(anim_spec.get("minimum_frames", 0))
		var loop_value: Variant = anim_spec.get("loop", null)
		if loop_value == null:
			_failures.append("Animation missing loop flag: %s" % anim_name)
		var frame_paths := _list_png_frames("res://" + directory)
		if frame_paths.size() < minimum_frames:
			_failures.append("%s requires at least %d png frames, found %d" % [anim_name, minimum_frames, frame_paths.size()])
		frame_paths_by_animation[anim_name] = frame_paths
	return frame_paths_by_animation


func _list_png_frames(directory: String) -> Array[String]:
	var result: Array[String] = []
	var dir := DirAccess.open(directory)
	if dir == null:
		return result
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while not file_name.is_empty():
		if not dir.current_is_dir() and file_name.get_extension().to_lower() == "png":
			result.append(directory.path_join(file_name))
		file_name = dir.get_next()
	dir.list_dir_end()
	result.sort()
	return result


func _build_sprite_frames_resource(frame_paths_by_animation: Dictionary, animations: Dictionary) -> SpriteFrames:
	var frames := SpriteFrames.new()
	for existing in frames.get_animation_names():
		frames.remove_animation(existing)
	for anim_name in _required_v04_animation_names():
		frames.add_animation(anim_name)
		frames.set_animation_loop(anim_name, bool(animations.get(anim_name, {}).get("loop", false)))
		frames.set_animation_speed(anim_name, _animation_speed(anim_name))
		var frame_paths: Array = frame_paths_by_animation.get(anim_name, [])
		var frame_count := frame_paths.size()
		for index in frame_paths.size():
			var path = frame_paths[index]
			var texture := _load_png_texture(String(path))
			if texture == null:
				_failures.append("Failed to load frame texture: %s" % path)
				continue
			frames.add_frame(anim_name, texture, _frame_duration(anim_name, index, frame_count))
	return frames


func _build_pet_resource(sprite_frames: SpriteFrames, frame_paths_by_animation: Dictionary) -> Resource:
	var pet_script := load(PET_RESOURCE_SCRIPT)
	var resource: Resource = pet_script.new()
	resource.set("pet_id", PET_ID)
	resource.set("display_name", DISPLAY_NAME)
	resource.set("sprite_frames", sprite_frames)
	var idle_frames: Array = frame_paths_by_animation.get("idle", [])
	if not idle_frames.is_empty():
		resource.set("thumbnail", _load_png_texture(String(idle_frames[0])))
	resource.set("animation_speeds", _animation_speeds())
	return resource


func _load_png_texture(path: String) -> Texture2D:
	var imported_texture := load(path) as Texture2D
	if imported_texture != null:
		return imported_texture

	var image := Image.new()
	var load_result := image.load(ProjectSettings.globalize_path(path))
	if load_result != OK:
		_failures.append("Failed to load PNG image %s: %s" % [path, error_string(load_result)])
		return null
	return ImageTexture.create_from_image(image)


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


func _animation_speeds() -> Dictionary:
	return {
		"idle": 2.0,
		"working": 5.0,
		"resting": 1.0,
		"clicked_hold": 1.0,
		"idle_clicked_single": 3.0,
		"idle_clicked_double": 3.5,
		"working_clicked_single": 3.0,
		"working_clicked_double": 3.25,
		"resting_clicked_single": 3.0,
		"resting_clicked_double": 3.25
	}


func _animation_speed(anim_name: String) -> float:
	return float(_animation_speeds().get(anim_name, 1.0))


func _frame_duration(anim_name: String, frame_index: int, frame_count: int) -> float:
	if frame_count <= 2:
		return 1.0
	if not anim_name.contains("_clicked_single") and not anim_name.contains("_clicked_double"):
		return 1.0
	if frame_index == 0 or frame_index == frame_count - 1:
		return 0.35
	return 2.2


func _quit_with_failures() -> void:
	for failure in _failures:
		push_error(failure)
	quit(1)
