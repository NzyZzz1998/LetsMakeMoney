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
var _drag_started_from_hold: bool = false
var _drag_start_window_pos: Vector2i = Vector2i.ZERO
var _drag_start_screen_mouse: Vector2i = Vector2i.ZERO
var _drag_start_viewport_mouse: Vector2 = Vector2.ZERO
var _return_token: int = 0
var _visual_tween: Tween = null
var _base_anim_scale: Vector2 = Vector2.ONE
var _texture_visible_rect_cache: Dictionary = {}

const DRAG_THRESHOLD := 5.0
const LONG_PRESS_THRESHOLD := 0.5
const DOUBLE_CLICK_WINDOW := 0.3
const CLICK_RETURN_DELAY := 1.55
const FALLBACK_TEXTURE_SIZE := Vector2(256, 256)
const HIT_PADDING := Vector2(12, 10)
const CLICK_SNAPSHOT_DELAYS: Array[float] = [0.05, 0.45, 0.90]


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
	_sync_hit_geometry()


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
	if _can_enter_hover():
		PetManager.request_interaction(PetManager.PetInteraction.HOVER)


func _on_mouse_exited() -> void:
	_hover_entered = false
	if not _mouse_pressed and not _dragging and _can_enter_hover():
		PetManager.return_to_auto_state()


func _can_enter_hover() -> bool:
	return not PetManager.current_interaction in [
		PetManager.PetInteraction.CLICKED_SINGLE,
		PetManager.PetInteraction.CLICKED_DOUBLE,
		PetManager.PetInteraction.CLICKED_HOLD
	]


func _play_anim(anim_name: String) -> void:
	if anim.sprite_frames == null:
		return
	if anim.sprite_frames.has_animation(anim_name):
		anim.play(anim_name)
		if not anim.sprite_frames.get_animation_loop(anim_name):
			anim.frame = 0
			anim.frame_progress = 0.0
		if PetManager.current_interaction in [PetManager.PetInteraction.CLICKED_SINGLE, PetManager.PetInteraction.CLICKED_DOUBLE]:
			Platform.write_boot_log("Pet: animation_play interaction=%s resolved=%s frames=%d speed=%.2f loop=%s" % [
				_interaction_debug_name(PetManager.current_interaction),
				anim_name,
				anim.sprite_frames.get_frame_count(anim_name),
				anim.sprite_frames.get_animation_speed(anim_name),
				str(anim.sprite_frames.get_animation_loop(anim_name))
			])
		_sync_hit_geometry()


func get_interaction_rect() -> Rect2:
	return _get_current_hit_rect()


func _sync_hit_geometry() -> void:
	var hit_rect := _get_current_hit_rect()
	for body in click_area.get_children():
		if body is CollisionShape2D and body.shape is RectangleShape2D:
			var shape := (body.shape as RectangleShape2D).duplicate()
			shape.size = hit_rect.size
			body.shape = shape
			body.position = hit_rect.position + hit_rect.size * 0.5


func _get_current_hit_rect() -> Rect2:
	var texture_size := _get_current_texture_size()
	var visible_rect := _get_current_texture_visible_rect()
	var scale_vec := Vector2(absf(anim.scale.x), absf(anim.scale.y))
	var visible_position := (visible_rect.position - texture_size * 0.5) * scale_vec
	var visible_size := visible_rect.size * scale_vec
	return Rect2(anim.position + visible_position, visible_size).grow_individual(
		HIT_PADDING.x,
		HIT_PADDING.y,
		HIT_PADDING.x,
		HIT_PADDING.y
	)


func _get_current_texture_size() -> Vector2:
	var texture := _get_current_frame_texture()
	if texture == null:
		return FALLBACK_TEXTURE_SIZE
	return texture.get_size()


func _get_current_texture_visible_rect() -> Rect2:
	var texture := _get_current_frame_texture()
	if texture == null:
		return Rect2(Vector2.ZERO, FALLBACK_TEXTURE_SIZE)
	var texture_size := texture.get_size()
	var cache_key := texture.resource_path if not texture.resource_path.is_empty() else str(texture.get_instance_id())
	if _texture_visible_rect_cache.has(cache_key):
		return _texture_visible_rect_cache[cache_key]

	var image := texture.get_image()
	if image == null or image.is_empty():
		var full_rect := Rect2(Vector2.ZERO, texture_size)
		_texture_visible_rect_cache[cache_key] = full_rect
		return full_rect

	var min_x := image.get_width()
	var min_y := image.get_height()
	var max_x := -1
	var max_y := -1
	for y in image.get_height():
		for x in image.get_width():
			if image.get_pixel(x, y).a > 0.05:
				min_x = mini(min_x, x)
				min_y = mini(min_y, y)
				max_x = maxi(max_x, x)
				max_y = maxi(max_y, y)

	if max_x < min_x or max_y < min_y:
		var empty_fallback := Rect2(Vector2.ZERO, texture_size)
		_texture_visible_rect_cache[cache_key] = empty_fallback
		return empty_fallback

	var visible_rect := Rect2(Vector2(min_x, min_y), Vector2(max_x - min_x + 1, max_y - min_y + 1))
	_texture_visible_rect_cache[cache_key] = visible_rect
	return visible_rect


