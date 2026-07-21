# src/scenes/wizard/wizard_dialog.gd
extends Control

signal finished

const WarmControlThemeScript := preload("res://src/ui/warm_control_theme.gd")
const SalaryScheduleCalculatorScript := preload("res://src/utils/salary_schedule_calculator.gd")
const ConfigurationDraftScript := preload("res://src/utils/configuration_draft.gd")

var _current_step: int = 1
var _pages: Array[Control] = []

var salary_input: SpinBox
var rest_mode_option: OptionButton
var alternating_week_type_option: OptionButton
var alternating_week_type_row: Control
var hours_input: SpinBox
var lunch_duration_input: SpinBox
var start_hour_input: SpinBox
var start_min_input: SpinBox
var lunch_start_hour_input: SpinBox
var lunch_start_min_input: SpinBox
var lunch_end_hour_input: SpinBox
var lunch_end_min_input: SpinBox
var end_hour_input: SpinBox
var end_min_input: SpinBox
var pet_list: ItemList
var welcome_preview: TextureRect
var pet_preview: TextureRect
var summary_label: Label
var prev_btn: Button
var next_btn: Button
var _summary_value_labels: Dictionary = {}
var _warm_theme: RefCounted = WarmControlThemeScript.new()
var _close_reason: String = "closed"
var _entry_config_snapshot: Dictionary = {}
var _entry_pet_id: String = ""
var _entry_state_restored: bool = false
var _configuration_draft: RefCounted = ConfigurationDraftScript.new()
var _schedule_section: Control
var _lunch_section: Control
var _inferred_section: Control
var _updating_draft_ui: bool = false
var _step_markers: Array[Label] = []
var _step_titles: Array[Label] = []
var _step_counter_label: Label
var _workdays_preview_label: Label
var _end_time_preview_label: Label
var _lunch_interval_preview_label: Label
var _lunch_start_controls: Control

const SURFACE_APP := Color(0.910, 0.906, 0.882, 1.0)
const SURFACE_CARD := Color(1.000, 0.992, 0.980, 1.0)
const SURFACE_WARM := Color(0.984, 0.961, 0.914, 1.0)
const SURFACE_COOL := Color(0.945, 0.957, 0.937, 1.0)
const SURFACE_SELECTED := Color(0.988, 0.910, 0.702, 1.0)
const TEXT_INK := Color(0.188, 0.169, 0.149, 1.0)
const TEXT_MUTED := Color(0.463, 0.412, 0.365, 1.0)
const TEXT_SUBTLE := Color(0.608, 0.561, 0.518, 1.0)
const ACCENT_COIN := Color(0.949, 0.706, 0.227, 1.0)
const ACCENT_ORANGE := Color(0.914, 0.471, 0.196, 1.0)
const ACCENT_MINT := Color(0.439, 0.608, 0.455, 1.0)
const BORDER_WARM := Color(0.271, 0.208, 0.153, 0.13)
const SHADOW_WARM := Color(0.188, 0.169, 0.149, 0.10)
const WIZARD_SIZE := Vector2(720, 520)
const STEP_TITLES := ["收入与休息", "上班时间", "午休时长", "确认配置"]


func _ready() -> void:
	theme = _build_wizard_theme()
	custom_minimum_size = WIZARD_SIZE
	mouse_filter = Control.MOUSE_FILTER_STOP
	focus_mode = Control.FOCUS_ALL
	_build_ui()
	_entry_config_snapshot = Config.get_data_snapshot()
	var entry_pet := PetManager.get_current_pet()
	_entry_pet_id = String(entry_pet.pet_id) if entry_pet != null else String(Config.get_value("pet_id", "cat_orange_v2"))
	_load_defaults()
	_populate_pets()
	Platform.write_boot_log("wizard_opened: step=1")
	_show_step(1)


func _exit_tree() -> void:
	if _close_reason != "finished":
		_restore_entry_state(_close_reason)
	Platform.write_boot_log("wizard_closed: reason=%s step=%d" % [_close_reason, _current_step])


func _new_page(page_name: String) -> VBoxContainer:
	var page := VBoxContainer.new()
	page.name = page_name
	page.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	page.size_flags_vertical = Control.SIZE_EXPAND_FILL
	page.add_theme_constant_override("separation", 10)
	return page


