# src/scenes/wizard/wizard_dialog.gd
extends Control

signal finished

var _current_step: int = 1
var _pages: Array[Control] = []

var salary_input: SpinBox
var rest_mode_option: OptionButton
var hours_input: SpinBox
var start_hour_input: SpinBox
var start_min_input: SpinBox
var end_hour_input: SpinBox
var end_min_input: SpinBox
var pet_list: ItemList
var welcome_preview: TextureRect
var pet_preview: TextureRect
var summary_label: Label
var prev_btn: Button
var next_btn: Button
var _summary_value_labels: Dictionary = {}

const SURFACE_APP := Color(1.0, 0.972, 0.914, 0.98)
const SURFACE_CARD := Color(1.0, 0.988, 0.952, 0.99)
const SURFACE_SELECTED := Color(1.0, 0.945, 0.792, 1.0)
const TEXT_INK := Color(0.227, 0.153, 0.098, 1.0)
const TEXT_MUTED := Color(0.550, 0.420, 0.298, 1.0)
const ACCENT_COIN := Color(0.965, 0.714, 0.243, 1.0)
const ACCENT_ORANGE := Color(0.780, 0.420, 0.137, 1.0)
const BORDER_WARM := Color(0.416, 0.263, 0.122, 0.16)
const SHADOW_WARM := Color(0.360, 0.184, 0.047, 0.16)


func _ready() -> void:
	theme = _build_wizard_theme()
	custom_minimum_size = Vector2(620, 460)
	mouse_filter = Control.MOUSE_FILTER_STOP
	focus_mode = Control.FOCUS_ALL
	_build_ui()
	_load_defaults()
	_populate_pets()
	_show_step(1)


func _new_page(page_name: String) -> VBoxContainer:
	var page := VBoxContainer.new()
	page.name = page_name
	page.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	page.size_flags_vertical = Control.SIZE_EXPAND_FILL
	page.add_theme_constant_override("separation", 10)
	page.add_theme_stylebox_override("panel", _stylebox(SURFACE_CARD, BORDER_WARM, 1, 16, 16, Color(0.360, 0.184, 0.047, 0.08), 4))
	return page


func _build_ui() -> void:
	var surface := PanelContainer.new()
	surface.name = "WizardSurface"
	surface.set_anchors_preset(Control.PRESET_FULL_RECT)
	surface.add_theme_stylebox_override("panel", _stylebox(SURFACE_APP, BORDER_WARM, 1, 18, 0, SHADOW_WARM, 8))
	add_child(surface)

	var outer_margin := MarginContainer.new()
	outer_margin.name = "WizardOuterMargin"
	outer_margin.add_theme_constant_override("margin_left", 16)
	outer_margin.add_theme_constant_override("margin_top", 14)
	outer_margin.add_theme_constant_override("margin_right", 16)
	outer_margin.add_theme_constant_override("margin_bottom", 10)
	surface.add_child(outer_margin)

	var box := VBoxContainer.new()
	box.name = "WizardRoot"
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation", 0)
	outer_margin.add_child(box)

	var content_holder := Control.new()
	content_holder.name = "WizardContentPages"
	content_holder.clip_contents = true
	content_holder.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_holder.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(content_holder)

	var welcome := _build_welcome_page()
	var salary := _build_salary_page()
	var pet := _build_pet_page()
	var confirm := _build_confirm_page()
	_pages = [welcome, salary, pet, confirm]
	for page in _pages:
		page.set_anchors_preset(Control.PRESET_FULL_RECT)
		page.offset_left = 0
		page.offset_top = 0
		page.offset_right = 0
		page.offset_bottom = 0
		content_holder.add_child(page)

	var nav_divider := ColorRect.new()
	nav_divider.name = "WizardActionDivider"
	nav_divider.color = Color(0.416, 0.263, 0.122, 0.10)
	nav_divider.custom_minimum_size = Vector2(0, 1)
	box.add_child(nav_divider)

	var nav := HBoxContainer.new()
	nav.name = "WizardActionRow"
	nav.custom_minimum_size = Vector2(0, 46)
	nav.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	nav.alignment = BoxContainer.ALIGNMENT_END
	nav.add_theme_constant_override("separation", 8)
	box.add_child(nav)

	var cancel_btn := Button.new()
	cancel_btn.name = "CancelButton"
	cancel_btn.text = "取消"
	cancel_btn.custom_minimum_size = Vector2(84, 34)
	cancel_btn.pressed.connect(_on_cancel)
	_style_button(cancel_btn)
	nav.add_child(cancel_btn)

	prev_btn = Button.new()
	prev_btn.text = "上一步"
	next_btn = Button.new()
	next_btn.text = "下一步"
	prev_btn.custom_minimum_size = Vector2(88, 34)
	next_btn.custom_minimum_size = Vector2(96, 34)
	_style_button(prev_btn)
	_style_button(next_btn, true)
	nav.add_child(prev_btn)
	nav.add_child(next_btn)
	prev_btn.pressed.connect(_on_prev)
	next_btn.pressed.connect(_on_next)