func _get_current_frame_texture() -> Texture2D:
	if anim.sprite_frames == null:
		return null
	var anim_name := anim.animation
	if anim_name.is_empty() or not anim.sprite_frames.has_animation(anim_name):
		anim_name = PetManager.get_current_animation_name()
	if anim_name.is_empty() or not anim.sprite_frames.has_animation(anim_name):
		return null
	var frame_count := anim.sprite_frames.get_frame_count(anim_name)
	if frame_count <= 0:
		return null
	var frame_index: int = clampi(anim.frame, 0, frame_count - 1)
	return anim.sprite_frames.get_frame_texture(anim_name, frame_index)


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
			_pulse_visual(Vector2(1.06, 1.06), Color(1.0, 0.90, 0.76, 1.0), 0.20, 0.34, 0.42)
		PetManager.PetInteraction.CLICKED_DOUBLE:
			_pulse_visual(Vector2(1.10, 1.10), Color(1.0, 0.78, 0.55, 1.0), 0.22, 0.48, 0.50)
		PetManager.PetInteraction.CLICKED_HOLD:
			_visual_tween = create_tween()
			_visual_tween.parallel().tween_property(anim, "scale", _base_anim_scale * 0.86, 0.08)
			_visual_tween.parallel().tween_property(anim, "modulate", Color(0.86, 0.70, 0.52, 1.0), 0.08)
		_:
			_visual_tween = create_tween()
			_visual_tween.parallel().tween_property(anim, "scale", _base_anim_scale, 0.12)
			_visual_tween.parallel().tween_property(anim, "modulate", Color.WHITE, 0.12)


func _pulse_visual(target_scale: Vector2, target_color: Color, out_time: float, hold_time: float, return_time: float) -> void:
	_visual_tween = create_tween()
	_visual_tween.set_trans(Tween.TRANS_BACK)
	_visual_tween.set_ease(Tween.EASE_OUT)
	_visual_tween.parallel().tween_property(anim, "scale", _base_anim_scale * target_scale, out_time)
	_visual_tween.parallel().tween_property(anim, "modulate", target_color, out_time)
	_visual_tween.tween_interval(hold_time)
	_visual_tween.set_ease(Tween.EASE_IN_OUT)
	_visual_tween.tween_property(anim, "scale", _base_anim_scale, return_time)
	_visual_tween.parallel().tween_property(anim, "modulate", Color.WHITE, return_time)


func _input(event: InputEvent) -> void:
	var pointer_over_pet := _is_pointer_over_pet()
	if pointer_over_pet and not _hover_entered:
		_on_mouse_entered()
	elif not pointer_over_pet and _hover_entered and not _mouse_pressed and not _dragging:
		_on_mouse_exited()

	if not pointer_over_pet and not _dragging and not _mouse_pressed:
		return

	if event is InputEventMouseButton:
		_handle_mouse_button(event)
	elif event is InputEventMouseMotion:
		_handle_mouse_motion(event)


func _is_pointer_over_pet() -> bool:
	return _get_current_hit_rect().has_point(to_local(get_global_mouse_position()))


func _handle_mouse_button(event: InputEventMouseButton) -> void:
	if event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_cancel_pending_return()
			_mouse_pressed = true
			_press_timer = 0.0
			_long_press_triggered = false
			_drag_start_viewport_mouse = event.position
			_drag_start_screen_mouse = DisplayServer.mouse_get_position()
			_drag_start_window_pos = get_window().position
			Platform.write_boot_log("Pet: input=mouse_down base=%s pointer=%s screen=%s" % [
				PetManager.base_state_to_anim_name(PetManager.current_base_state),
				str(to_local(get_global_mouse_position())),
				str(_drag_start_screen_mouse)
			])
		else:
			if _dragging:
				_end_drag()
			elif _long_press_triggered:
				_schedule_return_after_hold()
			else:
				Platform.write_boot_log("Pet: input=mouse_release classified=click pointer=%s screen=%s" % [
					str(to_local(get_global_mouse_position())),
					str(DisplayServer.mouse_get_position())
				])
				_register_click_release()
			_mouse_pressed = false
			_press_timer = 0.0
	elif event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		_reset_press_tracking()
		Platform.write_boot_log("Pet: interaction=right_click_menu base=%s pointer=%s" % [
			PetManager.base_state_to_anim_name(PetManager.current_base_state),
			str(to_local(get_global_mouse_position()))
		])
		DragResizeSystem.show_context_menu()
		get_viewport().set_input_as_handled()