func _build_ui() -> void:
	var surface := PanelContainer.new()
	surface.name = "WizardSurface"
	surface.set_anchors_preset(Control.PRESET_FULL_RECT)
	surface.add_theme_stylebox_override("panel", _stylebox(Color(0, 0, 0, 0), Color(0, 0, 0, 0), 0, 0, 0))
	add_child(surface)

	var outer_margin := MarginContainer.new()
	outer_margin.name = "WizardOuterMargin"
	outer_margin.add_theme_constant_override("margin_left", 0)
	outer_margin.add_theme_constant_override("margin_top", 0)
	outer_margin.add_theme_constant_override("margin_right", 0)
	outer_margin.add_theme_constant_override("margin_bottom", 0)
	surface.add_child(outer_margin)

	var shell := PanelContainer.new()
	shell.name = "WizardShell"
	shell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	shell.size_flags_vertical = Control.SIZE_EXPAND_FILL
	shell.clip_contents = true
	shell.add_theme_stylebox_override("panel", _stylebox(SURFACE_CARD, Color(0, 0, 0, 0), 0, 16, 0))
	outer_margin.add_child(shell)

	var shell_row := HBoxContainer.new()
	shell_row.name = "WizardShellRow"
	shell_row.add_theme_constant_override("separation", 0)
	shell.add_child(shell_row)

	var sidebar := _build_step_sidebar()
	shell_row.add_child(sidebar)

	var content_column := VBoxContainer.new()
	content_column.name = "WizardContentColumn"
	content_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_column.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content_column.add_theme_constant_override("separation", 0)
	shell_row.add_child(content_column)

	var top_surface := PanelContainer.new()
	top_surface.name = "WizardTopSurface"
	top_surface.custom_minimum_size = Vector2(0, 50)
	var top_style := _stylebox(Color(0, 0, 0, 0), Color(TEXT_MUTED.r, TEXT_MUTED.g, TEXT_MUTED.b, 0.10), 0, 0, 0)
	top_style.border_width_bottom = 1
	top_surface.add_theme_stylebox_override("panel", top_style)
	content_column.add_child(top_surface)

	var top_margin := MarginContainer.new()
	top_margin.add_theme_constant_override("margin_left", 28)
	top_margin.add_theme_constant_override("margin_right", 14)
	top_surface.add_child(top_margin)

	var top_row := HBoxContainer.new()
	top_row.name = "WizardTopRow"
	top_row.add_theme_constant_override("separation", 8)
	top_margin.add_child(top_row)
	_step_counter_label = Label.new()
	_step_counter_label.name = "WizardStepCounter"
	_step_counter_label.text = "第 1 步，共 4 步"
	_step_counter_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_step_counter_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_step_counter_label.add_theme_font_size_override("font_size", 11)
	_step_counter_label.add_theme_color_override("font_color", TEXT_MUTED)
	top_row.add_child(_step_counter_label)
	var close_button := Button.new()
	close_button.name = "CloseButton"
	close_button.text = "×"
	close_button.custom_minimum_size = Vector2(30, 30)
	close_button.tooltip_text = "关闭"
	close_button.pressed.connect(_on_cancel)
	_warm_theme.style_button(close_button, false, true)
	top_row.add_child(close_button)
	var content_margin := MarginContainer.new()
	content_margin.name = "WizardContentMargin"
	content_margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_margin.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content_margin.add_theme_constant_override("margin_left", 34)
	content_margin.add_theme_constant_override("margin_top", 30)
	content_margin.add_theme_constant_override("margin_right", 34)
	content_margin.add_theme_constant_override("margin_bottom", 0)
	content_column.add_child(content_margin)

	var content_holder := Control.new()
	content_holder.name = "WizardContentPages"
	content_holder.clip_contents = true
	content_holder.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_holder.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content_margin.add_child(content_holder)

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

	var nav_surface := PanelContainer.new()
	nav_surface.name = "WizardActionSurface"
	nav_surface.custom_minimum_size = Vector2(0, 57)
	var nav_style := _stylebox(Color(0.965, 0.969, 0.949, 1.0), Color(TEXT_MUTED.r, TEXT_MUTED.g, TEXT_MUTED.b, 0.10), 0, 0, 0)
	nav_style.border_width_top = 1
	nav_surface.add_theme_stylebox_override("panel", nav_style)
	content_column.add_child(nav_surface)

	var nav_margin := MarginContainer.new()
	nav_margin.name = "WizardActionMargin"
	nav_margin.add_theme_constant_override("margin_left", 24)
	nav_margin.add_theme_constant_override("margin_top", 10)
	nav_margin.add_theme_constant_override("margin_right", 24)
	nav_margin.add_theme_constant_override("margin_bottom", 10)
	nav_surface.add_child(nav_margin)

	var nav := HBoxContainer.new()
	nav.name = "WizardActionRow"
	nav.custom_minimum_size = Vector2(0, 37)
	nav.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	nav.add_theme_constant_override("separation", 8)
	nav_margin.add_child(nav)

	var cancel_btn := Button.new()
	cancel_btn.name = "CancelButton"
	cancel_btn.text = "取消"
	cancel_btn.custom_minimum_size = Vector2(92, 37)
	cancel_btn.pressed.connect(_on_cancel)
	_style_button(cancel_btn)
	nav.add_child(cancel_btn)
	var nav_fill := Control.new()
	nav_fill.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	nav.add_child(nav_fill)

	prev_btn = Button.new()
	prev_btn.text = "上一步"
	next_btn = Button.new()
	next_btn.text = "下一步"
	prev_btn.custom_minimum_size = Vector2(92, 37)
	next_btn.custom_minimum_size = Vector2(92, 37)
	_style_button(prev_btn)
	_style_button(next_btn, true)
	nav.add_child(prev_btn)
	nav.add_child(next_btn)
	prev_btn.pressed.connect(_on_prev)
	next_btn.pressed.connect(_on_next)


