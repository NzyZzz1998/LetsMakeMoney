# src/scenes/panel/panel.gd
extends Control

signal layout_changed
signal details_requested

@onready var background: Panel = $Background
@onready var collapsed_container: CenterContainer = $Collapsed
@onready var expanded_container: VBoxContainer = $Expanded
@onready var collapsed_content: VBoxContainer = $Collapsed/CollapsedContent
@onready var earnings_today_label: Label = $Collapsed/CollapsedContent/EarningsToday
@onready var collapsed_status_label: Label = $Collapsed/CollapsedContent/Header/ShortStatus
@onready var collapsed_caption_label: Label = $Collapsed/CollapsedContent/Header/Caption
@onready var collapsed_progress_bar: ProgressBar = $Collapsed/CollapsedContent/CollapsedProgress
@onready var collapsed_progress_text: Label = $Collapsed/CollapsedContent/CollapsedFooter/ProgressText
@onready var collapsed_next_node: Label = $Collapsed/CollapsedContent/CollapsedFooter/NextNode
@onready var exp_today_label: Label = $Expanded/TodayRow/TodayCopy/TodayValue
@onready var exp_month_label: Label = $Expanded/MetricsRow/MonthRow/MonthValue
@onready var exp_rate_label: Label = $Expanded/MetricsRow/RateRow/RateValue
@onready var exp_progress_bar: ProgressBar = $Expanded/ProgressRow/ProgressBar
@onready var exp_progress_text: Label = $Expanded/ProgressRow/ProgressHeader/ProgressText
@onready var exp_state_label: Label = $Expanded/TodayRow/StateValue
@onready var exp_today_title: Label = $Expanded/TodayRow/TodayCopy/TodayLabel
@onready var exp_month_title: Label = $Expanded/MetricsRow/MonthRow/MonthLabel
@onready var exp_rate_title: Label = $Expanded/MetricsRow/RateRow/RateLabel
@onready var exp_progress_title: Label = $Expanded/ProgressRow/ProgressHeader/ProgressLabel
@onready var exp_today_row: Control = $Expanded/TodayRow
@onready var exp_month_row: Control = $Expanded/MetricsRow/MonthRow
@onready var exp_rate_row: Control = $Expanded/MetricsRow/RateRow
@onready var exp_progress_row: Control = $Expanded/ProgressRow
@onready var exp_state_row: Control = $Expanded/TodayRow/StateValue
@onready var exp_schedule_row: Control = $Expanded/ScheduleRow
@onready var exp_schedule_title: Label = $Expanded/ScheduleRow/ScheduleLabel
@onready var exp_schedule_value: Label = $Expanded/ScheduleRow/ScheduleValue

var _tween: Tween = null
var _display_scale: float = 1.0

const SURFACE_PAPER := Color(1.000, 0.994, 0.984, 0.99)
const TEXT_INK := Color(0.188, 0.169, 0.149, 1.0)
const TEXT_MUTED := Color(0.463, 0.412, 0.365, 1.0)
const ACCENT_COIN := Color(0.949, 0.706, 0.227, 1.0)
const ACCENT_MINT := Color(0.439, 0.608, 0.455, 1.0)
const BORDER_WARM := Color(0.271, 0.208, 0.153, 0.12)
const SHADOW_WARM := Color(0.188, 0.169, 0.149, 0.14)
const COLLAPSED_BASE_SIZE := Vector2(300, 124)
const EXPANDED_BASE_SIZE := Vector2(344, 232)
const EXPANDED_CONTENT_BASE_SIZE := Vector2(312, 200)
const PanelLayoutScript := preload("res://src/utils/pet_panel_layout.gd")


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	gui_input.connect(_on_gui_input)
	theme = _build_panel_theme()
	custom_minimum_size = _scaled_size(COLLAPSED_BASE_SIZE)
	expanded_container.visible = false
	collapsed_container.visible = true
	_apply_style()
	_apply_panel_config()
	refresh_values()
	_update_background()
	PanelSystem.register_panel(self)


func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		details_requested.emit()
		accept_event()


