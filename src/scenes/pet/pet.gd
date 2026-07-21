extends Node2D

signal hit_region_changed(reason: String)

const AnimationControllerScript := preload("res://src/utils/pet_animation_controller.gd")
const InputArbiterScript := preload("res://src/utils/pet_input_arbiter.gd")
const ActionProfileScript := preload("res://src/utils/pet_action_profile.gd")
const HitRegionScript := preload("res://src/utils/pet_hit_region_service.gd")
const DirectionResolverScript := preload("res://src/utils/pet_direction_resolver.gd")
const VisualGeometryScript := preload("res://src/utils/pet_visual_geometry.gd")
const BusinessEventTrackerScript := preload("res://src/utils/pet_business_event_tracker.gd")

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var click_area: Area2D = $ClickArea

const DRAG_THRESHOLD := 5.0
const LONG_PRESS_THRESHOLD_MS := 500
const FALLBACK_TEXTURE_SIZE := Vector2(256, 256)
const HIT_PADDING := Vector2(12, 10)
const CLICK_SNAPSHOT_DELAYS: Array[float] = [0.05, 0.45, 0.90]
const ENVIRONMENT_ACTION_INTERVAL_MS := 60000
const BUSINESS_EVENT_POLL_INTERVAL_MS := 1000

var _hover_entered := false
var _dragging := false
var _drag_start_window_pos := Vector2i.ZERO
var _drag_start_screen_mouse := Vector2i.ZERO
var _run_direction := "right"
var _run_original_flip_h := false
var _visual_tween: Tween = null
var _base_anim_scale := Vector2.ONE
var _scene_anim_scale := Vector2.ONE
var _scene_anim_position := Vector2.ZERO
var _texture_visible_rect_cache: Dictionary = {}
var _animation_union_rect_cache: Dictionary = {}
var _last_native_hit_rect := Rect2()
var _pointer_left_at_ms := -1
var _next_environment_action_ms := 0
var _next_business_event_poll_ms := 0
var _animation_controller = AnimationControllerScript.new()
var _input_arbiter = InputArbiterScript.new(DRAG_THRESHOLD, LONG_PRESS_THRESHOLD_MS)
var _direction_resolver = DirectionResolverScript.new()
var _business_event_tracker = BusinessEventTrackerScript.new()


func _ready() -> void:
	_scene_anim_scale = anim.scale
	_scene_anim_position = anim.position
	_base_anim_scale = _scene_anim_scale
	_connect_runtime_signals()
	_setup_from_resource()
	click_area.input_pickable = true
	click_area.mouse_entered.connect(_on_mouse_entered)
	click_area.mouse_exited.connect(_on_mouse_exited)
	_next_environment_action_ms = Time.get_ticks_msec() + ENVIRONMENT_ACTION_INTERVAL_MS
	_next_business_event_poll_ms = Time.get_ticks_msec()


func _connect_runtime_signals() -> void:
	PetManager.pet_changed.connect(_on_pet_changed)
	PetManager.state_changed.connect(_on_state_changed)
	if PetManager.has_signal("base_animation_changed"):
		PetManager.base_animation_changed.connect(_on_base_animation_changed)
	_animation_controller.action_requested.connect(_on_action_requested)
	_animation_controller.action_started.connect(_on_action_started)
	_animation_controller.action_interrupted.connect(_on_action_interrupted)
	_animation_controller.action_finished.connect(_on_action_finished)
	_animation_controller.action_timeout.connect(_on_action_timeout)
	_animation_controller.base_animation_resolved.connect(_on_base_animation_resolved)
	anim.animation_finished.connect(_on_sprite_animation_finished)
	anim.frame_changed.connect(_on_sprite_frame_changed)


func _setup_from_resource() -> void:
	var pet_res := PetManager.get_current_pet()
	if pet_res == null or pet_res.sprite_frames == null:
		return
	_apply_runtime_geometry(pet_res)
	anim.sprite_frames = pet_res.sprite_frames
	_apply_animation_speeds(pet_res)
	_texture_visible_rect_cache.clear()
	_animation_union_rect_cache.clear()
	_animation_controller.interrupt("pet_changed", Time.get_ticks_msec())
	_animation_controller.set_base_animation(PetManager.get_current_base_animation_name())
	_play_base_animation("resource_ready")
	_sync_hit_geometry("resource_ready")


