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
		_verify_runtime_state(policy)
	_verify_geometry()
	_verify_overlay_lifecycle()
	_verify_context_menu_builder()
	if failures.is_empty():
		print("v0.7 window policy coordinator passed")
		quit(0)
	else:
		quit(1)


func _verify_runtime_state(policy: RefCounted) -> void:
	var state_script = load("res://src/utils/window_runtime_state.gd")
	_assert(state_script != null, "WindowRuntimeState script must load")
	if state_script == null:
		return
	var state = state_script.new()
	state.sync(false, true, true, true, true, false, false, true)
	_assert(not policy.desired_taskbar_for_state(state.snapshot()), "Pure pet runtime state must hide taskbar")
	_assert(policy.should_enable_passthrough_for_state(state.snapshot()), "Overlay-free runtime state must enable passthrough")
	state.set_overlay(true, false)
	_assert(not policy.should_enable_passthrough_for_state(state.snapshot()), "Runtime modal state must suspend passthrough")
	state.set_overlay(false, true)
	_assert(not policy.should_enable_passthrough_for_state(state.snapshot()), "Runtime popup state must suspend passthrough")
	state.set_overlay(false, false)
	state.window_visible = false
	_assert(not policy.should_enable_passthrough_for_state(state.snapshot()), "Hidden runtime window must disable passthrough")


func _verify_geometry() -> void:
	var geometry = load("res://src/utils/pet_window_geometry.gd")
	_assert(geometry != null, "PetWindowGeometry script must load")
	if geometry == null:
		return
	_assert(geometry.panel_target_size_for_scale(0.1, Vector2i(356, 256)) == Vector2i(178, 128), "Panel scale must clamp at 0.5")
	_assert(geometry.panel_target_size_for_scale(3.0, Vector2i(356, 256)) == Vector2i(712, 512), "Panel scale must clamp at 2.0")
	var panel_rect: Rect2 = geometry.panel_interaction_rect(Vector2(300, 104), Vector2(160, 90), Vector2(220, 110), 8.0)
	_assert(panel_rect == Rect2(Vector2(292, 96), Vector2(236, 126)), "Panel interaction rect must preserve the minimum hit target and hover padding")
	var pet_rect: Rect2 = geometry.pet_interaction_rect(Rect2(Vector2(-10, -20), Vector2(100, 120)), Vector2(28, 88), 1.5, Vector2(14, 12))
	_assert(pet_rect == Rect2(Vector2(-8, 40), Vector2(192, 216)), "Pet interaction rect must scale local coordinates and padding")


func _verify_overlay_lifecycle() -> void:
	var lifecycle_script = load("res://src/utils/overlay_lifecycle.gd")
	_assert(lifecycle_script != null, "OverlayLifecycle script must load")
	if lifecycle_script == null:
		return
	var lifecycle = lifecycle_script.new()
	var modal := Node.new()
	lifecycle.register_modal(modal)
	_assert(lifecycle.has_modal(), "Registered modal must be active")
	lifecycle.unregister_modal(modal)
	_assert(not lifecycle.has_modal(), "Unregistered modal must be inactive")
	modal.free()
	var popup := PopupMenu.new()
	lifecycle.register_popup(popup)
	_assert(lifecycle.has_popups(), "Registered popup must be active")
	lifecycle.unregister_popup(popup)
	_assert(not lifecycle.has_popups(), "Unregistered popup must be inactive")
	popup.free()


func _verify_context_menu_builder() -> void:
	var builder_script = load("res://src/utils/context_menu_builder.gd")
	_assert(builder_script != null, "ContextMenuBuilder script must load")
	if builder_script == null:
		return
	var builder = builder_script.new()
	var menu: PopupMenu = builder.build_context_menu([], "", "top", _ignore_menu_id)
	_assert(menu.get_item_index(600) >= 0, "Context menu must retain hide-to-tray command")
	_assert(menu.get_item_index(100) >= 0, "Context menu must retain settings command")
	_assert(menu.get_node_or_null("WindowModeSubmenu") != null, "Context menu must retain window mode submenu")
	_assert(menu.get_node_or_null("PetSubmenu") != null, "Context menu must retain pet submenu")
	menu.free()


func _ignore_menu_id(_id: int) -> void:
	pass
