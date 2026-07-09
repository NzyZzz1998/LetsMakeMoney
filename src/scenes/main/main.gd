# src/scenes/main/main.gd
extends Node2D

@onready var pet: Node2D = $Pet
@onready var panel = $Panel
@onready var debug_status: Label = $DebugStatus
@onready var debug_input_area: ColorRect = $DebugInputArea

const DEBUG_WINDOW_SIZE := Vector2i(900, 500)
const PET_WINDOW_SIZE := Vector2i(620, 380)
const PET_CONTENT_MARGIN := 24.0
const PET_TEXTURE_SIZE := Vector2(256, 256)
const PET_ANIM_LOCAL_POSITION := Vector2(112, 112)
const PET_ANIM_BASE_SCALE := 0.82
const PET_HIT_PADDING := Vector2(14, 12)
const PET_CONTEXT_PADDING := Vector2(28, 26)
const PANEL_TARGET_SIZE := Vector2i(356, 256)
const DEBUG_PET_POSITION := Vector2(72, 168)
const DEBUG_PANEL_POSITION := Vector2(340, 140)
const PET_MODE_PET_POSITION := Vector2(28, 88)
const PET_MODE_PANEL_POSITION := Vector2(300, 104)
const PET_MODE_PANEL_LEFT_POSITION := Vector2(12, 104)
const PET_MODE_PANEL_TOP_POSITION := Vector2(300, 12)
const PET_MODE_PANEL_TOP_LEFT_POSITION := Vector2(12, 12)
const PET_MODE_PANEL_BOTTOM_LEFT_POSITION := Vector2(12, 104)
const PET_MODE_PANEL_BOTTOM_RIGHT_POSITION := Vector2(300, 104)
const PANEL_EDGE_MARGIN := 12.0
const PANEL_HIT_SIZE := Vector2(220, 110)
const PANEL_HOVER_PADDING := 8.0
const DRAG_THRESHOLD := 4.0
const DOUBLE_CLICK_WINDOW := 0.3
const CLICK_FEEDBACK_RETURN_DELAY := 1.55

var _debug_mode: bool = false
var _tray_ready: bool = false
var _debug_mouse_pressed: bool = false
var _debug_dragging: bool = false
var _debug_drag_start_mouse: Vector2 = Vector2.ZERO
var _debug_drag_start_screen_mouse: Vector2i = Vector2i.ZERO
var _debug_drag_start_window_pos: Vector2i = Vector2i.ZERO
var _debug_click_count: int = 0
var _debug_click_timer_active: bool = false
var _runtime_mode_reapply_pending: bool = false
var _runtime_mode_reapply_deferred_until_modal_close: bool = false
var _native_health: Dictionary = {}
var _last_passthrough_rects_hash: int = 0
var _modal_open: bool = false
var _hit_debug_layer: Control = null
var _hit_debug_enabled: bool = false
var _passthrough_refresh_pending: bool = false
var _pending_passthrough_reason: String = ""
var _last_window_position: Vector2i = Vector2i(-99999, -99999)
var _last_scale: float = -1.0
var _last_opacity: float = -1.0
var _last_taskbar_visible: Variant = null
var _last_topmost: Variant = null


func _ready() -> void:
	Platform.write_boot_log("Main._ready: begin")
	get_tree().auto_accept_quit = false
	_apply_window_icon()
	_debug_mode = bool(Config.get_value("debug_mode", false))
	Platform.write_boot_log("Main._ready: debug_mode=%s" % str(_debug_mode))
	_native_health = Platform.get_native_health()
	Platform.write_boot_log("Main._ready: native_health=%s" % str(_native_health))
	_setup_window()
	Platform.write_boot_log("Main._ready: setup_window done")
	_restore_position()
	_last_window_position = get_window().position
	Platform.write_boot_log("Main._ready: restore_position done")
	_apply_scale_opacity()
	Platform.write_boot_log("Main._ready: scale_opacity done")
	DragResizeSystem.register_window(get_window())
	Platform.write_boot_log("Main._ready: register_window done")
	_connect_signals()
	_position_panel()
	_create_hit_debug_layer()
	_setup_tray()
	Platform.write_boot_log("Main._ready: setup_tray done ready=%s" % str(_tray_ready))
	_apply_pure_pet_mode()
	_request_mouse_passthrough_refresh("ready")
	Platform.write_boot_log("Main._ready: mouse_passthrough done")

	SalaryEngine.reload()
	Platform.write_boot_log("Main._ready: salary reload done")
	_set_debug_status("Debug: ready. Left/right click the pet area.")
	if not Config.has_config():
		call_deferred("_show_wizard")
	Platform.write_boot_log("Main._ready: end")


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		_on_window_close_requested()


func get_debug_window_size() -> Vector2i:
	return DEBUG_WINDOW_SIZE


func get_pet_window_size() -> Vector2i:
	return _pet_window_size_for_scale(float(Config.get_value("scale", 1.0)))