func _build_step_sidebar() -> PanelContainer:
	var sidebar := PanelContainer.new()
	sidebar.name = "WizardStepSidebar"
	sidebar.custom_minimum_size.x = 188
	sidebar.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var sidebar_style := _stylebox(Color(0.965, 0.969, 0.949, 1.0), BORDER_WARM, 0, 16, 0)
	sidebar_style.corner_radius_top_right = 0
	sidebar_style.corner_radius_bottom_right = 0
	sidebar_style.border_width_right = 1
	sidebar.add_theme_stylebox_override("panel", sidebar_style)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 22)
	margin.add_theme_constant_override("margin_top", 26)
	margin.add_theme_constant_override("margin_right", 22)
	margin.add_theme_constant_override("margin_bottom", 26)
	sidebar.add_child(margin)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 6)
	margin.add_child(column)

	var title := _add_label(column, "开始配置")
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", TEXT_INK)
	var subtitle := _add_label(column, "四步完成收入进度")
	subtitle.add_theme_font_size_override("font_size", 11)
	subtitle.add_theme_color_override("font_color", TEXT_MUTED)

	var step_spacer := Control.new()
	step_spacer.custom_minimum_size.y = 12
	column.add_child(step_spacer)
	_step_markers.clear()
	_step_titles.clear()
	for index in range(STEP_TITLES.size()):
		var row := HBoxContainer.new()
		row.custom_minimum_size.y = 40
		row.add_theme_constant_override("separation", 10)
		column.add_child(row)
		var marker := Label.new()
		marker.text = str(index + 1)
		marker.custom_minimum_size = Vector2(24, 24)
		marker.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		marker.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		marker.add_theme_font_size_override("font_size", 12)
		row.add_child(marker)
		var label := Label.new()
		label.text = STEP_TITLES[index]
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 12)
		row.add_child(label)
		_step_markers.append(marker)
		_step_titles.append(label)
	var local_fill := Control.new()
	local_fill.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(local_fill)
	var local_note := HBoxContainer.new()
	local_note.name = "WizardLocalNote"
	local_note.add_theme_constant_override("separation", 7)
	column.add_child(local_note)
	var local_check := Label.new()
	local_check.text = "✓"
	local_check.add_theme_font_size_override("font_size", 12)
	local_check.add_theme_color_override("font_color", ACCENT_MINT)
	local_note.add_child(local_check)
	var local_text := Label.new()
	local_text.text = "配置仅保存在本机"
	local_text.add_theme_font_size_override("font_size", 10)
	local_text.add_theme_color_override("font_color", ACCENT_MINT)
	local_note.add_child(local_text)
	return sidebar


func _stylebox(
	bg: Color,
	border: Color,
	border_width: int,
	radius: int,
	padding: int,
	shadow_color: Color = Color(0, 0, 0, 0),
	shadow_size: int = 0
) -> StyleBoxFlat:
	return _warm_theme.stylebox(bg, border, border_width, radius, padding, shadow_color, shadow_size)


func _build_wizard_theme() -> Theme:
	# Font contract lives in WarmControlTheme.build_theme:
	# SystemFont.new()
	# TextServer.FONT_ANTIALIASING_LCD
	# Microsoft YaHei UI
	return _warm_theme.build_theme(14)


func _style_button(button: Button, primary: bool = false) -> void:
	_warm_theme.style_button(button, primary, false)


func _style_option_button(option: OptionButton) -> void:
	# WarmControlTheme preserves the previous popup contract:
	# option.add_theme_icon_override("arrow", _make_dropdown_arrow())
	_warm_theme.style_option_button(option, 124)