func expand() -> void:
	_kill_tween()
	collapsed_container.visible = false
	expanded_container.visible = true
	custom_minimum_size = _scaled_size(EXPANDED_BASE_SIZE)
	expanded_container.size = _scaled_size(EXPANDED_CONTENT_BASE_SIZE)
	expanded_container.scale = Vector2(0.97, 0.97)
	expanded_container.modulate = Color(1, 1, 1, 0.0)
	_tween = create_tween()
	_tween.set_ease(Tween.EASE_OUT)
	_tween.set_trans(Tween.TRANS_CUBIC)
	_tween.parallel().tween_property(expanded_container, "modulate", Color.WHITE, 0.16)
	_tween.tween_property(expanded_container, "scale", Vector2.ONE, 0.20)
	refresh_values()
	_apply_panel_config()
	_update_background()


func collapse() -> void:
	_kill_tween()
	expanded_container.visible = false
	collapsed_container.visible = true
	custom_minimum_size = _scaled_size(COLLAPSED_BASE_SIZE)
	collapsed_container.position = Vector2.ZERO
	collapsed_container.size = custom_minimum_size
	collapsed_container.scale = Vector2(0.98, 0.98)
	collapsed_container.modulate = Color(1, 1, 1, 0.0)
	_tween = create_tween()
	_tween.set_ease(Tween.EASE_OUT)
	_tween.set_trans(Tween.TRANS_CUBIC)
	_tween.parallel().tween_property(collapsed_container, "modulate", Color.WHITE, 0.14)
	_tween.tween_property(collapsed_container, "scale", Vector2.ONE, 0.18)
	_update_background()


func set_display_scale(value: float) -> void:
	var next_scale: float = clamp(value, 0.5, 2.0)
	if is_equal_approx(next_scale, _display_scale):
		return
	_display_scale = next_scale
	scale = Vector2.ONE
	if expanded_container.visible:
		custom_minimum_size = _scaled_size(EXPANDED_BASE_SIZE)
		expanded_container.size = _scaled_size(EXPANDED_CONTENT_BASE_SIZE)
	else:
		custom_minimum_size = _scaled_size(COLLAPSED_BASE_SIZE)
		collapsed_container.size = custom_minimum_size
	_apply_style()
	_update_background()


func refresh_values() -> void:
	var today := SalaryEngine.get_earnings_today()
	earnings_today_label.text = "¥%.2f" % today
	collapsed_status_label.text = _get_collapsed_status_text()
	exp_today_label.text = "¥%.2f" % today
	exp_month_label.text = "¥%.2f" % SalaryEngine.get_earnings_this_month()
	exp_rate_label.text = "¥%.2f/小时" % SalaryEngine.get_hourly_rate()
	var progress := SalaryEngine.get_work_progress() * 100.0
	collapsed_progress_bar.value = progress
	exp_progress_bar.value = progress
	exp_progress_text.text = "%.0f%% · %.2f小时" % [progress, SalaryEngine.get_work_hours_per_day()]
	exp_state_label.text = SalaryEngine.get_state_text()
	exp_schedule_value.text = _get_next_schedule_node_text()
	collapsed_progress_text.text = "工作进度 %.0f%%" % progress
	collapsed_next_node.text = exp_schedule_value.text
	_fit_dynamic_text()


func _apply_panel_config() -> void:
	_set_row_visible(exp_today_row, Config.get_panel_item("earnings_today"))
	_set_row_visible(exp_month_row, Config.get_panel_item("earnings_month"))
	_set_row_visible(exp_rate_row, Config.get_panel_item("hourly_rate"))
	_set_row_visible(exp_progress_row, Config.get_panel_item("work_progress"))
	_set_row_visible(exp_state_row, Config.get_panel_item("status"))
	exp_schedule_row.visible = true


func _set_row_visible(row: Control, visible: bool) -> void:
	if row != null:
		row.visible = visible


func _apply_style() -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = SURFACE_PAPER
	style.border_color = BORDER_WARM
	style.set_border_width_all(1)
	style.set_corner_radius_all(_scaled_int(18))
	style.shadow_color = SHADOW_WARM
	style.shadow_size = _scaled_int(8)
	style.shadow_offset = Vector2(0, _scaled_int(4))
	background.add_theme_stylebox_override("panel", style)
	add_theme_font_size_override("font_size", _font_size(14))
	_apply_collapsed_text_style()
	_apply_expanded_text_style()
	_apply_progress_style()


