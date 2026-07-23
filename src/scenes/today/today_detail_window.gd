extends Window

const PlacementScript := preload("res://src/utils/today_window_placement.gd")
const WarmControlThemeScript := preload("res://src/ui/warm_control_theme.gd")

const SURFACE_APP := Color(0.910, 0.906, 0.882, 1.0)
const SURFACE_PAPER := Color(1.000, 0.992, 0.980, 1.0)
const SURFACE_COOL := Color(0.945, 0.957, 0.937, 1.0)
const TEXT_INK := Color(0.188, 0.169, 0.149, 1.0)
const TEXT_MUTED := Color(0.463, 0.412, 0.365, 1.0)
const TEXT_SUBTLE := Color(0.608, 0.561, 0.518, 1.0)
const ACCENT_COIN := Color(0.949, 0.706, 0.227, 1.0)
const ACCENT_ORANGE := Color(0.914, 0.471, 0.196, 1.0)
const ACCENT_MINT := Color(0.439, 0.608, 0.455, 1.0)
const ACCENT_MINT_SOFT := Color(0.875, 0.918, 0.863, 1.0)
const BORDER_SOFT := Color(0.271, 0.208, 0.153, 0.13)


class ProgressRing:
	extends Control

	var ratio: float = 0.0

	func _ready() -> void:
		custom_minimum_size = Vector2(94, 94)
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func set_ratio(value: float) -> void:
		ratio = clampf(value, 0.0, 1.0)
		queue_redraw()

	func _draw() -> void:
		var center := size * 0.5
		var radius := maxf(8.0, minf(size.x, size.y) * 0.5 - 7.0)
		draw_arc(center, radius, -PI / 2.0, TAU - PI / 2.0, 72, Color(0.463, 0.412, 0.365, 0.14), 6.0, true)
		if ratio > 0.0:
			draw_arc(center, radius, -PI / 2.0, -PI / 2.0 + TAU * ratio, 72, Color(0.439, 0.608, 0.455, 1.0), 6.0, true)


var _today_value: Label
var _state_value: Label
var _month_value: Label
var _rate_value: Label
var _workdays_value: Label
var _hourly_summary_value: Label
var _progress: ProgressBar
var _progress_value: Label
var _ring_value: Label
var _progress_ring: ProgressRing
var _schedule_start_value: Label
var _schedule_lunch_value: Label
var _schedule_end_value: Label
var _schedule_start_time: Label
var _schedule_lunch_time: Label
var _schedule_end_time: Label
var _refresh_elapsed := 0.0
var _header_dragging := false
var _header_drag_start_mouse := Vector2i.ZERO
var _header_drag_start_window := Vector2i.ZERO
var _warm_theme: RefCounted = WarmControlThemeScript.new()


func _ready() -> void:
	title = "今日详情"
	borderless = true
	unresizable = true
	transparent_bg = true
	min_size = Vector2i(460, 580)
	_restore_geometry()
	_build_content()
	close_requested.connect(_close_window)
	visibility_changed.connect(_on_visibility_changed)
	_refresh()
	Platform.write_info_log("today_detail_opened")


func _process(delta: float) -> void:
	_refresh_elapsed += delta
	if _refresh_elapsed >= 0.5:
		_refresh_elapsed = 0.0
		_refresh()


func _build_content() -> void:
	var window_surface := PanelContainer.new()
	window_surface.name = "TodayWindowSurface"
	window_surface.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	window_surface.theme = _warm_theme.build_theme(14)
	window_surface.add_theme_stylebox_override("panel", _stylebox(SURFACE_PAPER, BORDER_SOFT, 1, 18, 0))
	add_child(window_surface)

	var page := VBoxContainer.new()
	page.name = "TodayPage"
	page.add_theme_constant_override("separation", 0)
	window_surface.add_child(page)

	page.add_child(_build_title_bar())
	page.add_child(_divider())

	var body_margin := MarginContainer.new()
	body_margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body_margin.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body_margin.add_theme_constant_override("margin_left", 26)
	body_margin.add_theme_constant_override("margin_top", 16)
	body_margin.add_theme_constant_override("margin_right", 26)
	body_margin.add_theme_constant_override("margin_bottom", 16)
	page.add_child(body_margin)

	var body := VBoxContainer.new()
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 16)
	body_margin.add_child(body)

	body.add_child(_build_hero())
	body.add_child(_divider())
	body.add_child(_build_schedule())

	var flexible_space := Control.new()
	flexible_space.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_child(flexible_space)
	body.add_child(_build_month_summary())


