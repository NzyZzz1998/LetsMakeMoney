# src/scenes/pet/pet.gd
extends Node2D

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var click_area: Area2D = $ClickArea

var _hover_entered: bool = false
var _mouse_pressed: bool = false
var _press_timer: float = 0.0
var _click_count: int = 0
var _click_timer: float = 0.0
var _long_press_triggered: bool = false
var _dragging: bool = false
var _drag_start_window_pos: Vector2i = Vector2i.ZERO
var _drag_start_screen_mouse: Vector2i = Vector2i.ZERO
var _return_token: int = 0
var _visual_tween: Tween = null
var _base_anim_scale: Vector2 = Vector2.ONE

const DRAG_THRESHOLD := 5.0
const LONG_PRESS_THRESHOLD := 0.35
const DOUBLE_CLICK_WINDOW := 0.3
const HIT_RECT := Rect2(Vector2(62, 80), Vector2(98, 86))


func _ready() -> void:
	_base_anim_scale = anim.scale
	_setup_from_resource()
	PetManager.pet_changed.connect(_on_pet_changed)
	PetManager.state_changed.connect(_on_state_changed)
	click_area.input_pickable = true
	click_area.mouse_entered.connect(_on_mouse_entered)
	click_area.mouse_exited.connect(_on_mouse_exited)


func _setup_from_resource() -> void:
	var pet_res := PetManager.get_current_pet()
	if pet_res == null or pet_res.sprite_frames == null:
		return
	anim.sprite_frames = pet_res.sprite_frames
	_apply_animation_speeds(pet_res)
	_play_current_state()


func _apply_animation_speeds(pet_res: PetResource) -> void:
	if pet_res.sprite_frames == null:
		return
	for anim_name in pet_res.animation_speeds:
		if pet_res.sprite_frames.has_animation(anim_name):
			var fps: float = float(pet_res.animation_speeds[anim_name])
			if fps > 0:
				pet_res.sprite_frames.set_animation_speed(anim_name, fps)


func _on_pet_changed(_pet_id: String) -> void:
	_setup_from_resource()


func _on_state_changed(_new_state: PetManager.PetState) -> void:
	_play_anim(PetManager.get_current_animation_name())
	_apply_interaction_visual()


func _play_current_state() -> void:
	_play_anim(PetManager.get_current_animation_name())


func _on_mouse_entered() -> void:
	_hover_entered = true
	PetManager.request_interaction(PetManager.PetInteraction.HOVER)


func _on_mouse_exited() -> void:
	_hover_entered = false
	if not _mouse_pressed and not _dragging:
		PetManager.return_to_auto_state()


func _play_anim(anim_name: String) -> void:
	if anim.sprite_frames == null:
		return
	if anim.sprite_frames.has_animation(anim_name):
		anim.play(anim_name)


func _apply_interaction_visual() -> void:
	if anim == null:
		return
	if _visual_tween != null:
		_visual_tween.kill()
		_visual_tween = null
	anim.modulate = Color.WHITE
	var interaction := PetManager.current_interaction
	match interaction:
		PetManager.PetInteraction.HOVER:
			_visual_tween = create_tween()
			_visual_tween.set_trans(Tween.TRANS_BACK)
			_visual_tween.set_ease(Tween.EASE_OUT)
			_visual_tween.parallel().tween_property(anim, "scale", _base_anim_scale * 1.12, 0.10)
			_visual_tween.parallel().tween_property(anim, "modulate", Color(1.0, 0.92, 0.78, 1.0), 0.10)
		PetManager.PetInteraction.CLICKED_SINGLE:
			_pulse_visual(Vector2(1.12, 0.92), Color(1.0, 0.92, 0.82, 1.0))
		PetManager.PetInteraction.CLICKED_DOUBLE:
			_pulse_visual(Vector2(1.18, 0.86), Color(1.0, 0.86, 0.72, 1.0))
		PetManager.PetInteraction.CLICKED_HOLD:
			_visual_tween = create_tween()
			_visual_tween.parallel().tween_property(anim, "scale", _base_anim_scale * 0.86, 0.08)
			_visual_tween.parallel().tween_property(anim, "modulate", Color(0.86, 0.70, 0.52, 1.0), 0.08)
		_:
			_visual_tween = create_tween()
			_visual_tween.parallel().tween_property(anim, "scale", _base_anim_scale, 0.12)
			_visual_tween.parallel().tween_property(anim, "modulate", Color.WHITE, 0.12)


func _pulse_visual(target_scale: Vector2, target_color: Color) -> void:
	_visual_tween = create_tween()
	_visual_tween.set_trans(Tween.TRANS_BACK)
	_visual_tween.set_ease(Tween.EASE_OUT)
	_visual_tween.parallel().tween_property(anim, "scale", _base_anim_scale * target_scale, 0.08)
	_visual_tween.parallel().tween_property(anim, "modulate", target_color, 0.08)
	_visual_tween.tween_property(anim, "scale", _base_anim_scale, 0.14)
	_visual_tween.parallel().tween_property(anim, "modulate", Color.WHITE, 0.14)


