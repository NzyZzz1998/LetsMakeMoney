extends RefCounted
class_name PetPackageValidator

const SUPPORTED_SCHEMA_MAJOR := 1
const REQUIRED_FIELDS := ["schema_version", "pet_id", "display_name", "package_version", "minimum_lmm_version", "geometry", "animations", "files", "license", "source"]
const ALLOWED_EXTENSIONS := ["json", "webp", "png", "md"]
const FORBIDDEN_SEGMENTS := ["qa", "qa-actions", "provenance", "worktrees", "temp"]


static func validate_package(package_root: String) -> Dictionary:
	var file := FileAccess.open(package_root.path_join("pet-package.json"), FileAccess.READ)
	if file == null:
		return _result({}, ["missing pet-package.json"])
	var parsed = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		return _result({}, ["pet-package.json is not a JSON object"])
	return validate_manifest(parsed, package_root, true)


static func validate_manifest(manifest: Dictionary, package_root: String, verify_hashes: bool = true) -> Dictionary:
	var errors: Array[String] = []
	for field in REQUIRED_FIELDS:
		if not manifest.has(field): errors.append("missing field: %s" % field)
	var version := String(manifest.get("schema_version", ""))
	var major := int(version.get_slice(".", 0)) if not version.is_empty() else -1
	if major != SUPPORTED_SCHEMA_MAJOR: errors.append("unsupported schema major: %s" % version)
	if String(manifest.get("pet_id", "")).strip_edges().is_empty(): errors.append("pet_id must not be empty")

	var listed_paths: Array[String] = []
	var listed_hashes: Dictionary = {}
	for file_value in Array(manifest.get("files", [])):
		if not file_value is Dictionary:
			errors.append("files entries must be objects")
			continue
		var entry: Dictionary = file_value
		var relative_path := String(entry.get("path", ""))
		if not _is_safe_relative_path(relative_path):
			errors.append("unsafe package path: %s" % relative_path)
			continue
		if listed_paths.has(relative_path):
			errors.append("duplicate package path: %s" % relative_path)
			continue
		listed_paths.append(relative_path)
		listed_hashes[relative_path] = String(entry.get("sha256", "")).to_lower()
		if not ALLOWED_EXTENSIONS.has(relative_path.get_extension().to_lower()): errors.append("unknown package file type: %s" % relative_path)
		var path := package_root.path_join(relative_path)
		if not FileAccess.file_exists(path):
			errors.append("missing package file: %s" % relative_path)
			continue
		if verify_hashes:
			var expected := String(entry.get("sha256", "")).to_lower()
			var actual := FileAccess.get_sha256(path).to_lower()
			if expected.length() != 64 or expected != actual: errors.append("hash mismatch: %s" % relative_path)

	_validate_geometry(manifest.get("geometry", {}), errors)
	_validate_animations(manifest, listed_paths, errors)
	_validate_motion_extension(manifest, package_root, listed_paths, listed_hashes, errors)
	_validate_distribution_docs(manifest, listed_paths, errors)
	_validate_directory_boundary(package_root, listed_paths, errors)
	return _result(manifest, errors)


static func _validate_geometry(value, errors: Array[String]) -> void:
	if not value is Dictionary:
		errors.append("geometry must be an object")
		return
	var geometry: Dictionary = value
	for key in ["cell_width", "cell_height", "logical_width", "logical_height", "pivot_x", "pivot_y", "foot_baseline"]:
		if float(geometry.get(key, 0.0)) <= 0.0: errors.append("invalid geometry field: %s" % key)
	if not String(geometry.get("hit_strategy", "")) in ["per_frame_alpha", "action_union"]:
		errors.append("unsupported hit strategy: %s" % geometry.get("hit_strategy", ""))


static func _validate_animations(manifest: Dictionary, listed_paths: Array[String], errors: Array[String]) -> void:
	var animations = manifest.get("animations", {})
	if not animations is Dictionary or animations.is_empty():
		errors.append("animations must be a non-empty object")
		return
	for name in animations:
		var value = animations[name]
		if not value is Dictionary:
			errors.append("animation must be an object: %s" % name)
			continue
		var animation: Dictionary = value
		if not listed_paths.has(String(animation.get("atlas", ""))): errors.append("animation references an unlisted atlas: %s" % name)
		var count := int(animation.get("frame_count", 0))
		var durations := Array(animation.get("durations_ms", []))
		if count <= 0 or durations.size() != count: errors.append("animation duration count mismatch: %s" % name)
		for duration in durations:
			if float(duration) <= 0.0: errors.append("animation duration must be positive: %s" % name)