func _apply_runtime_geometry(pet_res: PetResource) -> void:
	anim.position = _scene_anim_position
	anim.scale = _scene_anim_scale
	if pet_res.runtime_profile != null:
		var transform: Dictionary = VisualGeometryScript.normalized_transform(
			pet_res.runtime_profile.logical_size,
			pet_res.runtime_profile.pivot,
			_scene_anim_position,
			_scene_anim_scale,
			FALLBACK_TEXTURE_SIZE
		)
		anim.position = transform.position
		anim.scale = transform.scale
	_base_anim_scale = anim.scale


func _apply_animation_speeds(pet_res: PetResource) -> void:
	if pet_res.sprite_frames == null:
		return
	for anim_name in pet_res.animation_speeds:
		if pet_res.sprite_frames.has_animation(anim_name):
			var fps := float(pet_res.animation_speeds[anim_name])
			if fps > 0:
				pet_res.sprite_frames.set_animation_speed(anim_name, fps)


func _on_pet_changed(_pet_id: String) -> void:
	_setup_from_resource()


func _on_base_animation_changed(animation_name: String) -> void:
	_animation_controller.set_base_animation(animation_name)
	if not _animation_controller.is_action_active() and not _is_pointer_look_active():
		_play_base_animation("schedule_state_changed")


func _on_state_changed(_new_state: PetManager.PetState) -> void:
	var interaction := PetManager.current_interaction
	if interaction == PetManager.PetInteraction.NONE:
		_animation_controller.set_base_animation(PetManager.get_current_base_animation_name())
		if not _animation_controller.is_action_active():
			_play_base_animation("pet_state_changed")
	elif interaction == PetManager.PetInteraction.HOVER:
		_play_anim(PetManager.get_current_animation_name(), "hover")
	else:
		_request_interaction_action(interaction)
	_apply_interaction_visual()


func _play_base_animation(reason: String) -> void:
	var candidates: Array[String] = ActionProfileScript.base_candidates(_animation_controller.base_animation)
	var resolved := ActionProfileScript.first_available(candidates, anim.sprite_frames)
	_play_anim(resolved, reason)


func _request_interaction_action(interaction: PetManager.PetInteraction) -> void:
	var interaction_name := _interaction_debug_name(interaction)
	var candidates: Array[String] = ActionProfileScript.interaction_candidates(_animation_controller.base_animation, interaction_name)
	var resolved := ActionProfileScript.first_available(candidates, anim.sprite_frames)
	if resolved.is_empty():
		Platform.write_error_log("pet.animation.request_rejected: reason=missing_frames interaction=%s" % interaction_name)
		PetManager.return_to_auto_state()
		return
	var duration_ms := _animation_duration_ms(resolved)
	var token: int = _animation_controller.request_action(
		resolved,
		maxi(duration_ms, 100),
		ActionProfileScript.priority_for(interaction_name),
		Time.get_ticks_msec(),
		ActionProfileScript.cooldown_for(interaction_name)
	)
	if token < 0:
		Platform.write_debug_log("pet.animation.request_rejected: reason=priority_or_cooldown interaction=%s resolved=%s" % [interaction_name, resolved])


func _on_action_requested(token: int, animation_name: String, priority: int) -> void:
	Platform.write_info_log("pet.animation.requested: token=%d animation=%s priority=%d base=%s" % [token, animation_name, priority, _animation_controller.base_animation])
	_play_anim(animation_name, "action_requested")
	_animation_controller.mark_started(token)


func _on_action_started(token: int, animation_name: String) -> void:
	Platform.write_info_log("pet.animation.started: token=%d animation=%s" % [token, animation_name])


func _on_action_interrupted(token: int, animation_name: String, reason: String) -> void:
	Platform.write_info_log("pet.animation.interrupted: token=%d animation=%s reason=%s" % [token, animation_name, reason])


func _on_action_finished(token: int, animation_name: String, reason: String) -> void:
	Platform.write_info_log("pet.animation.finished: token=%d animation=%s reason=%s" % [token, animation_name, reason])


func _on_action_timeout(token: int, animation_name: String) -> void:
	Platform.write_error_log("pet.animation.timeout: token=%d animation=%s" % [token, animation_name])


func _on_base_animation_resolved(animation_name: String, reason: String) -> void:
	if PetManager.current_interaction != PetManager.PetInteraction.NONE:
		PetManager.return_to_auto_state()
	if not _dragging:
		anim.flip_h = _run_original_flip_h
	var resolved := ActionProfileScript.first_available(ActionProfileScript.base_candidates(animation_name), anim.sprite_frames)
	_play_anim(resolved, "base_resolved:%s" % reason)
	_apply_interaction_visual()


