extends Control

const MINI_SIZE := Vector2i(344, 120)
const WORKBENCH_SIZE := Vector2i(820, 620)
const SETTINGS_SIZE := Vector2i(720, 540)

const COLOR_WINDOW := Color("#FCFCFB")
const COLOR_SURFACE := Color("#F5F5F3")
const COLOR_SURFACE_HIGH := Color("#FFFFFF")
const COLOR_TEXT := Color("#242320")
const COLOR_MUTED := Color("#6E6B65")
const COLOR_BORDER := Color("#DDDAD4")
const COLOR_ACCENT := Color("#E9A923")
const COLOR_ACCENT_HOVER := Color("#D99812")
const COLOR_SUCCESS := Color("#4E8A60")
const COLOR_SUCCESS_SOFT := Color("#E9F2EB")
const COLOR_DANGER := Color("#B45448")
const COLOR_DANGER_SOFT := Color("#F8ECEA")

var current_mode := "mini"
var saved_salary := "10,000"
var salary_input: LineEdit
var feedback_label: Label
var failure_toggle: CheckButton
var mini_view: Control
var workbench_view: Control
var settings_view: Control
var tray_indicator: Node
var tray_menu: PopupMenu
var system_font: SystemFont


func _ready() -> void:
	system_font = SystemFont.new()
	system_font.font_names = PackedStringArray(["Segoe UI Variable Text", "Segoe UI"])
	get_tree().auto_accept_quit = false
	get_window().close_requested.connect(_hide_to_tray)
	get_window().borderless = true
	get_window().transparent_bg = true
	get_viewport().transparent_bg = true
	_build_views()
	_setup_tray()
	_show_mode("mini")


func _build_views() -> void:
	mini_view = _build_mini_view()
	workbench_view = _build_workbench_view()
	settings_view = _build_settings_view()
	add_child(mini_view)
	add_child(workbench_view)
	add_child(settings_view)


func _build_mini_view() -> Control:
	var shell := _window_shell(12)
	shell.name = "MiniView"
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 10)
	shell.add_child(row)

	var open_button := Button.new()
	open_button.text = "¥"
	open_button.tooltip_text = "打开今日工作台"
	open_button.custom_minimum_size = Vector2(40, 40)
	open_button.add_theme_font_override("font", system_font)
	open_button.add_theme_font_size_override("font_size", 20)
	_style_button(open_button, COLOR_ACCENT, Color("#1F1B12"), 20)
	open_button.pressed.connect(func() -> void: _show_mode("workbench"))
	row.add_child(open_button)

	var content := VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 3)
	row.add_child(content)

	var heading := HBoxContainer.new()
	var eyebrow := _label("今日已赚", 12, COLOR_MUTED)
	eyebrow.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading.add_child(eyebrow)
	heading.add_child(_label("工作中", 12, COLOR_SUCCESS, 600))
	content.add_child(heading)
	content.add_child(_label("¥ 186.42", 26, COLOR_TEXT, 650))

	var progress := ProgressBar.new()
	progress.value = 56
	progress.show_percentage = false
	progress.custom_minimum_size = Vector2(0, 5)
	progress.add_theme_stylebox_override("background", _flat_style(Color("#E8E6E1"), 3))
	progress.add_theme_stylebox_override("fill", _flat_style(COLOR_ACCENT, 3))
	content.add_child(progress)

	var meta := HBoxContainer.new()
	var left_meta := _label("工作进度 56%", 11, COLOR_MUTED)
	left_meta.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	meta.add_child(left_meta)
	meta.add_child(_label("距离下班 4:38:20", 11, COLOR_MUTED))
	content.add_child(meta)

	var more := Button.new()
	more.text = "⋯"
	more.tooltip_text = "更多操作"
	more.custom_minimum_size = Vector2(32, 32)
	_style_button(more, COLOR_SURFACE, COLOR_TEXT, 8, true)
	more.pressed.connect(func() -> void: _show_mini_menu(more))
	row.add_child(more)
	return shell