func apply_runtime_mode(debug_mode: bool) -> void:
	_debug_mode = debug_mode
	_native_health = Platform.get_native_health()
	var transparent_pet_window := bool(Config.get_value("transparent_pet_window_enabled", true)) \
		and bool(Config.get_value("native_integration_enabled", true)) \
		and bool(_native_health.get("window_supported", false))
	_apply_viewport_transparency(transparent_pet_window and not _debug_mode)
	Platform.setup_window(get_window(), _debug_mode, transparent_pet_window)
	_apply_pet_window_size()
	debug_input_area.visible = _debug_mode
	debug_input_area.mouse_filter = Control.MOUSE_FILTER_STOP if _debug_mode else Control.MOUSE_FILTER_IGNORE
	debug_status.visible = _debug_mode
	if _debug_mode:
		pet.position = DEBUG_PET_POSITION
		panel.position = DEBUG_PANEL_POSITION
	else:
		pet.position = PET_MODE_PET_POSITION
		panel.position = PET_MODE_PANEL_POSITION
	_sync_hit_debug_layer()


func _setup_window() -> void:
	apply_runtime_mode(_debug_mode)
	var mode := String(Config.get_value("window_mode", "top"))
	var topmost := mode != "embed"
	if mode == "embed":
		if _last_topmost != topmost:
			Platform.set_window_embed_desktop(get_window(), true)
			_last_topmost = topmost
	else:
		if _last_topmost != topmost:
			Platform.set_window_topmost(get_window(), true)
			_last_topmost = topmost


func _connect_signals() -> void:
	Config.config_changed.connect(_on_config_changed)
	if not DragResizeSystem.modal_closed.is_connected(_on_modal_closed):
		DragResizeSystem.modal_closed.connect(_on_modal_closed)
	if not DragResizeSystem.modal_opened.is_connected(_on_modal_opened):
		DragResizeSystem.modal_opened.connect(_on_modal_opened)
	if not DragResizeSystem.popup_opened.is_connected(_on_popup_opened):
		DragResizeSystem.popup_opened.connect(_on_popup_opened)
	if not DragResizeSystem.popup_closed.is_connected(_on_popup_closed):
		DragResizeSystem.popup_closed.connect(_on_popup_closed)
	if panel != null and panel.has_signal("layout_changed") and not panel.layout_changed.is_connected(_on_panel_layout_changed):
		panel.layout_changed.connect(_on_panel_layout_changed)
	if not debug_input_area.gui_input.is_connected(_on_debug_input_area_gui_input):
		debug_input_area.gui_input.connect(_on_debug_input_area_gui_input)
	var window := get_window()
	if not window.close_requested.is_connected(_on_window_close_requested):
		window.close_requested.connect(_on_window_close_requested)


func _setup_tray() -> void:
	if _debug_mode:
		_tray_ready = false
		return
	if not bool(Config.get_value("native_integration_enabled", true)):
		_tray_ready = false
		return
	if not bool(Config.get_value("system_tray_enabled", true)):
		_tray_ready = false
		return
	_native_health = Platform.get_native_health()
	if not bool(_native_health.get("tray_supported", false)):
		_tray_ready = false
		return
	_tray_ready = Platform.setup_tray(_get_tray_icon_path())
	if _tray_ready:
		if not Platform.tray_toggle_requested.is_connected(_on_tray_toggle_requested):
			Platform.tray_toggle_requested.connect(_on_tray_toggle_requested)
		if not Platform.tray_left_toggle_requested.is_connected(_on_tray_left_toggle_requested):
			Platform.tray_left_toggle_requested.connect(_on_tray_left_toggle_requested)
		if not Platform.tray_settings_requested.is_connected(_open_settings):
			Platform.tray_settings_requested.connect(_open_settings)
		if not Platform.tray_about_requested.is_connected(DragResizeSystem.show_about):
			Platform.tray_about_requested.connect(DragResizeSystem.show_about)
		if not Platform.tray_exit_requested.is_connected(_exit_app):
			Platform.tray_exit_requested.connect(_exit_app)


func _restore_position() -> void:
	var window := get_window()
	var size := DEBUG_WINDOW_SIZE if _debug_mode else get_pet_window_size()
	var x := int(Config.get_value("window_x", -1))
	var y := int(Config.get_value("window_y", -1))
	var screen := Platform.get_screen_size()
	if x < 0 or y < 0 or x > screen.x - 50 or y > screen.y - 50:
		x = max(0, screen.x - size.x - 20)
		y = max(0, screen.y - size.y - 80)
	window.position = Vector2i(x, y)