func _style_form_control(control: Control) -> void:
	if control is OptionButton:
		var option := control as OptionButton
		_style_option_button(option)
	elif control is SpinBox:
		var spin := control as SpinBox
		# WarmControlTheme preserves the previous read-only contract:
		# line_edit.add_theme_stylebox_override("read_only")
		_warm_theme.style_spin_box(spin, 92)
	elif control is ItemList:
		var item_list := control as ItemList
		item_list.add_theme_stylebox_override("panel", _stylebox(SURFACE_CARD, BORDER_WARM, 1, 12, 8))
		item_list.add_theme_stylebox_override("hovered", _stylebox(SURFACE_COOL, Color(TEXT_MUTED.r, TEXT_MUTED.g, TEXT_MUTED.b, 0.16), 1, 10, 8))
		item_list.add_theme_stylebox_override("selected", _stylebox(SURFACE_SELECTED, Color(ACCENT_COIN.r, ACCENT_COIN.g, ACCENT_COIN.b, 0.28), 1, 10, 8))
		item_list.add_theme_stylebox_override("selected_focus", _stylebox(SURFACE_SELECTED, Color(ACCENT_COIN.r, ACCENT_COIN.g, ACCENT_COIN.b, 0.58), 1, 10, 8))
		item_list.add_theme_stylebox_override("focus", _stylebox(Color(0, 0, 0, 0), ACCENT_COIN, 2, 12, 8))
		item_list.add_theme_font_size_override("font_size", 15)
		item_list.add_theme_color_override("font_color", TEXT_INK)
		item_list.add_theme_color_override("font_selected_color", TEXT_INK)
		item_list.add_theme_color_override("guide_color", Color(0, 0, 0, 0))
		item_list.add_theme_color_override("font_hovered_color", TEXT_INK)
		item_list.add_theme_color_override("font_hovered_selected_color", TEXT_INK)


func _style_option_popup(option: OptionButton) -> void:
	# WarmControlTheme preserves the previous popup contract:
	# option.get_popup()
	# popup.transparent_bg = true
	# popup.add_theme_icon_override("radio_checked", _make_popup_check_icon(true))
	_warm_theme.style_option_popup(option)


func _build_welcome_page() -> Control:
	var page := _new_page("Welcome")
	page.name = "Welcome"
	var title_label := _add_label(page, "先确定你的收入与休息")
	title_label.add_theme_font_size_override("font_size", 22)
	title_label.add_theme_color_override("font_color", TEXT_INK)
	var subtitle := _add_label(page, "月薪与休息模式会用于计算每日收入和本月工作日。")
	subtitle.add_theme_font_size_override("font_size", 12)
	_add_heading_gap(page)

	var task := _new_task_block(page, "收入基准")
	salary_input = _new_spin(0, 999999, 1, 112)
	salary_input.suffix = " 元"
	_add_field_row(task, "月薪", salary_input)
	salary_input.value_changed.connect(_on_salary_value_changed)

	rest_mode_option = OptionButton.new()
	rest_mode_option.add_item("双休")
	rest_mode_option.add_item("单休")
	rest_mode_option.add_item("大小周")
	_style_form_control(rest_mode_option)
	_add_field_row(task, "休息模式", rest_mode_option)
	rest_mode_option.item_selected.connect(_on_rest_mode_selected)

	alternating_week_type_option = OptionButton.new()
	alternating_week_type_option.add_item("本周是大周")
	alternating_week_type_option.add_item("本周是小周")
	_style_form_control(alternating_week_type_option)
	alternating_week_type_row = _add_field_row(task, "本周类型", alternating_week_type_option)
	alternating_week_type_row.visible = false
	alternating_week_type_option.item_selected.connect(_on_alternating_week_type_selected)

	_workdays_preview_label = _add_inference_line(page, "预计本月工作日", "-- 天")
	return page


func _build_salary_page() -> Control:
	var page := _new_page("Salary")
	page.name = "Salary"
	var title_label := _add_label(page, "几点开始工作？")
	title_label.add_theme_font_size_override("font_size", 22)
	title_label.add_theme_color_override("font_color", TEXT_INK)
	var subtitle := _add_label(page, "先确定上班时间，再按 8 小时工作制推算完整安排。")
	subtitle.add_theme_font_size_override("font_size", 12)
	_add_heading_gap(page)

	_schedule_section = _new_task_block(page, "工作起点")
	var start_row := _new_time_controls()
	start_hour_input = start_row[0]
	start_min_input = start_row[1]
	_add_field_row(_schedule_section, "上班时间", start_row[2])

	var hidden_controls := VBoxContainer.new()
	hidden_controls.name = "WizardScheduleCompatibilityControls"
	hidden_controls.visible = false
	page.add_child(hidden_controls)
	var lunch_start_row := _new_time_controls()
	lunch_start_hour_input = lunch_start_row[0]
	lunch_start_min_input = lunch_start_row[1]
	_lunch_start_controls = lunch_start_row[2]

	var lunch_end_row := _new_time_controls()
	lunch_end_hour_input = lunch_end_row[0]
	lunch_end_min_input = lunch_end_row[1]
	hidden_controls.add_child(lunch_end_row[2])

	var end_row := _new_time_controls()
	end_hour_input = end_row[0]
	end_min_input = end_row[1]
	hidden_controls.add_child(end_row[2])

	hours_input = _new_spin(0, 24, 0.01, 96)
	hours_input.editable = false
	hidden_controls.add_child(hours_input)

	_end_time_preview_label = _add_inference_line(page, "预计下班时间", "--:--")
	_connect_time_inputs()
	return page