func _build_title_bar() -> Control:
	var margin := MarginContainer.new()
	margin.name = "TodayTitleBar"
	margin.custom_minimum_size = Vector2(0, 58)
	margin.mouse_filter = Control.MOUSE_FILTER_STOP
	margin.gui_input.connect(_on_header_gui_input)
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_bottom", 8)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	margin.add_child(row)

	var coin := Label.new()
	coin.text = "¥"
	coin.custom_minimum_size = Vector2(30, 30)
	coin.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	coin.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	coin.add_theme_font_size_override("font_size", 14)
	coin.add_theme_color_override("font_color", TEXT_INK)
	coin.add_theme_stylebox_override("normal", _stylebox(ACCENT_COIN, Color(0, 0, 0, 0), 0, 999, 0))
	row.add_child(coin)

	var heading := _label("今日详情", 17, TEXT_INK)
	heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(heading)

	var close_button := Button.new()
	close_button.name = "CloseButton"
	close_button.text = "×"
	close_button.custom_minimum_size = Vector2(32, 32)
	_warm_theme.style_button(close_button, false, true)
	close_button.pressed.connect(_close_window)
	row.add_child(close_button)
	return margin


func _build_hero() -> Control:
	var hero := VBoxContainer.new()
	hero.name = "TodayHero"
	hero.add_theme_constant_override("separation", 12)

	var hero_row := HBoxContainer.new()
	hero_row.add_theme_constant_override("separation", 18)
	hero.add_child(hero_row)

	var value_column := VBoxContainer.new()
	value_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	value_column.add_theme_constant_override("separation", 5)
	hero_row.add_child(value_column)

	var status_panel := PanelContainer.new()
	status_panel.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	status_panel.add_theme_stylebox_override("panel", _stylebox(ACCENT_MINT_SOFT, Color(ACCENT_MINT.r, ACCENT_MINT.g, ACCENT_MINT.b, 0.24), 1, 999, 0))
	_state_value = _label("需要完成设置", 12, Color(0.337, 0.463, 0.357, 1.0))
	_state_value.add_theme_constant_override("outline_size", 0)
	status_panel.add_child(_padded_control(_state_value, 10, 4))
	value_column.add_child(status_panel)

	value_column.add_child(_label("今日已赚", 13, TEXT_MUTED))
	_today_value = _label("¥0.00", 42, TEXT_INK)
	_today_value.add_theme_font_override("font", _number_font())
	value_column.add_child(_today_value)
	_rate_value = _label("日薪 ¥0.00 · 时薪 ¥0.00", 12, TEXT_MUTED)
	value_column.add_child(_rate_value)

	var ring_stack := Control.new()
	ring_stack.custom_minimum_size = Vector2(96, 96)
	hero_row.add_child(ring_stack)
	_progress_ring = ProgressRing.new()
	_progress_ring.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ring_stack.add_child(_progress_ring)
	var ring_center := CenterContainer.new()
	ring_center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ring_stack.add_child(ring_center)
	_ring_value = _label("0%", 18, TEXT_INK)
	_ring_value.add_theme_font_override("font", _number_font())
	ring_center.add_child(_ring_value)

	var progress_labels := HBoxContainer.new()
	progress_labels.add_theme_constant_override("separation", 8)
	hero.add_child(progress_labels)
	progress_labels.add_child(_label("收入进度", 12, TEXT_MUTED))
	_progress_value = _label("0%", 12, TEXT_MUTED)
	_progress_value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_progress_value.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	progress_labels.add_child(_progress_value)

	_progress = ProgressBar.new()
	_progress.max_value = 100.0
	_progress.show_percentage = false
	_progress.custom_minimum_size = Vector2(0, 6)
	_style_progress(_progress)
	hero.add_child(_progress)
	return hero


func _build_schedule() -> Control:
	var schedule := VBoxContainer.new()
	schedule.name = "TodaySchedule"
	schedule.add_theme_constant_override("separation", 8)

	var heading_row := HBoxContainer.new()
	heading_row.add_child(_label("今日安排", 18, TEXT_INK))
	var adjust := Button.new()
	adjust.text = "调整今天"
	adjust.size_flags_horizontal = Control.SIZE_SHRINK_END
	_warm_theme.style_button(adjust, false, true)
	adjust.tooltip_text = "打开作息设置"
	adjust.pressed.connect(_open_schedule_settings)
	heading_row.add_spacer(false)
	heading_row.add_child(adjust)
	schedule.add_child(heading_row)

	var start_row := _schedule_row(schedule, "08:00", ACCENT_MINT, "开始工作", "今天从这里开始")
	_schedule_start_time = start_row.time
	_schedule_start_value = start_row.detail
	var lunch_row := _schedule_row(schedule, "12:00", ACCENT_COIN, "午休", "12:00-14:00")
	_schedule_lunch_time = lunch_row.time
	_schedule_lunch_value = lunch_row.detail
	var end_row := _schedule_row(schedule, "18:00", Color(TEXT_SUBTLE.r, TEXT_SUBTLE.g, TEXT_SUBTLE.b, 0.55), "结束工作", "完成今日工作")
	_schedule_end_time = end_row.time
	_schedule_end_value = end_row.detail
	return schedule


