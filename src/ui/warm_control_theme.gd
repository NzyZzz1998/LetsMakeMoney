extends RefCounted
class_name WarmControlTheme

const SURFACE_APP = Color(0.988, 0.958, 0.890, 1.0)
const SURFACE_PAPER = Color(1.000, 0.992, 0.965, 1.0)
const SURFACE_CARD = Color(1.000, 0.998, 0.988, 1.0)
const SURFACE_SELECTED = Color(1.000, 0.930, 0.735, 1.0)

const TEXT_INK = Color(0.220, 0.120, 0.055, 1.0)
const TEXT_MUTED = Color(0.550, 0.420, 0.298, 1.0)
const ACCENT_COIN = Color(1.000, 0.714, 0.243, 1.0)
const ACCENT_ORANGE = Color(0.965, 0.512, 0.184, 1.0)
const ACCENT_MINT = Color(0.454, 0.737, 0.502, 1.0)
const DANGER_SOFT = Color(0.780, 0.330, 0.260, 1.0)
const BORDER_WARM = Color(0.416, 0.263, 0.122, 0.140)
const SHADOW_WARM = Color(0.360, 0.184, 0.047, 0.100)

const ROW_HEIGHT = 46.0
const INPUT_HEIGHT = 34.0
const BUTTON_HEIGHT = 38.0
const TAB_HEIGHT = 38.0
const SWITCH_SIZE = Vector2(40, 22)
const SLIDER_TRACK_HEIGHT = 6
const SCROLLBAR_WIDTH = 5


func stylebox(
	bg: Color,
	border: Color = BORDER_WARM,
	border_width: int = 1,
	radius: int = 10,
	padding: int = 6,
	shadow_color: Color = Color(0, 0, 0, 0),
	shadow_size: int = 0
) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(radius)
	style.shadow_color = shadow_color
	style.shadow_size = shadow_size
	style.shadow_offset = Vector2(0, 3)
	style.content_margin_left = padding
	style.content_margin_top = padding
	style.content_margin_right = padding
	style.content_margin_bottom = padding
	return style


func build_theme(default_size: int = 14) -> Theme:
	var theme := Theme.new()
	var font := SystemFont.new()
	font.font_names = PackedStringArray(["Microsoft YaHei UI", "Microsoft YaHei", "Segoe UI"])
	font.antialiasing = TextServer.FONT_ANTIALIASING_LCD
	font.hinting = TextServer.HINTING_NORMAL
	font.subpixel_positioning = TextServer.SUBPIXEL_POSITIONING_AUTO
	theme.default_font = font
	theme.default_font_size = default_size
	return theme


func style_button(button: Button, primary: bool = false, quiet: bool = false, danger: bool = false) -> void:
	var normal_bg := SURFACE_CARD
	var hover_bg := Color(1.0, 0.962, 0.842, 1.0)
	var pressed_bg := Color(0.986, 0.900, 0.720, 1.0)
	var border := BORDER_WARM
	var text_color := TEXT_INK

	if quiet:
		normal_bg = Color(0, 0, 0, 0)
		hover_bg = Color(1.0, 0.920, 0.730, 0.55)
		pressed_bg = Color(0.965, 0.714, 0.243, 0.35)
		border = Color(0, 0, 0, 0)

	if primary:
		normal_bg = ACCENT_COIN
		hover_bg = Color(1.0, 0.780, 0.310, 1.0)
		pressed_bg = ACCENT_ORANGE
		border = Color(0.780, 0.420, 0.137, 0.32)

	if danger:
		normal_bg = Color(0.992, 0.880, 0.830, 1.0)
		hover_bg = Color(0.980, 0.820, 0.756, 1.0)
		pressed_bg = Color(0.900, 0.620, 0.540, 1.0)
		border = Color(DANGER_SOFT.r, DANGER_SOFT.g, DANGER_SOFT.b, 0.24)
		text_color = Color(0.420, 0.145, 0.110, 1.0)

	button.custom_minimum_size.y = maxf(button.custom_minimum_size.y, BUTTON_HEIGHT)
	button.add_theme_stylebox_override("normal", stylebox(normal_bg, border, 1, 10, 7))
	button.add_theme_stylebox_override("hover", stylebox(hover_bg, Color(0.780, 0.420, 0.137, 0.26), 1, 10, 7, SHADOW_WARM, 2))
	button.add_theme_stylebox_override("pressed", stylebox(pressed_bg, Color(0.780, 0.420, 0.137, 0.38), 1, 10, 7))
	button.add_theme_stylebox_override("focus", stylebox(Color(0, 0, 0, 0), ACCENT_COIN, 2, 10, 7))
	button.add_theme_color_override("font_color", text_color)
	button.add_theme_color_override("font_hover_color", text_color)
	button.add_theme_color_override("font_pressed_color", text_color)
	button.add_theme_color_override("font_focus_color", text_color)
	button.add_theme_color_override("font_disabled_color", Color(TEXT_MUTED.r, TEXT_MUTED.g, TEXT_MUTED.b, 0.50))
	button.add_theme_font_size_override("font_size", 14)


