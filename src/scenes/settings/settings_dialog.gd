# src/scenes/settings/settings_dialog.gd
extends Control

var salary_input: SpinBox
var rest_mode_option: OptionButton
var rest_mode_single_toggle: CheckButton
var hours_input: SpinBox
var start_hour_input: SpinBox
var start_min_input: SpinBox
var end_hour_input: SpinBox
var end_min_input: SpinBox
var pet_list: ItemList
var scale_slider: HSlider
var scale_value_label: Label
var opacity_slider: HSlider
var opacity_value_label: Label
var window_mode_option: OptionButton
var window_mode_embed_toggle: CheckButton
var pure_pet_mode_toggle: CheckButton
var native_status_label: Label
var debug_mode_toggle: CheckButton
var auto_start_toggle: CheckButton
var minimize_to_tray_toggle: CheckButton
var reset_position_button: Button
var restore_defaults_button: Button
var save_button: Button
var cancel_button: Button
var general_message_label: Label
var show_today: CheckBox
var show_month: CheckBox
var show_rate: CheckBox
var show_progress: CheckBox
var show_state: CheckBox


func _ready() -> void:
	custom_minimum_size = Vector2(700, 560)
	_build_ui()
	_load_current_values()


func _build_ui() -> void:
	var root := VBoxContainer.new()
	root.name = "SettingsRoot"
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.offset_left = 14
	root.offset_top = 14
	root.offset_right = -14
	root.offset_bottom = -14
	root.add_theme_constant_override("separation", 12)
	add_child(root)

	var top_action_row := HBoxContainer.new()
	top_action_row.name = "TopActionRow"
	top_action_row.alignment = BoxContainer.ALIGNMENT_END
	top_action_row.add_theme_constant_override("separation", 10)
	root.add_child(top_action_row)

	var top_cancel_button := Button.new()
	top_cancel_button.text = "取消"
	top_cancel_button.custom_minimum_size = Vector2(96, 32)
	top_cancel_button.pressed.connect(_on_cancel)
	top_action_row.add_child(top_cancel_button)

	var top_save_button := Button.new()
	top_save_button.text = "保存"
	top_save_button.custom_minimum_size = Vector2(112, 32)
	top_save_button.pressed.connect(_on_save)
	top_action_row.add_child(top_save_button)

	var tabs := TabContainer.new()
	tabs.name = "TabContainer"
	tabs.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(tabs)

	tabs.add_child(_build_salary_tab())
	tabs.add_child(_build_pet_tab())
	tabs.add_child(_build_display_tab())
	tabs.add_child(_build_panel_tab())
	tabs.add_child(_build_general_tab())

	var action_row := HBoxContainer.new()
	action_row.name = "ActionRow"
	action_row.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	action_row.offset_left = 14
	action_row.offset_top = -50
	action_row.offset_right = -14
	action_row.offset_bottom = -14
	action_row.alignment = BoxContainer.ALIGNMENT_END
	action_row.add_theme_constant_override("separation", 10)
	action_row.visible = false
	add_child(action_row)

	cancel_button = Button.new()
	cancel_button.name = "CancelButton"
	cancel_button.text = "取消"
	cancel_button.custom_minimum_size = Vector2(96, 34)
	cancel_button.pressed.connect(_on_cancel)
	action_row.add_child(cancel_button)

	save_button = Button.new()
	save_button.name = "SaveButton"
	save_button.text = "保存"
	save_button.custom_minimum_size = Vector2(112, 34)
	save_button.pressed.connect(_on_save)
	action_row.add_child(save_button)


func _build_salary_tab() -> Control:
	var root := _new_tab("Salary")
	var box := _new_vbox(root)
	_add_inline_actions(box)
	_add_label(box, "月薪（元）")
	salary_input = _add_spin(box, 0, 999999, 1)
	_add_label(box, "休息模式")
	rest_mode_option = OptionButton.new()
	rest_mode_option.add_item("双休", 0)
	rest_mode_option.add_item("单休", 1)
	box.add_child(rest_mode_option)
	rest_mode_single_toggle = CheckButton.new()
	rest_mode_single_toggle.text = "单休（关闭则为双休）"
	rest_mode_single_toggle.visible = false
	box.add_child(rest_mode_single_toggle)
	_add_label(box, "每日工作小时数（由上下班时间自动计算）")
	hours_input = _add_spin(box, 0, 24, 0.25)
	hours_input.editable = false
	_add_label(box, "上班时间")
	var start_row := _add_time_row(box)
	start_hour_input = start_row[0]
	start_min_input = start_row[1]
	_add_label(box, "下班时间")
	var end_row := _add_time_row(box)
	end_hour_input = end_row[0]
	end_min_input = end_row[1]
	_connect_time_inputs()
	return root