func _open_schedule_settings() -> void:
	_close_window()
	DragResizeSystem.open_settings()


func _schedule_row(parent: VBoxContainer, time_text: String, dot_color: Color, title_text: String, detail_text: String) -> Dictionary:
	var row := HBoxContainer.new()
	row.custom_minimum_size = Vector2(0, 46)
	row.add_theme_constant_override("separation", 10)
	parent.add_child(row)

	var time_label := _label(time_text, 12, TEXT_MUTED)
	time_label.custom_minimum_size.x = 48
	time_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	time_label.add_theme_font_override("font", _number_font())
	row.add_child(time_label)

	var dot := Label.new()
	dot.text = "●"
	dot.custom_minimum_size.x = 16
	dot.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	dot.add_theme_font_size_override("font_size", 13)
	dot.add_theme_color_override("font_color", dot_color)
	row.add_child(dot)

	var copy := VBoxContainer.new()
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	copy.alignment = BoxContainer.ALIGNMENT_CENTER
	copy.add_theme_constant_override("separation", 2)
	row.add_child(copy)
	copy.add_child(_label(title_text, 15, TEXT_INK))
	var detail := _label(detail_text, 12, TEXT_MUTED)
	copy.add_child(detail)
	return {"time": time_label, "detail": detail}


func _build_month_summary() -> Control:
	var panel := PanelContainer.new()
	panel.name = "MonthSummary"
	panel.add_theme_stylebox_override("panel", _stylebox(SURFACE_COOL, Color(0, 0, 0, 0), 0, 12, 0))
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_bottom", 12)
	panel.add_child(margin)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 0)
	margin.add_child(row)
	_month_value = _summary_metric(row, "本月累计", "¥0.00")
	row.add_child(_vertical_divider())
	_workdays_value = _summary_metric(row, "本月工作日", "0 天")
	row.add_child(_vertical_divider())
	_hourly_summary_value = _summary_metric(row, "当前时薪", "¥0.00")
	return panel


func _summary_metric(parent: HBoxContainer, caption: String, value_text: String) -> Label:
	var column := VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation", 4)
	parent.add_child(column)
	column.add_child(_label(caption, 11, TEXT_MUTED))
	var value := _label(value_text, 15, TEXT_INK)
	value.add_theme_font_override("font", _number_font())
	column.add_child(value)
	return value


func _padded_control(control: Control, horizontal: int, vertical: int) -> MarginContainer:
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", horizontal)
	margin.add_theme_constant_override("margin_top", vertical)
	margin.add_theme_constant_override("margin_right", horizontal)
	margin.add_theme_constant_override("margin_bottom", vertical)
	margin.add_child(control)
	return margin


func _divider() -> ColorRect:
	var divider := ColorRect.new()
	divider.custom_minimum_size = Vector2(0, 1)
	divider.color = BORDER_SOFT
	return divider


func _vertical_divider() -> ColorRect:
	var divider := ColorRect.new()
	divider.custom_minimum_size = Vector2(1, 38)
	divider.color = BORDER_SOFT
	return divider


func _stylebox(bg: Color, border: Color, border_width: int, radius: int, padding: int) -> StyleBoxFlat:
	return _warm_theme.stylebox(bg, border, border_width, radius, padding)


