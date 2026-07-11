extends SceneTree

var failures: Array[String] = []
func _assert(value: bool, message: String) -> void:
	if not value:
		failures.append(message)
		push_error(message)

func _init() -> void:
	var script = load("res://src/utils/update_service.gd")
	_assert(script != null, "UpdateService must load")
	if script != null:
		var service = script.new()
		_assert(service.compare_versions("0.7.0", "0.6.9") > 0, "Semantic version upgrade failed")
		_assert(service.compare_versions("0.7.0-beta.2", "0.7.0-beta.1") > 0, "Beta sequence comparison failed")
		_assert(service.compare_versions("0.7.0", "0.7.0-beta.2") > 0, "Stable must outrank prerelease")
		var releases := [
			{"tag_name":"v0.8.0-beta.1", "prerelease":true, "draft":false, "assets":[]},
			{"tag_name":"v0.7.1", "prerelease":false, "draft":false, "assets":[]}
		]
		_assert(service.select_release(releases, "stable").tag_name == "v0.7.1", "Stable channel selected prerelease")
		_assert(service.select_release(releases, "beta").tag_name == "v0.8.0-beta.1", "Beta channel did not select newest release")
		_assert(service.redact_url("https://example.invalid/file?token=secret") == "https://example.invalid/file", "Update URL log redaction failed")
		var valid_asset := {"name":"LetsMakeMoney-Setup.exe", "size":1024, "digest":"sha256:" + "a".repeat(64), "browser_download_url":"https://github.com/NzyZzz1998/LetsMakeMoney/releases/download/v0.7/LetsMakeMoney-Setup.exe"}
		_assert(bool(service.validate_download_asset(valid_asset).ok), "Valid signed installer metadata was rejected")
		var missing_digest := valid_asset.duplicate(); missing_digest["digest"] = ""
		_assert(not bool(service.validate_download_asset(missing_digest).ok), "Missing SHA256 was accepted")
		var untrusted := valid_asset.duplicate(); untrusted["browser_download_url"] = "https://example.invalid/update.exe"
		_assert(not bool(service.validate_download_asset(untrusted).ok), "Untrusted update origin was accepted")
		var zip_asset := valid_asset.duplicate(); zip_asset["name"] = "portable.zip"
		_assert(not bool(service.validate_download_asset(zip_asset).ok), "Portable Zip was accepted for in-place installation")
		service.free()
	if failures.is_empty():
		print("v0.7 update service passed")
		quit(0)
	else:
		quit(1)