func _build_pet_page() -> Control:
	var page := _new_page("PetSelect")
	page.name = "PetSelect"
	var title_label := _add_label(page, "午休怎么安排？")
	title_label.add_theme_font_size_override("font_size", 22)
	title_label.add_theme_color_override("font_color", TEXT_INK)
	var subtitle := _add_label(page, "设置开始时间与时长，结束和下班时间会自动推算。")
	subtitle.add_theme_font_size_override("font_size", 12)
	_add_heading_gap(page)

	_lunch_section = _new_task_block(page, "午休安排")
	_add_field_row(_lunch_section, "午休开始", _lunch_start_controls)
	lunch_duration_input = _new_spin(0, 8, 0.5, 112)
	lunch_duration_input.suffix = " 小时"
	_add_field_row(_lunch_section, "午休时长", lunch_duration_input)
	lunch_duration_input.value_changed.connect(_on_lunch_duration_changed)
	_lunch_interval_preview_label = _add_inference_line(page, "预计午休区间", "--:-- 至 --:--")

	pet_list = ItemList.new()
	pet_list.name = "WizardPetCompatibilityList"
	pet_list.visible = false
	_style_form_control(pet_list)
	page.add_child(pet_list)
	pet_list.item_selected.connect(_on_pet_selected)
	return page


func _build_confirm_page() -> Control:
	var page := _new_page("Confirm")
	page.name = "Confirm"
	var title_label := _add_label(page, "确认你的工作安排")
	title_label.add_theme_font_size_override("font_size", 22)
	title_label.add_theme_color_override("font_color", TEXT_INK)
	var subtitle := _add_label(page, "这些信息会用于实时计算今日收入和工作进度。")
	subtitle.add_theme_font_size_override("font_size", 12)
	_add_heading_gap(page)

	var rows := _new_task_block(page, "计算结果")
	rows.name = "WizardConfirmRows"
	_summary_value_labels.clear()
	_summary_value_labels["salary"] = _add_summary_row(rows, "月薪", "")
	_summary_value_labels["rest_mode"] = _add_summary_row(rows, "休息模式", "")
	_summary_value_labels["hours"] = _add_summary_row(rows, "有效工时", "")
	_summary_value_labels["time"] = _add_summary_row(rows, "今日工作区间", "")

	summary_label = Label.new()
	summary_label.text = "完成后仍可在偏好设置中调整。"
	summary_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	summary_label.add_theme_font_size_override("font_size", 12)
	summary_label.add_theme_color_override("font_color", TEXT_MUTED)
	page.add_child(summary_label)
	return page


func _new_task_block(parent: Control, title_text: String) -> VBoxContainer:
	var panel := PanelContainer.new()
	panel.name = "WizardTaskBlock"
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var block_style := _stylebox(Color(0, 0, 0, 0), Color(TEXT_MUTED.r, TEXT_MUTED.g, TEXT_MUTED.b, 0.12), 0, 0, 0)
	block_style.border_width_top = 1
	panel.add_theme_stylebox_override("panel", block_style)
	parent.add_child(panel)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 0)
	margin.add_theme_constant_override("margin_top", 0)
	margin.add_theme_constant_override("margin_right", 0)
	margin.add_theme_constant_override("margin_bottom", 0)
	panel.add_child(margin)
	var rows := VBoxContainer.new()
	rows.add_theme_constant_override("separation", 0)
	margin.add_child(rows)
	var title := _add_label(rows, title_text)
	title.visible = false
	title.add_theme_font_size_override("font_size", 11)
	title.add_theme_color_override("font_color", TEXT_MUTED)
	return rows


func _add_inference_line(parent: Control, label_text: String, value_text: String) -> Label:
	var spacer := Control.new()
	spacer.custom_minimum_size.y = 16
	parent.add_child(spacer)
	var panel := PanelContainer.new()
	panel.name = "WizardInference"
	panel.custom_minimum_size.y = 42
	panel.add_theme_stylebox_override("panel", _stylebox(SURFACE_COOL, Color(0, 0, 0, 0), 0, 9, 14))
	parent.add_child(panel)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	panel.add_child(row)
	var label := Label.new()
	label.text = label_text
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 12)
	label.add_theme_color_override("font_color", TEXT_MUTED)
	row.add_child(label)
	var value := Label.new()
	value.text = value_text
	value.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	value.add_theme_font_size_override("font_size", 13)
	value.add_theme_color_override("font_color", TEXT_INK)
	row.add_child(value)
	return value