func _on_sprite_animation_finished() -> void:
	if _animation_controller.active_token != 0 and anim.animation == _animation_controller.active_animation:
		_animation_controller.mark_finished(_animation_controller.active_token, Time.get_ticks_msec())


func _play_anim(animation_name: String, reason: String = "unspecified") -> void:
	if anim.sprite_frames == null or animation_name.is_empty() or not anim.sprite_frames.has_animation(animation_name):
		return
	if anim.animation != animation_name or not anim.is_playing():
		anim.play(animation_name)
		if not anim.sprite_frames.get_animation_loop(animation_name):
			anim.frame = 0
			anim.frame_progress = 0.0
		Platform.write_debug_log("pet.animation.play: animation=%s reason=%s frames=%d duration_ms=%d" % [
			animation_name,
			reason,
			anim.sprite_frames.get_frame_count(animation_name),
			_animation_duration_ms(animation_name)
		])
	_sync_hit_geometry("animation:%s" % animation_name)


func _animation_duration_ms(animation_name: String) -> int:
	if anim.sprite_frames == null or not anim.sprite_frames.has_animation(animation_name):
		return 0
	var speed := anim.sprite_frames.get_animation_speed(animation_name)
	if speed <= 0:
		return 0
	var total := 0.0
	for frame_index in anim.sprite_frames.get_frame_count(animation_name):
		total += anim.sprite_frames.get_frame_duration(animation_name, frame_index) / speed * 1000.0
	return int(ceil(total))


func get_interaction_rect() -> Rect2:
	var pet_res := PetManager.get_current_pet()
	if pet_res != null and pet_res.runtime_profile != null and String(pet_res.runtime_profile.hit_strategy) == "action_union":
		return _get_animation_union_hit_rect(anim.animation)
	return _get_current_hit_rect()


func _sync_hit_geometry(reason: String) -> void:
	var hit_rect := _get_current_hit_rect()
	for body in click_area.get_children():
		if body is CollisionShape2D and body.shape is RectangleShape2D:
			var shape := (body.shape as RectangleShape2D).duplicate()
			shape.size = hit_rect.size
			body.shape = shape
			body.position = hit_rect.position + hit_rect.size * 0.5
	var native_rect := get_interaction_rect()
	if not _rect_approximately_equal(native_rect, _last_native_hit_rect):
		_last_native_hit_rect = native_rect
		Platform.write_debug_log("pet.hit_region.changed: reason=%s animation=%s frame=%d rect=%s" % [reason, anim.animation, anim.frame, str(native_rect)])
		hit_region_changed.emit(reason)


func _on_sprite_frame_changed() -> void:
	_sync_hit_geometry("frame_changed")


func _get_current_hit_rect() -> Rect2:
	return _visible_rect_to_local(_get_current_texture_visible_rect(), _get_current_texture_size())


func _get_animation_union_hit_rect(animation_name: String) -> Rect2:
	if anim.sprite_frames == null or animation_name.is_empty() or not anim.sprite_frames.has_animation(animation_name):
		return _get_current_hit_rect()
	if not _animation_union_rect_cache.has(animation_name):
		var frame_rects: Array[Rect2i] = HitRegionScript.animation_frame_rects(anim.sprite_frames, animation_name, 0.05)
		_animation_union_rect_cache[animation_name] = HitRegionScript.union_rect(frame_rects)
	var union_rect: Rect2i = _animation_union_rect_cache[animation_name]
	if union_rect.size.x <= 0 or union_rect.size.y <= 0:
		return _get_current_hit_rect()
	return _visible_rect_to_local(Rect2(union_rect), _get_current_texture_size())


func _visible_rect_to_local(visible_rect: Rect2, texture_size: Vector2) -> Rect2:
	var scale_vec := Vector2(absf(anim.scale.x), absf(anim.scale.y))
	var visible_position := (visible_rect.position - texture_size * 0.5) * scale_vec
	var visible_size := visible_rect.size * scale_vec
	return Rect2(anim.position + visible_position, visible_size).grow_individual(HIT_PADDING.x, HIT_PADDING.y, HIT_PADDING.x, HIT_PADDING.y)


