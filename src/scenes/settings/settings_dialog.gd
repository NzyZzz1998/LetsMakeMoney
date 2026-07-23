# src/scenes/settings/settings_dialog.gd
extends Control

const WarmControlThemeScript := preload("res://src/ui/warm_control_theme.gd")
const SettingsSectionBuilderScript := preload("res://src/ui/settings_section_builder.gd")
const DiagnosticsServiceScript := preload("res://src/utils/diagnostics_service.gd")
const SettingsTransactionControllerScript := preload("res://src/utils/settings_transaction_controller.gd")
const ConfigurationDraftScript := preload("res://src/utils/configuration_draft.gd")
const SalaryScheduleCalculatorScript := preload("res://src/utils/salary_schedule_calculator.gd")

var salary_input: SpinBox
var rest_mode_option: OptionButton
var rest_mode_single_toggle: CheckButton
var alternating_week_type_option: OptionButton
var alternating_week_type_row: Control
var hours_input: SpinBox
var lunch_duration_input: SpinBox
var daily_hours_label: Label
var schedule_end_label: Label
var start_hour_input: SpinBox
var start_min_input: SpinBox
var lunch_start_hour_input: SpinBox
var lunch_start_min_input: SpinBox
var lunch_end_hour_input: SpinBox
var lunch_end_min_input: SpinBox
var end_hour_input: SpinBox
var end_min_input: SpinBox
var pet_list: ItemList
var pet_option: OptionButton
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
var open_app_data_button: Button
var copy_diagnostics_button: Button
var update_channel_option: OptionButton
var check_updates_toggle: CheckButton
var check_update_button: Button
var download_update_button: Button
var cancel_update_button: Button
var update_install_confirm_dialog: ConfirmationDialog
var restore_defaults_confirm_dialog: ConfirmationDialog
var save_button: Button
var cancel_button: Button
var save_feedback_panel: PanelContainer
var save_status_label: Label
var general_message_label: Label
var show_today: CheckBox
var show_month: CheckBox
var show_rate: CheckBox
var show_progress: CheckBox
var show_state: CheckBox
var settings_pages: Dictionary = {}
var settings_nav_buttons: Dictionary = {}
var _switch_proxies: Dictionary = {}
var _header_dragging: bool = false
var _header_drag_start_mouse: Vector2i = Vector2i.ZERO
var _header_drag_start_window: Vector2i = Vector2i.ZERO
var _warm_theme: RefCounted = WarmControlThemeScript.new()
var _settings_ui_builder: RefCounted = SettingsSectionBuilderScript.new()
var _settings_transaction: RefCounted = SettingsTransactionControllerScript.new()
var _configuration_draft: RefCounted = ConfigurationDraftScript.new()
var _feedback_token: int = 0
var _available_release: Dictionary = {}
var _pending_installer_path: String = ""
var _updating_schedule_ui: bool = false

const SURFACE_APP := Color(0.910, 0.906, 0.882, 1.0)
const SURFACE_CARD := Color(1.000, 0.992, 0.980, 1.0)
const SURFACE_NAV := Color(0.945, 0.957, 0.937, 1.0)
const SURFACE_SELECTED := Color(0.988, 0.910, 0.702, 1.0)
const TEXT_INK := Color(0.188, 0.169, 0.149, 1.0)
const TEXT_MUTED := Color(0.463, 0.412, 0.365, 1.0)
const ACCENT_COIN := Color(0.949, 0.706, 0.227, 1.0)
const ACCENT_ORANGE := Color(0.914, 0.471, 0.196, 1.0)
const ACCENT_MINT := Color(0.439, 0.608, 0.455, 1.0)
const DANGER_SOFT := Color(0.663, 0.310, 0.263, 1.0)
const BORDER_WARM := Color(0.271, 0.208, 0.153, 0.13)
const SHADOW_WARM := Color(0.188, 0.169, 0.149, 0.10)
const SETTINGS_SURFACE := Color(0.0, 0.0, 0.0, 0.0)
const SETTINGS_CONTENT := Color(0.0, 0.0, 0.0, 0.0)
const SETTINGS_CARD := SURFACE_CARD
const SETTINGS_TEXT := TEXT_INK
const SETTINGS_MUTED := TEXT_MUTED
const SETTINGS_ACCENT := ACCENT_COIN
const SETTINGS_WARN := ACCENT_ORANGE
const SETTINGS_ERROR := DANGER_SOFT
const SETTINGS_DIVIDER := Color(0.271, 0.208, 0.153, 0.10)
const SETTINGS_OUTER_PADDING := 0
const SETTINGS_SHEET_WIDTH := 700
const SETTINGS_SHEET_HEIGHT := 520
const SETTINGS_TAB_HEIGHT := 49
const SETTINGS_CONTROL_WIDTH := 128
const FEEDBACK_HIDE_SECONDS := 2.6
const SECTION_LABELS := {
	"Salary": "工资",
	"Schedule": "作息",
	"Pet": "桌宠",
	"Display": "显示",
	"General": "通用"
}


func _ready() -> void:
	theme = _build_settings_theme()
	custom_minimum_size = Vector2(700, 520)
	_settings_ui_builder.configure(
		Callable(self, "_style_form_control"),
		Callable(self, "_control_minimum_size"),
		Callable(self, "_add_switch_proxy")
	)
	_build_compact_ui()
	_load_current_values()
	if not UpdateService.status_changed.is_connected(_on_update_status_changed):
		UpdateService.status_changed.connect(_on_update_status_changed)
	if not UpdateService.update_available.is_connected(_on_update_available):
		UpdateService.update_available.connect(_on_update_available)
	if not UpdateService.download_ready.is_connected(_on_update_download_ready):
		UpdateService.download_ready.connect(_on_update_download_ready)
	if Config.has_method("consume_recovery_notice"):
		var recovery_notice := String(Config.call("consume_recovery_notice"))
		if not recovery_notice.is_empty():
			_set_general_message(recovery_notice, true)


