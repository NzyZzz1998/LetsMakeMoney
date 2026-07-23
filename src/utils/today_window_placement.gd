class_name TodayWindowPlacement
extends RefCounted


static func sanitize(position: Vector2i, size: Vector2i, screen_rect: Rect2i, margin: int = 24) -> Vector2i:
	var usable_size := Vector2i(
		maxi(320, mini(size.x, screen_rect.size.x - margin * 2)),
		maxi(360, mini(size.y, screen_rect.size.y - margin * 2))
	)
	var min_x := screen_rect.position.x + margin
	var min_y := screen_rect.position.y + margin
	var max_x := maxi(min_x, screen_rect.end.x - usable_size.x - margin)
	var max_y := maxi(min_y, screen_rect.end.y - usable_size.y - margin)
	if position.x < screen_rect.position.x or position.y < screen_rect.position.y \
		or position.x >= screen_rect.end.x or position.y >= screen_rect.end.y:
		return Vector2i(max_x, max_y)
	return Vector2i(clampi(position.x, min_x, max_x), clampi(position.y, min_y, max_y))


static func sanitize_size(size: Vector2i, screen_rect: Rect2i, margin: int = 24) -> Vector2i:
	return Vector2i(
		maxi(320, mini(size.x, screen_rect.size.x - margin * 2)),
		maxi(360, mini(size.y, screen_rect.size.y - margin * 2))
	)