func _build_workbench_view() -> Control:
	var shell := _window_shell(12)
	shell.name = "WorkbenchView"
	var outer := VBoxContainer.new()
	outer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 0)
	shell.add_child(outer)
	outer.add_child(_titlebar("LetsMakeMoney", true))

	var body := HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 0)
	outer.add_child(body)

	var nav := VBoxContainer.new()
	nav.custom_minimum_size = Vector2(164, 0)
	nav.add_theme_constant_override("separation", 6)
	nav.add_theme_stylebox_override("panel", _flat_style(COLOR_SURFACE, 0))
	var nav_panel := PanelContainer.new()
	nav_panel.custom_minimum_size = Vector2(164, 0)
	nav_panel.add_theme_stylebox_override("panel", _flat_style(COLOR_SURFACE, 0))
	nav_panel.add_child(nav)
	body.add_child(nav_panel)
	_add_spacer(nav, 16)
	var today_button := _nav_button("◷  今日", true)
	nav.add_child(today_button)
	var calendar_button := _nav_button("▦  日历", false)
	nav.add_child(calendar_button)
	var nav_spacer := Control.new()
	nav_spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	nav.add_child(nav_spacer)
	var hide_button := _nav_button("▭  隐藏到托盘", false)
	hide_button.pressed.connect(_hide_to_tray)
	nav.add_child(hide_button)
	_add_spacer(nav, 12)

	var content_margin := MarginContainer.new()
	content_margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_margin.add_theme_constant_override("margin_left", 28)
	content_margin.add_theme_constant_override("margin_right", 28)
	content_margin.add_theme_constant_override("margin_top", 24)
	content_margin.add_theme_constant_override("margin_bottom", 24)
	body.add_child(content_margin)

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 20)
	content_margin.add_child(content)

	var heading := HBoxContainer.new()
	var heading_copy := VBoxContainer.new()
	heading_copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading_copy.add_child(_label("今天，继续把时间变成看得见的进度", 24, COLOR_TEXT, 650))
	heading_copy.add_child(_label("2026 年 7 月 23 日 · 周四", 13, COLOR_MUTED))
	heading.add_child(heading_copy)
	heading.add_child(_pill("工作中", COLOR_SUCCESS_SOFT, COLOR_SUCCESS))
	content.add_child(heading)

	var columns := HBoxContainer.new()
	columns.size_flags_vertical = Control.SIZE_EXPAND_FILL
	columns.add_theme_constant_override("separation", 18)
	content.add_child(columns)

	var income := _card()
	income.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var income_box := _card_content(income, 20, 16)
	income_box.add_child(_label("今日已赚", 12, COLOR_MUTED))
	income_box.add_child(_label("¥ 186.42", 38, COLOR_TEXT, 680))
	income_box.add_child(_label("日薪 ¥ 500.00 · 时薪 ¥ 62.50", 12, COLOR_MUTED))
	_add_spacer(income_box, 8)
	var progress_heading := HBoxContainer.new()
	var progress_label := _label("收入进度", 12, COLOR_MUTED)
	progress_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	progress_heading.add_child(progress_label)
	progress_heading.add_child(_label("56%", 12, COLOR_TEXT, 650))
	income_box.add_child(progress_heading)
	var progress := ProgressBar.new()
	progress.value = 56
	progress.show_percentage = false
	progress.custom_minimum_size = Vector2(0, 8)
	progress.add_theme_stylebox_override("background", _flat_style(Color("#E8E6E1"), 4))
	progress.add_theme_stylebox_override("fill", _flat_style(COLOR_ACCENT, 4))
	income_box.add_child(progress)
	_add_spacer(income_box, 12)
	income_box.add_child(_metric_row("本月累计", "¥ 3,842.00"))
	income_box.add_child(_separator())
	income_box.add_child(_metric_row("本月工作日", "8 / 20 天"))
	income_box.add_child(_separator())
	income_box.add_child(_metric_row("距离下班", "4:38:20"))
	columns.add_child(income)

	var schedule := _card()
	schedule.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var schedule_box := _card_content(schedule, 20, 16)
	var schedule_heading := HBoxContainer.new()
	var schedule_copy := VBoxContainer.new()
	schedule_copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	schedule_copy.add_child(_label("今日安排", 12, COLOR_MUTED))
	schedule_copy.add_child(_label("08:00—18:00", 18, COLOR_TEXT, 650))
	schedule_heading.add_child(schedule_copy)
	var adjust := Button.new()
	adjust.text = "调整今天"
	_style_button(adjust, Color.TRANSPARENT, COLOR_ACCENT_HOVER, 6, true)
	schedule_heading.add_child(adjust)
	schedule_box.add_child(schedule_heading)
	_add_spacer(schedule_box, 8)
	schedule_box.add_child(_timeline_row("08:00", COLOR_SUCCESS, "开始工作", "已完成 3 小时 22 分钟"))
	schedule_box.add_child(_timeline_row("12:00", COLOR_ACCENT, "午休", "12:00—14:00"))
	schedule_box.add_child(_timeline_row("18:00", COLOR_BORDER, "结束工作", "预计今日收入 ¥ 500.00"))
	columns.add_child(schedule)

	today_button.pressed.connect(func() -> void: pass)
	calendar_button.pressed.connect(func() -> void: _show_calendar_placeholder(content, columns))
	return shell