func _build_pet_tab() -> Control:
	var root := _new_tab("Pet")
	var box := _new_vbox(root)
	_add_inline_actions(box)
	_add_label(box, "选择角色")
	pet_list = ItemList.new()
	pet_list.custom_minimum_size = Vector2(0, 140)
	box.add_child(pet_list)
	_add_label(box, "缩放（50%-200%）")
	var scale_row := _add_slider_row(box, 50, 200, 1)
	scale_slider = scale_row[0]
	scale_value_label = scale_row[1]
	return root


func _build_display_tab() -> Control:
	var root := _new_tab("Display")
	var box := _new_vbox(root)
	_add_inline_actions(box)
	_add_label(box, "透明度（20%-100%）")
	var opacity_row := _add_slider_row(box, 20, 100, 1)
	opacity_slider = opacity_row[0]
	opacity_value_label = opacity_row[1]
	_add_label(box, "窗口模式")
	window_mode_option = OptionButton.new()
	window_mode_option.add_item("置顶悬浮", 0)
	window_mode_option.add_item("融入桌面（实验）", 1)
	box.add_child(window_mode_option)
	window_mode_embed_toggle = CheckButton.new()
	window_mode_embed_toggle.text = "融入桌面（关闭则为置顶悬浮，实验）"
	window_mode_embed_toggle.visible = false
	box.add_child(window_mode_embed_toggle)
	pure_pet_mode_toggle = CheckButton.new()
	pure_pet_mode_toggle.text = "纯桌宠模式（隐藏任务栏 / Alt+Tab，需托盘可用）"
	box.add_child(pure_pet_mode_toggle)
	native_status_label = Label.new()
	native_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	native_status_label.custom_minimum_size = Vector2(0, 52)
	box.add_child(native_status_label)
	return root


func _build_panel_tab() -> Control:
	var root := _new_tab("Panel")
	var box := _new_vbox(root)
	_add_inline_actions(box)
	show_today = _add_checkbox(box, "今日已赚")
	show_month = _add_checkbox(box, "本月累计")
	show_rate = _add_checkbox(box, "时薪")
	show_progress = _add_checkbox(box, "工作进度")
	show_state = _add_checkbox(box, "状态")
	return root


func _build_general_tab() -> Control:
	var root := _new_tab("General")
	var box := _new_vbox(root)
	_add_inline_actions(box)
	debug_mode_toggle = CheckButton.new()
	debug_mode_toggle.text = "Debug 模式"
	box.add_child(debug_mode_toggle)
	auto_start_toggle = CheckButton.new()
	auto_start_toggle.text = "开机自启"
	box.add_child(auto_start_toggle)
	minimize_to_tray_toggle = CheckButton.new()
	minimize_to_tray_toggle.text = "关闭时隐藏到托盘"
	box.add_child(minimize_to_tray_toggle)
	reset_position_button = Button.new()
	reset_position_button.text = "重置窗口位置"
	reset_position_button.pressed.connect(_on_reset_position_pressed)
	box.add_child(reset_position_button)
	restore_defaults_button = Button.new()
	restore_defaults_button.text = "恢复默认显示设置"
	restore_defaults_button.pressed.connect(_on_restore_defaults_pressed)
	box.add_child(restore_defaults_button)
	general_message_label = Label.new()
	general_message_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	general_message_label.custom_minimum_size = Vector2(0, 42)
	box.add_child(general_message_label)
	_add_label(box, "语言：中文")
	return root


func _new_tab(tab_name: String) -> Control:
	var margin := MarginContainer.new()
	margin.name = tab_name
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_bottom", 16)
	return margin


func _new_vbox(parent: Control) -> VBoxContainer:
	var box := VBoxContainer.new()
	box.name = "VBox"
	box.add_theme_constant_override("separation", 8)
	parent.add_child(box)
	return box


func _add_label(parent: Control, text: String) -> Label:
	var label := Label.new()
	label.text = text
	parent.add_child(label)
	return label


