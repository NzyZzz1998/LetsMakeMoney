# src/scenes/panel/panel.gd
extends Control

signal layout_changed

@onready var background: Panel = $Background
@onready var collapsed_container: CenterContainer = $Collapsed
@onready var expanded_container: VBoxContainer = $Expanded
@onready var collapsed_content: HBoxContainer = $Collapsed/CollapsedContent
@onready var coin_mark_label: Label = $Collapsed/CollapsedContent/CoinMark
@onready var earnings_today_label: Label = $Collapsed/CollapsedContent/CollapsedValue/EarningsToday
@onready var collapsed_status_label: Label = $Collapsed/CollapsedContent/CollapsedValue/ShortStatus
@onready var exp_today_label: Label = $Expanded/TodayRow/TodayValue
@onready var exp_month_label: Label = $Expanded/MonthRow/MonthValue
@onready var exp_rate_label: Label = $Expanded/RateRow/RateValue
@onready var exp_progress_bar: ProgressBar = $Expanded/ProgressRow/ProgressBar
@onready var exp_progress_text: Label = $Expanded/ProgressRow/ProgressText
@onready var exp_state_label: Label = $Expanded/StateRow/StateValue
@onready var exp_today_title: Label = $Expanded/TodayRow/TodayLabel
@onready var exp_month_title: Label = $Expanded/MonthRow/MonthLabel
@onready var exp_rate_title: Label = $Expanded/RateRow/RateLabel
@onready var exp_progress_title: Label = $Expanded/ProgressRow/ProgressLabel
@onready var exp_state_title: Label = $Expanded/StateRow/StateLabel
@onready var exp_today_row: Control = $Expanded/TodayRow
@onready var exp_month_row: Control = $Expanded/MonthRow
@onready var exp_rate_row: Control = $Expanded/RateRow
@onready var exp_progress_row: Control = $Expanded/ProgressRow
@onready var exp_state_row: Control = $Expanded/StateRow

var _tween: Tween = null
var _display_scale: float = 1.0

const SURFACE_PAPER := Color(1.0, 0.965, 0.878, 0.99)
const SURFACE_PAPER_STRONG := Color(1.0, 0.945, 0.792, 1.0)
const TEXT_INK := Color(0.227, 0.153, 0.098, 1.0)
const TEXT_MUTED := Color(0.550, 0.420, 0.298, 1.0)
const ACCENT_COIN := Color(0.965, 0.714, 0.243, 1.0)
const ACCENT_ORANGE := Color(0.780, 0.420, 0.137, 1.0)
const ACCENT_MINT := Color(0.427, 0.624, 0.447, 1.0)
const BORDER_WARM := Color(0.416, 0.263, 0.122, 0.16)
const SHADOW_WARM := Color(0.360, 0.184, 0.047, 0.20)
const COLLAPSED_BASE_SIZE := Vector2(214, 64)
const EXPANDED_BASE_SIZE := Vector2(328, 238)
const EXPANDED_CONTENT_BASE_SIZE := Vector2(292, 202)


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	theme = _build_panel_theme()
	custom_minimum_size = _scaled_size(COLLAPSED_BASE_SIZE)
	expanded_container.visible = false
	collapsed_container.visible = true
	_apply_style()
	_apply_panel_config()
	refresh_values()
	_update_background()
	PanelSystem.register_panel(self)