func _build_settings_view() -> Control:
	var shell := _window_shell(12)
	shell.name = "SettingsView"
	var outer := VBoxContainer.new()
	outer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 0)
	shell.add_child(outer)
	outer.add_child(_titlebar("设置", false))

	var body := HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 0)
	outer.add_child(body)

	var nav_panel := PanelContainer.new()
	nav_panel.custom_minimum_size = Vector2(178, 0)
	nav_panel.add_theme_stylebox_override("panel", _flat_style(COLOR_SURFACE, 0))
	var nav_margin := MarginContainer.new()
	nav_margin.add_theme_constant_override("margin_left", 14)
	nav_margin.add_theme_constant_override("margin_right", 14)
	nav_margin.add_theme_constant_override("margin_top", 20)
	nav_margin.add_theme_constant_override("margin_bottom", 16)
	nav_panel.add_child(nav_margin)
	var nav := VBoxContainer.new()
	nav.add_theme_constant_override("separation", 6)
	nav_margin.add_child(nav)
	nav.add_child(_label("偏好设置", 16, COLOR_TEXT, 650))
	nav.add_child(_label("更改只保存在本机", 11, COLOR_MUTED))
	_add_spacer(nav, 12)
	nav.add_child(_nav_button("¥  收入与作息", true))
	var calendar := _nav_button("▦  日历", false)
	calendar.disabled = true
	nav.add_child(calendar)
	var windows := _nav_button("▭  窗口与启动", false)
	windows.disabled = true
	nav.add_child(windows)
	var support := _nav_button("ⓘ  数据与支持", false)
	support.disabled = true
	nav.add_child(support)
	body.add_child(nav_panel)

	var content := VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 0)
	body.add_child(content)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	content.add_child(scroll)
	var form_margin := MarginContainer.new()
	form_margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	form_margin.add_theme_constant_override("margin_left", 28)
	form_margin.add_theme_constant_override("margin_right", 28)
	form_margin.add_theme_constant_override("margin_top", 24)
	form_margin.add_theme_constant_override("margin_bottom", 20)
	scroll.add_child(form_margin)
	var form := VBoxContainer.new()
	form.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	form.add_theme_constant_override("separation", 14)
	form_margin.add_child(form)

	var heading := HBoxContainer.new()
	var heading_copy := VBoxContainer.new()
	heading_copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading_copy.add_child(_label("收入与作息", 24, COLOR_TEXT, 650))
	heading_copy.add_child(_label("用于计算日薪、时薪、今日收益和工作进度。", 12, COLOR_MUTED))
	heading.add_child(heading_copy)
	heading.add_child(_pill("本机配置", COLOR_SUCCESS_SOFT, COLOR_SUCCESS))
	form.add_child(heading)
	form.add_child(_section_title("收入"))

	salary_input = LineEdit.new()
	salary_input.text = saved_salary
	salary_input.alignment = HORIZONTAL_ALIGNMENT_RIGHT
	salary_input.custom_minimum_size = Vector2(138, 36)
	_style_line_edit(salary_input)
	form.add_child(_setting_row("月薪", "税前月薪，按当月工作日折算", salary_input))

	var rest_mode := OptionButton.new()
	rest_mode.add_item("双休")
	rest_mode.add_item("单休")
	rest_mode.add_item("大小周")
	rest_mode.custom_minimum_size = Vector2(138, 36)
	_style_option(rest_mode)
	form.add_child(_setting_row("休息模式", "影响每月工作日和日薪计算", rest_mode))
	form.add_child(_section_title("工作时间"))

	var work_start := LineEdit.new()
	work_start.text = "08:00"
	work_start.alignment = HORIZONTAL_ALIGNMENT_RIGHT
	work_start.custom_minimum_size = Vector2(138, 36)
	_style_line_edit(work_start)
	form.add_child(_setting_row("上班时间", "默认按 8 小时有效工时推算下班", work_start))

	var lunch_duration := OptionButton.new()
	for item in ["2 小时", "1.5 小时", "1 小时", "不午休"]:
		lunch_duration.add_item(item)
	lunch_duration.custom_minimum_size = Vector2(138, 36)
	_style_option(lunch_duration)
	form.add_child(_setting_row("午休时长", "午休不计入有效工时", lunch_duration))

	var lunch_start := LineEdit.new()
	lunch_start.text = "12:00"
	lunch_start.alignment = HORIZONTAL_ALIGNMENT_RIGHT
	lunch_start.custom_minimum_size = Vector2(138, 36)
	_style_line_edit(lunch_start)
	form.add_child(_setting_row("午休开始", "修改后自动推算午休结束与下班时间", lunch_start))

	var prediction := PanelContainer.new()
	prediction.add_theme_stylebox_override("panel", _flat_style(COLOR_SUCCESS_SOFT, 8, COLOR_SUCCESS.lightened(0.45)))
	var prediction_row := HBoxContainer.new()
	prediction_row.add_theme_constant_override("separation", 10)
	var prediction_label := _label("自动推算", 12, COLOR_SUCCESS)
	prediction_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	prediction_row.add_child(prediction_label)
	prediction_row.add_child(_label("午休 12:00—14:00 · 下班 18:00 · 有效工时 8 小时", 12, COLOR_SUCCESS, 600))
	prediction.add_child(prediction_row)
	form.add_child(prediction)

	failure_toggle = CheckButton.new()
	failure_toggle.text = "模拟配置写入失败（技术 Spike）"
	failure_toggle.add_theme_font_override("font", system_font)
	failure_toggle.add_theme_font_size_override("font_size", 11)
	failure_toggle.add_theme_color_override("font_color", COLOR_MUTED)
	form.add_child(failure_toggle)

	var footer := HBoxContainer.new()
	footer.custom_minimum_size = Vector2(0, 58)
	footer.add_theme_constant_override("separation", 10)
	var footer_margin := MarginContainer.new()
	footer_margin.add_theme_constant_override("margin_left", 20)
	footer_margin.add_theme_constant_override("margin_right", 20)
	footer_margin.add_theme_constant_override("margin_top", 10)
	footer_margin.add_theme_constant_override("margin_bottom", 10)
	footer_margin.add_theme_stylebox_override("panel", _flat_style(COLOR_WINDOW, 0, COLOR_BORDER))
	content.add_child(footer_margin)
	footer_margin.add_child(footer)
	feedback_label = _label("没有未保存的更改", 12, COLOR_MUTED)
	feedback_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	footer.add_child(feedback_label)
	var reset := Button.new()
	reset.text = "恢复默认"
	_style_button(reset, COLOR_SURFACE_HIGH, COLOR_TEXT, 8, true)
	reset.pressed.connect(_reset_settings)
	footer.add_child(reset)
	var save := Button.new()
	save.text = "保存"
	save.custom_minimum_size = Vector2(88, 38)
	_style_button(save, COLOR_ACCENT, Color("#1F1B12"), 8)
	save.pressed.connect(_save_settings)
	footer.add_child(save)
	return shell


