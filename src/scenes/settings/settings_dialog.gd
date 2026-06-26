# src/scenes/settings/settings_dialog.gd
extends ConfirmationDialog

var salary_input: SpinBox
var rest_mode_option: OptionButton
var hours_input: SpinBox
var start_hour_input: SpinBox
var start_min_input: SpinBox
var end_hour_input: SpinBox
var end_min_input: SpinBox
var pet_list: ItemList
var scale_slider: HSlider
var opacity_slider: HSlider
var window_mode_option: OptionButton
var show_today: CheckBox
var show_month: CheckBox
var show_rate: CheckBox
var show_progress: CheckBox
var show_state: CheckBox


func _ready() -> void:
	title = "设置"
	min_size = Vector2i(700, 560)
	confirmed.connect(_on_save)
	canceled.connect(_on_cancel)
	close_requested.connect(_on_cancel)
	_build_ui()
	_load_current_values()


func _build_ui() -> void:
	var tabs := TabContainer.new()
	tabs.name = "TabContainer"
	add_child(tabs)

	tabs.add_child(_build_salary_tab())
	tabs.add_child(_build_pet_tab())
	tabs.add_child(_build_display_tab())
	tabs.add_child(_build_panel_tab())
	tabs.add_child(_build_general_tab())


func _build_salary_tab() -> Control:
	var root := _new_tab("Salary")
	var box := _new_vbox(root)
	_add_label(box, "月薪 (元)")
	salary_input = _add_spin(box, 0, 999999, 1)
	_add_label(box, "休息模式")
	rest_mode_option = OptionButton.new()
	rest_mode_option.add_item("双休")
	rest_mode_option.add_item("单休")
	box.add_child(rest_mode_option)
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
	_add_label(box, "选择角色")
	pet_list = ItemList.new()
	pet_list.custom_minimum_size = Vector2(0, 140)
	box.add_child(pet_list)
	_add_label(box, "缩放 (50%-200%)")
	scale_slider = _add_slider(box, 50, 200, 1)
	return root


func _build_display_tab() -> Control:
	var root := _new_tab("Display")
	var box := _new_vbox(root)
	_add_label(box, "透明度 (20%-100%)")
	opacity_slider = _add_slider(box, 20, 100, 1)
	_add_label(box, "窗口模式")
	window_mode_option = OptionButton.new()
	window_mode_option.add_item("置顶悬浮")
	window_mode_option.add_item("融入桌面")
	box.add_child(window_mode_option)
	return root


func _build_panel_tab() -> Control:
	var root := _new_tab("Panel")
	var box := _new_vbox(root)
	show_today = _add_checkbox(box, "今日已赚")
	show_month = _add_checkbox(box, "本月累计")
	show_rate = _add_checkbox(box, "时薪")
	show_progress = _add_checkbox(box, "工作进度")
	show_state = _add_checkbox(box, "状态")
	return root


func _build_general_tab() -> Control:
	var root := _new_tab("General")
	var box := _new_vbox(root)
	_add_label(box, "开机自启 (v0.1 暂不支持)")
	var auto_start := _add_checkbox(box, "启用")
	auto_start.disabled = true
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


func _add_checkbox(parent: Control, text: String) -> CheckBox:
	var checkbox := CheckBox.new()
	checkbox.text = text
	parent.add_child(checkbox)
	return checkbox


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
	rest_mode_option.select(0 if rm == "double" else 1)
	var st := String(Config.get_value("work_start_time", "09:00")).split(":")
	start_hour_input.value = int(st[0]) if st.size() > 0 else 9
	start_min_input.value = int(st[1]) if st.size() > 1 else 0
	var et := String(Config.get_value("work_end_time", "18:00")).split(":")
	end_hour_input.value = int(et[0]) if et.size() > 0 else 18
	end_min_input.value = int(et[1]) if et.size() > 1 else 0

	scale_slider.value = float(Config.get_value("scale", 1.0)) * 100.0
	opacity_slider.value = float(Config.get_value("opacity", 1.0)) * 100.0

	var wm := String(Config.get_value("window_mode", "top"))
	window_mode_option.select(0 if wm == "top" else 1)

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
	Config.set_value("monthly_salary", float(salary_input.value))
	Config.set_value("rest_mode", "single" if rest_mode_option.selected == 1 else "double")
	Config.set_value("work_start_time", "%02d:%02d" % [int(start_hour_input.value), int(start_min_input.value)])
	Config.set_value("work_end_time", "%02d:%02d" % [int(end_hour_input.value), int(end_min_input.value)])
	Config.set_value("work_hours_per_day", _calculate_work_hours())
	Config.set_value("scale", scale_slider.value / 100.0)
	Config.set_value("opacity", opacity_slider.value / 100.0)
	Config.set_value("window_mode", "top" if window_mode_option.selected == 0 else "embed")

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

	Config.save()
	queue_free()


func _on_cancel() -> void:
	queue_free()