func _handle_mouse_motion(event: InputEventMouseMotion) -> void:
	var left_button_down := (event.button_mask & MOUSE_BUTTON_MASK_LEFT) != 0
	if left_button_down and not _mouse_pressed:
		_cancel_pending_return()
		_mouse_pressed = true
		_drag_start_viewport_mouse = event.position
		_drag_start_screen_mouse = DisplayServer.mouse_get_position()
		_drag_start_window_pos = get_window().position

	if (_mouse_pressed or left_button_down) and not _dragging:
		var screen_delta := Vector2(DisplayServer.mouse_get_position() - _drag_start_screen_mouse)
		var viewport_delta := event.position - _drag_start_viewport_mouse
		var drag_distance: float = maxf(screen_delta.length(), viewport_delta.length())
		if drag_distance > DRAG_THRESHOLD:
			Platform.write_boot_log("Pet: input=drag_threshold distance=%.2f screen_delta=%s viewport_delta=%s" % [
				drag_distance,
				str(screen_delta),
				str(viewport_delta)
			])
			_start_drag()

	if _dragging:
		var delta := DisplayServer.mouse_get_position() - _drag_start_screen_mouse
		DragResizeSystem.move_window_to(_drag_start_window_pos + delta)
		get_viewport().set_input_as_handled()


func _start_drag() -> void:
	_cancel_pending_return()
	_drag_started_from_hold = _long_press_triggered
	_dragging = true
	_click_count = 0
	_click_timer = 0.0
	if not _drag_started_from_hold:
		_long_press_triggered = false
	Platform.write_boot_log("Pet: interaction=drag_start base=%s window=%s mouse=%s" % [
		PetManager.base_state_to_anim_name(PetManager.current_base_state),
		str(_drag_start_window_pos),
		str(DisplayServer.mouse_get_position())
	])
	if _drag_started_from_hold:
		PetManager.request_interaction(PetManager.PetInteraction.CLICKED_HOLD)
	else:
		PetManager.request_interaction(PetManager.PetInteraction.HOVER)


func _end_drag() -> void:
	var should_return_after_hold := _drag_started_from_hold or _long_press_triggered
	_dragging = false
	DragResizeSystem.save_position()
	_long_press_triggered = false
	_drag_started_from_hold = false
	Platform.write_boot_log("Pet: interaction=drag_end window=%s mouse=%s" % [
		str(get_window().position),
		str(DisplayServer.mouse_get_position())
	])
	if should_return_after_hold:
		_schedule_return_after_hold()
	elif _hover_entered:
		PetManager.request_interaction(PetManager.PetInteraction.HOVER)
	else:
		PetManager.return_to_auto_state()


func _process(delta: float) -> void:
	if _mouse_pressed and not _dragging:
		_press_timer += delta
		if _press_timer >= LONG_PRESS_THRESHOLD and not _long_press_triggered:
			_long_press_triggered = true
			_cancel_pending_return()
			Platform.write_boot_log("Pet: interaction=clicked_hold base=%s pointer=%s" % [
				PetManager.base_state_to_anim_name(PetManager.current_base_state),
				str(to_local(get_global_mouse_position()))
			])
			PetManager.request_interaction(PetManager.PetInteraction.CLICKED_HOLD)

	if _click_count > 0 and not _mouse_pressed:
		_click_timer += delta
		if _click_timer > DOUBLE_CLICK_WINDOW:
			_fire_click_interaction(PetManager.PetInteraction.CLICKED_SINGLE)


func _register_click_release() -> void:
	_click_count += 1
	_click_timer = 0.0
	if _click_count >= 2:
		_fire_click_interaction(PetManager.PetInteraction.CLICKED_DOUBLE)


func _fire_click_interaction(interaction: PetManager.PetInteraction) -> void:
	_click_count = 0
	_click_timer = 0.0
	Platform.write_boot_log("Pet: interaction=%s base=%s pointer=%s" % [
		_interaction_debug_name(interaction),
		PetManager.base_state_to_anim_name(PetManager.current_base_state),
		str(to_local(get_global_mouse_position()))
	])
	PetManager.request_interaction(interaction)
	_schedule_return_after_click()
	_queue_interaction_snapshots(interaction)


func _schedule_return_after_click() -> void:
	_return_token += 1
	var token := _return_token
	var timer := get_tree().create_timer(CLICK_RETURN_DELAY)
	timer.timeout.connect(_on_click_return.bind(token, true))


