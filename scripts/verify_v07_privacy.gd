extends SceneTree


func _init() -> void:
	var failures: Array[String] = []
	var service := load("res://src/utils/diagnostics_service.gd")
	if service == null:
		failures.append("diagnostics service unavailable")
	else:
		var user_path := "C:" + "\\Users\\AuditSampleUser\\Private"
		var private_path := "E:" + "\\PrivateAuditSample"
		var summary: String = service.build_summary({
			"monthly_salary": 987654.0,
			"username": "AuditSampleUser",
			"user_path": user_path,
			"private_path": private_path,
			"api_token": "audit_sample_token_not_a_secret",
			"window_x": 12345,
			"window_mode": "top",
			"pure_pet_mode": false,
			"minimize_to_tray": true,
			"debug_mode": false,
			"auto_start": false,
			"pet_id": "cat_orange_v2"
		}, {"tray_supported": true, "passthrough_supported": true})
		for forbidden in [
			"987654", "12345", "AuditSampleUser", user_path, private_path,
			"audit_sample_token_not_a_secret", "monthly_salary", "api_token", "user_path"
		]:
			if summary.contains(forbidden):
				failures.append("diagnostics summary leaked sample category: %s" % forbidden)

	if failures.is_empty():
		print("v0.7 diagnostics privacy verification passed")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)
