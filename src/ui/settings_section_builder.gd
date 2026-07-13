class_name SettingsSectionBuilder
extends RefCounted

const WarmControlThemeScript := preload("res://src/ui/warm_control_theme.gd")
const TEXT_INK := Color(0.227, 0.153, 0.098, 1.0)
const TEXT_MUTED := Color(0.550, 0.420, 0.298, 1.0)
const ACCENT_ORANGE := Color(0.780, 0.420, 0.137, 1.0)
const CONTROL_WIDTH := 128

var _theme: RefCounted = WarmControlThemeScript.new()
var _style_form_control: Callable
var _control_minimum_size: Callable
var _add_switch_proxy: Callable


func configure(style_form_control: Callable, control_minimum_size: Callable, add_switch_proxy: Callable) -> void:
	_style_form_control = style_form_control
	_control_minimum_size = control_minimum_size
	_add_switch_proxy = add_switch_proxy


func new_tab(tab_name: String) -> ScrollContainer:
	var scroll := ScrollContainer.new()
	scroll.name = tab_name
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.follow_focus = true
	scroll.mouse_filter = Control.MOUSE_FILTER_STOP
	var vbar := scroll.get_v_scroll_bar()
	vbar.custom_minimum_size = Vector2(5, 0)
	vbar.add_theme_stylebox_override("scroll", _theme.stylebox(Color(0, 0, 0, 0), Color(0, 0, 0, 0), 0, 3, 0))
	vbar.add_theme_stylebox_override("grabber", _theme.stylebox(Color(0.416, 0.263, 0.122, 0.18), Color(0, 0, 0, 0), 0, 3, 0))
	vbar.add_theme_stylebox_override("grabber_highlight", _theme.stylebox(Color(0.416, 0.263, 0.122, 0.30), Color(0, 0, 0, 0), 0, 3, 0))
	vbar.add_theme_stylebox_override("grabber_pressed", _theme.stylebox(Color(0.416, 0.263, 0.122, 0.38), Color(0, 0, 0, 0), 0, 3, 0))
	return scroll


func new_vbox(parent: Control) -> VBoxContainer:
	var container_parent := parent
	if parent is ScrollContainer:
		var margin := MarginContainer.new()
		margin.name = "TabContentMargin"
		margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		margin.size_flags_vertical = Control.SIZE_EXPAND_FILL
		margin.add_theme_constant_override("margin_left", 0)
		margin.add_theme_constant_override("margin_top", 0)
		margin.add_theme_constant_override("margin_right", 8)
		margin.add_theme_constant_override("margin_bottom", 4)
		parent.add_child(margin)
		container_parent = margin
	var box := VBoxContainer.new()
	box.name = "VBox"
	box.add_theme_constant_override("separation", 1)
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	container_parent.add_child(box)
	return box


func add_page_heading(parent: Control, title: String, hint: String) -> void:
	var row := VBoxContainer.new()
	row.name = "%sPageHeading" % title
	row.custom_minimum_size = Vector2(0, 34)
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", 2)
	parent.add_child(row)
	var title_label := Label.new()
	title_label.text = title
	title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_label.add_theme_font_size_override("font_size", 20)
	title_label.add_theme_color_override("font_color", TEXT_INK)
	row.add_child(title_label)
	var hint_label := Label.new()
	hint_label.text = hint
	hint_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint_label.add_theme_font_size_override("font_size", 12)
	hint_label.add_theme_color_override("font_color", TEXT_MUTED)
	row.add_child(hint_label)


func add_section_heading(parent: Control, title: String) -> void:
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 3)
	parent.add_child(spacer)
	var label := Label.new()
	label.name = "SettingsSectionHeading"
	label.text = title
	label.add_theme_font_size_override("font_size", 12)
	label.add_theme_color_override("font_color", ACCENT_ORANGE)
	parent.add_child(label)


func add_setting_card(parent: Control, title: String, description: String = "") -> VBoxContainer:
	var card := PanelContainer.new()
	card.name = "SettingCard"
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.custom_minimum_size = Vector2(0, 48)
	card.add_theme_stylebox_override("panel", _theme.stylebox(Color(1.0, 0.998, 0.988, 0.16), Color(0.416, 0.263, 0.122, 0.04), 0, 6, 4))
	parent.add_child(card)
	var box := VBoxContainer.new()
	box.name = "SettingCardBody"
	box.add_theme_constant_override("separation", 2)
	card.add_child(box)
	var title_label := Label.new()
	title_label.name = "SettingCardTitle"
	title_label.text = title
	title_label.add_theme_font_size_override("font_size", 15)
	title_label.add_theme_color_override("font_color", TEXT_INK)
	title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(title_label)
	if not description.is_empty():
		var description_label := Label.new()
		description_label.name = "SettingCardDescription"
		description_label.text = description
		description_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		description_label.add_theme_font_size_override("font_size", 13)
		description_label.add_theme_color_override("font_color", TEXT_MUTED)
		box.add_child(description_label)
	return box