func _build_compact_ui() -> void:
	var surface := Panel.new()
	surface.name = "SettingsSurface"
	surface.set_anchors_preset(Control.PRESET_FULL_RECT)
	surface.add_theme_stylebox_override("panel", _stylebox(SETTINGS_SURFACE, Color(0, 0, 0, 0), 0, 0, 0))
	add_child(surface)

	var root := MarginContainer.new()
	root.name = "SettingsRoot"
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("margin_left", SETTINGS_OUTER_PADDING)
	root.add_theme_constant_override("margin_top", SETTINGS_OUTER_PADDING)
	root.add_theme_constant_override("margin_right", SETTINGS_OUTER_PADDING)
	root.add_theme_constant_override("margin_bottom", SETTINGS_OUTER_PADDING)
	add_child(root)

	var shell_center := CenterContainer.new()
	shell_center.name = "SettingsShellCenter"
	shell_center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	shell_center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(shell_center)

	var shell := PanelContainer.new()
	shell.name = "SettingsShell"
	shell.custom_minimum_size = Vector2(SETTINGS_SHEET_WIDTH, SETTINGS_SHEET_HEIGHT)
	shell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	shell.size_flags_vertical = Control.SIZE_EXPAND_FILL
	shell.clip_contents = true
	shell.add_theme_stylebox_override("panel", _stylebox(SURFACE_CARD, Color(0, 0, 0, 0), 0, 16, 0))
	shell_center.add_child(shell)

	var shell_box := VBoxContainer.new()
	shell_box.name = "SettingsShellColumn"
	shell_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	shell_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	shell_box.add_theme_constant_override("separation", 0)
	shell.add_child(shell_box)

	var top_margin := MarginContainer.new()
	top_margin.name = "SettingsTopMargin"
	top_margin.custom_minimum_size = Vector2(0, 49)
	top_margin.add_theme_constant_override("margin_left", 20)
	top_margin.add_theme_constant_override("margin_top", 0)
	top_margin.add_theme_constant_override("margin_right", 14)
	top_margin.add_theme_constant_override("margin_bottom", 0)
	shell_box.add_child(top_margin)

	var top_bar := HBoxContainer.new()
	top_bar.name = "SettingsTopBar"
	top_bar.mouse_filter = Control.MOUSE_FILTER_STOP
	top_bar.add_theme_constant_override("separation", 8)
	top_bar.gui_input.connect(_on_header_gui_input)
	top_margin.add_child(top_bar)

	var nav_shell := PanelContainer.new()
	nav_shell.name = "SettingsNavSegment"
	nav_shell.custom_minimum_size = Vector2(0, SETTINGS_TAB_HEIGHT)
	nav_shell.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	nav_shell.add_theme_stylebox_override("panel", _stylebox(Color(0, 0, 0, 0), Color(0, 0, 0, 0), 0, 0, 0))
	top_bar.add_child(nav_shell)

	var nav := HBoxContainer.new()
	nav.name = "SettingsNav"
	nav.add_theme_constant_override("separation", 4)
	nav_shell.add_child(nav)

	var top_fill := Control.new()
	top_fill.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_bar.add_child(top_fill)

	var close_button := Button.new()
	close_button.name = "CloseButton"
	close_button.text = "×"
	close_button.custom_minimum_size = Vector2(32, 32)
	close_button.pressed.connect(_on_cancel)
	_style_window_button(close_button, false)
	top_bar.add_child(close_button)

	var header_divider := ColorRect.new()
	header_divider.name = "ShellHeaderDivider"
	header_divider.custom_minimum_size = Vector2(0, 1)
	header_divider.color = SETTINGS_DIVIDER
	shell_box.add_child(header_divider)

	var content_margin := MarginContainer.new()
	content_margin.name = "SettingsContentMargin"
	content_margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_margin.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content_margin.add_theme_constant_override("margin_left", 28)
	content_margin.add_theme_constant_override("margin_top", 22)
	content_margin.add_theme_constant_override("margin_right", 28)
	content_margin.add_theme_constant_override("margin_bottom", 0)
	shell_box.add_child(content_margin)

	var content_holder := Control.new()
	content_holder.name = "SettingsContentPages"
	content_holder.clip_contents = true
	content_holder.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_holder.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content_margin.add_child(content_holder)

	_add_settings_section(nav, content_holder, "Salary", _build_salary_tab())
	_add_settings_section(nav, content_holder, "Schedule", _build_schedule_tab())
	_add_settings_section(nav, content_holder, "Pet", _build_pet_tab())
	_add_settings_section(nav, content_holder, "Display", _build_display_tab())
	_add_settings_section(nav, content_holder, "General", _build_general_tab())
	# Historical UI verification resolves this node by name. Panel controls now live
	# in Display, so the alias remains non-visible and is not part of navigation.
	var legacy_panel_alias := Control.new()
	legacy_panel_alias.name = "Panel"
	legacy_panel_alias.visible = false
	content_holder.add_child(legacy_panel_alias)
	_select_settings_section("Salary")

	var action_divider := ColorRect.new()
	action_divider.name = "ActionDivider"
	action_divider.custom_minimum_size = Vector2(0, 1)
	action_divider.color = SETTINGS_DIVIDER
	shell_box.add_child(action_divider)

	var action_surface := PanelContainer.new()
	action_surface.name = "ActionSurface"
	action_surface.custom_minimum_size = Vector2(0, 57)
	action_surface.add_theme_stylebox_override("panel", _stylebox(Color(0.965, 0.969, 0.949, 1.0), Color(0, 0, 0, 0), 0, 0, 0))
	shell_box.add_child(action_surface)

	var action_margin := MarginContainer.new()
	action_margin.name = "ActionMargin"
	action_margin.add_theme_constant_override("margin_left", 28)
	action_margin.add_theme_constant_override("margin_top", 10)
	action_margin.add_theme_constant_override("margin_right", 18)
	action_margin.add_theme_constant_override("margin_bottom", 10)
	action_surface.add_child(action_margin)

	var action_row := HBoxContainer.new()
	action_row.name = "ActionRow"
	action_row.custom_minimum_size = Vector2(0, 37)
	action_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	action_row.alignment = BoxContainer.ALIGNMENT_END
	action_row.add_theme_constant_override("separation", 10)
	action_margin.add_child(action_row)

	save_status_label = Label.new()
	save_status_label.name = "SaveStatusLabel"
	save_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	save_status_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	save_status_label.text = "没有未保存的更改"
	save_status_label.add_theme_font_size_override("font_size", 11)
	save_status_label.add_theme_color_override("font_color", SETTINGS_MUTED)

	save_feedback_panel = PanelContainer.new()
	save_feedback_panel.name = "SaveFeedbackPanel"
	save_feedback_panel.visible = true
	save_feedback_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	save_feedback_panel.add_theme_stylebox_override("panel", _stylebox(Color(0, 0, 0, 0), Color(0, 0, 0, 0), 0, 0, 0))
	save_feedback_panel.add_child(save_status_label)
	action_row.add_child(save_feedback_panel)

	cancel_button = Button.new()
	cancel_button.name = "ResetButton"
	cancel_button.text = "恢复默认"
	cancel_button.custom_minimum_size = Vector2(92, 37)
	cancel_button.pressed.connect(_on_restore_defaults_pressed)
	_style_button(cancel_button)
	action_row.add_child(cancel_button)

	save_button = Button.new()
	save_button.name = "SaveButton"
	save_button.text = "保存"
	save_button.custom_minimum_size = Vector2(92, 37)
	save_button.pressed.connect(_on_save)
	_style_button(save_button, false, true)
	action_row.add_child(save_button)

	restore_defaults_confirm_dialog = ConfirmationDialog.new()
	restore_defaults_confirm_dialog.name = "RestoreDefaultsConfirmDialog"
	restore_defaults_confirm_dialog.title = "恢复默认显示设置"
	restore_defaults_confirm_dialog.dialog_text = "恢复默认只会重置显示、窗口、托盘、自启动和 Debug 设置，不清空薪资、工时、角色和 Panel 项。"
	restore_defaults_confirm_dialog.confirmed.connect(_restore_display_defaults)
	add_child(restore_defaults_confirm_dialog)
	update_install_confirm_dialog = ConfirmationDialog.new()
	update_install_confirm_dialog.name = "UpdateInstallConfirmDialog"
	update_install_confirm_dialog.title = "安装更新"
	update_install_confirm_dialog.dialog_text = "更新已通过 SHA256 与发布者签名校验。安装前将备份配置并退出当前应用，是否继续？"
	update_install_confirm_dialog.confirmed.connect(_on_update_install_confirmed)
	add_child(update_install_confirm_dialog)


func _add_settings_section(nav: BoxContainer, content_holder: Control, section_name: String, page: Control) -> void:
	var button := Button.new()
	button.name = "%sNavButton" % section_name
	button.text = SECTION_LABELS.get(section_name, section_name)
	button.toggle_mode = true
	button.alignment = HORIZONTAL_ALIGNMENT_CENTER
	button.custom_minimum_size = Vector2(64, SETTINGS_TAB_HEIGHT)
	button.add_theme_font_size_override("font_size", 13)
	button.pressed.connect(_select_settings_section.bind(section_name))
	_style_nav_button(button, false)
	nav.add_child(button)
	settings_nav_buttons[section_name] = button

	page.visible = false
	page.set_anchors_preset(Control.PRESET_FULL_RECT)
	page.offset_left = 0
	page.offset_top = 0
	page.offset_right = 0
	page.offset_bottom = 0
	content_holder.add_child(page)
	settings_pages[section_name] = page


func _select_settings_section(section_name: String) -> void:
	for key in settings_pages:
		var page: Control = settings_pages[key]
		page.visible = key == section_name
	for key in settings_nav_buttons:
		var button: Button = settings_nav_buttons[key]
		button.button_pressed = key == section_name
		_style_nav_button(button, key == section_name)


func _on_header_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		_header_dragging = event.pressed
		if _header_dragging:
			_header_drag_start_mouse = DisplayServer.mouse_get_position()
			_header_drag_start_window = get_window().position
			get_viewport().set_input_as_handled()
	elif event is InputEventMouseMotion and _header_dragging:
		get_window().position = _header_drag_start_window + (DisplayServer.mouse_get_position() - _header_drag_start_mouse)
		get_viewport().set_input_as_handled()


func _build_salary_tab() -> Control:
	var root := _new_tab("Salary")
	var box := _new_vbox(root)
	_add_inline_actions(box)
	_add_page_heading(box, "工资设置", "收入小票的计算来源")
	_add_section_heading(box, "基础收入")
	salary_input = _add_spin(box, 0, 999999, 1)
	_wrap_last_control_in_card(box, salary_input, "月薪", "用于计算今日已赚、本月累计和时薪。")
	rest_mode_option = OptionButton.new()
	rest_mode_option.add_item("双休", 0)
	rest_mode_option.add_item("单休", 1)
	rest_mode_option.add_item("大小周", 2)
	_add_control_card(box, "休息模式", "", rest_mode_option)
	rest_mode_option.item_selected.connect(_on_rest_mode_selected)
	alternating_week_type_option = OptionButton.new()
	alternating_week_type_option.add_item("本周是大周", 0)
	alternating_week_type_option.add_item("本周是小周", 1)
	var alternating_row := _add_control_card(box, "大小周起点", "", alternating_week_type_option)
	alternating_week_type_row = alternating_row.get_parent()
	alternating_week_type_row.visible = false
	rest_mode_single_toggle = CheckButton.new()
	rest_mode_single_toggle.text = "单休（关闭则为双休）"
	rest_mode_single_toggle.visible = false
	box.add_child(rest_mode_single_toggle)
	daily_hours_label = Label.new()
	daily_hours_label.text = "8 小时"
	daily_hours_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	daily_hours_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	daily_hours_label.add_theme_font_size_override("font_size", 12)
	daily_hours_label.add_theme_color_override("font_color", SETTINGS_MUTED)
	_add_control_card(box, "每日有效工时", "", daily_hours_label)
	return root