func _show_mode(mode: String) -> void:
	current_mode = mode
	mini_view.visible = mode == "mini"
	workbench_view.visible = mode == "workbench"
	settings_view.visible = mode == "settings"
	match mode:
		"mini":
			get_window().size = MINI_SIZE
		"workbench":
			get_window().size = WORKBENCH_SIZE
		"settings":
			get_window().size = SETTINGS_SIZE
	get_window().show()
	_update_tray_menu()


func _save_settings() -> void:
	if failure_toggle.button_pressed:
		feedback_label.text = "保存失败：配置文件暂时不可写，输入已保留"
		feedback_label.add_theme_color_override("font_color", COLOR_DANGER)
		return
	var normalized := salary_input.text.strip_edges()
	if normalized == saved_salary:
		feedback_label.text = "没有需要保存的更改"
		feedback_label.add_theme_color_override("font_color", COLOR_MUTED)
		return
	saved_salary = normalized
	feedback_label.text = "已保存到本机"
	feedback_label.add_theme_color_override("font_color", COLOR_SUCCESS)


func _reset_settings() -> void:
	salary_input.text = "10,000"
	feedback_label.text = "已恢复默认值，保存后生效"
	feedback_label.add_theme_color_override("font_color", COLOR_MUTED)


func _hide_to_tray() -> void:
	get_window().hide()
	_update_tray_menu()