func _add_label(parent: Control, text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", 16)
	label.add_theme_color_override("font_color", TEXT_MUTED)
	parent.add_child(label)
	return label


func _add_heading_gap(parent: Control) -> void:
	var spacer := Control.new()
	spacer.custom_minimum_size.y = 14
	parent.add_child(spacer)


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


func _add_field_row(parent: Control, label_text: String, control: Control) -> PanelContainer:
	var row_panel := PanelContainer.new()
	row_panel.name = "WizardFieldRow"
	row_panel.custom_minimum_size = Vector2(0, 64)
	row_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var row_style := StyleBoxFlat.new()
	row_style.bg_color = Color(0, 0, 0, 0)
	row_style.border_color = Color(TEXT_MUTED.r, TEXT_MUTED.g, TEXT_MUTED.b, 0.10)
	row_style.border_width_bottom = 1
	row_style.content_margin_top = 0
	row_style.content_margin_bottom = 0
	row_panel.add_theme_stylebox_override("panel", row_style)
	parent.add_child(row_panel)

	var row := HBoxContainer.new()
	row.custom_minimum_size = Vector2(0, 64)
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 12)
	row_panel.add_child(row)

	var label := Label.new()
	label.text = label_text
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 13)
	label.add_theme_color_override("font_color", TEXT_INK)
	row.add_child(label)

	control.size_flags_horizontal = Control.SIZE_SHRINK_END
	control.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(control)
	return row_panel


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
	start_hour_input.value_changed.connect(_on_time_input_changed)
	start_min_input.value_changed.connect(_on_time_input_changed)
	lunch_start_hour_input.value_changed.connect(_on_lunch_start_changed)
	lunch_start_min_input.value_changed.connect(_on_lunch_start_changed)


func _on_time_input_changed(_value: float) -> void:
	if _updating_draft_ui:
		return
	_configuration_draft.set_work_start_time(_time_value(start_hour_input, start_min_input))
	_apply_draft_schedule_to_controls()


func _on_lunch_start_changed(_value: float) -> void:
	if _updating_draft_ui:
		return
	_configuration_draft.set_lunch_start_time(_time_value(lunch_start_hour_input, lunch_start_min_input))
	_apply_draft_schedule_to_controls()


func _update_hours_preview() -> void:
	if hours_input == null:
		return
	hours_input.value = _calculate_work_hours()


func _calculate_work_hours() -> float:
	var minutes := SalaryScheduleCalculatorScript.effective_work_minutes(
		_time_value(start_hour_input, start_min_input),
		_time_value(end_hour_input, end_min_input),
		_time_value(lunch_start_hour_input, lunch_start_min_input),
		_time_value(lunch_end_hour_input, lunch_end_min_input)
	)
	return float(minutes) / 60.0


func _time_value(hour_input: SpinBox, minute_input: SpinBox) -> String:
	return "%02d:%02d" % [int(hour_input.value), int(minute_input.value)]


func _rest_mode_from_selection() -> String:
	match rest_mode_option.selected:
		1:
			return "single"
		2:
			return "alternating"
		_:
			return "double"


func _rest_mode_selection(rest_mode: String) -> int:
	match rest_mode:
		"single":
			return 1
		"alternating":
			return 2
		_:
			return 0


func _on_rest_mode_selected(_index: int) -> void:
	if rest_mode_option != null:
		_configuration_draft.set_rest_mode(_rest_mode_from_selection())
	if alternating_week_type_row != null:
		alternating_week_type_row.visible = rest_mode_option.selected == 2
	_update_progressive_visibility()
	_update_wizard_inference()


func _on_alternating_week_type_selected(_index: int) -> void:
	_configuration_draft.alternating_anchor_week_type = "small" if alternating_week_type_option.selected == 1 else "big"
	_update_wizard_inference()


func _on_salary_value_changed(value: float) -> void:
	_configuration_draft.set_salary(value)
	_update_progressive_visibility()
	_update_wizard_inference()


func _on_lunch_duration_changed(value: float) -> void:
	if _updating_draft_ui:
		return
	_configuration_draft.set_lunch_duration_minutes(roundi(value * 60.0))
	_apply_draft_schedule_to_controls()


func _sync_draft_from_time_controls() -> void:
	_configuration_draft.set_work_start_time(_time_value(start_hour_input, start_min_input))
	_configuration_draft.set_lunch_start_time(_time_value(lunch_start_hour_input, lunch_start_min_input))
	_configuration_draft.set_lunch_end_time(_time_value(lunch_end_hour_input, lunch_end_min_input))
	_configuration_draft.work_end_time = _time_value(end_hour_input, end_min_input)