func _add_spin(parent: Control, min_value: float, max_value: float, step: float) -> SpinBox:
	var spin := SpinBox.new()
	spin.min_value = min_value
	spin.max_value = max_value
	spin.step = step
	spin.custom_minimum_size = Vector2(120, 0)
	parent.add_child(spin)
	return spin


func _add_slider(parent: Control, min_value: float, max_value: float, step: float) -> HSlider:
	var slider := HSlider.new()
	slider.min_value = min_value
	slider.max_value = max_value
	slider.step = step
	parent.add_child(slider)
	return slider


func _add_slider_row(parent: Control, min_value: float, max_value: float, step: float) -> Array:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	parent.add_child(row)
	var slider := _add_slider(row, min_value, max_value, step)
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var value_label := Label.new()
	value_label.custom_minimum_size = Vector2(72, 0)
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	value_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(value_label)
	return [slider, value_label]


func _add_checkbox(parent: Control, text: String) -> CheckBox:
	var checkbox := CheckBox.new()
	checkbox.text = text
	parent.add_child(checkbox)
	return checkbox


func _add_inline_actions(_parent: Control) -> void:
	return


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


func _load_current_values() -> void:
	salary_input.value = float(Config.get_value("monthly_salary", 0))
	var rm := String(Config.get_value("rest_mode", "double"))
	rest_mode_option.select(1 if rm == "single" else 0)
	rest_mode_single_toggle.button_pressed = rm == "single"
	var st := String(Config.get_value("work_start_time", "09:00")).split(":")
	start_hour_input.value = int(st[0]) if st.size() > 0 else 9
	start_min_input.value = int(st[1]) if st.size() > 1 else 0
	var et := String(Config.get_value("work_end_time", "18:00")).split(":")
	end_hour_input.value = int(et[0]) if et.size() > 0 else 18
	end_min_input.value = int(et[1]) if et.size() > 1 else 0

	scale_slider.value = float(Config.get_value("scale", 1.0)) * 100.0
	opacity_slider.value = float(Config.get_value("opacity", 1.0)) * 100.0
	if not scale_slider.value_changed.is_connected(_on_scale_slider_changed):
		scale_slider.value_changed.connect(_on_scale_slider_changed)
	if not opacity_slider.value_changed.is_connected(_on_opacity_slider_changed):
		opacity_slider.value_changed.connect(_on_opacity_slider_changed)
	_update_slider_labels()

	var wm := String(Config.get_value("window_mode", "top"))
	window_mode_option.select(1 if wm == "embed" else 0)
	window_mode_embed_toggle.button_pressed = wm == "embed"
	pure_pet_mode_toggle.button_pressed = bool(Config.get_value("pure_pet_mode", false))
	_update_native_status_label()
	debug_mode_toggle.button_pressed = bool(Config.get_value("debug_mode", false))
	auto_start_toggle.button_pressed = bool(Config.get_value("auto_start", false))
	minimize_to_tray_toggle.button_pressed = bool(Config.get_value("minimize_to_tray", true))

	_populate_pet_list()
	_load_panel_checkboxes()
	_update_hours_preview()


func _populate_pet_list() -> void:
	pet_list.clear()
	var pets := PetManager.get_available_pets()
	var current_id := String(Config.get_value("pet_id", "cat"))
	for i in range(pets.size()):
		pet_list.add_item(pets[i].display_name)
		if pets[i].pet_id == current_id:
			pet_list.select(i)


func _load_panel_checkboxes() -> void:
	show_today.button_pressed = Config.get_panel_item("earnings_today")
	show_month.button_pressed = Config.get_panel_item("earnings_month")
	show_rate.button_pressed = Config.get_panel_item("hourly_rate")
	show_progress.button_pressed = Config.get_panel_item("work_progress")
	show_state.button_pressed = Config.get_panel_item("status")


