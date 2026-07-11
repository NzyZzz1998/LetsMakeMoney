extends Node

signal status_changed(state: String, message: String, details: Dictionary)
signal update_available(release: Dictionary)
signal download_ready(path: String, release: Dictionary)

const RELEASES_API := "https://api.github.com/repos/NzyZzz1998/LetsMakeMoney/releases"
const USER_AGENT := "LetsMakeMoney-Update/0.7"
const CHECK_INTERVAL_SECONDS := 21600
const MIN_FREE_SPACE_PADDING := 64 * 1024 * 1024
const RELEASES_PAGE := "https://github.com/NzyZzz1998/LetsMakeMoney/releases"

var _request: HTTPRequest
var _request_kind := ""
var _expected_sha256 := ""
var _download_path := ""
var _selected_release: Dictionary = {}
var _last_check_unix := 0

func _ready() -> void:
	_request = HTTPRequest.new()
	_request.timeout = 30.0
	_request.request_completed.connect(_on_request_completed)
	add_child(_request)

func compare_versions(left: String, right: String) -> int:
	var a := _parse_version(left)
	var b := _parse_version(right)
	for key in ["major", "minor", "patch"]:
		if a[key] != b[key]:
			return 1 if a[key] > b[key] else -1
	var ap: Array = a["prerelease"]
	var bp: Array = b["prerelease"]
	if ap.is_empty() and not bp.is_empty(): return 1
	if not ap.is_empty() and bp.is_empty(): return -1
	for index in range(maxi(ap.size(), bp.size())):
		if index >= ap.size(): return -1
		if index >= bp.size(): return 1
		var av := String(ap[index]); var bv := String(bp[index])
		if av == bv: continue
		if av.is_valid_int() and bv.is_valid_int(): return 1 if av.to_int() > bv.to_int() else -1
		return 1 if av > bv else -1
	return 0

func _parse_version(value: String) -> Dictionary:
	var normalized := value.trim_prefix("v")
	var parts := normalized.split("-", true, 1)
	var numbers := String(parts[0]).split(".")
	return {"major": int(numbers[0]) if numbers.size()>0 else 0, "minor":int(numbers[1]) if numbers.size()>1 else 0, "patch":int(numbers[2]) if numbers.size()>2 else 0, "prerelease":String(parts[1]).split(".") if parts.size()>1 else []}

func select_release(releases: Array, channel: String) -> Dictionary:
	var selected: Dictionary = {}
	for item in releases:
		if not item is Dictionary or bool(item.get("draft", false)): continue
		if channel == "stable" and bool(item.get("prerelease", false)): continue
		if selected.is_empty() or compare_versions(String(item.get("tag_name", "0.0.0")), String(selected.get("tag_name", "0.0.0"))) > 0:
			selected = item
	return selected

func check_for_updates(force: bool = false) -> void:
	if _request_kind != "":
		status_changed.emit("busy", "已有更新任务正在进行。", {})
		return
	var now := int(Time.get_unix_time_from_system())
	if not force and _last_check_unix > 0 and now - _last_check_unix < CHECK_INTERVAL_SECONDS:
		status_changed.emit("no_change", "最近已检查过更新。", {})
		return
	_request_kind = "check"
	status_changed.emit("loading", "正在检查更新…", {})
	var error := _request.request(RELEASES_API, ["Accept: application/vnd.github+json", "User-Agent: %s" % USER_AGENT])
	if error != OK:
		_request_kind = ""
		_log_error("update_check_failed: reason=request_start error=%s" % error_string(error))
		status_changed.emit("error", "无法开始检查更新。", {"reason": error_string(error)})

func download_update(release: Dictionary, asset: Dictionary) -> void:
	if _request_kind != "": return
	var preflight := validate_download_asset(asset)
	if not bool(preflight.get("ok", false)):
		_fail_download(String(preflight.get("error", "asset_preflight_failed")))
		return
	var url := String(asset.get("browser_download_url", ""))
	var digest := String(asset.get("digest", ""))
	if not digest.begins_with("sha256:"):
		_log_error("update_download_failed: reason=missing_sha256")
		status_changed.emit("error", "发布附件缺少 SHA256，已拒绝下载。", {})
		return
	var update_dir := OS.get_user_data_dir().path_join("updates")
	var mkdir_error := DirAccess.make_dir_recursive_absolute(update_dir)
	if mkdir_error != OK and mkdir_error != ERR_ALREADY_EXISTS:
		_fail_download("update_directory_unavailable_%s" % error_string(mkdir_error))
		return
	var dir := DirAccess.open(update_dir)
	var required_bytes := int(asset.get("size", 0)) + MIN_FREE_SPACE_PADDING
	if dir == null or dir.get_space_left() < required_bytes:
		_fail_download("insufficient_disk_space")
		return
	_download_path = update_dir.path_join(String(asset.get("name", "LetsMakeMoney-update.exe")).get_file())
	_expected_sha256 = digest.trim_prefix("sha256:").to_lower()
	_selected_release = release.duplicate(true)
	_request_kind = "download"
	_request.download_file = _download_path
	_log_info("update_download_started: url=%s" % redact_url(url))
	status_changed.emit("downloading", "正在下载更新…", {})
	var error := _request.request(url, ["User-Agent: %s" % USER_AGENT])
	if error != OK:
		_fail_download("request_start_%s" % error_string(error))