func _restore_from_tray() -> void:
	get_window().show()
	get_window().grab_focus()
	_update_tray_menu()


func _setup_tray() -> void:
	if not ClassDB.class_exists("StatusIndicator"):
		push_warning("StatusIndicator unavailable")
		return
	tray_menu = PopupMenu.new()
	tray_menu.add_item("显示窗口", 1)
	tray_menu.add_item("设置", 2)
	tray_menu.add_separator()
	tray_menu.add_item("退出", 3)
	tray_menu.id_pressed.connect(_on_tray_menu)
	add_child(tray_menu)
	tray_indicator = ClassDB.instantiate("StatusIndicator")
	if tray_indicator == null:
		push_warning("StatusIndicator could not be created")
		return
	add_child(tray_indicator)
	tray_indicator.set("tooltip", "LetsMakeMoney v1.0 技术 Spike")
	tray_indicator.set("icon", _create_tray_icon())
	tray_indicator.set("menu", tray_menu)
	tray_indicator.set("visible", true)
	if tray_indicator.has_signal("pressed"):
		tray_indicator.connect("pressed", _on_tray_pressed)


func _on_tray_pressed(_button: int = 0, _position: Vector2i = Vector2i.ZERO) -> void:
	if get_window().visible:
		_hide_to_tray()
	else:
		_restore_from_tray()


func _on_tray_menu(id: int) -> void:
	match id:
		1:
			_restore_from_tray()
		2:
			_show_mode("settings")
		3:
			get_tree().quit()


func _update_tray_menu() -> void:
	if tray_menu == null:
		return
	tray_menu.set_item_text(0, "隐藏窗口" if get_window().visible else "显示窗口")


func _show_mini_menu(anchor: Control) -> void:
	var popup := PopupMenu.new()
	popup.add_item("打开今日工作台", 1)
	popup.add_item("设置", 2)
	popup.add_separator()
	popup.add_item("隐藏到托盘", 3)
	popup.id_pressed.connect(func(id: int) -> void:
		match id:
			1:
				_show_mode("workbench")
			2:
				_show_mode("settings")
			3:
				_hide_to_tray()
		popup.queue_free()
	)
	add_child(popup)
	popup.position = Vector2i(anchor.global_position) + Vector2i(-170, 36)
	popup.popup()


func _show_calendar_placeholder(content: VBoxContainer, columns: HBoxContainer) -> void:
	columns.visible = false
	if content.has_node("CalendarPlaceholder"):
		content.get_node("CalendarPlaceholder").visible = true
		return
	var calendar := _card()
	calendar.name = "CalendarPlaceholder"
	calendar.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var box := _card_content(calendar, 24, 14)
	box.add_child(_label("收入日历", 24, COLOR_TEXT, 650))
	box.add_child(_label("工作日、休息日、调休和收入结果使用同一业务口径。", 13, COLOR_MUTED))
	_add_spacer(box, 12)
	for row in [
		"日    一    二    三    四    五    六",
		"                  1     2     3     4",
		" 5     6     7     8     9    10    11",
		"12    13    14    15    16    17    18",
		"19    20    21    22    23    24    25",
		"26    27    28    29    30    31"
	]:
		var line := _label(row, 16, COLOR_TEXT)
		line.add_theme_font_override("font", system_font)
		box.add_child(line)
	content.add_child(calendar)