func _apply_scale_opacity() -> void:
	var s := float(Config.get_value("scale", 1.0))
	var o := float(Config.get_value("opacity", 1.0))
	if not is_equal_approx(s, _last_scale):
		pet.scale = Vector2(s, s)
		if panel != null and panel.has_method("set_display_scale"):
			panel.call("set_display_scale", s)
		_apply_pet_window_size()
		_last_scale = s
	if not is_equal_approx(o, _last_opacity):
		modulate = Color(1, 1, 1, clamp(o, 0.2, 1.0))
		_last_opacity = o


func _apply_pet_window_size() -> void:
	if _debug_mode:
		return
	var window := get_window()
	var target_size := get_pet_window_size()
	if window.size != target_size:
		window.min_size = target_size
		window.size = target_size
		_sync_hit_debug_layer()


func _pet_window_size_for_scale(scale_value: float) -> Vector2i:
	var pet_bounds: Rect2 = _pet_sprite_bounds_for_scale(scale_value)
	var panel_size := _panel_target_size_for_scale(scale_value)
	var width: float = maxf(float(PET_WINDOW_SIZE.x), pet_bounds.end.x + PET_CONTENT_MARGIN)
	width = maxf(width, PET_MODE_PANEL_POSITION.x + float(panel_size.x) + PET_CONTENT_MARGIN)
	var height: float = maxf(float(PET_WINDOW_SIZE.y), pet_bounds.end.y + PET_CONTENT_MARGIN)
	height = maxf(height, PET_MODE_PANEL_POSITION.y + float(panel_size.y) + PET_CONTENT_MARGIN)
	return Vector2i(int(ceil(width)), int(ceil(height)))


func _panel_target_size_for_scale(scale_value: float) -> Vector2i:
	var safe_scale: float = clamp(scale_value, 0.5, 2.0)
	return Vector2i(
		int(ceil(float(PANEL_TARGET_SIZE.x) * safe_scale)),
		int(ceil(float(PANEL_TARGET_SIZE.y) * safe_scale))
	)


func _pet_sprite_bounds_for_scale(scale_value: float) -> Rect2:
	return _pet_sprite_bounds_at_position(scale_value, PET_MODE_PET_POSITION)


func _pet_sprite_bounds_at_position(scale_value: float, base_position: Vector2) -> Rect2:
	var safe_scale: float = clamp(scale_value, 0.5, 2.0)
	var sprite_size: Vector2 = PET_TEXTURE_SIZE * PET_ANIM_BASE_SCALE * safe_scale
	var sprite_center: Vector2 = base_position + PET_ANIM_LOCAL_POSITION * safe_scale
	return Rect2(sprite_center - sprite_size * 0.5, sprite_size)


func _position_panel() -> void:
	if _debug_mode:
		panel.position = DEBUG_PANEL_POSITION
		return
	var window := get_window()
	var screen := Platform.get_screen_size()
	panel.position = _resolve_panel_position(window.position, screen, _get_panel_target_size())


func _get_panel_target_size() -> Vector2i:
	var target := _panel_target_size_for_scale(float(Config.get_value("scale", 1.0)))
	if panel is Control:
		var control := panel as Control
		target.x = maxi(target.x, int(ceil(control.size.x)))
		target.y = maxi(target.y, int(ceil(control.size.y)))
	return target


func _resolve_panel_position(_window_position: Vector2i, _screen_size: Vector2i, _panel_size: Vector2i) -> Vector2:
	return PET_MODE_PANEL_BOTTOM_RIGHT_POSITION


func _request_mouse_passthrough_refresh(reason: String) -> void:
	_apply_mouse_passthrough(reason)
	_sync_hit_debug_layer()


func _queue_mouse_passthrough_refresh(reason: String) -> void:
	if _pending_passthrough_reason.is_empty():
		_pending_passthrough_reason = reason
	elif not _pending_passthrough_reason.contains(reason):
		_pending_passthrough_reason += "," + reason
	if _passthrough_refresh_pending:
		return
	_passthrough_refresh_pending = true
	call_deferred("_flush_mouse_passthrough_refresh")


func _flush_mouse_passthrough_refresh() -> void:
	_passthrough_refresh_pending = false
	var reason := _pending_passthrough_reason
	_pending_passthrough_reason = ""
	_request_mouse_passthrough_refresh(reason if not reason.is_empty() else "queued")