func _get_current_texture_size() -> Vector2:
	var texture := _get_current_frame_texture()
	return FALLBACK_TEXTURE_SIZE if texture == null else texture.get_size()


func _get_current_texture_visible_rect() -> Rect2:
	var texture := _get_current_frame_texture()
	if texture == null:
		return Rect2(Vector2.ZERO, FALLBACK_TEXTURE_SIZE)
	var cache_key := texture.resource_path if not texture.resource_path.is_empty() else str(texture.get_instance_id())
	if not _texture_visible_rect_cache.has(cache_key):
		_texture_visible_rect_cache[cache_key] = Rect2(HitRegionScript.texture_alpha_rect(texture, 0.05))
	return _texture_visible_rect_cache[cache_key]


func _get_current_frame_texture() -> Texture2D:
	if anim.sprite_frames == null or anim.animation.is_empty() or not anim.sprite_frames.has_animation(anim.animation):
		return null
	var count := anim.sprite_frames.get_frame_count(anim.animation)
	if count <= 0:
		return null
	return anim.sprite_frames.get_frame_texture(anim.animation, clampi(anim.frame, 0, count - 1))


func _rect_approximately_equal(left: Rect2, right: Rect2) -> bool:
	return left.position.distance_to(right.position) < 0.5 and left.size.distance_to(right.size) < 0.5


func _input(event: InputEvent) -> void:
	if DragResizeSystem.is_overlay_active():
		if _input_arbiter.is_pressed() or _dragging:
			_reset_press_tracking("overlay_open")
		return
	var pointer_over_pet := _is_pointer_over_pet()
	if pointer_over_pet and not _hover_entered:
		_on_mouse_entered()
	elif not pointer_over_pet and _hover_entered and not _input_arbiter.is_pressed() and not _dragging:
		_on_mouse_exited()
	if not pointer_over_pet and not _dragging and not _input_arbiter.is_pressed():
		return
	if event is InputEventMouseButton:
		_handle_mouse_button(event)
	elif event is InputEventMouseMotion:
		_handle_mouse_motion(event)


func _is_pointer_over_pet() -> bool:
	return _get_current_hit_rect().has_point(to_local(get_global_mouse_position()))


func _handle_mouse_button(event: InputEventMouseButton) -> void:
	var now_ms := Time.get_ticks_msec()
	var screen_position := Vector2(DisplayServer.mouse_get_position())
	if event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_drag_start_screen_mouse = DisplayServer.mouse_get_position()
			_drag_start_window_pos = get_window().position
			_handle_arbiter_events(_input_arbiter.press(now_ms, screen_position))
			Platform.write_info_log("pet.input.pressed: base=%s pointer=%s" % [_animation_controller.base_animation, str(screen_position)])
		else:
			_handle_arbiter_events(_input_arbiter.release(now_ms, screen_position))
	elif event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		_reset_press_tracking("right_click")
		_animation_controller.interrupt("right_click_menu", now_ms)
		PetManager.return_to_auto_state()
		Platform.write_info_log("pet.input.right_click: base=%s pointer=%s" % [_animation_controller.base_animation, str(screen_position)])
		DragResizeSystem.show_context_menu()
		get_viewport().set_input_as_handled()


func _handle_mouse_motion(event: InputEventMouseMotion) -> void:
	var left_down := (event.button_mask & MOUSE_BUTTON_MASK_LEFT) != 0
	var screen_position := Vector2(DisplayServer.mouse_get_position())
	if left_down and not _input_arbiter.is_pressed():
		_drag_start_screen_mouse = DisplayServer.mouse_get_position()
		_drag_start_window_pos = get_window().position
		_input_arbiter.press(Time.get_ticks_msec(), screen_position)
	_handle_arbiter_events(_input_arbiter.move(Time.get_ticks_msec(), screen_position))
	if _dragging:
		var delta := DisplayServer.mouse_get_position() - _drag_start_screen_mouse
		DragResizeSystem.move_window_to(_drag_start_window_pos + delta)
		get_viewport().set_input_as_handled()


func _handle_arbiter_events(events: Array) -> void:
	for event_value in events:
		if not event_value is Dictionary:
			continue
		var event: Dictionary = event_value
		var event_type := String(event.get("type", ""))
		Platform.write_debug_log("pet.input.classified: type=%s data=%s" % [event_type, str(event)])
		match event_type:
			"single":
				_fire_click_interaction(PetManager.PetInteraction.CLICKED_SINGLE)
			"run_prepare":
				_start_run()
			"run_move":
				_update_run(event)
			"run_settle":
				_end_run()


