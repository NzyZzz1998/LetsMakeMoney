extends SceneTree

var failures: Array[String] = []

func _assert(value: bool, message: String) -> void:
	if not value:
		failures.append(message)
		push_error(message)

func _init() -> void:
	var script = load("res://src/utils/window_policy_coordinator.gd")
	_assert(script != null, "WindowPolicyCoordinator script must load")
	if script != null:
		var policy = script.new()
		_assert(policy.desired_taskbar_visible(true, true, true, true), "Debug mode must keep taskbar visible")
		_assert(policy.desired_taskbar_visible(false, false, true, true), "Normal mode must keep taskbar visible")
		_assert(not policy.desired_taskbar_visible(false, true, true, true), "Pure pet with tray/native must hide taskbar")
		_assert(policy.desired_taskbar_visible(false, true, false, true), "Pure pet without tray must fall back visible")
		_assert(policy.should_enable_passthrough(false, false, true), "Configured passthrough should run without overlays")
		_assert(not policy.should_enable_passthrough(true, false, true), "Modal must suspend passthrough")
		_assert(not policy.should_enable_passthrough(false, true, true), "Popup must suspend passthrough")
	if failures.is_empty():
		print("v0.7 window policy coordinator passed")
		quit(0)
	else:
		quit(1)