func _apply_mouse_passthrough(reason: String = "unspecified") -> void:
	if _modal_open:
		_last_passthrough_rects_hash = 0
		Platform.set_mouse_passthrough(get_window(), false, [])
		Platform.write_debug_log("Main._apply_mouse_passthrough: reason=%s mode=modal clear" % reason)
		return
	if _debug_mode:
		_last_passthrough_rects_hash = 0
		Platform.write_debug_log("Main._apply_mouse_passthrough: reason=%s mode=debug skip" % reason)
		return
	if not bool(Config.get_value("native_integration_enabled", true)):
		Platform.set_mouse_passthrough(get_window(), false, [])
		_last_passthrough_rects_hash = 0
		Platform.write_debug_log("Main._apply_mouse_passthrough: reason=%s native disabled" % reason)
		return
	if not bool(Config.get_value("mouse_passthrough_enabled", true)):
		Platform.set_mouse_passthrough(get_window(), false, [])
		_last_passthrough_rects_hash = 0
		Platform.write_debug_log("Main._apply_mouse_passthrough: reason=%s config disabled" % reason)
		return
	_native_health = Platform.get_native_health()
	if not bool(_native_health.get("passthrough_supported", false)):
		Platform.set_mouse_passthrough(get_window(), false, [])
		_last_passthrough_rects_hash = 0
		Platform.write_debug_log("Main._apply_mouse_passthrough: reason=%s passthrough unsupported health=%s" % [reason, str(_native_health)])
		return
	var rects := get_interactive_rects()
	var rects_hash := hash(rects)
	if rects_hash == _last_passthrough_rects_hash:
		Platform.write_debug_log("Main._apply_mouse_passthrough: reason=%s unchanged hash=%s" % [reason, str(rects_hash)])
		return
	Platform.write_debug_log("Main._apply_mouse_passthrough: reason=%s window_pos=%s scale=%.2f rects=%s screen_rects=%s" % [
		reason,
		str(get_window().position),
		float(Config.get_value("scale", 1.0)),
		str(rects),
		str(_describe_screen_rects(rects))
	])
	var ok := Platform.set_mouse_passthrough(get_window(), true, rects)
	if not ok:
		Platform.write_boot_log("Main._apply_mouse_passthrough: reason=%s fallback disabled health=%s" % [reason, str(Platform.get_native_health())])
		_last_passthrough_rects_hash = 0
	else:
		_last_passthrough_rects_hash = rects_hash


func get_interactive_rects() -> Array[Rect2]:
	return [
		_get_pet_interaction_rect_for_passthrough(),
		_get_panel_interaction_rect()
	]


func _get_pet_interaction_rect_for_passthrough() -> Rect2:
	var s := float(Config.get_value("scale", 1.0))
	if pet != null and pet.has_method("get_interaction_rect"):
		var local_rect: Rect2 = pet.call("get_interaction_rect")
		return Rect2(pet.position + local_rect.position * s, local_rect.size * s).grow_individual(
			PET_HIT_PADDING.x * s,
			PET_HIT_PADDING.y * s,
			PET_HIT_PADDING.x * s,
			PET_HIT_PADDING.y * s
		)
	return _pet_sprite_bounds_at_position(s, pet.position).grow_individual(
		PET_HIT_PADDING.x * s,
		PET_HIT_PADDING.y * s,
		PET_HIT_PADDING.x * s,
		PET_HIT_PADDING.y * s
	)


func _get_panel_interaction_rect() -> Rect2:
	var panel_size := PANEL_HIT_SIZE
	if panel is Control:
		var panel_control := panel as Control
		panel_size = Vector2(max(PANEL_HIT_SIZE.x, panel_control.size.x), max(PANEL_HIT_SIZE.y, panel_control.size.y))
	return Rect2(panel.position, panel_size).grow(PANEL_HOVER_PADDING)


func _get_panel_visual_scale() -> Vector2:
	return Vector2.ONE


func _apply_window_icon() -> void:
	var texture := load("res://icons/app_icon_256.png") as Texture2D
	if texture != null:
		DisplayServer.set_icon(texture.get_image())


func _get_tray_icon_path() -> String:
	var executable_icon := OS.get_executable_path().get_base_dir().path_join("app_icon.ico")
	if FileAccess.file_exists(executable_icon):
		return executable_icon

	var user_icon := OS.get_user_data_dir().path_join("app_icon.ico")
	if _ensure_tray_icon_file(user_icon):
		return user_icon

	var project_icon := ProjectSettings.globalize_path("res://icons/app_icon.ico")
	if FileAccess.file_exists(project_icon):
		return project_icon
	return project_icon


func _ensure_tray_icon_file(target_path: String) -> bool:
	if FileAccess.file_exists(target_path):
		return true
	var source := FileAccess.open("res://icons/app_icon.ico", FileAccess.READ)
	if source == null:
		return false
	var bytes := source.get_buffer(source.get_length())
	var target := FileAccess.open(target_path, FileAccess.WRITE)
	if target == null:
		return false
	target.store_buffer(bytes)
	return FileAccess.file_exists(target_path)


func _get_hit_debug_rects() -> Array[Dictionary]:
	var interactive_rects := get_interactive_rects()
	var panel_name := "panel_expanded" if panel is Control and (panel as Control).size.x > PANEL_HIT_SIZE.x else "panel_collapsed"
	return [
		{"name": "pet_core", "rect": interactive_rects[0], "color": Color(0.2, 0.8, 1.0, 0.28)},
		{"name": "pet_context", "rect": get_pet_context_rect(), "color": Color(1.0, 0.72, 0.2, 0.20)},
		{"name": panel_name, "rect": interactive_rects[1], "color": Color(0.35, 1.0, 0.45, 0.24)}
	]