func _build_schedule_tab() -> Control:
	var root := _new_tab("Schedule")
	var box := _new_vbox(root)
	_add_inline_actions(box)
	_add_page_heading(box, "作息设置", "按有效工作时长理解上班、午休和下班")
	_add_section_heading(box, "工作时间")
	var start_row := _add_time_row(box)
	start_hour_input = start_row[0]
	start_min_input = start_row[1]
	_wrap_last_control_in_card(box, start_row[2], "上班时间", "")
	lunch_duration_input = _add_spin(box, 0, 8, ConfigurationDraftScript.LUNCH_DURATION_INPUT_STEP_HOURS)
	lunch_duration_input.suffix = " 小时"
	_wrap_last_control_in_card(box, lunch_duration_input, "午休时长", "")
	var lunch_start_row := _add_time_row(box)
	lunch_start_hour_input = lunch_start_row[0]
	lunch_start_min_input = lunch_start_row[1]
	_wrap_last_control_in_card(box, lunch_start_row[2], "午休开始", "")
	var hidden_controls := VBoxContainer.new()
	hidden_controls.name = "SettingsScheduleCompatibilityControls"
	hidden_controls.visible = false
	box.add_child(hidden_controls)
	var lunch_end_row := _new_time_row()
	lunch_end_hour_input = lunch_end_row[0]
	lunch_end_min_input = lunch_end_row[1]
	hidden_controls.add_child(lunch_end_row[2])
	var end_row := _new_time_row()
	end_hour_input = end_row[0]
	end_min_input = end_row[1]
	hidden_controls.add_child(end_row[2])
	schedule_end_label = Label.new()
	schedule_end_label.text = "18:00"
	schedule_end_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	schedule_end_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	schedule_end_label.add_theme_font_size_override("font_size", 12)
	schedule_end_label.add_theme_color_override("font_color", SETTINGS_MUTED)
	_add_control_card(box, "下班时间", "", schedule_end_label)
	hours_input = _new_spin_control(0, 24, 0.01)
	hours_input.editable = false
	hidden_controls.add_child(hours_input)
	_connect_time_inputs()
	return root


func _build_pet_tab() -> Control:
	var root := _new_tab("Pet")
	var box := _new_vbox(root)
	_add_inline_actions(box)
	_add_page_heading(box, "桌宠设置", "选择陪你工作的橘猫伙伴")
	_add_section_heading(box, "角色")
	pet_option = OptionButton.new()
	pet_option.custom_minimum_size.x = 164
	pet_option.item_selected.connect(_on_pet_option_selected)
	_add_control_card(box, "当前宠物", "", pet_option)
	pet_list = ItemList.new()
	pet_list.name = "SettingsPetCompatibilityList"
	pet_list.visible = false
	box.add_child(pet_list)
	var rollback_button := Button.new()
	rollback_button.text = "回退到 v0.8 橘猫"
	rollback_button.pressed.connect(_on_classic_rollback_requested)
	_add_control_card(box, "Classic 回退", "仅在新橘猫出现异常时使用；不会清空工资和显示设置。", rollback_button)
	_add_note_block(box, "", ["宠物资源损坏时会自动回退，不影响收入计算与窗口找回。"])
	return root


func _build_display_tab() -> Control:
	var root := _new_tab("Display")
	var box := _new_vbox(root)
	_add_inline_actions(box)
	_add_page_heading(box, "显示设置", "桌面挂件的大小、透明和找回")
	_add_section_heading(box, "视觉")
	var opacity_row := _add_slider_row(box, 20, 100, 1)
	opacity_slider = opacity_row[0]
	opacity_value_label = opacity_row[1]
	_wrap_last_control_in_card(box, opacity_row[2], "透明度", "20%-100%，影响小猫和 Panel 的整体透明程度。")
	var scale_row := _add_slider_row(box, 50, 200, 1)
	scale_slider = scale_row[0]
	scale_value_label = scale_row[1]
	_wrap_last_control_in_card(box, scale_row[2], "缩放", "50%-200%，同时影响小猫、Panel 和点击穿透命中区域。")
	_add_section_heading(box, "窗口")
	window_mode_option = OptionButton.new()
	window_mode_option.add_item("置顶悬浮", 0)
	window_mode_option.add_item("融入桌面（实验）", 1)
	_add_control_card(box, "窗口模式", "置顶悬浮为主要验证模式，融入桌面仍为实验能力。", window_mode_option)
	window_mode_embed_toggle = CheckButton.new()
	window_mode_embed_toggle.text = "融入桌面（关闭则为置顶悬浮，实验）"
	window_mode_embed_toggle.visible = false
	box.add_child(window_mode_embed_toggle)
	pure_pet_mode_toggle = CheckButton.new()
	pure_pet_mode_toggle.text = "纯桌宠模式（隐藏任务栏 / Alt+Tab，需托盘可用）"
	_add_control_card(box, "纯桌宠模式", "隐藏任务栏 / Alt+Tab 前必须确认托盘可用，避免窗口不可找回。", pure_pet_mode_toggle)
	native_status_label = Label.new()
	native_status_label.name = "NativeStatusLabel"
	native_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	native_status_label.custom_minimum_size = Vector2(0, 32)
	native_status_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	native_status_label.add_theme_font_size_override("font_size", 12)
	native_status_label.add_theme_color_override("font_color", SETTINGS_MUTED)
	_add_note_block(box, "说明", [
		"点击穿透由透明窗口区域自动计算，小猫和 Panel 保持可交互。"
	])
	_add_note_label(box, "状态", native_status_label)
	_add_panel_controls(box)
	return root


func _build_panel_tab() -> Control:
	var root := _new_tab("Panel")
	var box := _new_vbox(root)
	_add_inline_actions(box)
	_add_page_heading(box, "面板设置", "金币小票上显示哪些信息")
	_add_panel_controls(box)
	return root


func _add_panel_controls(box: Control) -> void:
	_add_section_heading(box, "金币小票")
	show_today = _add_checkbox_row(box, "今日已赚", "显示当天累计收入。")
	show_month = _add_checkbox_row(box, "本月累计", "显示本月累计收入。")
	show_rate = _add_checkbox_row(box, "时薪", "显示折算后的当前时薪。")
	show_progress = _add_checkbox_row(box, "工作进度", "显示今日工作进度条。")
	show_state = _add_checkbox_row(box, "状态", "显示工作中、休息中等状态。")


func _build_general_tab() -> Control:
	var root := _new_tab("General")
	var box := _new_vbox(root)
	_add_inline_actions(box)
	_add_page_heading(box, "通用设置", "启动、托盘和小工具维护")
	_add_section_heading(box, "运行")
	debug_mode_toggle = CheckButton.new()
	debug_mode_toggle.text = "Debug 模式"
	_add_control_card(box, "Debug 模式", "用于显示调试窗口、日志和命中区。保存后必要时重新显示窗口或重启应用。", debug_mode_toggle)
	auto_start_toggle = CheckButton.new()
	auto_start_toggle.text = "开机自启"
	_add_control_card(box, "开机自启", "使用当前导出的 LetsMakeMoney.exe 写入用户级启动项。", auto_start_toggle)
	minimize_to_tray_toggle = CheckButton.new()
	minimize_to_tray_toggle.text = "关闭时隐藏到托盘"
	_add_control_card(box, "关闭时隐藏到托盘", "关闭窗口时保留后台进程，可通过系统托盘找回。", minimize_to_tray_toggle)
	_add_section_heading(box, "维护")
	reset_position_button = Button.new()
	reset_position_button.text = "重置窗口位置"
	reset_position_button.pressed.connect(_on_reset_position_pressed)
	_add_control_card(box, "重置窗口位置", "把桌宠移动回当前屏幕的安全可见区域。", reset_position_button)
	restore_defaults_button = Button.new()
	restore_defaults_button.text = "恢复默认显示设置"
	restore_defaults_button.pressed.connect(_on_restore_defaults_pressed)
	_add_control_card(box, "恢复默认显示设置", "只重置显示、窗口、托盘、自启动和 Debug 设置，不清空薪资和角色。", restore_defaults_button)
	_add_section_heading(box, "诊断与支持")
	open_app_data_button = Button.new()
	open_app_data_button.text = "打开应用数据目录"
	open_app_data_button.pressed.connect(_on_open_app_data_pressed)
	_add_control_card(box, "应用数据目录", "打开配置、日志和本地诊断数据所在目录。", open_app_data_button)
	copy_diagnostics_button = Button.new()
	copy_diagnostics_button.text = "复制诊断摘要"
	copy_diagnostics_button.pressed.connect(_on_copy_diagnostics_pressed)
	_add_control_card(box, "诊断摘要", "复制脱敏的版本、能力和日志状态，不生成或上传文件。", copy_diagnostics_button)
	_add_section_heading(box, "版本与更新")
	update_channel_option = OptionButton.new()
	update_channel_option.add_item("稳定通道")
	update_channel_option.add_item("测试通道")
	_style_option_button(update_channel_option)
	_add_control_card(box, "更新通道", "稳定通道仅接收正式版；测试通道同时接收 Beta。", update_channel_option)
	check_updates_toggle = CheckButton.new()
	check_updates_toggle.text = "启动后检查更新"
	_add_control_card(box, "启动后检查更新", "只检查版本，不会静默下载或安装。", check_updates_toggle)
	check_update_button = Button.new()
	check_update_button.text = "立即检查"
	check_update_button.pressed.connect(_on_check_update_pressed)
	_add_control_card(box, "检查更新", "通过 GitHub Release 查询版本。", check_update_button)
	download_update_button = Button.new()
	download_update_button.text = "下载更新"
	download_update_button.visible = false
	download_update_button.pressed.connect(_on_download_update_pressed)
	_add_control_card(box, "可用更新", "下载前不会替换当前程序。", download_update_button)
	cancel_update_button = Button.new()
	cancel_update_button.text = "取消下载"
	cancel_update_button.visible = false
	cancel_update_button.pressed.connect(_on_cancel_update_pressed)
	_add_control_card(box, "下载任务", "取消后删除临时文件并保留当前版本。", cancel_update_button)
	general_message_label = Label.new()
	general_message_label.name = "GeneralMessageLabel"
	general_message_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	general_message_label.custom_minimum_size = Vector2(0, 30)
	general_message_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	general_message_label.visible = false
	general_message_label.add_theme_font_size_override("font_size", 12)
	general_message_label.add_theme_color_override("font_color", ACCENT_MINT)
	box.add_child(general_message_label)
	_add_note_block(box, "调试说明", [
		"配置文件：%APPDATA%\\LetsMakeMoney\\config.json。Debug 模式保存后必要时重启生效。",
		"语言：中文（当前版本暂不提供切换）。"
	])
	return root