func _start_run() -> void:
	_dragging = true
	_run_original_flip_h = anim.flip_h
	_animation_controller.interrupt("run_prepare", Time.get_ticks_msec())
	_play_run_phase("prepare")
	Platform.write_info_log("pet.input.run_prepare: direction=%s window=%s" % [_run_direction, str(_drag_start_window_pos)])


func _update_run(event: Dictionary) -> void:
	var total_delta: Vector2 = event.get("total_delta", Vector2.ZERO)
	var next_direction := _run_direction
	if absf(total_delta.x) > 1.0:
		next_direction = "left" if total_delta.x < 0.0 else "right"
	var direction_changed := next_direction != _run_direction
	_run_direction = next_direction
	_play_run_phase("move")
	if direction_changed:
		Platform.write_info_log("pet.input.run_direction: direction=%s delta=%s" % [_run_direction, str(total_delta)])


func _end_run() -> void:
	_dragging = false
	DragResizeSystem.save_position()
	Platform.write_info_log("pet.input.run_settle: direction=%s window=%s" % [_run_direction, str(get_window().position)])
	var candidates: Array[String] = ActionProfileScript.run_candidates("settle", _run_direction, _animation_controller.base_animation)
	var resolved := ActionProfileScript.first_available(candidates, anim.sprite_frames)
	if resolved == "run_settle":
		var token: int = _animation_controller.request_action(
			resolved,
			maxi(_animation_duration_ms(resolved), 100),
			ActionProfileScript.priority_for(resolved),
			Time.get_ticks_msec(),
			ActionProfileScript.cooldown_for(resolved)
		)
		if token >= 0:
			return
	anim.flip_h = _run_original_flip_h
	_play_base_animation("run_settle_fallback")


func _play_run_phase(phase: String) -> void:
	var candidates: Array[String] = ActionProfileScript.run_candidates(phase, _run_direction, _animation_controller.base_animation)
	var resolved := ActionProfileScript.first_available(candidates, anim.sprite_frames)
	if resolved.is_empty() or ActionProfileScript.base_candidates(_animation_controller.base_animation).has(resolved):
		_play_base_animation("run_%s_fallback" % phase)
		return
	if resolved == "running":
		anim.flip_h = _run_direction == "left"
	else:
		anim.flip_h = _run_original_flip_h
	_play_anim(resolved, "run_%s" % phase)


func _process(_delta: float) -> void:
	var now_ms := Time.get_ticks_msec()
	_poll_business_events(now_ms)
	if DragResizeSystem.is_overlay_active():
		return
	_handle_arbiter_events(_input_arbiter.advance(now_ms))
	_animation_controller.tick(now_ms)
	_update_pointer_follow(now_ms)
	_maybe_trigger_environment_action(now_ms)


func _poll_business_events(now_ms: int) -> void:
	if now_ms < _next_business_event_poll_ms:
		return
	_next_business_event_poll_ms = now_ms + BUSINESS_EVENT_POLL_INTERVAL_MS
	var datetime := Time.get_datetime_dict_from_system()
	var date_key := "%04d-%02d-%02d" % [int(datetime.year), int(datetime.month), int(datetime.day)]
	var events: Array = _business_event_tracker.observe(SalaryEngine.get_current_snapshot(), date_key)
	for event_value in events:
		if not event_value is Dictionary:
			continue
		_handle_business_event(event_value, now_ms)