func style_line_edit(line_edit: LineEdit) -> void:
	line_edit.custom_minimum_size.y = maxf(line_edit.custom_minimum_size.y, INPUT_HEIGHT)
	line_edit.add_theme_stylebox_override("normal", stylebox(Color(1.0, 0.998, 0.990, 1.0), Color(0.416, 0.263, 0.122, 0.12), 1, 9, 5))
	line_edit.add_theme_stylebox_override("read_only", stylebox(Color(1.0, 0.972, 0.902, 0.72), Color(0.416, 0.263, 0.122, 0.08), 1, 9, 5))
	line_edit.add_theme_stylebox_override("focus", stylebox(Color(1.0, 0.998, 0.990, 1.0), Color(ACCENT_COIN.r, ACCENT_COIN.g, ACCENT_COIN.b, 0.76), 2, 9, 5))
	line_edit.add_theme_color_override("font_color", TEXT_INK)
	line_edit.add_theme_color_override("font_uneditable_color", Color(TEXT_MUTED.r, TEXT_MUTED.g, TEXT_MUTED.b, 0.82))
	line_edit.add_theme_color_override("font_placeholder_color", Color(TEXT_MUTED.r, TEXT_MUTED.g, TEXT_MUTED.b, 0.62))
	line_edit.add_theme_font_size_override("font_size", 14)


func style_spin_box(spin: SpinBox, width: float = 96.0) -> void:
	spin.custom_minimum_size = Vector2(maxf(spin.custom_minimum_size.x, width), maxf(spin.custom_minimum_size.y, INPUT_HEIGHT))
	spin.add_theme_font_size_override("font_size", 14)
	spin.add_theme_color_override("font_color", TEXT_INK)
	style_line_edit(spin.get_line_edit())