func _stylebox(
	bg: Color,
	border: Color,
	border_width: int,
	radius: int,
	padding: int,
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


func _build_wizard_theme() -> Theme:
	var wizard_theme := Theme.new()
	var font := SystemFont.new()
	font.font_names = PackedStringArray(["Microsoft YaHei UI", "Microsoft YaHei", "Segoe UI"])
	font.antialiasing = TextServer.FONT_ANTIALIASING_LCD
	font.hinting = TextServer.HINTING_NORMAL
	font.subpixel_positioning = TextServer.SUBPIXEL_POSITIONING_AUTO
	wizard_theme.default_font = font
	wizard_theme.default_font_size = 16
	return wizard_theme


func _style_button(button: Button, primary: bool = false) -> void:
	var normal_bg := SURFACE_CARD
	var hover_bg := Color(1.0, 0.962, 0.842, 1.0)
	var pressed_bg := Color(0.986, 0.900, 0.720, 1.0)
	var border := BORDER_WARM
	if primary:
		normal_bg = ACCENT_COIN
		hover_bg = Color(1.0, 0.780, 0.310, 1.0)
		pressed_bg = ACCENT_ORANGE
		border = Color(0.780, 0.420, 0.137, 0.32)
	button.add_theme_stylebox_override("normal", _stylebox(normal_bg, border, 1, 12, 10))
	button.add_theme_stylebox_override("hover", _stylebox(hover_bg, Color(0.780, 0.420, 0.137, 0.28), 1, 12, 10, Color(0.360, 0.184, 0.047, 0.10), 3))
	button.add_theme_stylebox_override("pressed", _stylebox(pressed_bg, Color(0.780, 0.420, 0.137, 0.38), 1, 12, 10))
	button.add_theme_stylebox_override("focus", _stylebox(Color(0, 0, 0, 0), ACCENT_COIN, 2, 12, 10))
	button.add_theme_color_override("font_color", TEXT_INK)
	button.add_theme_color_override("font_hover_color", TEXT_INK)
	button.add_theme_color_override("font_pressed_color", TEXT_INK)
	button.add_theme_font_size_override("font_size", 15)


func _style_option_button(option: OptionButton) -> void:
	option.flat = false
	option.custom_minimum_size = Vector2(maxf(option.custom_minimum_size.x, 124), maxf(option.custom_minimum_size.y, 32))
	option.add_theme_stylebox_override("normal", _stylebox(Color(1.0, 0.998, 0.990, 1.0), Color(0.416, 0.263, 0.122, 0.12), 1, 9, 5))
	option.add_theme_stylebox_override("hover", _stylebox(Color(1.0, 0.970, 0.900, 1.0), Color(0.780, 0.420, 0.137, 0.20), 1, 9, 5))
	option.add_theme_stylebox_override("pressed", _stylebox(Color(1.0, 0.936, 0.760, 1.0), Color(0.965, 0.714, 0.243, 0.54), 1, 9, 5))
	option.add_theme_stylebox_override("focus", _stylebox(Color(1.0, 0.998, 0.990, 1.0), Color(0.965, 0.714, 0.243, 0.76), 2, 9, 5))
	option.add_theme_color_override("font_color", TEXT_INK)
	option.add_theme_color_override("font_hover_color", TEXT_INK)
	option.add_theme_color_override("font_pressed_color", TEXT_INK)
	option.add_theme_color_override("font_focus_color", TEXT_INK)
	option.add_theme_color_override("font_hover_pressed_color", TEXT_INK)
	option.add_theme_color_override("font_disabled_color", Color(TEXT_MUTED.r, TEXT_MUTED.g, TEXT_MUTED.b, 0.55))
	option.add_theme_font_size_override("font_size", 13)
	option.add_theme_icon_override("arrow", _make_dropdown_arrow())
	_style_option_popup(option)


func _style_form_control(control: Control) -> void:
	if control is OptionButton:
		var option := control as OptionButton
		_style_option_button(option)
	elif control is SpinBox:
		var spin := control as SpinBox
		spin.add_theme_font_size_override("font_size", 14)
		spin.add_theme_color_override("font_color", TEXT_INK)
		spin.custom_minimum_size = Vector2(maxf(spin.custom_minimum_size.x, 92), maxf(spin.custom_minimum_size.y, 32))
		var line_edit := spin.get_line_edit()
		line_edit.custom_minimum_size = Vector2(0, 32)
		line_edit.add_theme_stylebox_override("normal", _stylebox(Color(1.0, 0.998, 0.990, 1.0), Color(0.416, 0.263, 0.122, 0.12), 1, 9, 5))
		line_edit.add_theme_stylebox_override("read_only", _stylebox(Color(1.0, 0.972, 0.902, 0.72), Color(0.416, 0.263, 0.122, 0.08), 1, 9, 5))
		line_edit.add_theme_stylebox_override("focus", _stylebox(Color(1.0, 0.998, 0.990, 1.0), Color(0.965, 0.714, 0.243, 0.76), 2, 9, 5))
		line_edit.add_theme_color_override("font_color", TEXT_INK)
		line_edit.add_theme_color_override("font_uneditable_color", Color(TEXT_MUTED.r, TEXT_MUTED.g, TEXT_MUTED.b, 0.82))
	elif control is ItemList:
		var item_list := control as ItemList
		item_list.add_theme_stylebox_override("panel", _stylebox(Color(1.0, 0.990, 0.964, 1.0), BORDER_WARM, 1, 12, 8))
		item_list.add_theme_stylebox_override("hovered", _stylebox(Color(1.0, 0.960, 0.842, 1.0), Color(0.965, 0.714, 0.243, 0.22), 1, 10, 8))
		item_list.add_theme_stylebox_override("selected", _stylebox(Color(1.0, 0.914, 0.644, 1.0), Color(0.780, 0.420, 0.137, 0.40), 1, 10, 8))
		item_list.add_theme_stylebox_override("selected_focus", _stylebox(Color(1.0, 0.890, 0.560, 1.0), Color(0.780, 0.420, 0.137, 0.64), 1, 10, 8))
		item_list.add_theme_stylebox_override("focus", _stylebox(Color(0, 0, 0, 0), ACCENT_COIN, 2, 12, 8))
		item_list.add_theme_font_size_override("font_size", 15)
		item_list.add_theme_color_override("font_color", TEXT_INK)
		item_list.add_theme_color_override("font_selected_color", TEXT_INK)
		item_list.add_theme_color_override("guide_color", Color(0, 0, 0, 0))
		item_list.add_theme_color_override("font_hovered_color", TEXT_INK)
		item_list.add_theme_color_override("font_hovered_selected_color", TEXT_INK)


func _style_option_popup(option: OptionButton) -> void:
	var popup := option.get_popup()
	if popup == null:
		return
	popup.transparent_bg = true
	popup.borderless = true
	popup.min_size = Vector2i(int(maxf(option.size.x, option.custom_minimum_size.x)), 0)
	popup.add_theme_stylebox_override("panel", _stylebox(Color(1.0, 0.992, 0.965, 0.995), Color(0.416, 0.263, 0.122, 0.14), 1, 11, 6, Color(0.360, 0.184, 0.047, 0.12), 7))
	popup.add_theme_stylebox_override("hover", _stylebox(Color(1.0, 0.930, 0.735, 0.88), Color(0.965, 0.714, 0.243, 0.30), 1, 8, 5))
	popup.add_theme_stylebox_override("separator", _stylebox(Color(0.416, 0.263, 0.122, 0.12), Color(0, 0, 0, 0), 0, 1, 1))
	popup.add_theme_color_override("font_color", TEXT_INK)
	popup.add_theme_color_override("font_hover_color", TEXT_INK)
	popup.add_theme_color_override("font_pressed_color", TEXT_INK)
	popup.add_theme_color_override("font_hover_pressed_color", TEXT_INK)
	popup.add_theme_color_override("font_checked_color", ACCENT_ORANGE)
	popup.add_theme_color_override("font_disabled_color", Color(TEXT_MUTED.r, TEXT_MUTED.g, TEXT_MUTED.b, 0.55))
	popup.add_theme_constant_override("item_min_height", 28)
	popup.add_theme_constant_override("item_start_padding", 8)
	popup.add_theme_constant_override("item_end_padding", 8)
	popup.add_theme_constant_override("h_separation", 6)
	popup.add_theme_constant_override("v_separation", 1)
	popup.add_theme_constant_override("indent", 4)
	popup.add_theme_font_size_override("font_size", 13)
	popup.add_theme_icon_override("checked", _make_popup_check_icon(true))
	popup.add_theme_icon_override("radio_checked", _make_popup_check_icon(true))
	popup.add_theme_icon_override("unchecked", _make_popup_check_icon(false))
	popup.add_theme_icon_override("radio_unchecked", _make_popup_check_icon(false))


func _build_welcome_page() -> Control:
	var page := _new_page("Welcome")
	page.name = "Welcome"
	page.alignment = BoxContainer.ALIGNMENT_CENTER

	var content := VBoxContainer.new()
	content.name = "WizardWelcomeContent"
	content.alignment = BoxContainer.ALIGNMENT_CENTER
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 8)
	page.add_child(content)

	var title_label := _add_label(content, "开始配置桌面小挂件")
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 22)
	title_label.add_theme_color_override("font_color", TEXT_INK)
	var subtitle := _add_label(content, "让橘猫陪你看见今天赚了多少，也让金币小票保持轻巧顺手。")
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 13)
	welcome_preview = _add_pet_preview(content)
	welcome_preview.custom_minimum_size = Vector2(0, 132)
	return page