func _on_save() -> void:
	_update_slider_labels()
	Config.set_value("monthly_salary", float(salary_input.value))
	Config.set_value("rest_mode", "single" if rest_mode_option.selected == 1 else "double")
	Config.set_value("work_start_time", "%02d:%02d" % [int(start_hour_input.value), int(start_min_input.value)])
	Config.set_value("work_end_time", "%02d:%02d" % [int(end_hour_input.value), int(end_min_input.value)])
	Config.set_value("work_hours_per_day", _calculate_work_hours())
	Config.set_value("scale", scale_slider.value / 100.0)
	Config.set_value("opacity", opacity_slider.value / 100.0)
	Config.set_value("window_mode", "embed" if window_mode_option.selected == 1 else "top")
	Config.set_value("pure_pet_mode", pure_pet_mode_toggle.button_pressed and not pure_pet_mode_toggle.disabled)
	Config.set_value("debug_mode", debug_mode_toggle.button_pressed)
	Config.set_value("minimize_to_tray", minimize_to_tray_toggle.button_pressed)

	Config.set_panel_item("earnings_today", show_today.button_pressed)
	Config.set_panel_item("earnings_month", show_month.button_pressed)
	Config.set_panel_item("hourly_rate", show_rate.button_pressed)
	Config.set_panel_item("work_progress", show_progress.button_pressed)
	Config.set_panel_item("status", show_state.button_pressed)

	var selected := pet_list.get_selected_items()
	if selected.size() > 0:
		var pets := PetManager.get_available_pets()
		if int(selected[0]) < pets.size():
			var pet_id := pets[int(selected[0])].pet_id
			Config.set_value("pet_id", pet_id)
			PetManager.switch_pet(pet_id)

	_apply_auto_start_setting()
	Config.save()
	queue_free()


func _on_cancel() -> void:
	queue_free()


func _on_scale_slider_changed(value: float) -> void:
	_update_scale_label(value)


func _on_opacity_slider_changed(value: float) -> void:
	_update_opacity_label(value)


func _update_slider_labels() -> void:
	_update_scale_label(scale_slider.value)
	_update_opacity_label(opacity_slider.value)


func _update_scale_label(value: float) -> void:
	if scale_value_label != null:
		scale_value_label.text = "%d%%" % int(round(value))


func _update_opacity_label(value: float) -> void:
	if opacity_value_label != null:
		opacity_value_label.text = "%d%%" % int(round(value))


func _update_native_status_label() -> void:
	if native_status_label == null or pure_pet_mode_toggle == null:
		return
	var health := Platform.get_native_health()
	var tray_ok := bool(health.get("tray_supported", false))
	var passthrough_ok := bool(health.get("passthrough_supported", false))
	var host_window := DragResizeSystem.get_registered_window()
	var pure_ok := host_window != null and Platform.can_enable_pure_pet_mode(host_window)
	native_status_label.text = "原生能力：托盘 %s，点击穿透 %s，纯桌宠 %s。" % [
		"可用" if tray_ok else "不可用",
		"可用" if passthrough_ok else "不可用",
		"可用" if pure_ok else "不可用"
	]
	if not pure_ok:
		pure_pet_mode_toggle.disabled = true
		pure_pet_mode_toggle.button_pressed = false
	else:
		pure_pet_mode_toggle.disabled = false


func get_v02_control_names() -> Array[String]:
	return [
		"auto_start_toggle",
		"debug_mode_toggle",
		"minimize_to_tray_toggle",
		"reset_position_button",
		"restore_defaults_button"
	]


func _apply_auto_start_setting() -> bool:
	var desired := auto_start_toggle.button_pressed
	var actual := bool(Config.get_value("auto_start", false))
	if desired == actual:
		return true
	if not desired:
		if Platform.set_auto_start(false):
			Config.set_value("auto_start", false)
			return true
		if not Platform.is_auto_start_supported():
			Config.set_value("auto_start", false)
			return true
	if Platform.set_auto_start(desired):
		Config.set_value("auto_start", desired)
		return true
	actual = Platform.is_auto_start_enabled()
	Config.set_value("auto_start", actual)
	auto_start_toggle.button_pressed = actual
	if general_message_label != null:
		general_message_label.text = "开机自启设置失败：请使用导出的 LetsMakeMoney.exe 再试。"
	return false


func _on_reset_position_pressed() -> void:
	DragResizeSystem.reset_window_position()
	if general_message_label != null:
		general_message_label.text = "窗口位置已重置。"


func _on_restore_defaults_pressed() -> void:
	Config.reset_display_defaults()
	Platform.set_auto_start(false)
	_load_current_values()
	if general_message_label != null:
		general_message_label.text = "显示、窗口、托盘和自启动设置已恢复默认。"
	Config.save()
