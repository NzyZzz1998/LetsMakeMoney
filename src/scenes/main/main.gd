# src/scenes/main/main.gd
extends Node2D

@onready var pet: Node2D = $Pet
@onready var panel = $Panel
@onready var debug_status: Label = $DebugStatus
@onready var debug_input_area: ColorRect = $DebugInputArea

const DEBUG_WINDOW_SIZE := Vector2i(900, 500)
const PET_WINDOW_SIZE := Vector2i(620, 380)
const DEBUG_PET_POSITION := Vector2(72, 168)
const DEBUG_PANEL_POSITION := Vector2(340, 140)
const PET_MODE_PET_POSITION := Vector2(28, 88)
const PET_MODE_PANEL_POSITION := Vector2(300, 104)
const PET_MODE_PANEL_LEFT_POSITION := Vector2(12, 104)
const PET_MODE_PANEL_TOP_POSITION := Vector2(300, 12)
const PET_HIT_SIZE := Vector2(224, 224)
const PANEL_HIT_SIZE := Vector2(160, 90)
const DRAG_THRESHOLD := 4.0
const DOUBLE_CLICK_WINDOW := 0.3

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


func _ready() -> void:
	Platform.write_boot_log("Main._ready: begin")
	_debug_mode = bool(Config.get_value("debug_mode", false))
	Platform.write_boot_log("Main._ready: debug_mode=%s" % str(_debug_mode))
	_setup_window()
	Platform.write_boot_log("Main._ready: setup_window done")
	_restore_position()
	Platform.write_boot_log("Main._ready: restore_position done")
	_apply_scale_opacity()
	Platform.write_boot_log("Main._ready: scale_opacity done")
	DragResizeSystem.register_window(get_window())
	Platform.write_boot_log("Main._ready: register_window done")
	_connect_signals()
	_position_panel()
	_setup_tray()
	Platform.write_boot_log("Main._ready: setup_tray done ready=%s" % str(_tray_ready))
	_apply_mouse_passthrough()
	Platform.write_boot_log("Main._ready: mouse_passthrough done")

	SalaryEngine.reload()
	Platform.write_boot_log("Main._ready: salary reload done")
	_set_debug_status("Debug: ready. Left/right click the pet area.")
	if not Config.has_config():
		call_deferred("_show_wizard")
	Platform.write_boot_log("Main._ready: end")


func get_debug_window_size() -> Vector2i:
	return DEBUG_WINDOW_SIZE


func get_pet_window_size() -> Vector2i:
	return PET_WINDOW_SIZE


func apply_runtime_mode(debug_mode: bool) -> void:
	_debug_mode = debug_mode
	var transparent_pet_window := bool(Config.get_value("transparent_pet_window_enabled", false))
	Platform.setup_window(get_window(), _debug_mode, transparent_pet_window)
	debug_input_area.visible = _debug_mode
	debug_input_area.mouse_filter = Control.MOUSE_FILTER_STOP if _debug_mode else Control.MOUSE_FILTER_IGNORE
	debug_status.visible = _debug_mode
	if _debug_mode:
		pet.position = DEBUG_PET_POSITION
		panel.position = DEBUG_PANEL_POSITION
	else:
		pet.position = PET_MODE_PET_POSITION
		panel.position = PET_MODE_PANEL_POSITION


func _setup_window() -> void:
	apply_runtime_mode(_debug_mode)
	var mode := String(Config.get_value("window_mode", "top"))
	if mode == "embed":
		Platform.set_window_embed_desktop(get_window(), true)
	else:
		Platform.set_window_topmost(get_window(), true)


func _connect_signals() -> void:
	Config.config_changed.connect(_on_config_changed)
	if not debug_input_area.gui_input.is_connected(_on_debug_input_area_gui_input):
		debug_input_area.gui_input.connect(_on_debug_input_area_gui_input)
	var window := get_window()
	if not window.close_requested.is_connected(_on_window_close_requested):
		window.close_requested.connect(_on_window_close_requested)


func _setup_tray() -> void:
	if _debug_mode:
		_tray_ready = false
		return
	if not bool(Config.get_value("system_tray_enabled", false)):
		_tray_ready = false
		return
	_tray_ready = Platform.setup_tray("res://icons/app_icon.png")
	if _tray_ready:
		if not Platform.tray_toggle_requested.is_connected(_on_tray_toggle_requested):
			Platform.tray_toggle_requested.connect(_on_tray_toggle_requested)
		if not Platform.tray_settings_requested.is_connected(_open_settings):
			Platform.tray_settings_requested.connect(_open_settings)
		if not Platform.tray_about_requested.is_connected(DragResizeSystem.show_about):
			Platform.tray_about_requested.connect(DragResizeSystem.show_about)
		if not Platform.tray_exit_requested.is_connected(_exit_app):
			Platform.tray_exit_requested.connect(_exit_app)