func expand() -> void:
	_kill_tween()
	collapsed_container.visible = false
	expanded_container.visible = true
	custom_minimum_size = _scaled_size(EXPANDED_BASE_SIZE)
	expanded_container.size = _scaled_size(EXPANDED_CONTENT_BASE_SIZE)
	expanded_container.scale = Vector2(0.96, 0.96)
	expanded_container.modulate = Color(1, 1, 1, 0.0)
	_tween = create_tween()
	_tween.set_ease(Tween.EASE_OUT)
	_tween.set_trans(Tween.TRANS_CUBIC)
	_tween.parallel().tween_property(expanded_container, "modulate", Color.WHITE, 0.16)
	_tween.tween_property(expanded_container, "scale", Vector2.ONE, 0.18)
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
	collapsed_container.scale = Vector2(0.97, 0.97)
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
	exp_progress_bar.value = progress
	exp_progress_text.text = "%.0f%% · %s · %.2f小时" % [
		progress,
		SalaryEngine.get_work_time_range_text(),
		SalaryEngine.get_work_hours_per_day()
	]
	exp_state_label.text = SalaryEngine.get_state_text()


func _apply_panel_config() -> void:
	_set_row_visible(exp_today_row, Config.get_panel_item("earnings_today"))
	_set_row_visible(exp_month_row, Config.get_panel_item("earnings_month"))
	_set_row_visible(exp_rate_row, Config.get_panel_item("hourly_rate"))
	_set_row_visible(exp_progress_row, Config.get_panel_item("work_progress"))
	_set_row_visible(exp_state_row, Config.get_panel_item("status"))


func _set_row_visible(row: Control, visible: bool) -> void:
	if row != null:
		row.visible = visible


func _apply_style() -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = SURFACE_PAPER
	style.border_color = BORDER_WARM
	style.set_border_width_all(1)
	style.set_corner_radius_all(16)
	style.shadow_color = SHADOW_WARM
	style.shadow_size = 12
	style.shadow_offset = Vector2(0, 6)
	background.add_theme_stylebox_override("panel", style)
	add_theme_font_size_override("font_size", _font_size(16))
	_apply_coin_mark_style()
	earnings_today_label.add_theme_font_size_override("font_size", _font_size(23))
	earnings_today_label.add_theme_color_override("font_color", TEXT_INK)
	earnings_today_label.add_theme_font_override("font", _build_number_font())
	collapsed_status_label.add_theme_font_size_override("font_size", _font_size(12))
	collapsed_status_label.add_theme_color_override("font_color", TEXT_MUTED)
	collapsed_content.alignment = BoxContainer.ALIGNMENT_CENTER
	collapsed_content.add_theme_constant_override("separation", _scaled_int(10))
	_apply_expanded_text_style()
	_apply_progress_style()


func _apply_coin_mark_style() -> void:
	if coin_mark_label == null:
		return
	var coin_style := StyleBoxFlat.new()
	coin_style.bg_color = ACCENT_COIN
	coin_style.border_color = Color(0.780, 0.420, 0.137, 0.20)
	coin_style.set_border_width_all(1)
	coin_style.set_corner_radius_all(999)
	coin_style.shadow_color = Color(0.780, 0.420, 0.137, 0.24)
	coin_style.shadow_size = 5
	coin_style.shadow_offset = Vector2(0, 2)
	coin_mark_label.custom_minimum_size = _scaled_size(Vector2(34, 34))
	coin_mark_label.add_theme_stylebox_override("normal", coin_style)
	coin_mark_label.add_theme_font_size_override("font_size", _font_size(18))
	coin_mark_label.add_theme_color_override("font_color", Color(0.482, 0.239, 0.063, 1.0))
	coin_mark_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	coin_mark_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER


func _update_background() -> void:
	await get_tree().process_frame
	var target_size := custom_minimum_size
	if expanded_container.visible:
		target_size = Vector2(max(target_size.x, expanded_container.size.x + _scaled_int(32)), max(target_size.y, expanded_container.size.y + _scaled_int(30)))
	else:
		target_size = custom_minimum_size
	size = target_size
	background.size = target_size
	expanded_container.position = Vector2(_scaled_int(18), _scaled_int(18))
	layout_changed.emit()


func _kill_tween() -> void:
	if _tween != null:
		_tween.kill()
		_tween = null