static func _validate_motion_extension(
	manifest: Dictionary,
	package_root: String,
	listed_paths: Array[String],
	listed_hashes: Dictionary,
	errors: Array[String]
) -> void:
	if not manifest.has("motion"):
		return
	var value = manifest.get("motion")
	if not value is Dictionary:
		errors.append("motion must be an object")
		return
	var motion: Dictionary = value
	var manifest_path := String(motion.get("manifest", ""))
	if not _is_safe_relative_path(manifest_path) or not listed_paths.has(manifest_path):
		errors.append("motion manifest must be a listed safe package file")
		return
	var declared_hash := String(motion.get("manifest_sha256", "")).to_lower()
	var actual_hash := FileAccess.get_sha256(package_root.path_join(manifest_path)).to_lower()
	if declared_hash.length() != 64 or declared_hash != actual_hash:
		errors.append("motion manifest identity mismatch")
		return
	var motion_manifest := _read_json_object(package_root.path_join(manifest_path))
	if motion_manifest.is_empty():
		errors.append("motion manifest is not a JSON object")
		return
	if int(motion_manifest.get("schemaVersion", 0)) != 1:
		errors.append("unsupported motion schema version")
	if String(motion_manifest.get("petId", "")) != String(manifest.get("pet_id", "")):
		errors.append("motion pet identity mismatch")
	if String(motion_manifest.get("profileId", "")) != String(motion.get("profile_id", "")):
		errors.append("motion profile identity mismatch")
	if String(motion_manifest.get("profileVersion", "")) != String(motion.get("profile_version", "")):
		errors.append("motion profile version mismatch")
	var motion_geometry = motion_manifest.get("geometry", {})
	if not motion_geometry is Dictionary:
		errors.append("motion geometry must be an object")
	else:
		for geometry_key in ["cellWidth", "cellHeight", "logicalWidth", "logicalHeight", "footBaselineY"]:
			if float(motion_geometry.get(geometry_key, 0.0)) <= 0.0:
				errors.append("invalid motion geometry field: %s" % geometry_key)
	var review = motion.get("review", {})
	if not review is Dictionary:
		errors.append("motion review must be an object")
	else:
		if String(review.get("status", "")) != "approved" or not bool(review.get("ready", false)):
			errors.append("motion payload is not approved and ready")
		for evidence_key in ["review_sha256", "qa_evidence_sha256"]:
			if String(review.get(evidence_key, "")).length() != 64:
				errors.append("invalid motion review identity: %s" % evidence_key)

	var atlas_by_id: Dictionary = {}
	for atlas_value in Array(motion_manifest.get("atlases", [])):
		if not atlas_value is Dictionary:
			errors.append("motion atlas entries must be objects")
			continue
		var atlas: Dictionary = atlas_value
		var atlas_id := String(atlas.get("id", ""))
		var atlas_path := String(atlas.get("path", ""))
		var atlas_hash := String(atlas.get("sha256", "")).to_lower()
		if atlas_id.is_empty() or atlas_by_id.has(atlas_id):
			errors.append("duplicate or empty motion atlas id")
			continue
		if not _is_safe_relative_path(atlas_path) or not listed_paths.has(atlas_path):
			errors.append("motion atlas is not listed: %s" % atlas_path)
		elif atlas_hash.length() != 64 or atlas_hash != String(listed_hashes.get(atlas_path, "")):
			errors.append("motion atlas identity mismatch: %s" % atlas_path)
		if int(atlas.get("columns", 0)) <= 0 or int(atlas.get("rows", 0)) <= 0:
			errors.append("invalid motion atlas grid: %s" % atlas_id)
		atlas_by_id[atlas_id] = atlas

	var action_ids: Dictionary = {}
	for action_value in Array(motion_manifest.get("actions", [])):
		if not action_value is Dictionary:
			errors.append("motion action entries must be objects")
			continue
		var action: Dictionary = action_value
		var action_id := String(action.get("id", ""))
		if action_id.is_empty() or action_ids.has(action_id):
			errors.append("duplicate or empty motion action id")
			continue
		action_ids[action_id] = true
		if not String(action.get("playbackKind", "")) in ["loop", "oneshot", "hold_loop", "transition"]:
			errors.append("unsupported motion playback kind: %s" % action_id)
		if not String(action.get("semanticRole", "")) in ["base", "variation", "interaction", "hold", "transition", "event"]:
			errors.append("unsupported motion semantic role: %s" % action_id)
		if not String(action.get("mirrorPolicy", "")) in ["forbidden", "allowed", "generated_pair"]:
			errors.append("unsupported motion mirror policy: %s" % action_id)
		if not String(action.get("interruptPolicy", "")) in ["none", "interaction", "event", "interaction_or_event", "hold_release", "uninterruptible"]:
			errors.append("unsupported motion interrupt policy: %s" % action_id)
		var logical_size = action.get("logicalSize", {})
		if not logical_size is Dictionary or float(logical_size.get("width", 0.0)) <= 0.0 or float(logical_size.get("height", 0.0)) <= 0.0:
			errors.append("invalid motion logical size: %s" % action_id)
		var anchor = action.get("anchor", {})
		if not anchor is Dictionary or not _is_unit_value(anchor.get("x", -1.0)) or not _is_unit_value(anchor.get("y", -1.0)):
			errors.append("invalid motion anchor: %s" % action_id)
		if float(action.get("footBaselineY", 0.0)) <= 0.0:
			errors.append("invalid motion foot baseline: %s" % action_id)
		var action_frames := Array(action.get("frames", []))
		if action_frames.is_empty():
			errors.append("motion action has no frames: %s" % action_id)
		for frame_value in action_frames:
			if not frame_value is Dictionary:
				errors.append("motion frame must be an object: %s" % action_id)
				continue
			var frame: Dictionary = frame_value
			var atlas_id := String(frame.get("atlas", ""))
			if not atlas_by_id.has(atlas_id):
				errors.append("motion frame references unknown atlas: %s" % action_id)
				continue
			var atlas: Dictionary = atlas_by_id[atlas_id]
			if int(frame.get("column", -1)) < 0 or int(frame.get("column", -1)) >= int(atlas.get("columns", 0)):
				errors.append("motion frame column is outside atlas: %s" % action_id)
			if int(frame.get("row", -1)) < 0 or int(frame.get("row", -1)) >= int(atlas.get("rows", 0)):
				errors.append("motion frame row is outside atlas: %s" % action_id)
			if float(frame.get("durationMs", 0.0)) <= 0.0:
				errors.append("motion frame duration must be positive: %s" % action_id)