func _apply_collapsed_text_style() -> void:
	collapsed_content.custom_minimum_size = _scaled_size(Vector2(268, 96))
	collapsed_content.add_theme_constant_override("separation", _scaled_int(4))
	collapsed_caption_label.add_theme_font_size_override("font_size", _font_size(12))
	collapsed_caption_label.add_theme_color_override("font_color", TEXT_MUTED)
	collapsed_status_label.add_theme_font_size_override("font_size", _font_size(12))
	collapsed_status_label.add_theme_color_override("font_color", Color(0.306, 0.451, 0.329, 1.0))
	earnings_today_label.add_theme_font_size_override("font_size", _font_size(30))
	earnings_today_label.add_theme_color_override("font_color", TEXT_INK)
	earnings_today_label.add_theme_font_override("font", _build_number_font())
	collapsed_progress_text.add_theme_font_size_override("font_size", _font_size(11))
	collapsed_progress_text.add_theme_color_override("font_color", TEXT_MUTED)
	collapsed_next_node.add_theme_font_size_override("font_size", _font_size(11))
	collapsed_next_node.add_theme_color_override("font_color", TEXT_MUTED)


func _update_background() -> void:
	await get_tree().process_frame
	var target_size := custom_minimum_size
	if expanded_container.visible:
		expanded_container.size = _scaled_size(EXPANDED_CONTENT_BASE_SIZE)
	size = target_size
	background.size = target_size
	collapsed_container.size = target_size
	expanded_container.position = Vector2(_scaled_int(16), _scaled_int(16))
	layout_changed.emit()


func _kill_tween() -> void:
	if _tween != null:
		_tween.kill()
		_tween = null


func _get_collapsed_status_text() -> String:
	var state_text := SalaryEngine.get_state_text()
	if state_text == "未设置薪资":
		return "待设置"
	if state_text.contains("午休"):
		return "午休中"
	if state_text.contains("工作"):
		return "工作中"
	if state_text.contains("上班"):
		return "未开始"
	if state_text.contains("下班"):
		return "已下班"
	return "休息中"


func _apply_expanded_text_style() -> void:
	expanded_container.add_theme_constant_override("separation", _scaled_int(10))
	exp_today_row.custom_minimum_size = _scaled_size(Vector2(312, 50))
	exp_month_row.custom_minimum_size = Vector2.ZERO
	exp_rate_row.custom_minimum_size = Vector2.ZERO
	exp_progress_row.custom_minimum_size = _scaled_size(Vector2(312, 36))
	exp_progress_row.add_theme_constant_override("separation", _scaled_int(5))
	exp_schedule_row.custom_minimum_size = _scaled_size(Vector2(312, 28))
	exp_schedule_row.add_theme_constant_override("separation", _scaled_int(10))
	exp_schedule_title.add_theme_font_size_override("font_size", _font_size(12))
	exp_schedule_title.add_theme_color_override("font_color", TEXT_MUTED)
	exp_schedule_value.add_theme_font_size_override("font_size", _font_size(12))
	exp_schedule_value.add_theme_color_override("font_color", TEXT_INK)
	exp_progress_bar.custom_minimum_size = Vector2(0, _scaled_int(5))
	exp_today_title.add_theme_font_size_override("font_size", _font_size(12))
	exp_today_title.add_theme_color_override("font_color", TEXT_MUTED)
	exp_today_label.add_theme_font_size_override("font_size", _font_size(30))
	exp_today_label.add_theme_color_override("font_color", TEXT_INK)
	exp_today_label.add_theme_font_override("font", _build_number_font())
	exp_state_label.custom_minimum_size = _scaled_size(Vector2(82, 28))
	exp_state_label.add_theme_font_size_override("font_size", _font_size(12))
	exp_state_label.add_theme_color_override("font_color", Color(0.306, 0.451, 0.329, 1.0))
	exp_state_label.add_theme_stylebox_override("normal", _status_chip_style())
	for label in [exp_month_title, exp_rate_title, exp_progress_title]:
		label.add_theme_font_size_override("font_size", _font_size(12))
		label.add_theme_color_override("font_color", TEXT_MUTED)
	for label in [exp_month_label, exp_rate_label, exp_progress_text]:
		label.add_theme_font_size_override("font_size", _font_size(14))
		label.add_theme_color_override("font_color", TEXT_INK)