func _queue_interaction_snapshots(interaction: PetManager.PetInteraction) -> void:
	if not interaction in [PetManager.PetInteraction.CLICKED_SINGLE, PetManager.PetInteraction.CLICKED_DOUBLE]:
		return
	call_deferred("_capture_interaction_snapshots", _interaction_debug_name(interaction), _return_token)


func _capture_interaction_snapshots(interaction_name: String, token: int) -> void:
	for index in CLICK_SNAPSHOT_DELAYS.size():
		var delay: float = CLICK_SNAPSHOT_DELAYS[index]
		await get_tree().create_timer(delay).timeout
		_save_interaction_snapshot(interaction_name, token, index, delay)


func _save_interaction_snapshot(interaction_name: String, token: int, index: int, delay: float) -> void:
	if anim == null or anim.sprite_frames == null:
		return
	var image := get_viewport().get_texture().get_image()
	if image == null or image.is_empty():
		return
	var crop_rect := _current_pet_viewport_rect().grow(10.0)
	var bounds := Rect2(Vector2.ZERO, Vector2(image.get_width(), image.get_height()))
	crop_rect = crop_rect.intersection(bounds)
	if crop_rect.size.x <= 0 or crop_rect.size.y <= 0:
		return
	var region := image.get_region(Rect2i(
		int(floor(crop_rect.position.x)),
		int(floor(crop_rect.position.y)),
		int(ceil(crop_rect.size.x)),
		int(ceil(crop_rect.size.y))
	))
	var dir_path := _interaction_snapshot_dir()
	if dir_path.is_empty():
		return
	var file_name := "%s_%s_%02d_%dms_%s_f%d.png" % [
		_screenshot_timestamp(),
		interaction_name,
		index + 1,
		int(round(delay * 1000.0)),
		anim.animation,
		anim.frame
	]
	var path := dir_path.path_join(file_name)
	var result := region.save_png(path)
	Platform.write_boot_log("Pet: snapshot interaction=%s token=%d delay_ms=%d anim=%s frame=%d progress=%.3f path=%s ok=%s" % [
		interaction_name,
		token,
		int(round(delay * 1000.0)),
		anim.animation,
		anim.frame,
		anim.frame_progress,
		path,
		str(result == OK)
	])


func _current_pet_viewport_rect() -> Rect2:
	var local_rect := _get_current_hit_rect()
	var transform := get_global_transform()
	var points := [
		transform * local_rect.position,
		transform * (local_rect.position + Vector2(local_rect.size.x, 0.0)),
		transform * (local_rect.position + Vector2(0.0, local_rect.size.y)),
		transform * (local_rect.position + local_rect.size)
	]
	var rect := Rect2(points[0], Vector2.ZERO)
	for point in points:
		rect = rect.expand(point)
	return rect


func _interaction_snapshot_dir() -> String:
	var appdata := OS.get_environment("APPDATA")
	if appdata.is_empty():
		appdata = OS.get_user_data_dir()
	var dir_path := appdata.path_join("LetsMakeMoney").path_join("interaction-screenshots")
	if not DirAccess.dir_exists_absolute(dir_path):
		var result := DirAccess.make_dir_recursive_absolute(dir_path)
		if result != OK:
			Platform.write_boot_log("Pet: snapshot mkdir failed path=%s error=%s" % [dir_path, error_string(result)])
			return ""
	return dir_path


func _screenshot_timestamp() -> String:
	var text := Time.get_datetime_string_from_system()
	return text.replace(":", "").replace("-", "").replace("T", "_")


func _schedule_return_after_hold() -> void:
	_return_token += 1
	var token := _return_token
	var timer := get_tree().create_timer(0.45)
	timer.timeout.connect(_on_click_return.bind(token, false))


func _cancel_pending_return() -> void:
	_return_token += 1


func _reset_press_tracking() -> void:
	_cancel_pending_return()
	_mouse_pressed = false
	_press_timer = 0.0
	_click_count = 0
	_click_timer = 0.0
	_long_press_triggered = false
	_drag_started_from_hold = false
	if _dragging:
		_dragging = false


func _interaction_debug_name(interaction: PetManager.PetInteraction) -> String:
	match interaction:
		PetManager.PetInteraction.HOVER:
			return "hover"
		PetManager.PetInteraction.CLICKED_SINGLE:
			return "clicked_single"
		PetManager.PetInteraction.CLICKED_DOUBLE:
			return "clicked_double"
		PetManager.PetInteraction.CLICKED_HOLD:
			return "clicked_hold"
	return "none"


func _on_click_return(token: int, _prefer_hover: bool) -> void:
	if token != _return_token or _mouse_pressed or _dragging:
		return
	PetManager.return_to_interaction_base_state()