func _handle_business_event(event: Dictionary, now_ms: int) -> void:
	var event_type := String(event.get("type", ""))
	var event_key := String(event.get("event_key", event_type))
	Platform.write_info_log("pet.business_event.observed: type=%s key=%s amount=%.2f state=%s reason=%s" % [
		event_type,
		event_key,
		float(event.get("amount", 0.0)),
		String(event.get("state", "")),
		String(event.get("reason", ""))
	])
	var blocked_reason := ""
	if DragResizeSystem.is_overlay_active():
		blocked_reason = "overlay_active"
	elif not _has_runtime_profile():
		blocked_reason = "legacy_pet"
	elif _animation_controller.is_action_active():
		blocked_reason = "action_active"
	elif _input_arbiter.is_pressed() or _dragging:
		blocked_reason = "explicit_input"
	if not blocked_reason.is_empty():
		Platform.write_debug_log("pet.business_event.skipped: type=%s key=%s reason=%s" % [event_type, event_key, blocked_reason])
		return
	var candidates: Array[String] = ActionProfileScript.business_event_candidates(event_type, _animation_controller.base_animation)
	var resolved := ActionProfileScript.first_available(candidates, anim.sprite_frames)
	if resolved.is_empty() or ActionProfileScript.base_candidates(_animation_controller.base_animation).has(resolved):
		Platform.write_debug_log("pet.business_event.skipped: type=%s key=%s reason=missing_frames" % [event_type, event_key])
		return
	var token: int = _animation_controller.request_action(
		resolved,
		maxi(_animation_duration_ms(resolved), 100),
		ActionProfileScript.priority_for("business_event"),
		now_ms,
		ActionProfileScript.cooldown_for(resolved)
	)
	Platform.write_info_log("pet.business_event.requested: type=%s key=%s animation=%s token=%d" % [event_type, event_key, resolved, token])


func _fire_click_interaction(interaction: PetManager.PetInteraction) -> void:
	var name := _interaction_debug_name(interaction)
	Platform.write_info_log("pet.input.interaction: type=%s base=%s pointer=%s" % [name, _animation_controller.base_animation, str(DisplayServer.mouse_get_position())])
	PetManager.request_interaction(interaction)
	_queue_interaction_snapshots(interaction, _animation_controller.active_token)


func trigger_interaction_from_debug(interaction: PetManager.PetInteraction) -> void:
	if DragResizeSystem.is_overlay_active():
		return
	_fire_click_interaction(interaction)


func _on_mouse_entered() -> void:
	_hover_entered = true
	_pointer_left_at_ms = -1
	if not _has_runtime_profile() and not _animation_controller.is_action_active():
		PetManager.request_interaction(PetManager.PetInteraction.HOVER)


func _on_mouse_exited() -> void:
	_hover_entered = false
	_pointer_left_at_ms = Time.get_ticks_msec()
	if not _has_runtime_profile() and not _input_arbiter.is_pressed() and not _dragging:
		PetManager.return_to_auto_state()


func _update_pointer_follow(now_ms: int) -> void:
	if not _has_runtime_profile() or _animation_controller.base_animation == "sleeping" or _animation_controller.is_action_active() or _input_arbiter.is_pressed() or _dragging:
		return
	if _hover_entered and _direction_resolver.should_sample(now_ms):
		var delta := to_local(get_global_mouse_position()) - anim.position
		if delta.length_squared() <= 1.0:
			return
		var direction := _direction_resolver.resolve_with_hysteresis(rad_to_deg(atan2(delta.y, delta.x)))
		var animation_name := "look_%s" % direction
		if anim.sprite_frames.has_animation(animation_name):
			_play_anim(animation_name, "pointer_follow")
	elif _pointer_left_at_ms >= 0 and _direction_resolver.should_restore_after_leave(now_ms - _pointer_left_at_ms) and _is_pointer_look_active():
		_pointer_left_at_ms = -1
		_direction_resolver.reset()
		_play_base_animation("pointer_leave")


func _is_pointer_look_active() -> bool:
	return String(anim.animation).begins_with("look_")


func _maybe_trigger_environment_action(now_ms: int) -> void:
	if now_ms < _next_environment_action_ms or not _has_runtime_profile() or _animation_controller.is_action_active() or _input_arbiter.is_pressed() or _dragging:
		return
	_next_environment_action_ms = now_ms + ENVIRONMENT_ACTION_INTERVAL_MS
	var context := SalaryEngine.get_environment_context()
	if context.is_empty() or context in ["night", "after_work"]:
		return
	var candidates: Array[String] = ActionProfileScript.environment_candidates(context, _animation_controller.base_animation)
	var resolved := ActionProfileScript.first_available(candidates, anim.sprite_frames)
	if resolved.is_empty() or ActionProfileScript.base_candidates(_animation_controller.base_animation).has(resolved):
		return
	var token: int = _animation_controller.request_action(resolved, maxi(_animation_duration_ms(resolved), 100), ActionProfileScript.priority_for("environment"), now_ms, ActionProfileScript.cooldown_for(resolved))
	Platform.write_debug_log("pet.environment.request: context=%s animation=%s token=%d" % [context, resolved, token])


func _has_runtime_profile() -> bool:
	var pet_res := PetManager.get_current_pet()
	return pet_res != null and pet_res.runtime_profile != null