func _get_collapsed_status_text() -> String:
	var state_text := SalaryEngine.get_state_text()
	if state_text == "未设置薪资":
		return "待设置"
	if state_text.find("工作") >= 0:
		return "工作中"
	if state_text.find("上班") >= 0:
		return "未开始"
	return "休息中"


func _apply_expanded_text_style() -> void:
	expanded_container.add_theme_constant_override("separation", _scaled_int(8))
	for row in [exp_today_row, exp_month_row, exp_rate_row, exp_state_row]:
		if row != null:
			row.custom_minimum_size = Vector2(_scaled_int(292), 0)
			row.add_theme_constant_override("separation", _scaled_int(14))
	exp_progress_row.custom_minimum_size = Vector2(_scaled_int(292), 0)
	exp_progress_row.add_theme_constant_override("separation", _scaled_int(5))
	exp_progress_bar.custom_minimum_size = Vector2(0, _scaled_int(9))
	exp_today_title.add_theme_font_size_override("font_size", _font_size(13))
	exp_today_title.add_theme_color_override("font_color", TEXT_MUTED)
	exp_today_label.add_theme_font_size_override("font_size", _font_size(38))
	exp_today_label.add_theme_color_override("font_color", TEXT_INK)
	exp_today_label.add_theme_font_override("font", _build_number_font())
	exp_state_title.add_theme_font_size_override("font_size", _font_size(13))
	exp_state_title.add_theme_color_override("font_color", TEXT_MUTED)
	exp_state_label.add_theme_font_size_override("font_size", _font_size(13))
	exp_state_label.add_theme_color_override("font_color", ACCENT_ORANGE)
	for label in [exp_month_title, exp_rate_title, exp_progress_title]:
		label.add_theme_font_size_override("font_size", _font_size(13))
		label.add_theme_color_override("font_color", TEXT_MUTED)
	for label in [exp_month_label, exp_rate_label, exp_progress_text]:
		label.add_theme_font_size_override("font_size", _font_size(14))
		label.add_theme_color_override("font_color", TEXT_INK)
		label.add_theme_font_override("font", _build_number_font())


func _apply_progress_style() -> void:
	var background_style := StyleBoxFlat.new()
	background_style.bg_color = Color(0.416, 0.263, 0.122, 0.10)
	background_style.set_corner_radius_all(999)
	exp_progress_bar.add_theme_stylebox_override("background", background_style)
	var fill_style := StyleBoxFlat.new()
	fill_style.bg_color = Color(0.650, 0.760, 0.405, 1.0)
	fill_style.set_corner_radius_all(999)
	exp_progress_bar.add_theme_stylebox_override("fill", fill_style)


func _build_panel_theme() -> Theme:
	var panel_theme := Theme.new()
	var font := SystemFont.new()
	font.font_names = PackedStringArray(["Microsoft YaHei UI", "Microsoft YaHei", "Segoe UI"])
	font.antialiasing = TextServer.FONT_ANTIALIASING_LCD
	font.hinting = TextServer.HINTING_NORMAL
	font.subpixel_positioning = TextServer.SUBPIXEL_POSITIONING_AUTO
	panel_theme.default_font = font
	panel_theme.default_font_size = 16
	return panel_theme


func _build_number_font() -> Font:
	var font := SystemFont.new()
	font.font_names = PackedStringArray(["Cascadia Mono", "Consolas", "Microsoft YaHei UI", "Microsoft YaHei"])
	font.antialiasing = TextServer.FONT_ANTIALIASING_LCD
	font.hinting = TextServer.HINTING_NORMAL
	font.subpixel_positioning = TextServer.SUBPIXEL_POSITIONING_AUTO
	return font


func _scaled_size(base: Vector2) -> Vector2:
	return Vector2(_scaled_int(base.x), _scaled_int(base.y))


func _scaled_int(value: float) -> int:
	return int(round(value * _display_scale))


func _font_size(base: int) -> int:
	return maxi(12, _scaled_int(base))