func _update_progressive_visibility() -> void:
	if _schedule_section != null:
		_schedule_section.visible = true
	if _lunch_section != null:
		_lunch_section.visible = true
	if _inferred_section != null:
		_inferred_section.visible = true


func _apply_draft_schedule_to_controls() -> void:
	_updating_draft_ui = true
	_set_time_controls(start_hour_input, start_min_input, _configuration_draft.work_start_time)
	_set_time_controls(lunch_start_hour_input, lunch_start_min_input, _configuration_draft.lunch_start_time)
	_set_time_controls(lunch_end_hour_input, lunch_end_min_input, _configuration_draft.lunch_end_time)
	_set_time_controls(end_hour_input, end_min_input, _configuration_draft.work_end_time)
	if lunch_duration_input != null:
		lunch_duration_input.value = float(_configuration_draft.lunch_duration_minutes) / 60.0
	_updating_draft_ui = false
	_update_hours_preview()
	_update_wizard_inference()


func _update_wizard_inference() -> void:
	if _workdays_preview_label != null:
		var now := Time.get_datetime_dict_from_system()
		var anchor: String = _configuration_draft.alternating_anchor_date
		if anchor.is_empty():
			anchor = SalaryScheduleCalculatorScript.week_anchor_date(now)
		var workdays := SalaryScheduleCalculatorScript.workday_count(
			int(now.get("year", 0)),
			int(now.get("month", 0)),
			_rest_mode_from_selection(),
			anchor,
			"small" if alternating_week_type_option.selected == 1 else "big"
		)
		_workdays_preview_label.text = "%d 天" % workdays
	if _end_time_preview_label != null:
		_end_time_preview_label.text = _configuration_draft.work_end_time
	if _lunch_interval_preview_label != null:
		_lunch_interval_preview_label.text = "%s 至 %s" % [
			_configuration_draft.lunch_start_time,
			_configuration_draft.lunch_end_time
		]


func _set_time_controls(hour_input: SpinBox, minute_input: SpinBox, value: String) -> void:
	var parts := value.split(":")
	hour_input.value = int(parts[0]) if parts.size() > 0 else 0
	minute_input.value = int(parts[1]) if parts.size() > 1 else 0


func _add_pet_preview(parent: Control) -> TextureRect:
	var preview := TextureRect.new()
	preview.custom_minimum_size = Vector2(0, 118)
	preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	parent.add_child(preview)
	return preview


func _load_defaults() -> void:
	_configuration_draft.load_config(Config.get_data_snapshot())
	_updating_draft_ui = true
	salary_input.value = _configuration_draft.monthly_salary
	rest_mode_option.select(_rest_mode_selection(_configuration_draft.rest_mode))
	var anchor_date := String(Config.get_value("alternating_anchor_date", ""))
	var anchor_week_type := String(Config.get_value("alternating_anchor_week_type", "big"))
	var current_week_is_big := anchor_week_type != "small"
	if not anchor_date.is_empty():
		current_week_is_big = SalaryScheduleCalculatorScript.is_big_week(
			Time.get_datetime_dict_from_system(),
			anchor_date,
			anchor_week_type
		)
	alternating_week_type_option.select(0 if current_week_is_big else 1)
	_on_rest_mode_selected(rest_mode_option.selected)
	_updating_draft_ui = false
	_apply_draft_schedule_to_controls()
	_update_progressive_visibility()


func _populate_pets() -> void:
	pet_list.clear()
	var pets := PetManager.get_available_pets()
	var current_id := _entry_pet_id
	var selected_index := 0
	for index in range(pets.size()):
		var pet = pets[index]
		pet_list.add_item(pet.display_name)
		if String(pet.pet_id) == current_id:
			selected_index = index
	if pets.size() > 0:
		pet_list.select(selected_index)
		_set_preview_pet(pets[selected_index])


func _show_step(step: int) -> void:
	var previous_step := _current_step
	_current_step = clampi(step, 1, 4)
	for i in range(_pages.size()):
		_pages[i].visible = i == _current_step - 1
	prev_btn.visible = true
	prev_btn.disabled = _current_step == 1
	next_btn.text = "完成" if _current_step == 4 else "下一步"
	if _step_counter_label != null:
		_step_counter_label.text = "第 %d 步，共 4 步" % _current_step
	_refresh_step_sidebar()
	_update_wizard_inference()
	if _current_step == 4:
		_update_summary()
	if previous_step != _current_step:
		Platform.write_boot_log("wizard_step_changed: from=%d to=%d" % [previous_step, _current_step])


