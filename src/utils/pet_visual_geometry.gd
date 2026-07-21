extends RefCounted
class_name PetVisualGeometry


static func normalized_transform(
	logical_size: Vector2,
	pivot: Vector2,
	base_position: Vector2,
	base_scale: Vector2,
	reference_size: Vector2
) -> Dictionary:
	if logical_size.x <= 0.0 or logical_size.y <= 0.0 or reference_size.y <= 0.0:
		return {"position": base_position, "scale": base_scale, "scale_factor": 1.0}
	var scale_factor := clampf(reference_size.y / logical_size.y, 0.75, 1.5)
	var normalized_scale := base_scale * scale_factor
	var reference_pivot_world := base_position + Vector2(0.0, reference_size.y * 0.5 * base_scale.y)
	var source_pivot_offset := pivot - logical_size * 0.5
	return {
		"position": reference_pivot_world - source_pivot_offset * normalized_scale,
		"scale": normalized_scale,
		"scale_factor": scale_factor,
		"pivot_world": reference_pivot_world,
	}