func _build_salary_page() -> Control:
	var page := _new_page("Salary")
	page.name = "Salary"
	var title_label := _add_label(page, "配置收入")
	title_label.add_theme_font_size_override("font_size", 21)
	title_label.add_theme_color_override("font_color", TEXT_INK)
	var subtitle := _add_label(page, "这会决定金币小票的计算方式。")
	subtitle.add_theme_font_size_override("font_size", 13)

	var rows := VBoxContainer.new()
	rows.name = "WizardSalaryRows"
	rows.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rows.add_theme_constant_override("separation", 2)
	page.add_child(rows)

	salary_input = _new_spin(0, 999999, 1, 108)
	_add_field_row(rows, "月薪", salary_input)

	rest_mode_option = OptionButton.new()
	rest_mode_option.add_item("双休")
	rest_mode_option.add_item("单休")
	_style_form_control(rest_mode_option)
	_add_field_row(rows, "休息模式", rest_mode_option)

	hours_input = _new_spin(0, 24, 0.25, 96)
	hours_input.editable = false
	_add_field_row(rows, "每日工作小时数", hours_input)

	var start_row := _new_time_controls()
	start_hour_input = start_row[0]
	start_min_input = start_row[1]
	_add_field_row(rows, "上班时间", start_row[2])

	var end_row := _new_time_controls()
	end_hour_input = end_row[0]
	end_min_input = end_row[1]
	_add_field_row(rows, "下班时间", end_row[2])
	_connect_time_inputs()
	return page


