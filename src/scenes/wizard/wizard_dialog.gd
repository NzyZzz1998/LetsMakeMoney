# src/scenes/wizard/wizard_dialog.gd
extends ConfirmationDialog

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
	title = "开始配置桌面小挂件"
	transparent_bg = true
	borderless = true
	min_size = Vector2i(680, 520)
	get_ok_button().visible = false
	get_cancel_button().visible = false
	close_requested.connect(_on_cancel)
	_build_ui()
	_load_defaults()
	_populate_pets()
	_show_step(1)


func _new_page(page_name: String) -> VBoxContainer:
	var page := VBoxContainer.new()
	page.name = page_name
	page.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	page.size_flags_vertical = Control.SIZE_EXPAND_FILL
	page.add_theme_constant_override("separation", 12)
	page.add_theme_stylebox_override("panel", _stylebox(SURFACE_CARD, BORDER_WARM, 1, 16, 16, Color(0.360, 0.184, 0.047, 0.08), 4))
	return page


func _build_ui() -> void:
	var surface := PanelContainer.new()
	surface.name = "WizardSurface"
	surface.set_anchors_preset(Control.PRESET_FULL_RECT)
	surface.add_theme_stylebox_override("panel", _stylebox(SURFACE_APP, BORDER_WARM, 1, 20, 18, SHADOW_WARM, 12))
	add_child(surface)

	var box := VBoxContainer.new()
	box.name = "WizardRoot"
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation", 14)
	surface.add_child(box)

	var welcome := _build_welcome_page()
	var salary := _build_salary_page()
	var pet := _build_pet_page()
	var confirm := _build_confirm_page()
	_pages = [welcome, salary, pet, confirm]
	for page in _pages:
		box.add_child(page)

	var nav := HBoxContainer.new()
	nav.alignment = BoxContainer.ALIGNMENT_END
	nav.add_theme_constant_override("separation", 8)
	box.add_child(nav)
	prev_btn = Button.new()
	prev_btn.text = "上一步"
	next_btn = Button.new()
	next_btn.text = "下一步"
	prev_btn.custom_minimum_size = Vector2(110, 42)
	next_btn.custom_minimum_size = Vector2(126, 42)
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


func _style_form_control(control: Control) -> void:
	if control is OptionButton:
		var option := control as OptionButton
		_style_button(option)
		option.custom_minimum_size = Vector2(maxf(option.custom_minimum_size.x, 220), maxf(option.custom_minimum_size.y, 40))
	elif control is SpinBox:
		var spin := control as SpinBox
		spin.add_theme_font_size_override("font_size", 16)
		spin.add_theme_color_override("font_color", TEXT_INK)
		spin.get_line_edit().add_theme_stylebox_override("normal", _stylebox(Color(1.0, 0.990, 0.964, 1.0), BORDER_WARM, 1, 12, 8))
		spin.get_line_edit().add_theme_color_override("font_color", TEXT_INK)
	elif control is ItemList:
		var item_list := control as ItemList
		item_list.add_theme_stylebox_override("panel", _stylebox(Color(1.0, 0.990, 0.964, 1.0), BORDER_WARM, 1, 14, 10))
		item_list.add_theme_stylebox_override("focus", _stylebox(Color(0, 0, 0, 0), ACCENT_COIN, 2, 14, 10))
		item_list.add_theme_font_size_override("font_size", 16)
		item_list.add_theme_color_override("font_color", TEXT_INK)
		item_list.add_theme_color_override("font_selected_color", TEXT_INK)


func _build_welcome_page() -> Control:
	var page := _new_page("Welcome")
	page.name = "Welcome"
	var title_label := _add_label(page, "开始配置桌面小挂件")
	title_label.add_theme_font_size_override("font_size", 26)
	title_label.add_theme_color_override("font_color", TEXT_INK)
	_add_label(page, "让橘猫陪你看见今天赚了多少，也让金币小票保持轻巧顺手。")
	welcome_preview = _add_pet_preview(page)
	return page


func _build_salary_page() -> Control:
	var page := _new_page("Salary")
	page.name = "Salary"
	_add_label(page, "月薪（元）")
	salary_input = _add_spin(page, 0, 999999, 1)
	_add_label(page, "休息模式")
	rest_mode_option = OptionButton.new()
	rest_mode_option.add_item("双休")
	rest_mode_option.add_item("单休")
	_style_form_control(rest_mode_option)
	page.add_child(rest_mode_option)
	_add_label(page, "每日工作小时数（由上下班时间自动计算）")
	hours_input = _add_spin(page, 0, 24, 0.25)
	hours_input.editable = false
	_add_label(page, "上班时间")
	var start_row := _add_time_row(page)
	start_hour_input = start_row[0]
	start_min_input = start_row[1]
	_add_label(page, "下班时间")
	var end_row := _add_time_row(page)
	end_hour_input = end_row[0]
	end_min_input = end_row[1]
	_connect_time_inputs()
	return page


func _build_pet_page() -> Control:
	var page := _new_page("PetSelect")
	page.name = "PetSelect"
	_add_label(page, "选择你的伙伴")
	pet_preview = _add_pet_preview(page)
	pet_list = ItemList.new()
	pet_list.custom_minimum_size = Vector2(0, 160)
	_style_form_control(pet_list)
	page.add_child(pet_list)
	pet_list.item_selected.connect(_on_pet_selected)
	return page


func _build_confirm_page() -> Control:
	var page := _new_page("Confirm")
	page.name = "Confirm"
	_add_label(page, "确认设置")
	summary_label = Label.new()
	summary_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	summary_label.add_theme_font_size_override("font_size", 17)
	summary_label.add_theme_color_override("font_color", TEXT_INK)
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


func _add_spin(parent: Control, min_value: float, max_value: float, step: float) -> SpinBox:
	var spin := SpinBox.new()
	spin.min_value = min_value
	spin.max_value = max_value
	spin.step = step
	spin.custom_minimum_size = Vector2(142, 40)
	_style_form_control(spin)
	parent.add_child(spin)
	return spin


func _add_time_row(parent: Control) -> Array[SpinBox]:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	parent.add_child(row)
	var hour := _add_spin(row, 0, 23, 1)
	hour.custom_minimum_size = Vector2(80, 0)
	_add_label(row, ":")
	var minute := _add_spin(row, 0, 59, 1)
	minute.custom_minimum_size = Vector2(80, 0)
	return [hour, minute]


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
	preview.custom_minimum_size = Vector2(0, 126)
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
	summary_label.text = "月薪 ¥%d\n%s，每天 %.2f 小时\n工作时间 %s\n伙伴：%s" % [
		int(salary_input.value), rm_text, _calculate_work_hours(), time_text, pet_name
	]


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