static func _validate_distribution_docs(manifest: Dictionary, listed_paths: Array[String], errors: Array[String]) -> void:
	for section_name in ["license", "source"]:
		var value = manifest.get(section_name, {})
		if not value is Dictionary:
			errors.append("%s must be an object" % section_name)
			continue
		if not listed_paths.has(String(value.get("file", ""))): errors.append("%s document must be listed in files" % section_name)
	if _contains_private_path(JSON.stringify(manifest)): errors.append("manifest contains a local absolute path")


static func _validate_directory_boundary(package_root: String, listed_paths: Array[String], errors: Array[String]) -> void:
	var actual: Array[String] = []
	_collect_files(package_root, package_root, actual)
	for relative_path in actual:
		if relative_path == "pet-package.json": continue
		if not listed_paths.has(relative_path): errors.append("unlisted runtime package file: %s" % relative_path)
		if _contains_forbidden_segment(relative_path): errors.append("forbidden production artifact: %s" % relative_path)
		if relative_path.get_extension().to_lower() in ["json", "md"]:
			var file := FileAccess.open(package_root.path_join(relative_path), FileAccess.READ)
			if file != null and _contains_private_path(file.get_as_text()): errors.append("runtime document contains a local absolute path: %s" % relative_path)


static func _collect_files(root: String, current: String, output: Array[String]) -> void:
	var dir := DirAccess.open(current)
	if dir == null: return
	dir.list_dir_begin()
	var entry := dir.get_next()
	while not entry.is_empty():
		if entry != ".godot":
			var child := current.path_join(entry)
			if dir.current_is_dir(): _collect_files(root, child, output)
			elif not entry.ends_with(".import"):
				# Godot owns these generated sidecars; they are not pet-package payload.
				output.append(child.trim_prefix(root).trim_prefix("/").replace("\\", "/"))
		entry = dir.get_next()
	dir.list_dir_end()


static func _is_safe_relative_path(path: String) -> bool:
	return not path.is_empty() and not path.is_absolute_path() and not path.contains("..") and not path.contains("\\") and not _contains_forbidden_segment(path)


static func _is_unit_value(value) -> bool:
	var number := float(value)
	return number >= 0.0 and number <= 1.0


static func _contains_forbidden_segment(path: String) -> bool:
	for segment in path.to_lower().split("/", false):
		if FORBIDDEN_SEGMENTS.has(segment): return true
	return false


static func _contains_private_path(text: String) -> bool:
	var lower := text.to_lower()
	return lower.contains(":\\") or lower.contains("/users/") or lower.contains("/home/") or lower.contains(".worktrees")


static func _read_json_object(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed = JSON.parse_string(file.get_as_text())
	return parsed if parsed is Dictionary else {}


static func _result(manifest: Dictionary, errors: Array[String]) -> Dictionary:
	return {"ok": errors.is_empty(), "errors": errors, "manifest": manifest}