func _build_pet_page() -> Control:
	var page := _new_page("PetSelect")
	page.name = "PetSelect"
	var title_label := _add_label(page, "选择伙伴")
	title_label.add_theme_font_size_override("font_size", 21)
	title_label.add_theme_color_override("font_color", TEXT_INK)
	var subtitle := _add_label(page, "默认使用橘猫 v2，也可以保留旧素材作为回退。")
	subtitle.add_theme_font_size_override("font_size", 13)
	pet_preview = _add_pet_preview(page)
	pet_preview.custom_minimum_size = Vector2(0, 96)
	var rows := VBoxContainer.new()
	rows.name = "WizardPetRows"
	rows.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rows.add_theme_constant_override("separation", 2)
	page.add_child(rows)
	pet_list = ItemList.new()
	pet_list.custom_minimum_size = Vector2(0, 96)
	_style_form_control(pet_list)
	rows.add_child(pet_list)
	pet_list.item_selected.connect(_on_pet_selected)
	return page


func _build_confirm_page() -> Control:
	var page := _new_page("Confirm")
	page.name = "Confirm"
	var title_label := _add_label(page, "确认设置")
	title_label.add_theme_font_size_override("font_size", 21)
	title_label.add_theme_color_override("font_color", TEXT_INK)
	var subtitle := _add_label(page, "检查无误后，就可以开始让金币小票工作。")
	subtitle.add_theme_font_size_override("font_size", 13)

	var rows := VBoxContainer.new()
	rows.name = "WizardConfirmRows"
	rows.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rows.add_theme_constant_override("separation", 2)
	page.add_child(rows)
	_summary_value_labels.clear()
	_summary_value_labels["salary"] = _add_summary_row(rows, "月薪", "")
	_summary_value_labels["rest_mode"] = _add_summary_row(rows, "休息模式", "")
	_summary_value_labels["hours"] = _add_summary_row(rows, "每日工作小时数", "")
	_summary_value_labels["time"] = _add_summary_row(rows, "工作时间", "")
	_summary_value_labels["pet"] = _add_summary_row(rows, "伙伴", "")

	summary_label = Label.new()
	summary_label.text = "完成后也可以在设置里再次修改。"
	summary_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	summary_label.add_theme_font_size_override("font_size", 13)
	summary_label.add_theme_color_override("font_color", TEXT_MUTED)
	page.add_child(summary_label)
	return page