func _window_shell(radius: int) -> PanelContainer:
	var shell := PanelContainer.new()
	shell.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shell.add_theme_stylebox_override("panel", _flat_style(COLOR_WINDOW, radius, COLOR_BORDER, 10))
	return shell


func _titlebar(title: String, show_settings: bool) -> Control:
	var margin := MarginContainer.new()
	margin.custom_minimum_size = Vector2(0, 52)
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	margin.add_child(row)
	var mark := _pill("¥", COLOR_ACCENT, Color("#1F1B12"))
	row.add_child(mark)
	var title_label := _label(title, 14, COLOR_TEXT, 650)
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(title_label)
	if show_settings:
		var settings := Button.new()
		settings.text = "⚙"
		settings.tooltip_text = "设置"
		settings.custom_minimum_size = Vector2(34, 34)
		_style_button(settings, COLOR_SURFACE, COLOR_TEXT, 8, true)
		settings.pressed.connect(func() -> void: _show_mode("settings"))
		row.add_child(settings)
	var close := Button.new()
	close.text = "×"
	close.tooltip_text = "关闭"
	close.custom_minimum_size = Vector2(34, 34)
	_style_button(close, COLOR_SURFACE, COLOR_TEXT, 8, true)
	close.pressed.connect(func() -> void:
		if current_mode == "mini":
			_hide_to_tray()
		else:
			_show_mode("mini")
	)
	row.add_child(close)
	return margin


func _label(text: String, size: int, color: Color, weight: int = 400) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_override("font", system_font)
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	if weight >= 600:
		label.add_theme_constant_override("outline_size", 0)
	return label


func _pill(text: String, background: Color, foreground: Color) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _flat_style(background, 12))
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_top", 4)
	margin.add_theme_constant_override("margin_bottom", 4)
	margin.add_child(_label(text, 11, foreground, 600))
	panel.add_child(margin)
	return panel


func _card() -> PanelContainer:
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", _flat_style(COLOR_SURFACE_HIGH, 10, COLOR_BORDER))
	return card


func _card_content(card: PanelContainer, padding: int, separation: int) -> VBoxContainer:
	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, padding)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", separation)
	margin.add_child(box)
	card.add_child(margin)
	return box


func _metric_row(label_text: String, value_text: String) -> HBoxContainer:
	var row := HBoxContainer.new()
	var label := _label(label_text, 12, COLOR_MUTED)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(label)
	row.add_child(_label(value_text, 13, COLOR_TEXT, 650))
	return row


func _timeline_row(time_text: String, dot_color: Color, title: String, detail: String) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.custom_minimum_size = Vector2(0, 58)
	row.add_theme_constant_override("separation", 10)
	var time := _label(time_text, 11, COLOR_MUTED)
	time.custom_minimum_size = Vector2(46, 0)
	row.add_child(time)
	var dot := ColorRect.new()
	dot.color = dot_color
	dot.custom_minimum_size = Vector2(9, 9)
	row.add_child(dot)
	var copy := VBoxContainer.new()
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	copy.add_theme_constant_override("separation", 3)
	copy.add_child(_label(title, 14, COLOR_TEXT, 650))
	copy.add_child(_label(detail, 11, COLOR_MUTED))
	row.add_child(copy)
	return row


func _section_title(text: String) -> Control:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	box.add_child(_label(text, 12, COLOR_SUCCESS, 650))
	box.add_child(_separator())
	return box


func _setting_row(title: String, description: String, control: Control) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.custom_minimum_size = Vector2(0, 54)
	row.add_theme_constant_override("separation", 16)
	var copy := VBoxContainer.new()
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	copy.add_theme_constant_override("separation", 2)
	copy.add_child(_label(title, 13, COLOR_TEXT, 650))
	copy.add_child(_label(description, 11, COLOR_MUTED))
	row.add_child(copy)
	row.add_child(control)
	return row