func _describe_screen_rects(rects: Array[Rect2]) -> Array[String]:
	var result: Array[String] = []
	var window_pos := Vector2(get_window().position)
	for rect in rects:
		result.append("pos=%s size=%s" % [str(window_pos + rect.position), str(rect.size)])
	return result


func _create_hit_debug_layer() -> void:
	if _hit_debug_layer != null:
		return
	_hit_debug_layer = Control.new()
	_hit_debug_layer.name = "HitDebugLayer"
	_hit_debug_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hit_debug_layer.z_index = 1000
	_hit_debug_layer.visible = false
	add_child(_hit_debug_layer)
	_sync_hit_debug_layer()


func set_hit_debug_enabled(enabled: bool) -> void:
	_hit_debug_enabled = enabled
	_sync_hit_debug_layer()


func _sync_hit_debug_layer() -> void:
	if _hit_debug_layer == null:
		return
	for child in _hit_debug_layer.get_children():
		child.queue_free()
	_hit_debug_layer.visible = _debug_mode and _hit_debug_enabled
	if not _debug_mode or not _hit_debug_enabled:
		return
	_hit_debug_layer.size = Vector2(get_window().size)
	for item in _get_hit_debug_rects():
		var rect: Rect2 = item["rect"]
		var block := ColorRect.new()
		block.name = String(item["name"])
		block.mouse_filter = Control.MOUSE_FILTER_IGNORE
		block.position = rect.position
		block.size = rect.size
		block.color = item["color"]
		_hit_debug_layer.add_child(block)


func get_pet_context_rect() -> Rect2:
	var s := float(Config.get_value("scale", 1.0))
	return _get_pet_interaction_rect_for_passthrough().grow_individual(
		PET_CONTEXT_PADDING.x * s,
		PET_CONTEXT_PADDING.y * s,
		PET_CONTEXT_PADDING.x * s,
		PET_CONTEXT_PADDING.y * s
	)


func suspend_mouse_passthrough() -> void:
	_last_passthrough_rects_hash = 0
	Platform.set_mouse_passthrough(get_window(), false, [])


func _apply_viewport_transparency(enabled: bool) -> void:
	get_viewport().transparent_bg = enabled
	RenderingServer.set_default_clear_color(Color(0, 0, 0, 0) if enabled else Color(0, 0, 0, 1))


func _apply_pure_pet_mode() -> void:
	if _debug_mode:
		_set_taskbar_visible_cached(true)
		Platform.write_debug_log("pure_pet_mode_fallback: reason=debug_mode taskbar_visible=true")
		return

	var desired := bool(Config.get_value("pure_pet_mode", false))
	if not desired:
		_set_taskbar_visible_cached(true)
		Platform.write_debug_log("pure_pet_mode_apply: desired=false taskbar_visible=true")
		return

	if not _tray_ready or not Platform.can_enable_pure_pet_mode(get_window()):
		Config.set_value("pure_pet_mode", false)
		_set_taskbar_visible_cached(true)
		Platform.write_boot_log("pure_pet_mode_fallback: reason=tray_or_native_unavailable")
		return

	var ok := _set_taskbar_visible_cached(false)
	if not ok:
		Config.set_value("pure_pet_mode", false)
		_set_taskbar_visible_cached(true)
		Platform.write_boot_log("pure_pet_mode_fallback: reason=set_taskbar_visible_failed")
	else:
		Platform.write_debug_log("pure_pet_mode_apply: desired=true taskbar_visible=false")


func _set_taskbar_visible_cached(visible: bool) -> bool:
	if _last_taskbar_visible == visible:
		return true
	var ok := Platform.set_taskbar_visible(get_window(), visible)
	if ok or visible:
		_last_taskbar_visible = visible
	return ok


func _invalidate_taskbar_visibility_cache(reason: String) -> void:
	_last_taskbar_visible = null
	Platform.write_debug_log("Main._invalidate_taskbar_visibility_cache: reason=%s" % reason)


func _reapply_tray_restore_window_policy() -> void:
	_last_topmost = null
	_invalidate_taskbar_visibility_cache("tray_restore")
	Platform.write_boot_log("Main._reapply_tray_restore_window_policy: pure_pet_mode=%s visible=%s window_prop=%s" % [
		str(Config.get_value("pure_pet_mode", false)),
		str(DragResizeSystem.is_window_visible()),
		str(get_window().visible)
	])
	_set_primary_content_visible(true)
	_setup_window()
	_restore_position()
	_apply_scale_opacity()
	_position_panel()
	_apply_pure_pet_mode()
	_request_mouse_passthrough_refresh("tray_restore")
	Platform.write_boot_log("window_policy_reapplied: phase=tray_restore pure_pet_mode=%s" % str(Config.get_value("pure_pet_mode", false)))

	await get_tree().process_frame
	if not DragResizeSystem.is_window_visible():
		return
	_invalidate_taskbar_visibility_cache("tray_restore_post_frame")
	Platform.write_boot_log("Main._reapply_tray_restore_window_policy: post_frame pure_pet_mode=%s visible=%s window_prop=%s" % [
		str(Config.get_value("pure_pet_mode", false)),
		str(DragResizeSystem.is_window_visible()),
		str(get_window().visible)
	])
	_apply_pure_pet_mode()
	_request_mouse_passthrough_refresh("tray_restore_post_frame")
	Platform.write_boot_log("window_policy_reapplied: phase=tray_restore_post_frame pure_pet_mode=%s" % str(Config.get_value("pure_pet_mode", false)))


