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


static func _contains_forbidden_segment(path: String) -> bool:
	for segment in path.to_lower().split("/", false):
		if FORBIDDEN_SEGMENTS.has(segment): return true
	return false


static func _contains_private_path(text: String) -> bool:
	var lower := text.to_lower()
	return lower.contains(":\\") or lower.contains("/users/") or lower.contains("/home/") or lower.contains(".worktrees")


static func _result(manifest: Dictionary, errors: Array[String]) -> Dictionary:
	return {"ok": errors.is_empty(), "errors": errors, "manifest": manifest}