func validate_download_asset(asset: Dictionary) -> Dictionary:
	var url := String(asset.get("browser_download_url", ""))
	var name := String(asset.get("name", "")).get_file()
	var digest := String(asset.get("digest", ""))
	if not url.begins_with("https://github.com/"):
		return {"ok": false, "error": "untrusted_download_origin"}
	if name.is_empty() or not name.to_lower().ends_with(".exe"):
		return {"ok": false, "error": "unsupported_update_asset"}
	if not digest.begins_with("sha256:") or digest.length() != 71:
		return {"ok": false, "error": "missing_sha256"}
	if int(asset.get("size", 0)) <= 0:
		return {"ok": false, "error": "missing_asset_size"}
	return {"ok": true, "error": ""}

func verify_installer(path: String, expected_sha256: String, expected_publisher: String = "LetsMakeMoney") -> Dictionary:
	if not FileAccess.file_exists(path):
		return {"ok": false, "error": "download_missing"}
	if FileAccess.get_sha256(path).to_lower() != expected_sha256.to_lower():
		return {"ok": false, "error": "sha256_mismatch"}
	var platform := get_node_or_null("/root/Platform")
	if platform == null or not platform.has_method("verify_authenticode"):
		return {"ok": false, "error": "authenticode_unavailable"}
	var signature: Dictionary = platform.call("verify_authenticode", path, expected_publisher)
	if not bool(signature.get("valid", false)):
		return {"ok": false, "error": "authenticode_invalid", "details": signature}
	return {"ok": true, "publisher": String(signature.get("publisher", "")), "error": ""}

func cancel_download() -> void:
	if _request_kind != "download": return
	_request.cancel_request()
	if FileAccess.file_exists(_download_path): DirAccess.remove_absolute(_download_path)
	_request_kind = ""
	_log_info("update_download_cancelled")
	status_changed.emit("cancelled", "已取消下载，当前版本保持不变。", {})

func _on_request_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	var kind := _request_kind
	_request_kind = ""
	if result != HTTPRequest.RESULT_SUCCESS or response_code < 200 or response_code >= 300:
		if kind == "download": _fail_download("http_%d_result_%d" % [response_code, result])
		else:
			_log_error("update_check_failed: response=%d result=%d" % [response_code, result])
			status_changed.emit("error", "检查更新失败，请稍后重试或前往 GitHub Release。", {})
		return
	if kind == "check":
		_last_check_unix = int(Time.get_unix_time_from_system())
		var parsed = JSON.parse_string(body.get_string_from_utf8())
		if not parsed is Array:
			_log_error("update_check_failed: reason=invalid_json")
			status_changed.emit("error", "更新服务返回了无法识别的数据。", {})
			return
		var config := get_node_or_null("/root/Config")
		var channel := String(config.get_value("update_channel", "beta")) if config != null else "beta"
		var release := select_release(parsed, channel)
		if release.is_empty() or compare_versions(String(release.get("tag_name", "0.0.0")), String(ProjectSettings.get_setting("application/config/version", "0.0.0"))) <= 0:
			_log_info("update_check_success: result=up_to_date channel=%s" % channel)
			status_changed.emit("up_to_date", "当前已是最新版本。", {})
		else:
			_log_info("update_check_success: result=available version=%s" % String(release.get("tag_name", "")))
			status_changed.emit("available", "发现新版本 %s。" % String(release.get("tag_name", "")), release)
			update_available.emit(release)
	elif kind == "download":
		var actual := FileAccess.get_sha256(_download_path).to_lower() if FileAccess.file_exists(_download_path) else ""
		if actual != _expected_sha256:
			_fail_download("sha256_mismatch")
			return
		var signature := verify_installer(_download_path, _expected_sha256)
		if not bool(signature.get("ok", false)):
			_fail_download(String(signature.get("error", "authenticode_invalid")))
			return
		_log_info("update_download_verified: sha256=matched")
		status_changed.emit("downloaded", "下载和 SHA256 校验完成，等待安装确认。", {"path": _download_path})
		download_ready.emit(_download_path, _selected_release)

func _fail_download(reason: String) -> void:
	_request_kind = ""
	if FileAccess.file_exists(_download_path): DirAccess.remove_absolute(_download_path)
	_log_error("update_download_failed: reason=%s" % reason)
	status_changed.emit("error", "更新下载失败，当前版本未受影响。", {"reason": reason})

func redact_url(url: String) -> String:
	return url.split("?", true, 1)[0]

func open_releases_page() -> bool:
	var error := OS.shell_open(RELEASES_PAGE)
	if error != OK:
		_log_error("update_release_page_failed: reason=%s" % error_string(error))
		return false
	_log_info("update_release_page_opened")
	return true

func _log_info(message: String) -> void:
	var platform := get_node_or_null("/root/Platform")
	if platform != null: platform.write_info_log(message)

func _log_error(message: String) -> void:
	var platform := get_node_or_null("/root/Platform")
	if platform != null: platform.write_error_log(message)