func _on_config_changed() -> void:
	var changed_keys: Array[String] = []
	if Config.has_method("get_last_changed_keys"):
		changed_keys = Config.get_last_changed_keys()
	_apply_config_change_scope(changed_keys)


func _apply_config_change_scope(changed_keys: Array[String]) -> void:
	var next_debug_mode := bool(Config.get_value("debug_mode", false))
	if next_debug_mode != _debug_mode:
		_debug_mode = next_debug_mode
		if _modal_open:
			_runtime_mode_reapply_deferred_until_modal_close = true
			Platform.write_debug_log("Main._apply_config_change_scope: deferred debug mode runtime apply until modal closes")
		else:
			_setup_window()
			_restore_position()
			_setup_tray()
			_schedule_runtime_mode_reapply()
	if _config_scope_requires_salary_refresh(changed_keys):
		SalaryEngine.reload()
	if _config_scope_requires_window_policy(changed_keys):
		if _modal_open:
			_runtime_mode_reapply_deferred_until_modal_close = true
			Platform.write_debug_log("Main._apply_config_change_scope: deferred window policy apply until modal closes")
		else:
			_apply_scale_opacity()
			_position_panel()
			_apply_pure_pet_mode()
			_queue_mouse_passthrough_refresh("config_changed")
	if panel != null:
		if changed_keys.is_empty() or changed_keys.has("panel_items"):
			panel._apply_panel_config()
		if _config_scope_requires_salary_refresh(changed_keys) or changed_keys.has("panel_items"):
			panel.refresh_values()
	Platform.update_tray_menu(DragResizeSystem.is_window_visible())


func _config_scope_requires_salary_refresh(changed_keys: Array[String]) -> bool:
	if changed_keys.is_empty():
		return true
	for key in ["monthly_salary", "rest_mode", "work_start_time", "work_end_time", "work_hours_per_day"]:
		if changed_keys.has(key):
			return true
	return false


func _config_scope_requires_window_policy(changed_keys: Array[String]) -> bool:
	if changed_keys.is_empty():
		return true
	for key in [
		"scale",
		"opacity",
		"window_mode",
		"debug_mode",
		"pure_pet_mode",
		"native_integration_enabled",
		"mouse_passthrough_enabled",
		"transparent_pet_window_enabled",
		"system_tray_enabled"
	]:
		if changed_keys.has(key):
			return true
	return false


func _schedule_runtime_mode_reapply() -> void:
	if _modal_open:
		_runtime_mode_reapply_deferred_until_modal_close = true
		Platform.write_debug_log("Main._schedule_runtime_mode_reapply: deferred until modal closes")
		return
	if _runtime_mode_reapply_pending:
		return
	_runtime_mode_reapply_pending = true
	call_deferred("_reapply_runtime_mode_after_popups")


func _reapply_runtime_mode_after_popups() -> void:
	await get_tree().process_frame
	_runtime_mode_reapply_pending = false
	if _modal_open:
		_runtime_mode_reapply_deferred_until_modal_close = true
		Platform.write_debug_log("Main._reapply_runtime_mode_after_popups: modal still open, deferred")
		return
	_runtime_mode_reapply_deferred_until_modal_close = false
	_set_primary_content_visible(true)
	_setup_window()
	_restore_position()
	_apply_scale_opacity()
	_position_panel()
	_apply_pure_pet_mode()
	_request_mouse_passthrough_refresh("runtime_reapply")


func _on_modal_opened() -> void:
	_modal_open = true
	_runtime_mode_reapply_deferred_until_modal_close = false
	_last_passthrough_rects_hash = 0
	_set_primary_content_visible(false)
	_apply_viewport_transparency(true)
	Platform.set_mouse_passthrough(get_window(), false, [])
	Platform.write_debug_log("passthrough_suspended: reason=modal_opened")


func _on_modal_closed() -> void:
	_modal_open = false
	_runtime_mode_reapply_deferred_until_modal_close = false
	_schedule_runtime_mode_reapply()
	Platform.write_debug_log("passthrough_resumed: reason=modal_closed")


