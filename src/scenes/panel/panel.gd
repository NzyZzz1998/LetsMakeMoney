# src/scenes/panel/panel.gd
extends Control

@onready var background: Panel = $Background
@onready var collapsed_container: CenterContainer = $Collapsed
@onready var expanded_container: VBoxContainer = $Expanded
@onready var earnings_today_label: Label = $Collapsed/EarningsToday
@onready var exp_today_label: Label = $Expanded/TodayRow/TodayValue
@onready var exp_month_label: Label = $Expanded/MonthRow/MonthValue
@onready var exp_rate_label: Label = $Expanded/RateRow/RateValue
@onready var exp_progress_bar: ProgressBar = $Expanded/ProgressRow/ProgressBar
@onready var exp_progress_text: Label = $Expanded/ProgressRow/ProgressText
@onready var exp_state_label: Label = $Expanded/StateRow/StateValue
@onready var exp_today_row: Control = $Expanded/TodayRow
@onready var exp_month_row: Control = $Expanded/MonthRow
@onready var exp_rate_row: Control = $Expanded/RateRow
@onready var exp_progress_row: Control = $Expanded/ProgressRow
@onready var exp_state_row: Control = $Expanded/StateRow

var _tween: Tween = null


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS
	custom_minimum_size = Vector2(150, 54)
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
	custom_minimum_size = Vector2(300, 206)
	expanded_container.size = Vector2(270, 180)
	expanded_container.scale = Vector2(0.9, 0.9)
	_tween = create_tween()
	_tween.set_ease(Tween.EASE_OUT)
	_tween.set_trans(Tween.TRANS_CUBIC)
	_tween.tween_property(expanded_container, "scale", Vector2.ONE, 0.18)
	refresh_values()
	_apply_panel_config()
	_update_background()


func collapse() -> void:
	_kill_tween()
	expanded_container.visible = false
	collapsed_container.visible = true
	custom_minimum_size = Vector2(150, 54)
	collapsed_container.position = Vector2.ZERO
	collapsed_container.size = custom_minimum_size
	collapsed_container.scale = Vector2(0.9, 0.9)
	_tween = create_tween()
	_tween.set_ease(Tween.EASE_OUT)
	_tween.set_trans(Tween.TRANS_CUBIC)
	_tween.tween_property(collapsed_container, "scale", Vector2.ONE, 0.18)
	_update_background()


func refresh_values() -> void:
	var today := SalaryEngine.get_earnings_today()
	earnings_today_label.text = "¥%.2f" % today
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
	style.bg_color = Color(0.06, 0.07, 0.08, 0.78)
	style.border_color = Color(1.0, 1.0, 1.0, 0.12)
	style.set_border_width_all(1)
	style.set_corner_radius_all(8)
	background.add_theme_stylebox_override("panel", style)
	add_theme_font_size_override("font_size", 18)


func _update_background() -> void:
	await get_tree().process_frame
	var target_size := custom_minimum_size
	if expanded_container.visible:
		target_size = Vector2(max(target_size.x, expanded_container.size.x + 24), max(target_size.y, expanded_container.size.y + 24))
	else:
		target_size = custom_minimum_size
	size = target_size
	background.size = target_size


func _kill_tween() -> void:
	if _tween != null:
		_tween.kill()
		_tween = null