func add_control_row(parent: Control, title: String, control: Control) -> HBoxContainer:
	return add_control_card(parent, title, "", control)


func add_control_card(parent: Control, title: String, _description: String, control: Control) -> HBoxContainer:
	var row_panel := PanelContainer.new()
	row_panel.name = "SettingRow"
	row_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row_panel.custom_minimum_size = Vector2(0, 38)
	row_panel.add_theme_stylebox_override("panel", _theme.stylebox(Color(1.0, 0.998, 0.988, 0.0), Color(0, 0, 0, 0), 0, 0, 2))
	parent.add_child(row_panel)
	var row := HBoxContainer.new()
	row.name = "SettingControlRow"
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", 10)
	row_panel.add_child(row)
	var copy := VBoxContainer.new()
	copy.name = "SettingCopy"
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	copy.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	copy.add_theme_constant_override("separation", 2)
	row.add_child(copy)
	var title_label := Label.new()
	title_label.name = "SettingCardTitle"
	title_label.text = title
	title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 14)
	title_label.add_theme_color_override("font_color", TEXT_INK)
	copy.add_child(title_label)
	if control is CheckButton or control is CheckBox:
		if _add_switch_proxy.is_valid():
			_add_switch_proxy.call(row, control as BaseButton)
		else:
			row.add_child(control)
		return row
	if _style_form_control.is_valid():
		_style_form_control.call(control)
	if _control_minimum_size.is_valid():
		control.custom_minimum_size = _control_minimum_size.call(control)
	control.size_flags_horizontal = Control.SIZE_SHRINK_END
	control.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(control)
	return row


func add_note_block(parent: Control, title: String, lines: Array[String]) -> void:
	if lines.is_empty():
		return
	var block := VBoxContainer.new()
	block.name = "SettingsNoteBlock"
	block.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	block.add_theme_constant_override("separation", 3)
	parent.add_child(block)
	add_note_title(block, title)
	for line in lines:
		if not line.is_empty():
			block.add_child(new_note_text(line))


func add_note_label(parent: Control, title: String, label: Label) -> void:
	var block := VBoxContainer.new()
	block.name = "SettingsNoteBlock"
	block.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	block.add_theme_constant_override("separation", 3)
	parent.add_child(block)
	add_note_title(block, title)
	style_note_label(label)
	block.add_child(label)


func add_note_title(parent: Control, title: String) -> void:
	var divider := ColorRect.new()
	divider.name = "SettingsNoteDivider"
	divider.custom_minimum_size = Vector2(0, 1)
	divider.color = Color(0.416, 0.263, 0.122, 0.08)
	parent.add_child(divider)
	var label := Label.new()
	label.name = "SettingsNoteTitle"
	label.text = title
	label.add_theme_font_size_override("font_size", 12)
	label.add_theme_color_override("font_color", Color(0.550, 0.420, 0.298, 0.82))
	parent.add_child(label)


func new_note_text(text: String) -> Label:
	var label := Label.new()
	label.text = text
	style_note_label(label)
	return label


func style_note_label(label: Label) -> void:
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.add_theme_font_size_override("font_size", 12)
	label.add_theme_color_override("font_color", Color(TEXT_MUTED.r, TEXT_MUTED.g, TEXT_MUTED.b, 0.84))


func wrap_control(parent: Control, control: Control, title: String, description: String) -> void:
	parent.remove_child(control)
	add_control_card(parent, title, description, control)


func add_checkbox_row(parent: Control, title: String, description: String) -> CheckBox:
	var checkbox := CheckBox.new()
	checkbox.text = ""
	add_control_card(parent, title, description, checkbox)
	return checkbox


func control_minimum_size(control: Control) -> Vector2:
	if control is HBoxContainer and control.name == "SliderRow":
		return Vector2(236, 32)
	if control is HBoxContainer and control.name == "TimeRow":
		return Vector2(148, 32)
	if control is ItemList:
		return Vector2(CONTROL_WIDTH + 110, 98)
	if control is Button:
		return Vector2(104, 32)
	if control is OptionButton:
		return Vector2(CONTROL_WIDTH, 32)
	if control is SpinBox:
		return Vector2(92, 32)
	if control is CheckButton or control is CheckBox:
		return Vector2(42, 24)
	return Vector2(CONTROL_WIDTH, 34)