func _on_popup_opened() -> void:
	_last_passthrough_rects_hash = 0
	Platform.set_mouse_passthrough(get_window(), false, [])
	Platform.write_debug_log("passthrough_suspended: reason=popup_opened")


func _on_popup_closed() -> void:
	_queue_mouse_passthrough_refresh("popup_closed")
	Platform.write_debug_log("passthrough_resumed: reason=popup_closed")


func _set_primary_content_visible(visible: bool) -> void:
	if pet != null:
		pet.visible = visible
	if panel != null:
		panel.visible = visible
	if debug_input_area != null:
		debug_input_area.visible = visible and _debug_mode
	if debug_status != null:
		debug_status.visible = visible and _debug_mode


func _on_panel_layout_changed() -> void:
	_queue_mouse_passthrough_refresh("panel_layout_changed")


func _process(_delta: float) -> void:
	if _modal_open:
		return
	var window := get_window()
	if window.position != _last_window_position:
		_last_window_position = window.position
	else:
		return
	var old_panel_position: Vector2 = panel.position
	_position_panel()
	if panel.position != old_panel_position:
		_queue_mouse_passthrough_refresh("panel_reposition")


func _input(event: InputEvent) -> void:
	if not _debug_mode and not _modal_open and event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			var context_rect := get_pet_context_rect()
			if context_rect.has_point(event.position):
				Platform.write_boot_log("Main._input: context menu via pet context rect pos=%s rect=%s" % [str(event.position), str(context_rect)])
				DragResizeSystem.show_context_menu()
				get_viewport().set_input_as_handled()
				return
	if _debug_mode and event is InputEventKey:
		_handle_debug_key(event)


func _on_debug_input_area_gui_input(event: InputEvent) -> void:
	if not _debug_mode:
		return
	if event is InputEventMouseButton:
		_handle_debug_mouse_button(event)
	elif event is InputEventMouseMotion:
		_handle_debug_mouse_motion(event)


func _handle_debug_mouse_button(event: InputEventMouseButton) -> void:
	if event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_debug_mouse_pressed = true
			_debug_dragging = false
			_debug_drag_start_mouse = event.position
			_debug_drag_start_screen_mouse = DisplayServer.mouse_get_position()
			_debug_drag_start_window_pos = get_window().position
			_set_debug_status("Debug: left pressed at %s" % event.position)
			PetManager.request_interaction(PetManager.PetInteraction.HOVER)
			get_viewport().set_input_as_handled()
		elif _debug_mouse_pressed:
			if _debug_dragging:
				DragResizeSystem.save_position()
				_set_debug_status("Debug: drag saved at window %s" % get_window().position)
			else:
				_register_debug_click()
			_debug_mouse_pressed = false
			_debug_dragging = false
			get_viewport().set_input_as_handled()
	elif event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		_set_debug_status("Debug: right click menu at %s" % event.position)
		DragResizeSystem.show_context_menu()
		get_viewport().set_input_as_handled()


func _handle_debug_mouse_motion(event: InputEventMouseMotion) -> void:
	var left_button_down := (event.button_mask & MOUSE_BUTTON_MASK_LEFT) != 0
	if not _debug_mouse_pressed and left_button_down:
		_debug_mouse_pressed = true
		_debug_drag_start_mouse = event.position
		_debug_drag_start_screen_mouse = DisplayServer.mouse_get_position()
		_debug_drag_start_window_pos = get_window().position

	if not _debug_mouse_pressed:
		return

	if not _debug_dragging and (event.position - _debug_drag_start_mouse).length() >= DRAG_THRESHOLD:
		_debug_dragging = true
		_set_debug_status("Debug: drag started")

	if _debug_dragging:
		var delta := DisplayServer.mouse_get_position() - _debug_drag_start_screen_mouse
		var target_pos := _debug_drag_start_window_pos + delta
		if target_pos != get_window().position:
			DragResizeSystem.move_window_to(target_pos)
			get_viewport().set_input_as_handled()


func _handle_debug_key(event: InputEventKey) -> void:
	if not event.pressed or event.echo:
		return

	var step := 12
	if event.shift_pressed:
		step = 48

	var delta := Vector2i.ZERO
	match event.keycode:
		KEY_LEFT:
			delta = Vector2i(-step, 0)
		KEY_RIGHT:
			delta = Vector2i(step, 0)
		KEY_UP:
			delta = Vector2i(0, -step)
		KEY_DOWN:
			delta = Vector2i(0, step)

	if delta != Vector2i.ZERO:
		DragResizeSystem.move_window_to(get_window().position + delta)
		DragResizeSystem.save_position()
		_set_debug_status("Debug: key moved window by %s" % delta)
		_request_mouse_passthrough_refresh("debug_key_move")
		get_viewport().set_input_as_handled()
		return

	if event.keycode == KEY_H:
		set_hit_debug_enabled(not _hit_debug_enabled)
		_set_debug_status("Debug: hit areas %s" % ("shown" if _hit_debug_enabled else "hidden"))
		get_viewport().set_input_as_handled()


