# src/scenes/main/main.gd
extends Node2D

@onready var pet: Node2D = $Pet
@onready var panel = $Panel
@onready var debug_status: Label = $DebugStatus
@onready var debug_input_area: ColorRect = $DebugInputArea

const WINDOW_SIZE := Vector2i(900, 500)
const PET_POSITION := Vector2(72, 168)
const PANEL_POSITION := Vector2(340, 140)
const DEBUG_PET_HIT_RECT := Rect2(PET_POSITION, Vector2(160, 160))
const DRAG_THRESHOLD := 4.0
const DOUBLE_CLICK_WINDOW := 0.3

var _debug_mouse_pressed: bool = false
var _debug_dragging: bool = false
var _debug_drag_start_mouse: Vector2 = Vector2.ZERO
var _debug_drag_start_screen_mouse: Vector2i = Vector2i.ZERO
var _debug_drag_start_window_pos: Vector2i = Vector2i.ZERO
var _debug_click_count: int = 0
var _debug_click_timer_active: bool = false


func _ready() -> void:
	_setup_window()
	_restore_position()
	_apply_scale_opacity()
	DragResizeSystem.register_window(get_window())
	_position_panel()

	Config.config_changed.connect(_on_config_changed)
	SalaryEngine.reload()
	debug_input_area.gui_input.connect(_on_debug_input_area_gui_input)
	_set_debug_status("Debug: ready. Left/right click the pet area.")
	if not Config.has_config():
		call_deferred("_show_wizard")


func _setup_window() -> void:
	var window := get_window()
	Platform.setup_window(window)
	window.size = WINDOW_SIZE
	var mode := String(Config.get_value("window_mode", "top"))
	if mode == "embed":
		Platform.set_window_embed_desktop(window, true)
	else:
		Platform.set_window_topmost(window, true)


func _restore_position() -> void:
	var window := get_window()
	var x := int(Config.get_value("window_x", -1))
	var y := int(Config.get_value("window_y", -1))
	var screen := Platform.get_screen_size()
	if x < 0 or y < 0 or x > screen.x - 50 or y > screen.y - 50:
		x = max(0, screen.x - WINDOW_SIZE.x - 20)
		y = max(0, screen.y - WINDOW_SIZE.y - 20)
	window.position = Vector2i(x, y)


func _apply_scale_opacity() -> void:
	var s := float(Config.get_value("scale", 1.0))
	var o := float(Config.get_value("opacity", 1.0))
	pet.position = PET_POSITION
	pet.scale = Vector2(s, s)
	modulate = Color(1, 1, 1, clamp(o, 0.2, 1.0))


func _position_panel() -> void:
	panel.position = PANEL_POSITION


func _on_config_changed() -> void:
	SalaryEngine.reload()
	_apply_scale_opacity()
	_position_panel()
	if panel != null:
		panel.refresh_values()
		panel._apply_panel_config()


func _process(_delta: float) -> void:
	_position_panel()


func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		_handle_debug_key(event)


func _on_debug_input_area_gui_input(event: InputEvent) -> void:
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
			print("[Main] left pressed in debug input area: %s" % event.position)
			_set_debug_status("Debug: left pressed at %s" % event.position)
			PetManager.request_state(PetManager.PetState.HOVER)
			get_viewport().set_input_as_handled()
		elif not event.pressed and _debug_mouse_pressed:
			if _debug_dragging:
				DragResizeSystem.save_position()
				print("[Main] drag saved")
				_set_debug_status("Debug: drag saved at window %s" % get_window().position)
			else:
				_register_debug_click()
			_debug_mouse_pressed = false
			_debug_dragging = false
			get_viewport().set_input_as_handled()
	elif event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		print("[Main] right pressed in debug input area: %s" % event.position)
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
		print("[Main] drag started")
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
		print("[Main] debug key moved window by %s" % delta)
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
	if panel != null:
		panel.refresh_values()


func _register_debug_click() -> void:
	_debug_click_count += 1
	if _debug_click_count >= 2:
		_trigger_debug_click(PetManager.PetState.CLICKED_DOUBLE, "double click")
		return

	if not _debug_click_timer_active:
		_debug_click_timer_active = true
		get_tree().create_timer(DOUBLE_CLICK_WINDOW).timeout.connect(_resolve_debug_click)


func _resolve_debug_click() -> void:
	_debug_click_timer_active = false
	if _debug_click_count == 1:
		_trigger_debug_click(PetManager.PetState.CLICKED_SINGLE, "single click")
	else:
		_trigger_debug_click(PetManager.PetState.CLICKED_DOUBLE, "double click")


func _trigger_debug_click(state: PetManager.PetState, label: String) -> void:
	_debug_click_count = 0
	_debug_click_timer_active = false
	PetManager.request_state(state)
	print("[Main] %s" % label)
	_set_debug_status("Debug: %s" % label)
	get_tree().create_timer(0.8).timeout.connect(PetManager.return_to_auto_state)