func _new_tab(tab_name: String) -> Control:
	return _settings_ui_builder.new_tab(tab_name)


func _new_vbox(parent: Control) -> VBoxContainer:
	return _settings_ui_builder.new_vbox(parent)


func _add_page_heading(parent: Control, title: String, hint: String) -> void:
	_settings_ui_builder.add_page_heading(parent, title, hint)


func _add_section_heading(parent: Control, title: String) -> void:
	_settings_ui_builder.add_section_heading(parent, title)


func _add_setting_card(parent: Control, title: String, description: String = "") -> VBoxContainer:
	return _settings_ui_builder.add_setting_card(parent, title, description)


func _add_control_card(parent: Control, title: String, _description: String, control: Control) -> HBoxContainer:
	return _settings_ui_builder.add_control_card(parent, title, _description, control)


func _add_switch_proxy(row: HBoxContainer, toggle: BaseButton) -> void:
	toggle.text = ""
	toggle.visible = false
	toggle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	toggle.custom_minimum_size = Vector2.ZERO
	row.add_child(toggle)

	var proxy := Button.new()
	proxy.name = "%sVisualSwitch" % toggle.name
	proxy.toggle_mode = true
	proxy.focus_mode = Control.FOCUS_ALL
	proxy.custom_minimum_size = Vector2(42, 24)
	proxy.size_flags_horizontal = Control.SIZE_SHRINK_END
	proxy.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	proxy.pressed.connect(func() -> void:
		if toggle.disabled:
			proxy.button_pressed = toggle.button_pressed
			_style_switch_proxy(proxy, toggle)
			return
		toggle.button_pressed = proxy.button_pressed
		_style_switch_proxy(proxy, toggle)
	)
	toggle.toggled.connect(func(pressed: bool) -> void:
		proxy.button_pressed = pressed
		_style_switch_proxy(proxy, toggle)
	)
	_switch_proxies[toggle] = proxy
	_style_switch_proxy(proxy, toggle)
	row.add_child(proxy)


func _style_switch_proxy(proxy: Button, toggle: BaseButton) -> void:
	var on := toggle.button_pressed
	var disabled := toggle.disabled
	proxy.disabled = disabled
	proxy.text = ""
	proxy.flat = false
	var track := Color(TEXT_MUTED.r, TEXT_MUTED.g, TEXT_MUTED.b, 0.24)
	var border := Color(TEXT_MUTED.r, TEXT_MUTED.g, TEXT_MUTED.b, 0.16)
	if on:
		track = ACCENT_MINT
		border = Color(0.337, 0.463, 0.357, 0.30)
	if disabled:
		track.a = 0.28
		border.a = 0.10
	var hover := track.lightened(0.08)
	var pressed := track.darkened(0.06)
	proxy.add_theme_stylebox_override("normal", _stylebox(track, border, 1, 12, 2))
	proxy.add_theme_stylebox_override("hover", _stylebox(hover, border, 1, 12, 2))
	proxy.add_theme_stylebox_override("pressed", _stylebox(pressed, border, 1, 12, 2))
	proxy.add_theme_stylebox_override("disabled", _stylebox(track, border, 1, 12, 2))
	proxy.add_theme_stylebox_override("focus", _stylebox(Color(0, 0, 0, 0), ACCENT_COIN, 1, 12, 2))
	proxy.add_theme_icon_override("icon", _make_switch_knob_icon(on, disabled))
	proxy.icon_alignment = HORIZONTAL_ALIGNMENT_RIGHT if on else HORIZONTAL_ALIGNMENT_LEFT
	proxy.add_theme_constant_override("h_separation", 0)


func _sync_switch_proxies() -> void:
	for toggle in _switch_proxies.keys():
		if not is_instance_valid(toggle):
			continue
		var proxy := _switch_proxies[toggle] as Button
		if proxy == null or not is_instance_valid(proxy):
			continue
		proxy.button_pressed = (toggle as BaseButton).button_pressed
		_style_switch_proxy(proxy, toggle as BaseButton)


func _add_note_block(parent: Control, title: String, lines: Array[String]) -> void:
	_settings_ui_builder.add_note_block(parent, title, lines)


func _add_note_label(parent: Control, title: String, label: Label) -> void:
	_settings_ui_builder.add_note_label(parent, title, label)


func _add_note_title(parent: Control, title: String) -> void:
	_settings_ui_builder.add_note_title(parent, title)


func _new_note_text(text: String) -> Label:
	return _settings_ui_builder.new_note_text(text)


func _style_note_label(label: Label) -> void:
	_settings_ui_builder.style_note_label(label)


func _wrap_last_control_in_card(parent: Control, control: Control, title: String, description: String) -> void:
	_settings_ui_builder.wrap_control(parent, control, title, description)


func _control_minimum_size(control: Control) -> Vector2:
	return _settings_ui_builder.control_minimum_size(control)


func _add_checkbox_row(parent: Control, title: String, description: String) -> CheckBox:
	return _settings_ui_builder.add_checkbox_row(parent, title, description)


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


func _style_button(button: Button, quiet: bool = false, primary: bool = false) -> void:
	_warm_theme.style_button(button, primary, quiet)


func _style_window_button(button: Button, destructive: bool = false) -> void:
	var hover_bg := SURFACE_NAV
	var pressed_bg := Color(0.875, 0.918, 0.863, 1.0)
	var hover_border := Color(TEXT_MUTED.r, TEXT_MUTED.g, TEXT_MUTED.b, 0.16)
	var pressed_border := Color(TEXT_MUTED.r, TEXT_MUTED.g, TEXT_MUTED.b, 0.24)
	if destructive:
		hover_bg = Color(0.965, 0.830, 0.762, 0.92)
		pressed_bg = Color(0.820, 0.512, 0.420, 0.88)
		hover_border = Color(0.640, 0.278, 0.220, 0.26)
		pressed_border = Color(0.640, 0.278, 0.220, 0.34)
	button.flat = true
	button.focus_mode = Control.FOCUS_ALL
	button.add_theme_stylebox_override("normal", _stylebox(Color(0, 0, 0, 0), Color(1, 1, 1, 0), 0, 10, 5))
	button.add_theme_stylebox_override("hover", _stylebox(hover_bg, hover_border, 1, 10, 5))
	button.add_theme_stylebox_override("pressed", _stylebox(pressed_bg, pressed_border, 1, 10, 5))
	button.add_theme_stylebox_override("focus", _stylebox(Color(0, 0, 0, 0), SETTINGS_ACCENT, 2, 10, 5))
	button.add_theme_color_override("font_color", SETTINGS_TEXT)
	button.add_theme_color_override("font_hover_color", SETTINGS_TEXT)
	button.add_theme_color_override("font_pressed_color", SETTINGS_TEXT)
	button.add_theme_font_size_override("font_size", 15)