func style_option_button(option: OptionButton, width: float = 124.0) -> void:
	option.flat = false
	option.custom_minimum_size = Vector2(maxf(option.custom_minimum_size.x, width), maxf(option.custom_minimum_size.y, INPUT_HEIGHT))
	option.add_theme_stylebox_override("normal", stylebox(Color(1.0, 0.998, 0.990, 1.0), Color(0.416, 0.263, 0.122, 0.12), 1, 9, 5))
	option.add_theme_stylebox_override("hover", stylebox(Color(1.0, 0.970, 0.900, 1.0), Color(0.780, 0.420, 0.137, 0.20), 1, 9, 5))
	option.add_theme_stylebox_override("pressed", stylebox(Color(1.0, 0.936, 0.760, 1.0), Color(ACCENT_COIN.r, ACCENT_COIN.g, ACCENT_COIN.b, 0.54), 1, 9, 5))
	option.add_theme_stylebox_override("focus", stylebox(Color(1.0, 0.998, 0.990, 1.0), Color(ACCENT_COIN.r, ACCENT_COIN.g, ACCENT_COIN.b, 0.76), 2, 9, 5))
	option.add_theme_color_override("font_color", TEXT_INK)
	option.add_theme_color_override("font_hover_color", TEXT_INK)
	option.add_theme_color_override("font_pressed_color", TEXT_INK)
	option.add_theme_color_override("font_focus_color", TEXT_INK)
	option.add_theme_color_override("font_hover_pressed_color", TEXT_INK)
	option.add_theme_color_override("font_disabled_color", Color(TEXT_MUTED.r, TEXT_MUTED.g, TEXT_MUTED.b, 0.55))
	option.add_theme_font_size_override("font_size", 14)
	option.add_theme_icon_override("arrow", _make_dropdown_arrow())
	style_option_popup(option)


func style_option_popup(option: OptionButton) -> void:
	var popup := option.get_popup()
	if popup == null:
		return
	popup.transparent_bg = true
	popup.borderless = true
	popup.min_size = Vector2i(int(maxf(option.size.x, option.custom_minimum_size.x)), 0)
	popup.add_theme_stylebox_override("panel", stylebox(Color(1.0, 0.992, 0.965, 0.995), Color(0.416, 0.263, 0.122, 0.14), 1, 11, 6, SHADOW_WARM, 7))
	popup.add_theme_stylebox_override("hover", stylebox(SURFACE_SELECTED, Color(ACCENT_COIN.r, ACCENT_COIN.g, ACCENT_COIN.b, 0.30), 1, 8, 5))
	popup.add_theme_stylebox_override("separator", stylebox(Color(0.416, 0.263, 0.122, 0.12), Color(0, 0, 0, 0), 0, 1, 1))
	popup.add_theme_color_override("font_color", TEXT_INK)
	popup.add_theme_color_override("font_hover_color", TEXT_INK)
	popup.add_theme_color_override("font_pressed_color", TEXT_INK)
	popup.add_theme_color_override("font_hover_pressed_color", TEXT_INK)
	popup.add_theme_color_override("font_checked_color", ACCENT_ORANGE)
	popup.add_theme_color_override("font_disabled_color", Color(TEXT_MUTED.r, TEXT_MUTED.g, TEXT_MUTED.b, 0.55))
	popup.add_theme_constant_override("item_min_height", 30)
	popup.add_theme_constant_override("item_start_padding", 8)
	popup.add_theme_constant_override("item_end_padding", 8)
	popup.add_theme_constant_override("h_separation", 6)
	popup.add_theme_constant_override("v_separation", 1)
	popup.add_theme_constant_override("indent", 4)
	popup.add_theme_font_size_override("font_size", 14)
	popup.add_theme_icon_override("checked", _make_popup_check_icon(true))
	popup.add_theme_icon_override("radio_checked", _make_popup_check_icon(true))
	popup.add_theme_icon_override("unchecked", _make_popup_check_icon(false))
	popup.add_theme_icon_override("radio_unchecked", _make_popup_check_icon(false))