func _add_label(parent: Control, text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", 16)
	label.add_theme_color_override("font_color", TEXT_MUTED)
	parent.add_child(label)
	return label


func _new_spin(min_value: float, max_value: float, step: float, width: float = 108.0) -> SpinBox:
	var spin := SpinBox.new()
	spin.min_value = min_value
	spin.max_value = max_value
	spin.step = step
	spin.custom_minimum_size = Vector2(width, 34)
	_style_form_control(spin)
	return spin


func _add_spin(parent: Control, min_value: float, max_value: float, step: float) -> SpinBox:
	var spin := _new_spin(min_value, max_value, step, 108)
	parent.add_child(spin)
	return spin


func _add_field_row(parent: Control, label_text: String, control: Control) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.custom_minimum_size = Vector2(0, 42)
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 12)
	parent.add_child(row)

	var label := Label.new()
	label.text = label_text
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 15)
	label.add_theme_color_override("font_color", TEXT_INK)
	row.add_child(label)

	control.size_flags_horizontal = Control.SIZE_SHRINK_END
	row.add_child(control)
	return row


func _add_summary_row(parent: Control, label_text: String, value_text: String) -> Label:
	var value := Label.new()
	value.text = value_text
	value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	value.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	value.size_flags_horizontal = Control.SIZE_SHRINK_END
	value.add_theme_font_size_override("font_size", 15)
	value.add_theme_color_override("font_color", TEXT_INK)
	_add_field_row(parent, label_text, value)
	return value


func _new_time_controls() -> Array:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	var hour := _new_spin(0, 23, 1, 66)
	var minute := _new_spin(0, 59, 1, 66)
	row.add_child(hour)
	var colon := Label.new()
	colon.text = ":"
	colon.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	colon.add_theme_font_size_override("font_size", 15)
	colon.add_theme_color_override("font_color", TEXT_MUTED)
	row.add_child(colon)
	row.add_child(minute)
	return [hour, minute, row]


func _add_time_row(parent: Control) -> Array[SpinBox]:
	var controls := _new_time_controls()
	parent.add_child(controls[2])
	return [controls[0], controls[1]]


