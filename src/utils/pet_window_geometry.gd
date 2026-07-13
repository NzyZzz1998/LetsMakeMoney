class_name PetWindowGeometry
extends RefCounted


static func clamp_scale(scale_value: float) -> float:
	return clamp(scale_value, 0.5, 2.0)


static func panel_target_size_for_scale(scale_value: float, base_size: Vector2i) -> Vector2i:
	var safe_scale := clamp_scale(scale_value)
	return Vector2i(
		int(ceil(float(base_size.x) * safe_scale)),
		int(ceil(float(base_size.y) * safe_scale))
	)


static func pet_sprite_bounds(
	scale_value: float,
	base_position: Vector2,
	texture_size: Vector2,
	local_position: Vector2,
	base_scale: float
) -> Rect2:
	var safe_scale := clamp_scale(scale_value)
	var sprite_size := texture_size * base_scale * safe_scale
	var sprite_center := base_position + local_position * safe_scale
	return Rect2(sprite_center - sprite_size * 0.5, sprite_size)


static func pet_window_size(
	scale_value: float,
	base_window_size: Vector2i,
	pet_position: Vector2,
	panel_position: Vector2,
	texture_size: Vector2,
	local_position: Vector2,
	base_scale: float,
	panel_base_size: Vector2i,
	content_margin: float
) -> Vector2i:
	var pet_bounds := pet_sprite_bounds(scale_value, pet_position, texture_size, local_position, base_scale)
	var panel_size := panel_target_size_for_scale(scale_value, panel_base_size)
	var width := maxf(float(base_window_size.x), pet_bounds.end.x + content_margin)
	width = maxf(width, panel_position.x + float(panel_size.x) + content_margin)
	var height := maxf(float(base_window_size.y), pet_bounds.end.y + content_margin)
	height = maxf(height, panel_position.y + float(panel_size.y) + content_margin)
	return Vector2i(int(ceil(width)), int(ceil(height)))


static func pet_interaction_rect(local_rect: Rect2, pet_position: Vector2, scale_value: float, padding: Vector2) -> Rect2:
	var scaled_rect := Rect2(pet_position + local_rect.position * scale_value, local_rect.size * scale_value)
	return scaled_rect.grow_individual(
		padding.x * scale_value,
		padding.y * scale_value,
		padding.x * scale_value,
		padding.y * scale_value
	)


static func panel_interaction_rect(panel_position: Vector2, control_size: Vector2, minimum_size: Vector2, hover_padding: float) -> Rect2:
	var hit_size := Vector2(maxf(minimum_size.x, control_size.x), maxf(minimum_size.y, control_size.y))
	return Rect2(panel_position, hit_size).grow(hover_padding)
