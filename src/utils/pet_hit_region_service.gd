extends RefCounted
class_name PetHitRegionService


static func animation_frame_rects(frames: SpriteFrames, animation_name: String, alpha_threshold: float = 0.05) -> Array[Rect2i]:
	var output: Array[Rect2i] = []
	if frames == null or not frames.has_animation(animation_name): return output
	for index in frames.get_frame_count(animation_name): output.append(texture_alpha_rect(frames.get_frame_texture(animation_name, index), alpha_threshold))
	return output


static func texture_alpha_rect(texture: Texture2D, alpha_threshold: float = 0.05) -> Rect2i:
	if texture == null: return Rect2i()
	var image := texture.get_image()
	if image == null or image.is_empty(): return Rect2i(Vector2i.ZERO, Vector2i(texture.get_width(), texture.get_height()))
	var min_x := image.get_width()
	var min_y := image.get_height()
	var max_x := -1
	var max_y := -1
	for y in image.get_height():
		for x in image.get_width():
			if image.get_pixel(x, y).a > alpha_threshold:
				min_x = mini(min_x, x); min_y = mini(min_y, y); max_x = maxi(max_x, x); max_y = maxi(max_y, y)
	if max_x < min_x or max_y < min_y: return Rect2i()
	return Rect2i(min_x, min_y, max_x - min_x + 1, max_y - min_y + 1)


static func union_rect(rects: Array[Rect2i]) -> Rect2i:
	var result := Rect2i()
	var initialized := false
	for rect in rects:
		if rect.size.x <= 0 or rect.size.y <= 0: continue
		if initialized: result = result.merge(rect)
		else: result = rect; initialized = true
	return result


static func benchmark_animation(frames: SpriteFrames, animation_name: String, alpha_threshold: float = 0.05) -> Dictionary:
	var started := Time.get_ticks_usec()
	var rects := animation_frame_rects(frames, animation_name, alpha_threshold)
	return {"frame_count": rects.size(), "elapsed_ms": float(Time.get_ticks_usec() - started) / 1000.0, "union": union_rect(rects)}