func _make_dropdown_arrow() -> Texture2D:
	const WIDTH := 14
	const HEIGHT := 10
	var image := Image.create_empty(WIDTH, HEIGHT, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	var color := Color(TEXT_MUTED.r, TEXT_MUTED.g, TEXT_MUTED.b, 0.86)
	for y in range(4):
		var start := 3 + y
		var finish := WIDTH - 4 - y
		for x in range(start, finish + 1):
			image.set_pixel(x, 3 + y, color)
	return ImageTexture.create_from_image(image)


func _make_popup_check_icon(visible: bool) -> Texture2D:
	const SIZE := 12
	var image := Image.create_empty(SIZE, SIZE, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	if not visible:
		return ImageTexture.create_from_image(image)
	var color := ACCENT_ORANGE
	for i in range(3):
		image.set_pixel(3 + i, 6 + i, color)
		image.set_pixel(4 + i, 6 + i, color)
	for i in range(5):
		image.set_pixel(6 + i, 8 - i, color)
		image.set_pixel(7 + i, 8 - i, color)
	return ImageTexture.create_from_image(image)


func _connect_time_inputs() -> void:
	for input in [start_hour_input, start_min_input, end_hour_input, end_min_input]:
		input.value_changed.connect(_on_time_input_changed)


func _on_time_input_changed(_value: float) -> void:
	_update_hours_preview()


func _update_hours_preview() -> void:
	if hours_input == null:
		return
	hours_input.value = _calculate_work_hours()


func _calculate_work_hours() -> float:
	var start_min := int(start_hour_input.value) * 60 + int(start_min_input.value)
	var end_min := int(end_hour_input.value) * 60 + int(end_min_input.value)
	if end_min <= start_min:
		return 0.0
	return float(end_min - start_min) / 60.0


func _add_pet_preview(parent: Control) -> TextureRect:
	var preview := TextureRect.new()
	preview.custom_minimum_size = Vector2(0, 118)
	preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	parent.add_child(preview)
	return preview


func _load_defaults() -> void:
	salary_input.value = float(Config.get_value("monthly_salary", 0))
	rest_mode_option.select(0 if String(Config.get_value("rest_mode", "double")) == "double" else 1)
	var st := String(Config.get_value("work_start_time", "09:00")).split(":")
	start_hour_input.value = int(st[0]) if st.size() > 0 else 9
	start_min_input.value = int(st[1]) if st.size() > 1 else 0
	var et := String(Config.get_value("work_end_time", "18:00")).split(":")
	end_hour_input.value = int(et[0]) if et.size() > 0 else 18
	end_min_input.value = int(et[1]) if et.size() > 1 else 0
	_update_hours_preview()


func _populate_pets() -> void:
	pet_list.clear()
	var pets := PetManager.get_available_pets()
	for pet in pets:
		pet_list.add_item(pet.display_name)
	if pets.size() > 0:
		pet_list.select(0)
		PetManager.switch_pet(pets[0].pet_id)
		_set_preview_pet(pets[0])


func _show_step(step: int) -> void:
	_current_step = clampi(step, 1, 4)
	for i in range(_pages.size()):
		_pages[i].visible = i == _current_step - 1
	prev_btn.visible = _current_step > 1
	next_btn.text = "开始赚钱！" if _current_step == 4 else "下一步"
	if _current_step == 4:
		_update_summary()


func _on_prev() -> void:
	_show_step(_current_step - 1)


func _on_next() -> void:
	if _current_step < 4:
		_show_step(_current_step + 1)
	else:
		_finish()


func _on_pet_selected(idx: int) -> void:
	var pets := PetManager.get_available_pets()
	if idx >= 0 and idx < pets.size():
		PetManager.switch_pet(pets[idx].pet_id)
		_set_preview_pet(pets[idx])


func _set_preview_pet(pet: PetResource) -> void:
	var texture: Texture2D = null
	if pet != null and pet.sprite_frames != null and pet.sprite_frames.has_animation("idle"):
		texture = pet.sprite_frames.get_frame_texture("idle", 0)
	if welcome_preview != null:
		welcome_preview.texture = texture
	if pet_preview != null:
		pet_preview.texture = texture


func _update_summary() -> void:
	var rm_text := "双休" if rest_mode_option.selected == 0 else "单休"
	var time_text := "%02d:%02d - %02d:%02d" % [
		int(start_hour_input.value), int(start_min_input.value),
		int(end_hour_input.value), int(end_min_input.value)
	]
	var pet_name := "小猫"
	var selected := pet_list.get_selected_items()
	if selected.size() > 0:
		var pets := PetManager.get_available_pets()
		if int(selected[0]) < pets.size():
			pet_name = pets[int(selected[0])].display_name
	if _summary_value_labels.has("salary"):
		(_summary_value_labels["salary"] as Label).text = "¥%d" % int(salary_input.value)
	if _summary_value_labels.has("rest_mode"):
		(_summary_value_labels["rest_mode"] as Label).text = rm_text
	if _summary_value_labels.has("hours"):
		(_summary_value_labels["hours"] as Label).text = "%.2f 小时" % _calculate_work_hours()
	if _summary_value_labels.has("time"):
		(_summary_value_labels["time"] as Label).text = time_text
	if _summary_value_labels.has("pet"):
		(_summary_value_labels["pet"] as Label).text = pet_name


func _finish() -> void:
	Config.set_value("monthly_salary", float(salary_input.value))
	Config.set_value("rest_mode", "single" if rest_mode_option.selected == 1 else "double")
	Config.set_value("work_start_time", "%02d:%02d" % [int(start_hour_input.value), int(start_min_input.value)])
	Config.set_value("work_end_time", "%02d:%02d" % [int(end_hour_input.value), int(end_min_input.value)])
	Config.set_value("work_hours_per_day", _calculate_work_hours())
	var selected := pet_list.get_selected_items()
	if selected.size() > 0:
		var pets := PetManager.get_available_pets()
		if int(selected[0]) < pets.size():
			Config.set_value("pet_id", pets[int(selected[0])].pet_id)
	Config.save()
	finished.emit()
	queue_free()


func _on_cancel() -> void:
	queue_free()