func style_switch(toggle: BaseButton) -> void:
	var transparent := stylebox(Color(0, 0, 0, 0), Color(0, 0, 0, 0), 0, 0, 0)
	toggle.custom_minimum_size = SWITCH_SIZE
	toggle.flat = true
	toggle.add_theme_stylebox_override("normal", transparent)
	toggle.add_theme_stylebox_override("hover", transparent)
	toggle.add_theme_stylebox_override("pressed", transparent)
	toggle.add_theme_stylebox_override("hover_pressed", transparent)
	toggle.add_theme_stylebox_override("disabled", transparent)
	toggle.add_theme_stylebox_override("focus", stylebox(Color(0, 0, 0, 0), ACCENT_COIN, 1, 10, 0))
	toggle.add_theme_constant_override("h_separation", 0)
	toggle.add_theme_icon_override("checked", _make_switch_icon(true, false))
	toggle.add_theme_icon_override("unchecked", _make_switch_icon(false, false))
	toggle.add_theme_icon_override("checked_disabled", _make_switch_icon(true, true))
	toggle.add_theme_icon_override("unchecked_disabled", _make_switch_icon(false, true))
	toggle.add_theme_font_size_override("font_size", 14)
	toggle.add_theme_color_override("font_color", TEXT_INK)
	toggle.add_theme_color_override("font_disabled_color", Color(TEXT_MUTED.r, TEXT_MUTED.g, TEXT_MUTED.b, 0.52))


func style_slider(slider: HSlider) -> void:
	slider.custom_minimum_size.y = maxf(slider.custom_minimum_size.y, 28)
	slider.add_theme_stylebox_override("slider", _slider_track_stylebox(Color(0.620, 0.460, 0.245, 0.32)))
	slider.add_theme_stylebox_override("grabber_area", _slider_track_stylebox(Color(1.000, 0.714, 0.243, 0.92)))
	slider.add_theme_stylebox_override("grabber_area_highlight", _slider_track_stylebox(Color(0.965, 0.512, 0.184, 0.96)))
	slider.add_theme_icon_override("grabber", _make_slider_grabber(Color(0.780, 0.420, 0.137, 0.22), SURFACE_CARD))
	slider.add_theme_icon_override("grabber_highlight", _make_slider_grabber(Color(0.780, 0.420, 0.137, 0.34), Color(1.0, 0.965, 0.860, 1.0)))
	slider.add_theme_icon_override("grabber_pressed", _make_slider_grabber(Color(0.780, 0.420, 0.137, 0.42), ACCENT_COIN))
	slider.add_theme_constant_override("center_grabber", 0)
	slider.add_theme_constant_override("grabber_offset", 0)
	slider.add_theme_constant_override("slider_width", SLIDER_TRACK_HEIGHT)


func _slider_track_stylebox(color: Color) -> StyleBoxFlat:
	var track := stylebox(color, Color(0, 0, 0, 0), 0, 4, 0)
	track.content_margin_top = SLIDER_TRACK_HEIGHT / 2.0
	track.content_margin_bottom = SLIDER_TRACK_HEIGHT / 2.0
	return track


func style_scrollbar(scrollbar: ScrollBar) -> void:
	scrollbar.custom_minimum_size.x = SCROLLBAR_WIDTH
	scrollbar.add_theme_stylebox_override("scroll", stylebox(Color(0, 0, 0, 0), Color(0, 0, 0, 0), 0, 3, 0))
	scrollbar.add_theme_stylebox_override("scroll_focus", stylebox(Color(0, 0, 0, 0), Color(0, 0, 0, 0), 0, 3, 0))
	scrollbar.add_theme_stylebox_override("grabber", stylebox(Color(0.416, 0.263, 0.122, 0.22), Color(0, 0, 0, 0), 0, 3, 0))
	scrollbar.add_theme_stylebox_override("grabber_highlight", stylebox(Color(0.416, 0.263, 0.122, 0.32), Color(0, 0, 0, 0), 0, 3, 0))
	scrollbar.add_theme_stylebox_override("grabber_pressed", stylebox(Color(0.416, 0.263, 0.122, 0.42), Color(0, 0, 0, 0), 0, 3, 0))


func style_compact_row(row: Control) -> void:
	row.custom_minimum_size.y = maxf(row.custom_minimum_size.y, ROW_HEIGHT)
	row.add_theme_stylebox_override("panel", stylebox(Color(0, 0, 0, 0), Color(0, 0, 0, 0), 0, 0, 0))


