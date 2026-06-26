# src/scenes/pet/pet.gd
extends Node2D

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var click_area: Area2D = $ClickArea

# 交互状态
var _hover_entered: bool = false
var _mouse_pressed: bool = false
var _press_timer: float = 0.0
var _click_count: int = 0
var _click_timer: float = 0.0
var _long_press_triggered: bool = false

# 拖拽
var _dragging: bool = false
var _drag_start_pos: Vector2i = Vector2i.ZERO
var _drag_start_mouse: Vector2i = Vector2i.ZERO
const DRAG_THRESHOLD := 5.0  # 像素，超过则判定为拖拽
const LONG_PRESS_THRESHOLD := 0.5  # 秒
const DOUBLE_CLICK_WINDOW := 0.3  # 秒
const HIT_RECT := Rect2(Vector2.ZERO, Vector2(120, 120))


func _ready() -> void:
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


func _on_state_changed(new_state: PetManager.PetState) -> void:
	var anim_name := PetManager.state_to_anim_name(new_state)
	_play_anim(anim_name)


func _play_current_state() -> void:
	_play_anim(PetManager.state_to_anim_name(PetManager.current_state))


func _on_mouse_entered() -> void:
	_hover_entered = true
	PetManager.request_state(PetManager.PetState.HOVER)


func _on_mouse_exited() -> void:
	_hover_entered = false
	# 如果正在拖拽或按下，不立即回退——等松开
	if not _mouse_pressed and not _dragging:
		PetManager.return_to_auto_state()


func _play_anim(anim_name: String) -> void:
	if anim.sprite_frames == null:
		return
	if anim.sprite_frames.has_animation(anim_name):
		anim.play(anim_name)


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
	return HIT_RECT.has_point(to_local(get_global_mouse_position()))


func _handle_mouse_button(event: InputEventMouseButton) -> void:
	if event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_mouse_pressed = true
			_press_timer = 0.0
			_long_press_triggered = false
			_drag_start_mouse = DisplayServer.mouse_get_position()
			_drag_start_pos = get_window().position
		else:
			if _dragging:
				_end_drag()
			elif _long_press_triggered:
				# 长按刚结束，松开恢复
				PetManager.return_to_auto_state()
			else:
				# 短按——计入点击计数
				_click_count += 1
				_click_timer = 0.0
			_mouse_pressed = false
			_press_timer = 0.0
	elif event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		DragResizeSystem.show_context_menu()


func _handle_mouse_motion(event: InputEventMouseMotion) -> void:
	var left_button_down := (event.button_mask & MOUSE_BUTTON_MASK_LEFT) != 0
	if left_button_down and not _mouse_pressed:
		_mouse_pressed = true
		_drag_start_mouse = DisplayServer.mouse_get_position()
		_drag_start_pos = get_window().position

	if (_mouse_pressed or left_button_down) and not _dragging:
		if (DisplayServer.mouse_get_position() - _drag_start_mouse).length() > DRAG_THRESHOLD or event.relative.length() > DRAG_THRESHOLD:
			_start_drag()
	if _dragging:
		var delta := Vector2i(roundi(event.relative.x), roundi(event.relative.y))
		if delta != Vector2i.ZERO:
			DragResizeSystem.move_window_to(get_window().position + delta)


func _start_drag() -> void:
	_dragging = true
	print("[Pet] drag started")


func _end_drag() -> void:
	_dragging = false
	DragResizeSystem.save_position()


func _process(delta: float) -> void:
	if _mouse_pressed and not _dragging:
		_press_timer += delta
		if _press_timer >= LONG_PRESS_THRESHOLD and not _long_press_triggered:
			_long_press_triggered = true
			PetManager.request_state(PetManager.PetState.CLICKED_HOLD)

	if _click_count > 0 and not _mouse_pressed:
		_click_timer += delta
		if _click_timer > DOUBLE_CLICK_WINDOW:
			if _click_count >= 2:
				PetManager.request_state(PetManager.PetState.CLICKED_DOUBLE)
			else:
				PetManager.request_state(PetManager.PetState.CLICKED_SINGLE)
			_click_count = 0
			_click_timer = 0.0
			# 单击/双击动画播完后回到自动状态——由定时器触发
			_schedule_return_after_click()


func _schedule_return_after_click() -> void:
	# 单击/双击是单次动画，0.8s 后回退
	var timer := get_tree().create_timer(0.8)
	timer.timeout.connect(_on_click_return)


func _on_click_return() -> void:
	if _hover_entered:
		PetManager.request_state(PetManager.PetState.HOVER)
	else:
		PetManager.return_to_auto_state()