func _refresh_step_sidebar() -> void:
	for index in range(_step_markers.size()):
		var marker := _step_markers[index]
		var label := _step_titles[index]
		var step_number := index + 1
		var completed := step_number < _current_step
		var active := step_number == _current_step
		marker.text = "✓" if completed else str(step_number)
		var marker_bg := Color(1, 1, 1, 0.70)
		var marker_border := Color(TEXT_MUTED.r, TEXT_MUTED.g, TEXT_MUTED.b, 0.14)
		var marker_text := TEXT_MUTED
		if completed:
			marker_bg = Color(0.875, 0.918, 0.863, 1.0)
			marker_border = Color(ACCENT_MINT.r, ACCENT_MINT.g, ACCENT_MINT.b, 0.24)
			marker_text = Color(0.337, 0.463, 0.357, 1.0)
		elif active:
			marker_bg = ACCENT_COIN
			marker_border = Color(0.875, 0.584, 0.118, 0.32)
			marker_text = TEXT_INK
		marker.add_theme_stylebox_override("normal", _stylebox(marker_bg, marker_border, 1, 999, 0))
		marker.add_theme_color_override("font_color", marker_text)
		label.add_theme_color_override("font_color", TEXT_INK if active else TEXT_MUTED)


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
	var rm_text := "双休"
	if rest_mode_option.selected == 1:
		rm_text = "单休"
	elif rest_mode_option.selected == 2:
		rm_text = "大小周（%s）" % ("本周小周" if alternating_week_type_option.selected == 1 else "本周大周")
	var time_text := "%s-%s，午休 %s-%s" % [
		_time_value(start_hour_input, start_min_input),
		_time_value(end_hour_input, end_min_input),
		_time_value(lunch_start_hour_input, lunch_start_min_input),
		_time_value(lunch_end_hour_input, lunch_end_min_input)
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
	_sync_draft_from_time_controls()
	_configuration_draft.set_salary(float(salary_input.value))
	_configuration_draft.set_rest_mode(_rest_mode_from_selection())
	var validation: Dictionary = _configuration_draft.validate()
	if not bool(validation.get("valid", false)) or _calculate_work_hours() <= 0.0:
		summary_label.text = String(validation.get("message", "工作与午休时间顺序无效，请返回检查。"))
		Platform.write_boot_log("wizard_finish_failed: reason=%s" % String(validation.get("field", "invalid_schedule")), "error")
		return
	var previous_config := Config.get_data_snapshot()
	var rest_mode := _rest_mode_from_selection()
	var draft_values: Dictionary = _configuration_draft.to_config()
	for key in draft_values:
		Config.set_value(key, draft_values[key])
	if rest_mode == "alternating":
		Config.set_value("alternating_anchor_date", SalaryScheduleCalculatorScript.week_anchor_date(Time.get_datetime_dict_from_system()))
	Config.set_value("alternating_anchor_week_type", "small" if alternating_week_type_option.selected == 1 else "big")
	Config.set_value("work_start_time", _time_value(start_hour_input, start_min_input))
	Config.set_value("lunch_start_time", _time_value(lunch_start_hour_input, lunch_start_min_input))
	Config.set_value("lunch_end_time", _time_value(lunch_end_hour_input, lunch_end_min_input))
	Config.set_value("work_end_time", _time_value(end_hour_input, end_min_input))
	Config.set_value("work_hours_per_day", _calculate_work_hours())
	var selected := pet_list.get_selected_items()
	if selected.size() > 0:
		var pets := PetManager.get_available_pets()
		if int(selected[0]) < pets.size():
			Config.set_value("pet_id", pets[int(selected[0])].pet_id)
	if not Config.save():
		var reason := Config.get_last_save_error()
		Config.restore_data_snapshot(previous_config)
		_restore_entry_state("finish_failed")
		Platform.write_boot_log("wizard_finish_failed: reason=%s" % reason, "error")
		return
	_close_reason = "finished"
	Platform.write_boot_log("wizard_finished: changed_keys=%s step=%d" % [str(Config.get_last_changed_keys()), _current_step])
	finished.emit()
	queue_free()


func _on_cancel() -> void:
	_close_reason = "cancelled"
	_restore_entry_state(_close_reason)
	Platform.write_boot_log("wizard_cancelled: step=%d" % _current_step)
	queue_free()


func _restore_entry_state(reason: String) -> void:
	if _entry_state_restored:
		return
	_entry_state_restored = true
	if not _entry_pet_id.is_empty():
		PetManager.switch_pet(_entry_pet_id)
	Config.restore_data_snapshot(_entry_config_snapshot)
	Platform.write_info_log("wizard_state_restored: reason=%s pet_id=%s" % [reason, _entry_pet_id])