func _input(event: InputEvent) -> void:
	var pointer_over_pet := _is_pointer_over_pet()
	if pointer_over_pet and not _hover_entered:
		_on_mouse_entered()
	elif not pointer_over_pet and _hover_entered and not _mouse_pressed and not _dragging:
		_on_mouse_exited()

	if not pointer_over_pet and not _dragging:
		return

	if event is InputEventMouseButton:
		_handle_mouse_button(event)
	elif event is InputEventMouseMotion:
		_handle_mouse_motion(event)


func _is_pointer_over_pet() -> bool:
	if click_area != null:
		for body in click_area.get_children():
			if body is CollisionShape2D and body.shape is RectangleShape2D:
				var shape_size: Vector2 = body.shape.size
				var shape_rect := Rect2(body.position - shape_size * 0.5, shape_size)
				if shape_rect.has_point(to_local(get_global_mouse_position())):
					return true
	return HIT_RECT.has_point(to_local(get_global_mouse_position()))


func _handle_mouse_button(event: InputEventMouseButton) -> void:
	if event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_cancel_pending_return()
			_mouse_pressed = true
			_press_timer = 0.0
			_long_press_triggered = false
			_drag_start_screen_mouse = DisplayServer.mouse_get_position()
			_drag_start_window_pos = get_window().position
		else:
			if _dragging:
				_end_drag()
			elif _long_press_triggered:
				_schedule_return_after_hold()
			else:
				_click_count += 1
				_click_timer = 0.0
			_mouse_pressed = false
			_press_timer = 0.0
	elif event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		DragResizeSystem.show_context_menu()


func _handle_mouse_motion(event: InputEventMouseMotion) -> void:
	var left_button_down := (event.button_mask & MOUSE_BUTTON_MASK_LEFT) != 0
	if left_button_down and not _mouse_pressed:
		_cancel_pending_return()
		_mouse_pressed = true
		_drag_start_screen_mouse = DisplayServer.mouse_get_position()
		_drag_start_window_pos = get_window().position

	if (_mouse_pressed or left_button_down) and not _dragging:
		var drag_delta := DisplayServer.mouse_get_position() - _drag_start_screen_mouse
		if drag_delta.length() > DRAG_THRESHOLD:
			_start_drag()

	if _dragging:
		if _long_press_triggered and PetManager.current_interaction != PetManager.PetInteraction.CLICKED_HOLD:
			PetManager.request_interaction(PetManager.PetInteraction.CLICKED_HOLD)
		var delta := DisplayServer.mouse_get_position() - _drag_start_screen_mouse
		DragResizeSystem.move_window_to(_drag_start_window_pos + delta)
		get_viewport().set_input_as_handled()


func _start_drag() -> void:
	_cancel_pending_return()
	_dragging = true
	_click_count = 0
	_click_timer = 0.0
	if _long_press_triggered:
		PetManager.request_interaction(PetManager.PetInteraction.CLICKED_HOLD)
	else:
		PetManager.request_interaction(PetManager.PetInteraction.HOVER)


func _end_drag() -> void:
	_dragging = false
	DragResizeSystem.save_position()
	if _long_press_triggered:
		_schedule_return_after_hold()


func _process(delta: float) -> void:
	if _mouse_pressed and not _dragging:
		_press_timer += delta
		if _press_timer >= LONG_PRESS_THRESHOLD and not _long_press_triggered:
			_long_press_triggered = true
			_cancel_pending_return()
			PetManager.request_interaction(PetManager.PetInteraction.CLICKED_HOLD)

	if _click_count > 0 and not _mouse_pressed:
		_click_timer += delta
		if _click_timer > DOUBLE_CLICK_WINDOW:
			if _click_count >= 2:
				PetManager.request_interaction(PetManager.PetInteraction.CLICKED_DOUBLE)
			else:
				PetManager.request_interaction(PetManager.PetInteraction.CLICKED_SINGLE)
			_click_count = 0
			_click_timer = 0.0
			_schedule_return_after_click()


func _schedule_return_after_click() -> void:
	_return_token += 1
	var token := _return_token
	var timer := get_tree().create_timer(0.8)
	timer.timeout.connect(_on_click_return.bind(token, true))


func _schedule_return_after_hold() -> void:
	_return_token += 1
	var token := _return_token
	var timer := get_tree().create_timer(0.45)
	timer.timeout.connect(_on_click_return.bind(token, false))


func _cancel_pending_return() -> void:
	_return_token += 1


func _on_click_return(token: int, prefer_hover: bool) -> void:
	if token != _return_token or _mouse_pressed or _dragging:
		return
	if prefer_hover and _hover_entered:
		PetManager.request_interaction(PetManager.PetInteraction.HOVER)
	else:
		PetManager.return_to_auto_state()