func _separator() -> HSeparator:
	var separator := HSeparator.new()
	separator.add_theme_stylebox_override("separator", _flat_style(COLOR_BORDER, 0))
	return separator


func _nav_button(text: String, active: bool) -> Button:
	var button := Button.new()
	button.text = text
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.custom_minimum_size = Vector2(0, 38)
	button.add_theme_font_override("font", system_font)
	button.add_theme_font_size_override("font_size", 12)
	if active:
		_style_button(button, Color("#F6E7BF"), COLOR_TEXT, 8)
	else:
		_style_button(button, Color.TRANSPARENT, COLOR_MUTED, 8, true)
	return button


func _style_button(button: Button, background: Color, foreground: Color, radius: int, subtle_border: bool = false) -> void:
	button.add_theme_font_override("font", system_font)
	button.add_theme_font_size_override("font_size", 12)
	button.add_theme_color_override("font_color", foreground)
	button.add_theme_color_override("font_hover_color", foreground)
	button.add_theme_color_override("font_pressed_color", foreground)
	button.add_theme_stylebox_override("normal", _flat_style(background, radius, COLOR_BORDER if subtle_border else Color.TRANSPARENT))
	button.add_theme_stylebox_override("hover", _flat_style(background.lightened(0.035) if background != Color.TRANSPARENT else COLOR_SURFACE, radius, COLOR_BORDER))
	button.add_theme_stylebox_override("pressed", _flat_style(background.darkened(0.06) if background != Color.TRANSPARENT else Color("#E8E6E1"), radius, COLOR_BORDER))
	button.add_theme_stylebox_override("focus", _flat_style(background, radius, COLOR_ACCENT, 2))
	button.add_theme_stylebox_override("disabled", _flat_style(COLOR_SURFACE, radius, COLOR_BORDER))


func _style_line_edit(input: LineEdit) -> void:
	input.add_theme_font_override("font", system_font)
	input.add_theme_font_size_override("font_size", 12)
	input.add_theme_color_override("font_color", COLOR_TEXT)
	input.add_theme_stylebox_override("normal", _flat_style(COLOR_SURFACE_HIGH, 8, COLOR_BORDER))
	input.add_theme_stylebox_override("focus", _flat_style(COLOR_SURFACE_HIGH, 8, COLOR_ACCENT, 2))


func _style_option(option: OptionButton) -> void:
	option.add_theme_font_override("font", system_font)
	option.add_theme_font_size_override("font_size", 12)
	option.add_theme_color_override("font_color", COLOR_TEXT)
	option.add_theme_stylebox_override("normal", _flat_style(COLOR_SURFACE_HIGH, 8, COLOR_BORDER))
	option.add_theme_stylebox_override("hover", _flat_style(COLOR_SURFACE, 8, COLOR_BORDER))
	option.add_theme_stylebox_override("focus", _flat_style(COLOR_SURFACE_HIGH, 8, COLOR_ACCENT, 2))


func _flat_style(background: Color, radius: int, border: Color = Color.TRANSPARENT, border_width: int = 1) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_left = radius
	style.corner_radius_bottom_right = radius
	if border != Color.TRANSPARENT:
		style.border_color = border
		style.border_width_left = border_width
		style.border_width_top = border_width
		style.border_width_right = border_width
		style.border_width_bottom = border_width
	return style


func _add_spacer(container: Container, height: int) -> void:
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, height)
	container.add_child(spacer)


func _create_tray_icon() -> ImageTexture:
	var image := Image.create(32, 32, false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	var center := Vector2(15.5, 15.5)
	for y in range(32):
		for x in range(32):
			var distance := Vector2(x, y).distance_to(center)
			if distance <= 14.0:
				image.set_pixel(x, y, COLOR_ACCENT)
			if distance <= 7.0 and abs(x - 16) <= 1:
				image.set_pixel(x, y, Color("#2B2518"))
	for x in range(10, 22):
		image.set_pixel(x, 22, Color("#2B2518"))
	return ImageTexture.create_from_image(image)