func _fit_dynamic_text() -> void:
	earnings_today_label.add_theme_font_size_override(
		"font_size",
		_font_size(PanelLayoutScript.amount_font_size(earnings_today_label.text, 30))
	)
	exp_today_label.add_theme_font_size_override(
		"font_size",
		_font_size(PanelLayoutScript.amount_font_size(exp_today_label.text, 30))
	)
	exp_month_label.add_theme_font_size_override("font_size", _font_size(13 if exp_month_label.text.length() > 11 else 14))
	exp_rate_label.add_theme_font_size_override("font_size", _font_size(12 if exp_rate_label.text.length() > 12 else 14))
	exp_state_label.add_theme_font_size_override("font_size", _font_size(10 if exp_state_label.text.length() > 6 else 12))
	collapsed_status_label.add_theme_font_size_override("font_size", _font_size(10 if collapsed_status_label.text.length() > 6 else 12))
	exp_schedule_value.add_theme_font_size_override("font_size", _font_size(11 if exp_schedule_value.text.length() > 12 else 12))
	collapsed_next_node.add_theme_font_size_override("font_size", _font_size(10 if collapsed_next_node.text.length() > 12 else 11))


func _status_chip_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.875, 0.918, 0.863, 1.0)
	style.border_color = Color(ACCENT_MINT.r, ACCENT_MINT.g, ACCENT_MINT.b, 0.22)
	style.set_border_width_all(1)
	style.set_corner_radius_all(999)
	style.content_margin_left = _scaled_int(9)
	style.content_margin_right = _scaled_int(9)
	style.content_margin_top = _scaled_int(4)
	style.content_margin_bottom = _scaled_int(4)
	return style


func _get_next_schedule_node_text() -> String:
	var snapshot := SalaryEngine.get_current_snapshot()
	var state := String(snapshot.get("state", "setup_required"))
	var reason := String(snapshot.get("state_reason", ""))
	if state == "setup_required":
		return "完成设置后显示"
	if reason == "lunch":
		return "%s 继续工作" % String(Config.get_value("lunch_end_time", "14:00"))
	if state == "working":
		var now := Time.get_datetime_dict_from_system()
		var current_minutes := int(now.get("hour", 0)) * 60 + int(now.get("minute", 0))
		var lunch_start := _time_to_minutes(String(Config.get_value("lunch_start_time", "12:00")))
		if lunch_start >= 0 and current_minutes < lunch_start:
			return "%s 午休" % String(Config.get_value("lunch_start_time", "12:00"))
		return "%s 下班" % String(Config.get_value("work_end_time", "18:00"))
	return "%s 开始工作" % String(Config.get_value("work_start_time", "08:00"))


func _time_to_minutes(value: String) -> int:
	var parts := value.split(":")
	if parts.size() != 2 or not parts[0].is_valid_int() or not parts[1].is_valid_int():
		return -1
	return int(parts[0]) * 60 + int(parts[1])


func _apply_progress_style() -> void:
	var background_style := StyleBoxFlat.new()
	background_style.bg_color = Color(TEXT_MUTED.r, TEXT_MUTED.g, TEXT_MUTED.b, 0.14)
	background_style.set_corner_radius_all(999)
	exp_progress_bar.add_theme_stylebox_override("background", background_style)
	collapsed_progress_bar.add_theme_stylebox_override("background", background_style)
	var fill_style := StyleBoxFlat.new()
	fill_style.bg_color = ACCENT_COIN
	fill_style.set_corner_radius_all(999)
	exp_progress_bar.add_theme_stylebox_override("fill", fill_style)
	collapsed_progress_bar.add_theme_stylebox_override("fill", fill_style)


func _build_panel_theme() -> Theme:
	var panel_theme := Theme.new()
	var font := SystemFont.new()
	font.font_names = PackedStringArray(["Segoe UI Variable", "Microsoft YaHei UI", "Microsoft YaHei", "Segoe UI"])
	font.antialiasing = TextServer.FONT_ANTIALIASING_GRAY
	font.hinting = TextServer.HINTING_NORMAL
	font.subpixel_positioning = TextServer.SUBPIXEL_POSITIONING_AUTO
	panel_theme.default_font = font
	panel_theme.default_font_size = 14
	return panel_theme


func _build_number_font() -> Font:
	var font := SystemFont.new()
	font.font_names = PackedStringArray(["Segoe UI Variable", "Segoe UI", "Microsoft YaHei UI", "Microsoft YaHei"])
	font.antialiasing = TextServer.FONT_ANTIALIASING_GRAY
	font.hinting = TextServer.HINTING_NORMAL
	font.subpixel_positioning = TextServer.SUBPIXEL_POSITIONING_AUTO
	return font


func _scaled_size(base: Vector2) -> Vector2:
	return Vector2(_scaled_int(base.x), _scaled_int(base.y))


func _scaled_int(value: float) -> int:
	return int(round(value * _display_scale))


func _font_size(base: int) -> int:
	return maxi(11, _scaled_int(base))