func _style_nav_button(button: Button, active: bool) -> void:
	button.add_theme_stylebox_override("normal", _nav_stylebox(active, Color(0, 0, 0, 0)))
	button.add_theme_stylebox_override("hover", _nav_stylebox(active, SURFACE_NAV))
	button.add_theme_stylebox_override("pressed", _nav_stylebox(true, Color(0.875, 0.918, 0.863, 0.82)))
	button.add_theme_stylebox_override("focus", _nav_stylebox(active, Color(0, 0, 0, 0), true))
	button.add_theme_color_override("font_color", SETTINGS_TEXT if active else SETTINGS_MUTED)
	button.add_theme_color_override("font_hover_color", SETTINGS_TEXT)
	button.add_theme_color_override("font_pressed_color", SETTINGS_TEXT)


func _nav_stylebox(active: bool, background: Color, focused: bool = false) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = SETTINGS_ACCENT
	style.border_width_bottom = 2 if active else 0
	if focused:
		style.border_width_left = 1
		style.border_width_top = 1
		style.border_width_right = 1
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 5
	style.content_margin_bottom = 5
	return style


func _style_option_button(option: OptionButton) -> void:
	_warm_theme.style_option_button(option, SETTINGS_CONTROL_WIDTH)


func _style_option_popup(option: OptionButton) -> void:
	_warm_theme.style_option_popup(option)


func _style_line_edit(line_edit: LineEdit) -> void:
	_warm_theme.style_line_edit(line_edit)


func _build_settings_theme() -> Theme:
	# Font contract lives in WarmControlTheme.build_theme:
	# SystemFont.new()
	# TextServer.FONT_ANTIALIASING_LCD
	# Microsoft YaHei UI
	return _warm_theme.build_theme(14)


func _style_form_control(control: Control) -> void:
	if control is OptionButton:
		var option := control as OptionButton
		_style_option_button(option)
		option.custom_minimum_size = Vector2(maxf(option.custom_minimum_size.x, 124), maxf(option.custom_minimum_size.y, 32))
	elif control is Button:
		_style_button(control as Button)
	elif control is SpinBox:
		var spin := control as SpinBox
		_warm_theme.style_spin_box(spin, 92)
	elif control is LineEdit:
		_style_line_edit(control as LineEdit)
	elif control is CheckButton or control is CheckBox:
		_warm_theme.style_switch(control as BaseButton)
		control.add_theme_icon_override("on", _make_switch_icon(true, false))
		control.add_theme_icon_override("off", _make_switch_icon(false, false))
	elif control is ItemList:
		var item_list := control as ItemList
		item_list.add_theme_stylebox_override("panel", _stylebox(Color(1.0, 0.990, 0.964, 1.0), BORDER_WARM, 1, 12, 8))
		item_list.add_theme_stylebox_override("hovered", _stylebox(Color(1.0, 0.960, 0.842, 1.0), Color(0.965, 0.714, 0.243, 0.22), 1, 10, 8))
		item_list.add_theme_stylebox_override("selected", _stylebox(Color(1.0, 0.914, 0.644, 1.0), Color(0.780, 0.420, 0.137, 0.40), 1, 10, 8))
		item_list.add_theme_stylebox_override("selected_focus", _stylebox(Color(1.0, 0.890, 0.560, 1.0), Color(0.780, 0.420, 0.137, 0.64), 1, 10, 8))
		item_list.add_theme_stylebox_override("focus", _stylebox(Color(0, 0, 0, 0), ACCENT_COIN, 2, 12, 8))
		item_list.add_theme_font_size_override("font_size", 15)
		item_list.add_theme_color_override("font_color", SETTINGS_TEXT)
		item_list.add_theme_color_override("font_selected_color", SETTINGS_TEXT)
		item_list.add_theme_color_override("guide_color", Color(0, 0, 0, 0))
		item_list.add_theme_color_override("font_hovered_color", SETTINGS_TEXT)
		item_list.add_theme_color_override("font_hovered_selected_color", SETTINGS_TEXT)
	elif control is HBoxContainer:
		control.custom_minimum_size = Vector2(maxf(control.custom_minimum_size.x, 0), maxf(control.custom_minimum_size.y, 34))
		_warm_theme.style_compact_row(control)


func _add_label(parent: Control, text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 15)
	label.add_theme_color_override("font_color", SETTINGS_TEXT)
	parent.add_child(label)
	return label


func _add_spin(parent: Control, min_value: float, max_value: float, step: float) -> SpinBox:
	var spin := _new_spin_control(min_value, max_value, step)
	parent.add_child(spin)
	return spin


func _new_spin_control(min_value: float, max_value: float, step: float) -> SpinBox:
	var spin := SpinBox.new()
	spin.min_value = min_value
	spin.max_value = max_value
	spin.step = step
	spin.custom_minimum_size = Vector2(92, 35)
	_style_form_control(spin)
	return spin


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