func _restore_position() -> void:
	var window := get_window()
	var size := DEBUG_WINDOW_SIZE if _debug_mode else PET_WINDOW_SIZE
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
	pet.scale = Vector2(s, s)
	modulate = Color(1, 1, 1, clamp(o, 0.2, 1.0))


func _position_panel() -> void:
	if _debug_mode:
		panel.position = DEBUG_PANEL_POSITION
		return
	var window := get_window()
	var screen := Platform.get_screen_size()
	var expanded_size := Vector2i(310, 220)
	var right_overflow := window.position.x + int(PET_MODE_PANEL_POSITION.x) + expanded_size.x > screen.x
	var bottom_overflow := window.position.y + int(PET_MODE_PANEL_POSITION.y) + expanded_size.y > screen.y
	if bottom_overflow:
		panel.position = PET_MODE_PANEL_TOP_POSITION
	elif right_overflow:
		panel.position = PET_MODE_PANEL_LEFT_POSITION
	else:
		panel.position = PET_MODE_PANEL_POSITION


func _apply_mouse_passthrough() -> void:
	if _debug_mode:
		return
	if not bool(Config.get_value("mouse_passthrough_enabled", false)):
		return
	var s := float(Config.get_value("scale", 1.0))
	var rects: Array[Rect2] = [
		Rect2(PET_MODE_PET_POSITION, PET_HIT_SIZE * s),
		Rect2(PET_MODE_PANEL_POSITION, PANEL_HIT_SIZE)
	]
	Platform.set_mouse_passthrough(get_window(), true, rects)


func _on_config_changed() -> void:
	var next_debug_mode := bool(Config.get_value("debug_mode", false))
	if next_debug_mode != _debug_mode:
		_debug_mode = next_debug_mode
		_setup_window()
		_restore_position()
		_setup_tray()
		_schedule_runtime_mode_reapply()
	SalaryEngine.reload()
	_apply_scale_opacity()
	_position_panel()
	_apply_mouse_passthrough()
	if panel != null:
		panel.refresh_values()
		panel._apply_panel_config()
	Platform.update_tray_menu(get_window().visible)


func _schedule_runtime_mode_reapply() -> void:
	if _runtime_mode_reapply_pending:
		return
	_runtime_mode_reapply_pending = true
	call_deferred("_reapply_runtime_mode_after_popups")


func _reapply_runtime_mode_after_popups() -> void:
	await get_tree().process_frame
	_runtime_mode_reapply_pending = false
	_setup_window()
	_restore_position()
	_apply_scale_opacity()
	_position_panel()
	_apply_mouse_passthrough()


func _process(_delta: float) -> void:
	_position_panel()


func _input(event: InputEvent) -> void:
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
		get_viewport().set_input_as_handled()


func _set_debug_status(text: String) -> void:
	if debug_status != null:
		debug_status.text = text
		debug_status.add_theme_font_size_override("font_size", 18)


func _show_wizard() -> void:
	await get_tree().process_frame
	var wizard_scene := load("res://src/scenes/wizard/wizard_dialog.tscn")
	if wizard_scene == null:
		push_error("Wizard scene not found")
		return
	var dlg: ConfirmationDialog = wizard_scene.instantiate()
	get_window().add_child(dlg)
	if dlg.has_signal("finished"):
		dlg.finished.connect(_on_wizard_done)
	dlg.popup_centered()
	dlg.grab_focus()


func _on_wizard_done() -> void:
	SalaryEngine.reload()
	_apply_scale_opacity()
	_position_panel()
	_apply_mouse_passthrough()
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
	get_tree().create_timer(0.8).timeout.connect(PetManager.return_to_auto_state)


func _on_tray_toggle_requested() -> void:
	DragResizeSystem.toggle_window_visible()
	Platform.update_tray_menu(get_window().visible)


func _open_settings() -> void:
	DragResizeSystem.open_settings()


func _on_window_close_requested() -> void:
	if bool(Config.get_value("minimize_to_tray", true)) and _tray_ready:
		DragResizeSystem.set_window_visible(false)
		Platform.update_tray_menu(false)
	else:
		_exit_app()


func _exit_app() -> void:
	DragResizeSystem.quit_app()
