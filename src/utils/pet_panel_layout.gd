class_name PetPanelLayout
extends RefCounted


static func resolve(window_position: Vector2i, window_size: Vector2i, screen_rect: Rect2i) -> Dictionary:
	var window_center_x := window_position.x + window_size.x / 2
	var screen_center_x := screen_rect.position.x + screen_rect.size.x / 2
	var pet_on_right := window_center_x >= screen_center_x
	return {
		"pet_position": Vector2(356, 88) if pet_on_right else Vector2(28, 88),
		"panel_position": Vector2(12, 104) if pet_on_right else Vector2(300, 104),
		"pet_on_right": pet_on_right
	}


static func amount_font_size(text_value: String, base_size: int = 38) -> int:
	var digit_count := text_value.replace("¥", "").replace("￥", "").replace(",", "").replace(".", "").length()
	if digit_count <= 7:
		return base_size
	if digit_count <= 9:
		return maxi(int(round(base_size * 0.82)), base_size - 5)
	return maxi(int(round(base_size * 0.72)), base_size - 9)