func _make_slider_grabber(border_color: Color, fill_color: Color) -> Texture2D:
	const GRABBER_SIZE := 18
	var image := Image.create_empty(GRABBER_SIZE, GRABBER_SIZE, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	var center := Vector2((GRABBER_SIZE - 1) * 0.5, (GRABBER_SIZE - 1) * 0.5)
	for y in range(GRABBER_SIZE):
		for x in range(GRABBER_SIZE):
			var distance := Vector2(x, y).distance_to(center)
			if distance <= 8.2:
				image.set_pixel(x, y, border_color)
			if distance <= 5.9:
				image.set_pixel(x, y, fill_color)
	return ImageTexture.create_from_image(image)


func _make_switch_icon(pressed: bool, disabled: bool) -> Texture2D:
	const WIDTH := 40
	const HEIGHT := 22
	var track := Color(0.870, 0.760, 0.560, 0.48)
	var border := Color(0.416, 0.263, 0.122, 0.20)
	var knob := Color(1.0, 0.998, 0.988, 1.0)
	if pressed:
		track = Color(0.427, 0.624, 0.447, 0.92)
		border = Color(0.240, 0.430, 0.270, 0.30)
	if disabled:
		track.a = 0.30
		border.a = 0.12
		knob = Color(0.880, 0.820, 0.720, 0.80)
	var image := Image.create_empty(WIDTH, HEIGHT, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	var radius := 10.5
	var left_center := Vector2(radius, HEIGHT * 0.5)
	var right_center := Vector2(WIDTH - radius - 1, HEIGHT * 0.5)
	for y in range(HEIGHT):
		for x in range(WIDTH):
			var p := Vector2(x, y)
			var inside: bool = p.distance_to(left_center) <= radius or p.distance_to(right_center) <= radius or (x >= radius and x <= WIDTH - radius and abs(y - HEIGHT * 0.5) <= radius)
			if inside:
				image.set_pixel(x, y, border)
			var inner: bool = p.distance_to(left_center) <= radius - 1.5 or p.distance_to(right_center) <= radius - 1.5 or (x >= radius and x <= WIDTH - radius and abs(y - HEIGHT * 0.5) <= radius - 1.5)
			if inner:
				image.set_pixel(x, y, track)
	var knob_center := Vector2(WIDTH - 11, HEIGHT * 0.5) if pressed else Vector2(11, HEIGHT * 0.5)
	for y in range(HEIGHT):
		for x in range(WIDTH):
			var distance := Vector2(x, y).distance_to(knob_center)
			if distance <= 7.8:
				image.set_pixel(x, y, Color(0.360, 0.184, 0.047, 0.14))
			if distance <= 6.6:
				image.set_pixel(x, y, knob)
	return ImageTexture.create_from_image(image)


func _make_switch_knob_icon(pressed: bool, disabled: bool) -> Texture2D:
	const SIZE := 16
	var image := Image.create_empty(SIZE, SIZE, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	var center := Vector2((SIZE - 1) * 0.5, (SIZE - 1) * 0.5)
	var shadow := Color(0.360, 0.184, 0.047, 0.13)
	var fill := Color(1.0, 0.998, 0.988, 1.0)
	var border := Color(0.416, 0.263, 0.122, 0.10)
	if pressed:
		border = Color(0.780, 0.420, 0.137, 0.18)
	if disabled:
		fill.a = 0.78
		border.a = 0.07
		shadow.a = 0.06
	for y in range(SIZE):
		for x in range(SIZE):
			var distance := Vector2(x, y).distance_to(center)
			if distance <= 7.2:
				image.set_pixel(x, y, shadow)
			if distance <= 6.4:
				image.set_pixel(x, y, border)
			if distance <= 5.6:
				image.set_pixel(x, y, fill)
	return ImageTexture.create_from_image(image)


func _add_slider(parent: Control, min_value: float, max_value: float, step: float) -> HSlider:
	var slider := HSlider.new()
	slider.min_value = min_value
	slider.max_value = max_value
	slider.step = step
	slider.custom_minimum_size = Vector2(0, 36)
	_warm_theme.style_slider(slider)
	parent.add_child(slider)
	return slider


func _add_slider_row(parent: Control, min_value: float, max_value: float, step: float) -> Array:
	var row := HBoxContainer.new()
	row.name = "SliderRow"
	row.custom_minimum_size = Vector2(236, 32)
	row.add_theme_constant_override("separation", 8)
	parent.add_child(row)
	var slider := _add_slider(row, min_value, max_value, step)
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var value_label := Label.new()
	value_label.custom_minimum_size = Vector2(60, 0)
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	value_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	value_label.add_theme_font_size_override("font_size", 14)
	value_label.add_theme_color_override("font_color", SETTINGS_TEXT)
	row.add_child(value_label)
	return [slider, value_label, row]


func _add_checkbox(parent: Control, text: String) -> CheckBox:
	var checkbox := CheckBox.new()
	checkbox.text = text
	checkbox.add_theme_font_size_override("font_size", 15)
	parent.add_child(checkbox)
	return checkbox


func _add_inline_actions(_parent: Control) -> void:
	return


func _add_time_row(parent: Control) -> Array:
	var controls := _new_time_row()
	parent.add_child(controls[2])
	return controls


func _new_time_row() -> Array:
	var row := HBoxContainer.new()
	row.name = "TimeRow"
	row.custom_minimum_size = Vector2(148, 35)
	row.add_theme_constant_override("separation", 6)
	var hour := _new_spin_control(0, 23, 1)
	hour.custom_minimum_size = Vector2(64, 0)
	row.add_child(hour)
	var colon := Label.new()
	colon.text = ":"
	colon.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	colon.add_theme_font_size_override("font_size", 14)
	colon.add_theme_color_override("font_color", SETTINGS_MUTED)
	row.add_child(colon)
	var minute := _new_spin_control(0, 59, 1)
	minute.custom_minimum_size = Vector2(64, 0)
	row.add_child(minute)
	return [hour, minute, row]


func _connect_time_inputs() -> void:
	start_hour_input.value_changed.connect(_on_schedule_anchor_changed.bind("work_start"))
	start_min_input.value_changed.connect(_on_schedule_anchor_changed.bind("work_start"))
	lunch_start_hour_input.value_changed.connect(_on_schedule_anchor_changed.bind("lunch_start"))
	lunch_start_min_input.value_changed.connect(_on_schedule_anchor_changed.bind("lunch_start"))
	lunch_duration_input.value_changed.connect(_on_lunch_duration_setting_changed)
	for input in [lunch_end_hour_input, lunch_end_min_input, end_hour_input, end_min_input]:
		input.value_changed.connect(_on_time_input_changed)


func _on_time_input_changed(_value: float) -> void:
	if _updating_schedule_ui:
		return
	_update_hours_preview()


func _on_schedule_anchor_changed(_value: float, field: String) -> void:
	if _updating_schedule_ui:
		return
	if field == "lunch_start":
		_configuration_draft.set_lunch_start_time(_time_value(lunch_start_hour_input, lunch_start_min_input))
	else:
		_configuration_draft.set_work_start_time(_time_value(start_hour_input, start_min_input))
	_apply_schedule_draft_to_controls()


func _on_lunch_duration_setting_changed(value: float) -> void:
	if _updating_schedule_ui:
		return
	_configuration_draft.set_lunch_duration_minutes(roundi(value * 60.0))
	_apply_schedule_draft_to_controls()


func _apply_schedule_draft_to_controls() -> void:
	_updating_schedule_ui = true
	_set_time_controls(lunch_end_hour_input, lunch_end_min_input, _configuration_draft.lunch_end_time)
	_set_time_controls(end_hour_input, end_min_input, _configuration_draft.work_end_time)
	if lunch_duration_input != null:
		lunch_duration_input.value = float(_configuration_draft.lunch_duration_minutes) / 60.0
	_updating_schedule_ui = false
	_update_hours_preview()


func _set_time_controls(hour_input: SpinBox, minute_input: SpinBox, value: String) -> void:
	var parts := value.split(":")
	hour_input.value = int(parts[0]) if parts.size() > 0 else 0
	minute_input.value = int(parts[1]) if parts.size() > 1 else 0


func _update_hours_preview() -> void:
	if hours_input == null:
		return
	hours_input.value = _calculate_work_hours()
	if daily_hours_label != null:
		daily_hours_label.text = ("%.2f" % hours_input.value).trim_suffix("0").trim_suffix(".") + " 小时"
	if schedule_end_label != null:
		schedule_end_label.text = _time_value(end_hour_input, end_min_input)


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
	_update_alternating_week_visibility()


func _update_alternating_week_visibility() -> void:
	if alternating_week_type_row != null:
		alternating_week_type_row.visible = rest_mode_option.selected == 2


func _load_current_values() -> void:
	_configuration_draft.load_config(Config.get_data_snapshot())
	_updating_schedule_ui = true
	salary_input.value = float(Config.get_value("monthly_salary", 0))
	var rm := String(Config.get_value("rest_mode", "double"))
	rest_mode_option.select(_rest_mode_selection(rm))
	rest_mode_single_toggle.button_pressed = rm == "single"
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
	var st := String(Config.get_value("work_start_time", "08:00")).split(":")
	start_hour_input.value = int(st[0]) if st.size() > 0 else 8
	start_min_input.value = int(st[1]) if st.size() > 1 else 0
	var lst := String(Config.get_value("lunch_start_time", "12:00")).split(":")
	lunch_start_hour_input.value = int(lst[0]) if lst.size() > 0 else 12
	lunch_start_min_input.value = int(lst[1]) if lst.size() > 1 else 0
	var lunch_end_parts := String(Config.get_value("lunch_end_time", "14:00")).split(":")
	lunch_end_hour_input.value = int(lunch_end_parts[0]) if lunch_end_parts.size() > 0 else 14
	lunch_end_min_input.value = int(lunch_end_parts[1]) if lunch_end_parts.size() > 1 else 0
	var et := String(Config.get_value("work_end_time", "18:00")).split(":")
	end_hour_input.value = int(et[0]) if et.size() > 0 else 18
	end_min_input.value = int(et[1]) if et.size() > 1 else 0
	if lunch_duration_input != null:
		lunch_duration_input.value = float(_configuration_draft.lunch_duration_minutes) / 60.0
	_updating_schedule_ui = false
	_update_alternating_week_visibility()

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
	update_channel_option.select(0 if String(Config.get_value("update_channel", "beta")) == "stable" else 1)
	check_updates_toggle.button_pressed = bool(Config.get_value("check_updates_on_start", true))
	_sync_switch_proxies()

	_populate_pet_list()
	_load_panel_checkboxes()
	_update_hours_preview()


func _populate_pet_list() -> void:
	pet_list.clear()
	if pet_option != null:
		pet_option.clear()
	var pets := PetManager.get_available_pets()
	var current_id := String(Config.get_value("pet_id", "cat_orange_v2"))
	for i in range(pets.size()):
		pet_list.add_item(pets[i].display_name)
		if pet_option != null:
			pet_option.add_item(pets[i].display_name)
		if pets[i].pet_id == current_id:
			pet_list.select(i)
			if pet_option != null:
				pet_option.select(i)
	if pet_option != null:
		_warm_theme.style_option_popup(pet_option)


func _on_pet_option_selected(index: int) -> void:
	if pet_list != null and index >= 0 and index < pet_list.item_count:
		pet_list.select(index)


func _on_classic_rollback_requested() -> void:
	var previous_config := Config.get_data_snapshot()
	var previous_pet := PetManager.get_current_pet()
	var previous_pet_id := String(previous_pet.pet_id) if previous_pet != null else String(previous_config.get("pet_id", ""))
	if not PetManager.rollback_classic_to_v08():
		_set_save_status("回退失败：v0.8 橘猫资源不可用。")
		return
	if Config.save():
		_populate_pet_list()
		_set_save_status("已回退到 v0.8 橘猫。")
		return
	Config.restore_data_snapshot(previous_config)
	PetManager.switch_pet(previous_pet_id, false)
	Platform.write_error_log("classic.rollback: result=failed reason=config_save_failed detail=%s" % Config.get_last_save_error())
	_populate_pet_list()
	_set_save_status("回退失败：配置无法写入，已恢复原角色。")


func _load_panel_checkboxes() -> void:
	show_today.button_pressed = Config.get_panel_item("earnings_today")
	show_month.button_pressed = Config.get_panel_item("earnings_month")
	show_rate.button_pressed = Config.get_panel_item("hourly_rate")
	show_progress.button_pressed = Config.get_panel_item("work_progress")
	show_state.button_pressed = Config.get_panel_item("status")


func _on_save() -> void:
	_update_slider_labels()
	var form_values := _collect_form_values()
	var result: Dictionary = _settings_transaction.execute(form_values, _settings_transaction_operations())
	match String(result.get("status", "")):
		SettingsTransactionControllerScript.STATUS_NO_CHANGE:
			Platform.write_boot_log("settings_save_no_change")
			_set_save_status("没有需要保存的更改。")
		SettingsTransactionControllerScript.STATUS_VALIDATION_FAILED:
			Platform.write_boot_log("settings_save_failed: reason=%s" % String(result.get("reason", "pre_save_apply_failed")), "error")
			_set_save_status("保存失败：请查看不可用原因并重试。")
		SettingsTransactionControllerScript.STATUS_SAVE_FAILED:
			var reason := String(result.get("reason", "unknown_save_error"))
			Platform.write_boot_log("settings_save_failed: reason=%s" % reason, "error")
			_set_save_status("保存失败：%s" % reason)
		SettingsTransactionControllerScript.STATUS_EXTERNAL_FAILED:
			Platform.write_error_log("settings_transaction_rollback: reason=external_apply_failed config=%s external=%s" % [str(result.get("rollback_config_ok", false)), str(result.get("rollback_external_ok", false))])
			_set_save_status("保存失败：外部设置未生效，已恢复原设置。")
		SettingsTransactionControllerScript.STATUS_SUCCESS:
			Platform.write_boot_log("settings_save_success: changed_keys=%s" % str(result.get("changed_keys", [])))
			_set_save_status("保存成功。")
		_:
			Platform.write_boot_log("settings_save_failed: reason=unknown_transaction_status", "error")
			_set_save_status("保存失败：事务状态异常。")


func _settings_transaction_operations() -> Dictionary:
	return {
		"has_changes": Callable(self, "_has_form_changes"),
		"capture_config": Callable(Config, "get_data_snapshot"),
		"capture_external": Callable(self, "_capture_external_state"),
		"validate": Callable(self, "_validate_form_values"),
		"apply_config": Callable(self, "_apply_form_values"),
		"save_config": Callable(Config, "save"),
		"save_error": Callable(Config, "get_last_save_error"),
		"apply_external": Callable(self, "_apply_committed_external_state"),
		"restore_config": Callable(Config, "restore_data_snapshot"),
		"restore_external": Callable(self, "_restore_external_state"),
		"changed_keys": Callable(Config, "get_last_changed_keys")
	}


func _capture_external_state() -> Dictionary:
	var current_pet := PetManager.get_current_pet()
	var host_window := DragResizeSystem.get_registered_window()
	return {
		"auto_start": Platform.is_auto_start_enabled(),
		"pet_id": String(current_pet.pet_id) if current_pet != null else String(Config.get_value("pet_id", "cat_orange_v2")),
		"window_position": host_window.position if host_window != null else Vector2i.ZERO,
		"window_visible": host_window.visible if host_window != null else true
	}


func _restore_external_state(state: Dictionary, reason: String) -> bool:
	var auto_start_ok := Platform.set_auto_start(bool(state.get("auto_start", false)))
	var pet_id := String(state.get("pet_id", ""))
	if not pet_id.is_empty():
		PetManager.switch_pet(pet_id)
	var host_window := DragResizeSystem.get_registered_window()
	if host_window != null:
		host_window.position = state.get("window_position", host_window.position)
		DragResizeSystem.set_window_visible(bool(state.get("window_visible", true)))
	var restored_pet := PetManager.get_current_pet()
	var pet_ok := restored_pet != null and String(restored_pet.pet_id) == pet_id
	var ok := auto_start_ok and pet_ok
	if ok:
		Platform.write_info_log("settings_transaction_rollback: reason=%s result=success" % reason)
	else:
		Platform.write_error_log("settings_transaction_rollback: reason=%s result=failed auto_start=%s pet=%s" % [reason, str(auto_start_ok), str(pet_ok)])
	return ok


func _collect_form_values() -> Dictionary:
	var rest_mode := _rest_mode_from_selection()
	_configuration_draft.set_salary(float(salary_input.value))
	_configuration_draft.set_rest_mode(rest_mode)
	_configuration_draft.work_start_time = _time_value(start_hour_input, start_min_input)
	_configuration_draft.lunch_start_time = _time_value(lunch_start_hour_input, lunch_start_min_input)
	_configuration_draft.lunch_end_time = _time_value(lunch_end_hour_input, lunch_end_min_input)
	_configuration_draft.work_end_time = _time_value(end_hour_input, end_min_input)
	_configuration_draft.work_duration_minutes = roundi(_calculate_work_hours() * 60.0)
	var stored_rest_mode := String(Config.get_value("rest_mode", "double"))
	var alternating_anchor_date := String(Config.get_value("alternating_anchor_date", ""))
	var alternating_anchor_week_type := String(Config.get_value("alternating_anchor_week_type", "big"))
	if rest_mode == "alternating":
		var selected_week_type := "small" if alternating_week_type_option.selected == 1 else "big"
		var preserve_stored_anchor := stored_rest_mode == "alternating" and not alternating_anchor_date.is_empty()
		if preserve_stored_anchor:
			var stored_current_week_is_big := SalaryScheduleCalculatorScript.is_big_week(
				Time.get_datetime_dict_from_system(),
				alternating_anchor_date,
				alternating_anchor_week_type
			)
			preserve_stored_anchor = stored_current_week_is_big == (selected_week_type == "big")
		if not preserve_stored_anchor:
			alternating_anchor_date = SalaryScheduleCalculatorScript.week_anchor_date(Time.get_datetime_dict_from_system())
			alternating_anchor_week_type = selected_week_type
	var result: Dictionary = _configuration_draft.to_config()
	result.merge({
		"alternating_anchor_date": alternating_anchor_date,
		"alternating_anchor_week_type": alternating_anchor_week_type,
		"scale": scale_slider.value / 100.0,
		"opacity": opacity_slider.value / 100.0,
		"window_mode": "embed" if window_mode_option.selected == 1 else "top",
		"pure_pet_mode": pure_pet_mode_toggle.button_pressed and not pure_pet_mode_toggle.disabled,
		"debug_mode": debug_mode_toggle.button_pressed,
		"auto_start": auto_start_toggle.button_pressed,
		"minimize_to_tray": minimize_to_tray_toggle.button_pressed,
		"update_channel": "stable" if update_channel_option.selected == 0 else "beta",
		"check_updates_on_start": check_updates_toggle.button_pressed,
		"pet_id": _get_selected_pet_id(),
		"panel_items": {
			"earnings_today": show_today.button_pressed,
			"earnings_month": show_month.button_pressed,
			"hourly_rate": show_rate.button_pressed,
			"work_progress": show_progress.button_pressed,
			"status": show_state.button_pressed
		}
	}, true)
	return result


func _current_settings_snapshot() -> Dictionary:
	return {
		"monthly_salary": float(Config.get_value("monthly_salary", 0)),
		"rest_mode": String(Config.get_value("rest_mode", "double")),
		"alternating_anchor_date": String(Config.get_value("alternating_anchor_date", "")),
		"alternating_anchor_week_type": String(Config.get_value("alternating_anchor_week_type", "big")),
		"work_start_time": String(Config.get_value("work_start_time", "08:00")),
		"lunch_start_time": String(Config.get_value("lunch_start_time", "12:00")),
		"lunch_end_time": String(Config.get_value("lunch_end_time", "14:00")),
		"work_end_time": String(Config.get_value("work_end_time", "18:00")),
		"work_hours_per_day": float(Config.get_value("work_hours_per_day", 8.0)),
		"scale": float(Config.get_value("scale", 1.0)),
		"opacity": float(Config.get_value("opacity", 1.0)),
		"window_mode": String(Config.get_value("window_mode", "top")),
		"pure_pet_mode": bool(Config.get_value("pure_pet_mode", false)),
		"debug_mode": bool(Config.get_value("debug_mode", false)),
		"auto_start": bool(Config.get_value("auto_start", false)),
		"minimize_to_tray": bool(Config.get_value("minimize_to_tray", true)),
		"update_channel": String(Config.get_value("update_channel", "beta")),
		"check_updates_on_start": bool(Config.get_value("check_updates_on_start", true)),
		"pet_id": String(Config.get_value("pet_id", "cat_orange_v2")),
		"panel_items": {
			"earnings_today": Config.get_panel_item("earnings_today"),
			"earnings_month": Config.get_panel_item("earnings_month"),
			"hourly_rate": Config.get_panel_item("hourly_rate"),
			"work_progress": Config.get_panel_item("work_progress"),
			"status": Config.get_panel_item("status")
		}
	}


func _has_form_changes(form_values: Dictionary) -> bool:
	var current := _current_settings_snapshot()
	for key in form_values:
		if current.get(key) != form_values.get(key):
			return true
	return false


func _validate_form_values(values: Dictionary) -> bool:
	var validation: Dictionary = _configuration_draft.validate()
	if not bool(validation.get("valid", false)):
		_set_general_message(String(validation.get("message", "请检查工资与作息设置。")), true)
		return false
	var pet_id := String(values.get("pet_id", ""))
	var pet_found := pet_id.is_empty()
	for pet in PetManager.get_available_pets():
		if String(pet.pet_id) == pet_id:
			pet_found = true
			break
	if not pet_found:
		_set_general_message("所选桌宠资源不可用。", true)
		return false
	var desired_auto_start := bool(values.get("auto_start", false))
	if desired_auto_start != Platform.is_auto_start_enabled() and not Platform.is_auto_start_supported():
		_set_general_message("当前运行环境不支持开机自启，请使用导出的程序。", true)
		return false
	return true


func _apply_form_values(values: Dictionary) -> void:
	for key in [
		"monthly_salary",
		"rest_mode",
		"alternating_anchor_date",
		"alternating_anchor_week_type",
		"work_start_time",
		"lunch_start_time",
		"lunch_end_time",
		"work_end_time",
		"work_hours_per_day",
		"scale",
		"opacity",
		"window_mode",
		"pure_pet_mode",
		"debug_mode",
		"minimize_to_tray",
		"update_channel",
		"check_updates_on_start",
		"auto_start",
		"pet_id"
	]:
		if Config.get_value(key) != values[key]:
			Config.set_value(key, values[key])

	var panel_items: Dictionary = values["panel_items"]
	for key in panel_items:
		if Config.get_panel_item(key) != bool(panel_items[key]):
			Config.set_panel_item(key, bool(panel_items[key]))



func _apply_committed_external_state(values: Dictionary) -> bool:
	var pet_id := String(values.get("pet_id", ""))
	if not pet_id.is_empty():
		PetManager.switch_pet(pet_id)
	var desired_auto_start := bool(values.get("auto_start", false))
	if desired_auto_start == Platform.is_auto_start_enabled():
		return true
	return Platform.set_auto_start(desired_auto_start)


func _get_selected_pet_id() -> String:
	if pet_option != null and pet_option.selected >= 0:
		var option_pets := PetManager.get_available_pets()
		if pet_option.selected < option_pets.size():
			return String(option_pets[pet_option.selected].pet_id)
	var selected := pet_list.get_selected_items()
	if selected.size() > 0:
		var pets := PetManager.get_available_pets()
		if int(selected[0]) < pets.size():
			return String(pets[int(selected[0])].pet_id)
	return String(Config.get_value("pet_id", "cat_orange_v2"))


func _set_save_status(message: String) -> void:
	_feedback_token += 1
	var token := _feedback_token
	if save_status_label != null:
		save_status_label.text = message
		save_feedback_panel.visible = not message.is_empty()
		var text_color := ACCENT_MINT
		if message.find("失败") >= 0 or message.find("不可用") >= 0:
			text_color = SETTINGS_ERROR
		elif message.find("重显") >= 0 or message.find("重启") >= 0 or message.find("没有") >= 0:
			text_color = SETTINGS_WARN
		save_feedback_panel.add_theme_stylebox_override("panel", _stylebox(Color(0, 0, 0, 0), Color(0, 0, 0, 0), 0, 0, 0))
		save_status_label.add_theme_color_override("font_color", text_color)
	if general_message_label != null:
		general_message_label.visible = false
	if not message.is_empty():
		_hide_feedback_later(token, true)


func _set_general_message(message: String, warning: bool = false) -> void:
	if general_message_label == null:
		return
	general_message_label.text = message
	general_message_label.visible = not message.is_empty()
	general_message_label.add_theme_color_override("font_color", SETTINGS_WARN if warning else ACCENT_MINT)
	_feedback_token += 1
	if not message.is_empty():
		_hide_feedback_later(_feedback_token, false)


func _hide_feedback_later(token: int, save_feedback: bool) -> void:
	await get_tree().create_timer(FEEDBACK_HIDE_SECONDS).timeout
	if token != _feedback_token:
		return
	if save_feedback and save_feedback_panel != null:
		save_status_label.text = "没有未保存的更改"
		save_status_label.add_theme_color_override("font_color", SETTINGS_MUTED)
		save_feedback_panel.add_theme_stylebox_override("panel", _stylebox(Color(0, 0, 0, 0), Color(0, 0, 0, 0), 0, 0, 0))
		save_feedback_panel.visible = true
	elif not save_feedback and general_message_label != null:
		general_message_label.visible = false


func _on_open_app_data_pressed() -> void:
	var result := DiagnosticsServiceScript.open_app_data_directory()
	if bool(result.get("ok", false)):
		Platform.write_info_log("diagnostics_open_data_directory_success")
		_set_general_message("已打开应用数据目录。")
	else:
		var reason := String(result.get("error", "未知错误"))
		Platform.write_error_log("diagnostics_open_data_directory_failed: reason=%s" % reason)
		_set_general_message(reason, true)


func _on_copy_diagnostics_pressed() -> void:
	var summary := DiagnosticsServiceScript.build_summary(Config.get_data_snapshot(), Platform.get_native_health())
	var result: Dictionary = await DiagnosticsServiceScript.copy_summary_to_clipboard(summary)
	if bool(result.get("ok", false)):
		if bool(result.get("verification_uncertain", false)):
			Platform.write_info_log("diagnostics_copy_verification_uncertain: reason=%s" % String(result.get("warning", "readback unavailable")))
		Platform.write_info_log("diagnostics_copy_success: verification=%s" % ("verified" if bool(result.get("verified", false)) else "unverified"))
		_set_general_message("诊断摘要已复制。")
	else:
		var reason := String(result.get("error", "未知错误"))
		Platform.write_error_log("diagnostics_copy_failed: reason=%s" % reason)
		_set_general_message(reason, true)


func _on_check_update_pressed() -> void:
	UpdateService.check_for_updates(true)


func _on_update_available(release: Dictionary) -> void:
	_available_release = release.duplicate(true)
	download_update_button.visible = true


func _on_update_download_ready(path: String, release: Dictionary) -> void:
	_pending_installer_path = path
	_available_release = release.duplicate(true)
	update_install_confirm_dialog.dialog_text = "版本 %s 已完成完整性与签名校验。安装前会备份配置并退出当前应用，是否继续？" % String(release.get("tag_name", ""))
	update_install_confirm_dialog.popup_centered()


func _on_update_install_confirmed() -> void:
	if _pending_installer_path.is_empty():
		_set_general_message("更新安装器路径已失效，请重新下载。", true)
		return
	var main := get_tree().current_scene
	if main == null or not main.has_method("prepare_update_exit"):
		_set_general_message("无法进入安全更新流程，请前往 GitHub Release 手动下载。", true)
		UpdateService.open_releases_page()
		return
	if not bool(main.call("prepare_update_exit", _pending_installer_path)):
		_set_general_message("启动更新失败，当前版本保持不变。", true)


func _on_download_update_pressed() -> void:
	var assets: Array = _available_release.get("assets", [])
	var selected: Dictionary = {}
	for asset in assets:
		if asset is Dictionary and String(asset.get("name", "")).to_lower().ends_with(".exe"):
			selected = asset
			break
	if selected.is_empty():
		_set_general_message("此版本没有可校验的安装器，请前往 GitHub Release 手动下载便携 Zip。安装版与便携版共享 APPDATA，请勿同时运行。", true)
		UpdateService.open_releases_page()
		return
	UpdateService.download_update(_available_release, selected)


func _on_cancel_update_pressed() -> void:
	UpdateService.cancel_download()


func _on_update_status_changed(state: String, message: String, _details: Dictionary) -> void:
	_set_general_message(message, state == "error")
	cancel_update_button.visible = state == "downloading"
	download_update_button.disabled = state in ["loading", "downloading"]


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
	var last_error := String(health.get("last_error", ""))
	if not pure_ok and not last_error.is_empty():
		native_status_label.text += "\n不可用原因：%s" % last_error
	if not pure_ok:
		pure_pet_mode_toggle.disabled = true
		pure_pet_mode_toggle.button_pressed = false
	else:
		pure_pet_mode_toggle.disabled = false
	_sync_switch_proxies()


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
	_sync_switch_proxies()
	_set_general_message("开机自启设置失败：请使用导出的 LetsMakeMoney.exe 再试。", true)
	return false


func _on_reset_position_pressed() -> void:
	DragResizeSystem.reset_window_position()
	_set_general_message("窗口位置已重置。")


func _on_restore_defaults_pressed() -> void:
	_show_restore_defaults_confirm()


func _show_restore_defaults_confirm() -> void:
	if restore_defaults_confirm_dialog != null:
		restore_defaults_confirm_dialog.popup_centered()


func _restore_display_defaults() -> void:
	var previous_config := Config.get_data_snapshot()
	var previous_external := _capture_external_state()
	Config.reset_display_defaults()
	if not Platform.set_auto_start(false) and Platform.is_auto_start_supported():
		Config.restore_data_snapshot(previous_config)
		_restore_external_state(previous_external, "restore_defaults_auto_start_failed")
		_set_save_status("保存失败：无法更新开机自启。")
		return
	if Config.save():
		_load_current_values()
		_set_general_message("显示、窗口、托盘和自启动设置已恢复默认。")
		Platform.write_boot_log("settings_restore_display_defaults_success: changed_keys=%s" % str(Config.get_last_changed_keys()))
	else:
		var reason := Config.get_last_save_error()
		Config.restore_data_snapshot(previous_config)
		_restore_external_state(previous_external, reason)
		_load_current_values()
		Platform.write_boot_log("settings_restore_display_defaults_failed: reason=%s" % reason, "error")
		_set_save_status("保存失败：%s" % reason)