func _apply_interaction_visual() -> void:
	if _visual_tween != null:
		_visual_tween.kill()
		_visual_tween = null
	anim.modulate = Color.WHITE
	match PetManager.current_interaction:
		PetManager.PetInteraction.HOVER:
			_visual_tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			_visual_tween.parallel().tween_property(anim, "scale", _base_anim_scale * 1.05, 0.10)
			_visual_tween.parallel().tween_property(anim, "modulate", Color(1.0, 0.94, 0.84, 1.0), 0.10)
		PetManager.PetInteraction.CLICKED_SINGLE:
			_pulse_visual(1.04, Color(1.0, 0.94, 0.84, 1.0), 0.14)
		PetManager.PetInteraction.CLICKED_DOUBLE:
			_pulse_visual(1.07, Color(1.0, 0.86, 0.68, 1.0), 0.16)
		PetManager.PetInteraction.CLICKED_HOLD:
			_pulse_visual(0.96, Color(0.94, 0.84, 0.72, 1.0), 0.12)
		_:
			_visual_tween = create_tween()
			_visual_tween.parallel().tween_property(anim, "scale", _base_anim_scale, 0.12)
			_visual_tween.parallel().tween_property(anim, "modulate", Color.WHITE, 0.12)


func _pulse_visual(scale_factor: float, color: Color, duration: float) -> void:
	_visual_tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_visual_tween.parallel().tween_property(anim, "scale", _base_anim_scale * scale_factor, duration)
	_visual_tween.parallel().tween_property(anim, "modulate", color, duration)


func _reset_press_tracking(reason: String) -> void:
	_input_arbiter.reset()
	if _dragging:
		_dragging = false
		DragResizeSystem.save_position()
	anim.flip_h = _run_original_flip_h
	_play_base_animation("input_reset:%s" % reason)
	Platform.write_debug_log("pet.input.reset: reason=%s" % reason)


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


func _queue_interaction_snapshots(interaction: PetManager.PetInteraction, token: int) -> void:
	if interaction != PetManager.PetInteraction.CLICKED_SINGLE or not _should_capture_interaction_snapshots():
		return
	call_deferred("_capture_interaction_snapshots", _interaction_debug_name(interaction), token)


func _should_capture_interaction_snapshots() -> bool:
	return OS.get_environment("LETSMAKEMONEY_CAPTURE_INTERACTION_SCREENSHOTS") == "1" or bool(Config.get_value("debug_mode", false))


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
	var region := image.get_region(Rect2i(int(floor(crop_rect.position.x)), int(floor(crop_rect.position.y)), int(ceil(crop_rect.size.x)), int(ceil(crop_rect.size.y))))
	var dir_path := _interaction_snapshot_dir()
	if dir_path.is_empty():
		return
	var path := dir_path.path_join("%s_%s_%02d_%dms_%s_f%d.png" % [_screenshot_timestamp(), interaction_name, index + 1, int(round(delay * 1000.0)), anim.animation, anim.frame])
	var result := region.save_png(path)
	Platform.write_debug_log("pet.snapshot: interaction=%s token=%d delay_ms=%d animation=%s frame=%d path=%s ok=%s" % [interaction_name, token, int(round(delay * 1000.0)), anim.animation, anim.frame, path, str(result == OK)])


func _current_pet_viewport_rect() -> Rect2:
	var local_rect := _get_current_hit_rect()
	var transform := get_global_transform()
	var points := [transform * local_rect.position, transform * (local_rect.position + Vector2(local_rect.size.x, 0.0)), transform * (local_rect.position + Vector2(0.0, local_rect.size.y)), transform * (local_rect.position + local_rect.size)]
	var rect := Rect2(points[0], Vector2.ZERO)
	for point in points:
		rect = rect.expand(point)
	return rect


func _interaction_snapshot_dir() -> String:
	var appdata := OS.get_environment("APPDATA")
	if appdata.is_empty():
		appdata = OS.get_user_data_dir()
	var dir_path := appdata.path_join("LetsMakeMoney").path_join("interaction-screenshots")
	if not DirAccess.dir_exists_absolute(dir_path) and DirAccess.make_dir_recursive_absolute(dir_path) != OK:
		return ""
	return dir_path


func _screenshot_timestamp() -> String:
	return Time.get_datetime_string_from_system().replace(":", "").replace("-", "").replace("T", "_")