func style_section_divider(divider: ColorRect) -> void:
	divider.custom_minimum_size = Vector2(0, 1)
	divider.color = Color(BORDER_WARM.r, BORDER_WARM.g, BORDER_WARM.b, 0.55)


func style_inline_status(label: Label, kind: String = "normal") -> void:
	var color := TEXT_MUTED
	if kind == "success":
		color = ACCENT_MINT
	elif kind == "warning":
		color = ACCENT_ORANGE
	elif kind == "danger" or kind == "error":
		color = DANGER_SOFT
	label.add_theme_font_size_override("font_size", 12)
	label.add_theme_color_override("font_color", color)


func _make_dropdown_arrow() -> Texture2D:
	var size := 12
	var image := Image.create(size, size, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	var color := Color(TEXT_MUTED.r, TEXT_MUTED.g, TEXT_MUTED.b, 0.86)
	for i in range(4):
		image.set_pixel(3 + i, 4 + i, color)
		image.set_pixel(8 - i, 4 + i, color)
	return ImageTexture.create_from_image(image)


func _make_popup_check_icon(checked: bool) -> Texture2D:
	var size := 12
	var image := Image.create(size, size, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	if checked:
		var color := ACCENT_ORANGE
		for i in range(3):
			image.set_pixel(3 + i, 6 + i, color)
			image.set_pixel(6 + i, 8 - i, color)
	return ImageTexture.create_from_image(image)


func _make_slider_grabber(border_color: Color, fill_color: Color) -> Texture2D:
	var size := 18
	var image := Image.create(size, size, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	var center := Vector2(size / 2.0, size / 2.0)
	for y in range(size):
		for x in range(size):
			var distance := Vector2(x + 0.5, y + 0.5).distance_to(center)
			if distance <= 8.0:
				image.set_pixel(x, y, border_color)
			if distance <= 6.6:
				image.set_pixel(x, y, fill_color)
	return ImageTexture.create_from_image(image)


func _make_switch_icon(pressed: bool, disabled: bool) -> Texture2D:
	var width := int(SWITCH_SIZE.x)
	var height := int(SWITCH_SIZE.y)
	var image := Image.create(width, height, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	var track := Color(0.416, 0.263, 0.122, 0.22)
	var border := Color(0.416, 0.263, 0.122, 0.14)
	if pressed:
		track = ACCENT_COIN
		border = Color(0.780, 0.420, 0.137, 0.26)
	if disabled:
		track.a *= 0.45
		border.a *= 0.55

	var radius := height / 2.0
	for y in range(height):
		for x in range(width):
			var left_center := Vector2(radius, radius)
			var right_center := Vector2(width - radius, radius)
			var p := Vector2(x + 0.5, y + 0.5)
			var in_rect := x >= radius and x <= width - radius and y >= 0 and y <= height
			var in_left := p.distance_to(left_center) <= radius
			var in_right := p.distance_to(right_center) <= radius
			if in_rect or in_left or in_right:
				image.set_pixel(x, y, track)
			var edge_radius := radius - 1.0
			var in_inner_rect := x >= radius and x <= width - radius and y >= 1 and y <= height - 1
			var in_inner_left := p.distance_to(left_center) <= edge_radius
			var in_inner_right := p.distance_to(right_center) <= edge_radius
			if (in_rect or in_left or in_right) and not (in_inner_rect or in_inner_left or in_inner_right):
				image.set_pixel(x, y, border)

	var knob_radius := 8.0
	var knob_center := Vector2(11.0 if not pressed else width - 11.0, height / 2.0)
	var knob := Color(1.0, 0.998, 0.990, 1.0)
	if disabled:
		knob = Color(1.0, 0.998, 0.990, 0.72)
	for y in range(height):
		for x in range(width):
			var p := Vector2(x + 0.5, y + 0.5)
			var distance := p.distance_to(knob_center)
			if distance <= knob_radius:
				image.set_pixel(x, y, knob)
	return ImageTexture.create_from_image(image)