func _set_debug_status(text: String) -> void:
	if debug_status != null:
		debug_status.text = text
		debug_status.add_theme_font_size_override("font_size", 18)


func _show_wizard() -> void:
	await get_tree().process_frame
	DragResizeSystem.prepare_modal_window(DragResizeSystem.WIZARD_DIALOG_SIZE)
	var wizard_scene := load("res://src/scenes/wizard/wizard_dialog.tscn")
	if wizard_scene == null:
		push_error("Wizard scene not found")
		return
	var wizard_view: Control = wizard_scene.instantiate()
	get_window().title = "开始配置"
	get_window().add_child(wizard_view)
	wizard_view.set_anchors_preset(Control.PRESET_FULL_RECT)
	wizard_view.offset_left = 0
	wizard_view.offset_top = 0
	wizard_view.offset_right = 0
	wizard_view.offset_bottom = 0
	wizard_view.tree_exited.connect(_on_modal_closed)
	if wizard_view.has_signal("finished"):
		wizard_view.finished.connect(_on_wizard_done)
	wizard_view.grab_focus()


func _on_wizard_done() -> void:
	SalaryEngine.reload()
	_apply_scale_opacity()
	_position_panel()
	_request_mouse_passthrough_refresh("wizard_done")
	if panel != null:
		panel.refresh_values()


func _register_debug_click() -> void:
	_debug_click_count += 1
	if _debug_click_count >= 2:
		_trigger_debug_click(PetManager.PetInteraction.CLICKED_DOUBLE, "double click")
		return

	if not _debug_click_timer_active:
		_debug_click_timer_active = true
		get_tree().create_timer(DOUBLE_CLICK_WINDOW).timeout.connect(_resolve_debug_click)


func _resolve_debug_click() -> void:
	_debug_click_timer_active = false
	if _debug_click_count == 1:
		_trigger_debug_click(PetManager.PetInteraction.CLICKED_SINGLE, "single click")
	else:
		_trigger_debug_click(PetManager.PetInteraction.CLICKED_DOUBLE, "double click")


func _trigger_debug_click(interaction: PetManager.PetInteraction, label: String) -> void:
	_debug_click_count = 0
	_debug_click_timer_active = false
	PetManager.request_interaction(interaction)
	_set_debug_status("Debug: %s" % label)
	get_tree().create_timer(CLICK_FEEDBACK_RETURN_DELAY).timeout.connect(PetManager.return_to_interaction_base_state)


func _on_tray_toggle_requested() -> void:
	var visible_before := DragResizeSystem.is_window_visible()
	Platform.write_boot_log("tray_toggle_requested: visible_before=%s window_prop=%s" % [str(visible_before), str(get_window().visible)])
	Platform.write_boot_log("Main._on_tray_toggle_requested: visible_before=%s window_prop=%s" % [str(visible_before), str(get_window().visible)])
	if visible_before:
		DragResizeSystem.save_position()
	DragResizeSystem.toggle_window_visible()
	var visible_after := DragResizeSystem.is_window_visible()
	if visible_after:
		_reapply_tray_restore_window_policy()
	Platform.update_tray_menu(visible_after)
	Platform.write_boot_log("Main._on_tray_toggle_requested: visible_after=%s window_prop=%s" % [str(visible_after), str(get_window().visible)])


func _on_tray_left_toggle_requested() -> void:
	var visible_before := DragResizeSystem.is_window_visible()
	var pure_pet_mode := bool(Config.get_value("pure_pet_mode", false))
	Platform.write_boot_log("tray_left_toggle_requested: visible_before=%s pure_pet_mode=%s window_prop=%s" % [
		str(visible_before),
		str(pure_pet_mode),
		str(get_window().visible)
	])
	if visible_before:
		DragResizeSystem.save_position()
	DragResizeSystem.toggle_window_visible()
	var visible_after := DragResizeSystem.is_window_visible()
	if visible_after:
		_reapply_tray_restore_window_policy()
	Platform.update_tray_menu(visible_after)
	Platform.write_boot_log("tray_left_toggle_result: visible_after=%s pure_pet_mode=%s window_prop=%s" % [
		str(visible_after),
		str(pure_pet_mode),
		str(get_window().visible)
	])


func _open_settings() -> void:
	DragResizeSystem.open_settings()


func _on_window_close_requested() -> void:
	if _modal_open:
		DragResizeSystem.close_active_modal()
		return
	if can_hide_to_tray():
		DragResizeSystem.save_position()
		DragResizeSystem.set_window_visible(false)
		Platform.update_tray_menu(false)
	else:
		_exit_app()


func can_hide_to_tray() -> bool:
	return bool(Config.get_value("minimize_to_tray", true)) and _tray_ready


func _exit_app() -> void:
	DragResizeSystem.quit_app()