func _label(text_value: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text_value
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label


func _style_progress(bar: ProgressBar) -> void:
	var background := StyleBoxFlat.new()
	background.bg_color = Color(TEXT_MUTED.r, TEXT_MUTED.g, TEXT_MUTED.b, 0.13)
	background.set_corner_radius_all(999)
	bar.add_theme_stylebox_override("background", background)
	var fill := StyleBoxFlat.new()
	fill.bg_color = ACCENT_COIN
	fill.set_corner_radius_all(999)
	bar.add_theme_stylebox_override("fill", fill)


func _number_font() -> Font:
	var font := SystemFont.new()
	font.font_names = PackedStringArray(["Segoe UI Variable", "Cascadia Mono", "Consolas", "Microsoft YaHei UI"])
	font.antialiasing = TextServer.FONT_ANTIALIASING_LCD
	font.hinting = TextServer.HINTING_NORMAL
	font.subpixel_positioning = TextServer.SUBPIXEL_POSITIONING_AUTO
	return font


func _refresh() -> void:
	if _today_value == null:
		return
	var snapshot: Dictionary = SalaryEngine.get_current_snapshot()
	var today_earnings := SalaryEngine.get_earnings_today()
	var hourly_rate := SalaryEngine.get_hourly_rate()
	var daily_salary := float(snapshot.get("daily_salary", hourly_rate * SalaryEngine.get_work_hours_per_day()))
	_today_value.text = "¥%.2f" % today_earnings
	_state_value.text = SalaryEngine.get_state_text()
	_month_value.text = "¥%.2f" % SalaryEngine.get_earnings_this_month()
	_workdays_value.text = "%d 天" % SalaryEngine.get_work_days_this_month()
	_rate_value.text = "日薪 ¥%.2f · 时薪 ¥%.2f" % [daily_salary, hourly_rate]
	_hourly_summary_value.text = "¥%.2f" % hourly_rate
	var percentage := SalaryEngine.get_work_progress() * 100.0
	_progress.value = percentage
	_progress_ring.set_ratio(percentage / 100.0)
	_ring_value.text = "%.0f%%" % percentage
	_progress_value.text = "%.0f%% · 有效工时 %.1f 小时" % [percentage, SalaryEngine.get_work_hours_per_day()]
	var schedule_values := schedule_display_values({
		"work_start_time": Config.get_value("work_start_time", "08:00"),
		"lunch_start_time": Config.get_value("lunch_start_time", "12:00"),
		"lunch_end_time": Config.get_value("lunch_end_time", "14:00"),
		"work_end_time": Config.get_value("work_end_time", "18:00"),
	})
	var work_start := String(schedule_values.work_start)
	var lunch_start := String(schedule_values.lunch_start)
	var lunch_range := String(schedule_values.lunch_range)
	var work_end := String(schedule_values.work_end)
	_schedule_start_time.text = work_start
	_schedule_lunch_time.text = lunch_start
	_schedule_end_time.text = work_end
	_schedule_start_value.text = "%s 开始" % work_start
	_schedule_lunch_value.text = lunch_range
	_schedule_end_value.text = "%s 完成今日工作" % work_end


static func schedule_display_values(source: Dictionary) -> Dictionary:
	var lunch_start := String(source.get("lunch_start_time", "12:00"))
	var lunch_end := String(source.get("lunch_end_time", lunch_start))
	return {
		"work_start": String(source.get("work_start_time", "08:00")),
		"lunch_start": lunch_start,
		"lunch_range": "%s-%s" % [lunch_start, lunch_end],
		"work_end": String(source.get("work_end_time", "18:00")),
	}


func _restore_geometry() -> void:
	var size_data: Dictionary = Config.get_value("today_window_size", {"width": 480, "height": 600})
	var saved_size := Vector2i(int(size_data.get("width", 500)), int(size_data.get("height", 700)))
	saved_size.x = maxi(saved_size.x, 460)
	saved_size.y = maxi(saved_size.y, 620)
	var screen_index := DisplayServer.get_primary_screen()
	var screen_rect := Rect2i(DisplayServer.screen_get_position(screen_index), DisplayServer.screen_get_usable_rect(screen_index).size)
	size = PlacementScript.sanitize_size(saved_size, screen_rect)
	var position_data: Dictionary = Config.get_value("today_window_position", {"x": -1, "y": -1})
	position = PlacementScript.sanitize(Vector2i(int(position_data.get("x", -1)), int(position_data.get("y", -1))), size, screen_rect)


func _save_geometry() -> void:
	Config.set_value("today_window_position", {"x": position.x, "y": position.y})
	Config.set_value("today_window_size", {"width": size.x, "height": size.y})
	Config.save()


func _on_header_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		_header_dragging = event.pressed
		if _header_dragging:
			_header_drag_start_mouse = DisplayServer.mouse_get_position()
			_header_drag_start_window = position
		set_input_as_handled()
	elif event is InputEventMouseMotion and _header_dragging:
		position = _header_drag_start_window + DisplayServer.mouse_get_position() - _header_drag_start_mouse
		set_input_as_handled()


func _on_visibility_changed() -> void:
	if not visible and is_inside_tree():
		_save_geometry()


func _close_window() -> void:
	_save_geometry()
	Platform.write_info_log("today_detail_closed")
	hide()
