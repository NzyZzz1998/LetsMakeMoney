# src/scenes/settings/settings_dialog.gd
extends Control

const WarmControlThemeScript := preload("res://src/ui/warm_control_theme.gd")
const DiagnosticsServiceScript := preload("res://src/utils/diagnostics_service.gd")

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
var open_app_data_button: Button
var copy_diagnostics_button: Button
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
var _feedback_token: int = 0

const SURFACE_APP := Color(1.0, 0.980, 0.940, 1.0)
const SURFACE_CARD := Color(1.0, 0.996, 0.978, 1.0)
const SURFACE_NAV := Color(1.0, 0.952, 0.862, 1.0)
const SURFACE_SELECTED := Color(1.0, 0.938, 0.760, 1.0)
const TEXT_INK := Color(0.227, 0.153, 0.098, 1.0)
const TEXT_MUTED := Color(0.550, 0.420, 0.298, 1.0)
const ACCENT_COIN := Color(0.965, 0.714, 0.243, 1.0)
const ACCENT_ORANGE := Color(0.780, 0.420, 0.137, 1.0)
const ACCENT_MINT := Color(0.427, 0.624, 0.447, 1.0)
const DANGER_SOFT := Color(0.640, 0.278, 0.220, 1.0)
const BORDER_WARM := Color(0.416, 0.263, 0.122, 0.16)
const SHADOW_WARM := Color(0.360, 0.184, 0.047, 0.16)
const SETTINGS_SURFACE := SURFACE_APP
const SETTINGS_CONTENT := Color(0.0, 0.0, 0.0, 0.0)
const SETTINGS_CARD := SURFACE_CARD
const SETTINGS_TEXT := TEXT_INK
const SETTINGS_MUTED := TEXT_MUTED
const SETTINGS_ACCENT := ACCENT_COIN
const SETTINGS_WARN := ACCENT_ORANGE
const SETTINGS_ERROR := DANGER_SOFT
const SETTINGS_DIVIDER := Color(0.416, 0.263, 0.122, 0.10)
const SETTINGS_OUTER_PADDING := 10
const SETTINGS_SHEET_WIDTH := 680
const SETTINGS_SHEET_HEIGHT := 510
const SETTINGS_TAB_HEIGHT := 38
const SETTINGS_CONTROL_WIDTH := 128
const FEEDBACK_HIDE_SECONDS := 2.6
const SECTION_LABELS := {
	"Salary": "工资",
	"Pet": "桌宠",
	"Display": "显示",
	"Panel": "面板",
	"General": "通用"
}


func _ready() -> void:
	theme = _build_settings_theme()
	custom_minimum_size = Vector2(700, 530)
	_build_compact_ui()
	_load_current_values()
	if Config.has_method("consume_recovery_notice"):
		var recovery_notice := String(Config.call("consume_recovery_notice"))
		if not recovery_notice.is_empty():
			_set_general_message(recovery_notice, true)


func _build_compact_ui() -> void:
	var surface := Panel.new()
	surface.name = "SettingsSurface"
	surface.set_anchors_preset(Control.PRESET_FULL_RECT)
	surface.add_theme_stylebox_override("panel", _stylebox(SETTINGS_SURFACE, Color(0, 0, 0, 0), 0, 16, 0))
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
	shell.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	shell.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	shell.add_theme_stylebox_override("panel", _stylebox(SURFACE_CARD, Color(0.416, 0.263, 0.122, 0.10), 1, 18, 0, Color(0.360, 0.184, 0.047, 0.05), 3))
	shell_center.add_child(shell)

	var shell_box := VBoxContainer.new()
	shell_box.name = "SettingsShellColumn"
	shell_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	shell_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	shell_box.add_theme_constant_override("separation", 0)
	shell.add_child(shell_box)

	var top_margin := MarginContainer.new()
	top_margin.name = "SettingsTopMargin"
	top_margin.custom_minimum_size = Vector2(0, 46)
	top_margin.add_theme_constant_override("margin_left", 16)
	top_margin.add_theme_constant_override("margin_top", 6)
	top_margin.add_theme_constant_override("margin_right", 12)
	top_margin.add_theme_constant_override("margin_bottom", 4)
	shell_box.add_child(top_margin)

	var top_bar := HBoxContainer.new()
	top_bar.name = "SettingsTopBar"
	top_bar.mouse_filter = Control.MOUSE_FILTER_STOP
	top_bar.add_theme_constant_override("separation", 8)
	top_bar.gui_input.connect(_on_header_gui_input)
	top_margin.add_child(top_bar)

	var nav_spacer_left := Control.new()
	nav_spacer_left.custom_minimum_size = Vector2(8, 0)
	top_bar.add_child(nav_spacer_left)

	var nav_shell := PanelContainer.new()
	nav_shell.name = "SettingsNavSegment"
	nav_shell.custom_minimum_size = Vector2(0, SETTINGS_TAB_HEIGHT)
	nav_shell.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	nav_shell.add_theme_stylebox_override("panel", _stylebox(Color(1.0, 0.952, 0.862, 0.42), Color(0.416, 0.263, 0.122, 0.08), 1, 17, 5))
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
	close_button.custom_minimum_size = Vector2(28, 28)
	close_button.pressed.connect(_on_cancel)
	_style_window_button(close_button, true)
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
	content_margin.add_theme_constant_override("margin_left", 24)
	content_margin.add_theme_constant_override("margin_top", 4)
	content_margin.add_theme_constant_override("margin_right", 24)
	content_margin.add_theme_constant_override("margin_bottom", 0)
	shell_box.add_child(content_margin)

	var content_holder := Control.new()
	content_holder.name = "SettingsContentPages"
	content_holder.clip_contents = true
	content_holder.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_holder.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content_margin.add_child(content_holder)

	_add_settings_section(nav, content_holder, "Salary", _build_salary_tab())
	_add_settings_section(nav, content_holder, "Pet", _build_pet_tab())
	_add_settings_section(nav, content_holder, "Display", _build_display_tab())
	_add_settings_section(nav, content_holder, "Panel", _build_panel_tab())
	_add_settings_section(nav, content_holder, "General", _build_general_tab())
	_select_settings_section("Salary")

	save_status_label = Label.new()
	save_status_label.name = "SaveStatusLabel"
	save_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	save_status_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	save_status_label.add_theme_font_size_override("font_size", 13)
	save_status_label.add_theme_color_override("font_color", ACCENT_MINT)

	save_feedback_panel = PanelContainer.new()
	save_feedback_panel.name = "SaveFeedbackPanel"
	save_feedback_panel.visible = false
	save_feedback_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	save_feedback_panel.add_theme_stylebox_override("panel", _stylebox(Color(0.918, 0.980, 0.886, 0.98), Color(0.427, 0.624, 0.447, 0.42), 1, 9, 8))
	save_feedback_panel.add_child(save_status_label)
	var feedback_margin := MarginContainer.new()
	feedback_margin.name = "SaveFeedbackMargin"
	feedback_margin.add_theme_constant_override("margin_left", 24)
	feedback_margin.add_theme_constant_override("margin_top", 0)
	feedback_margin.add_theme_constant_override("margin_right", 24)
	feedback_margin.add_theme_constant_override("margin_bottom", 4)
	feedback_margin.add_child(save_feedback_panel)
	shell_box.add_child(feedback_margin)

	var action_divider := ColorRect.new()
	action_divider.name = "ActionDivider"
	action_divider.custom_minimum_size = Vector2(0, 1)
	action_divider.color = SETTINGS_DIVIDER
	shell_box.add_child(action_divider)

	var action_margin := MarginContainer.new()
	action_margin.name = "ActionMargin"
	action_margin.custom_minimum_size = Vector2(0, 46)
	action_margin.add_theme_constant_override("margin_left", 24)
	action_margin.add_theme_constant_override("margin_top", 5)
	action_margin.add_theme_constant_override("margin_right", 24)
	action_margin.add_theme_constant_override("margin_bottom", 5)
	shell_box.add_child(action_margin)

	var action_row := HBoxContainer.new()
	action_row.name = "ActionRow"
	action_row.custom_minimum_size = Vector2(0, 36)
	action_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	action_row.alignment = BoxContainer.ALIGNMENT_END
	action_row.add_theme_constant_override("separation", 10)
	action_margin.add_child(action_row)

	cancel_button = Button.new()
	cancel_button.name = "CancelButton"
	cancel_button.text = "取消"
	cancel_button.custom_minimum_size = Vector2(88, 34)
	cancel_button.pressed.connect(_on_cancel)
	_style_button(cancel_button)
	action_row.add_child(cancel_button)

	save_button = Button.new()
	save_button.name = "SaveButton"
	save_button.text = "保存"
	save_button.custom_minimum_size = Vector2(96, 34)
	save_button.pressed.connect(_on_save)
	_style_button(save_button, false, true)
	action_row.add_child(save_button)

	restore_defaults_confirm_dialog = ConfirmationDialog.new()
	restore_defaults_confirm_dialog.name = "RestoreDefaultsConfirmDialog"
	restore_defaults_confirm_dialog.title = "恢复默认显示设置"
	restore_defaults_confirm_dialog.dialog_text = "恢复默认只会重置显示、窗口、托盘、自启动和 Debug 设置，不清空薪资、工时、角色和 Panel 项。"
	restore_defaults_confirm_dialog.confirmed.connect(_restore_display_defaults)
	add_child(restore_defaults_confirm_dialog)


func _add_settings_section(nav: BoxContainer, content_holder: Control, section_name: String, page: Control) -> void:
	var button := Button.new()
	button.name = "%sNavButton" % section_name
	button.text = SECTION_LABELS.get(section_name, section_name)
	button.toggle_mode = true
	button.alignment = HORIZONTAL_ALIGNMENT_CENTER
	button.custom_minimum_size = Vector2(68, 30)
	button.add_theme_font_size_override("font_size", 14)
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
	_add_control_card(box, "休息模式", "选择单休或双休，影响每月工作日和时薪计算。", rest_mode_option)
	rest_mode_single_toggle = CheckButton.new()
	rest_mode_single_toggle.text = "单休（关闭则为双休）"
	rest_mode_single_toggle.visible = false
	box.add_child(rest_mode_single_toggle)
	_add_section_heading(box, "工作时间")
	hours_input = _add_spin(box, 0, 24, 0.25)
	hours_input.editable = false
	var start_row := _add_time_row(box)
	start_hour_input = start_row[0]
	start_min_input = start_row[1]
	_wrap_last_control_in_card(box, start_row[2], "上班时间", "用于判断工作中状态和今日已赚起点。")
	var end_row := _add_time_row(box)
	end_hour_input = end_row[0]
	end_min_input = end_row[1]
	_wrap_last_control_in_card(box, end_row[2], "下班时间", "用于判断休息状态和今日收入封顶时间。")
	_wrap_last_control_in_card(box, hours_input, "每日工作小时数", "根据上下班时间自动计算，只读展示。")
	_connect_time_inputs()
	return root


func _build_pet_tab() -> Control:
	var root := _new_tab("Pet")
	var box := _new_vbox(root)
	_add_inline_actions(box)
	_add_page_heading(box, "桌宠设置", "选择陪你工作的橘猫伙伴")
	_add_section_heading(box, "角色")
	pet_list = ItemList.new()
	pet_list.custom_minimum_size = Vector2(0, 108)
	_add_control_card(box, "选择角色", "", pet_list)
	_add_note_block(box, "说明", [
		"当前默认使用橘猫 v2，并保留旧素材作为回退。"
	])
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
	return root


func _build_panel_tab() -> Control:
	var root := _new_tab("Panel")
	var box := _new_vbox(root)
	_add_inline_actions(box)
	_add_page_heading(box, "面板设置", "金币小票上显示哪些信息")
	_add_section_heading(box, "展开态显示项")
	show_today = _add_checkbox_row(box, "今日已赚", "显示当天累计收入。")
	show_month = _add_checkbox_row(box, "本月累计", "显示本月累计收入。")
	show_rate = _add_checkbox_row(box, "时薪", "显示折算后的当前时薪。")
	show_progress = _add_checkbox_row(box, "工作进度", "显示今日工作进度条。")
	show_state = _add_checkbox_row(box, "状态", "显示工作中、休息中等状态。")
	return root


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
	var scroll := ScrollContainer.new()
	scroll.name = tab_name
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.follow_focus = true
	scroll.mouse_filter = Control.MOUSE_FILTER_STOP
	var vbar := scroll.get_v_scroll_bar()
	vbar.custom_minimum_size = Vector2(5, 0)
	vbar.add_theme_stylebox_override("scroll", _stylebox(Color(0, 0, 0, 0), Color(0, 0, 0, 0), 0, 3, 0))
	vbar.add_theme_stylebox_override("grabber", _stylebox(Color(0.416, 0.263, 0.122, 0.18), Color(0, 0, 0, 0), 0, 3, 0))
	vbar.add_theme_stylebox_override("grabber_highlight", _stylebox(Color(0.416, 0.263, 0.122, 0.30), Color(0, 0, 0, 0), 0, 3, 0))
	vbar.add_theme_stylebox_override("grabber_pressed", _stylebox(Color(0.416, 0.263, 0.122, 0.38), Color(0, 0, 0, 0), 0, 3, 0))
	return scroll


func _new_vbox(parent: Control) -> VBoxContainer:
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


func _add_page_heading(parent: Control, title: String, hint: String) -> void:
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
	title_label.add_theme_color_override("font_color", SETTINGS_TEXT)
	row.add_child(title_label)

	var hint_label := Label.new()
	hint_label.text = hint
	hint_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint_label.add_theme_font_size_override("font_size", 12)
	hint_label.add_theme_color_override("font_color", SETTINGS_MUTED)
	row.add_child(hint_label)


func _add_section_heading(parent: Control, title: String) -> void:
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 3)
	parent.add_child(spacer)

	var label := Label.new()
	label.name = "SettingsSectionHeading"
	label.text = title
	label.add_theme_font_size_override("font_size", 12)
	label.add_theme_color_override("font_color", ACCENT_ORANGE)
	parent.add_child(label)


func _add_setting_card(parent: Control, title: String, description: String = "") -> VBoxContainer:
	var card := PanelContainer.new()
	card.name = "SettingCard"
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.custom_minimum_size = Vector2(0, 48)
	card.add_theme_stylebox_override("panel", _stylebox(Color(1.0, 0.998, 0.988, 0.16), Color(0.416, 0.263, 0.122, 0.04), 0, 6, 4))
	parent.add_child(card)

	var box := VBoxContainer.new()
	box.name = "SettingCardBody"
	box.add_theme_constant_override("separation", 2)
	card.add_child(box)

	var title_label := Label.new()
	title_label.name = "SettingCardTitle"
	title_label.text = title
	title_label.add_theme_font_size_override("font_size", 15)
	title_label.add_theme_color_override("font_color", SETTINGS_TEXT)
	title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(title_label)

	if not description.is_empty():
		var description_label := Label.new()
		description_label.name = "SettingCardDescription"
		description_label.text = description
		description_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		description_label.add_theme_font_size_override("font_size", 13)
		description_label.add_theme_color_override("font_color", SETTINGS_MUTED)
		box.add_child(description_label)
	return box


func _add_control_card(parent: Control, title: String, _description: String, control: Control) -> void:
	var row_panel := PanelContainer.new()
	row_panel.name = "SettingRow"
	row_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row_panel.custom_minimum_size = Vector2(0, 38)
	row_panel.add_theme_stylebox_override("panel", _stylebox(Color(1.0, 0.998, 0.988, 0.0), Color(0, 0, 0, 0), 0, 0, 2))
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
	title_label.add_theme_color_override("font_color", SETTINGS_TEXT)
	copy.add_child(title_label)

	if control is CheckButton or control is CheckBox:
		_add_switch_proxy(row, control as BaseButton)
		return
	_style_form_control(control)
	control.custom_minimum_size = _control_minimum_size(control)
	control.size_flags_horizontal = Control.SIZE_SHRINK_END
	control.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(control)


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
	var track := Color(0.870, 0.760, 0.560, 0.48)
	var border := Color(0.416, 0.263, 0.122, 0.18)
	if on:
		track = ACCENT_COIN
		border = Color(0.780, 0.420, 0.137, 0.28)
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
	if lines.is_empty():
		return
	var block := VBoxContainer.new()
	block.name = "SettingsNoteBlock"
	block.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	block.add_theme_constant_override("separation", 3)
	parent.add_child(block)
	_add_note_title(block, title)
	for line in lines:
		if line.is_empty():
			continue
		var label := _new_note_text(line)
		block.add_child(label)


func _add_note_label(parent: Control, title: String, label: Label) -> void:
	var block := VBoxContainer.new()
	block.name = "SettingsNoteBlock"
	block.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	block.add_theme_constant_override("separation", 3)
	parent.add_child(block)
	_add_note_title(block, title)
	_style_note_label(label)
	block.add_child(label)


func _add_note_title(parent: Control, title: String) -> void:
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


func _new_note_text(text: String) -> Label:
	var label := Label.new()
	label.text = text
	_style_note_label(label)
	return label


func _style_note_label(label: Label) -> void:
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.add_theme_font_size_override("font_size", 12)
	label.add_theme_color_override("font_color", Color(TEXT_MUTED.r, TEXT_MUTED.g, TEXT_MUTED.b, 0.84))


func _wrap_last_control_in_card(parent: Control, control: Control, title: String, description: String) -> void:
	parent.remove_child(control)
	_add_control_card(parent, title, description, control)


func _control_minimum_size(control: Control) -> Vector2:
	if control is HBoxContainer and control.name == "SliderRow":
		return Vector2(236, 32)
	if control is HBoxContainer and control.name == "TimeRow":
		return Vector2(148, 32)
	if control is ItemList:
		return Vector2(SETTINGS_CONTROL_WIDTH + 110, 98)
	if control is Button:
		return Vector2(104, 32)
	if control is OptionButton:
		return Vector2(SETTINGS_CONTROL_WIDTH, 32)
	if control is SpinBox:
		return Vector2(92, 32)
	if control is CheckButton or control is CheckBox:
		return Vector2(42, 24)
	return Vector2(SETTINGS_CONTROL_WIDTH, 34)


func _add_checkbox_row(parent: Control, title: String, description: String) -> CheckBox:
	var checkbox := CheckBox.new()
	checkbox.text = ""
	_add_control_card(parent, title, description, checkbox)
	return checkbox


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
	var hover_bg := Color(1.0, 0.930, 0.760, 0.82)
	var pressed_bg := Color(0.965, 0.714, 0.243, 0.36)
	var hover_border := Color(0.780, 0.420, 0.137, 0.22)
	var pressed_border := Color(0.780, 0.420, 0.137, 0.30)
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
	var normal_bg := Color(0.0, 0.0, 0.0, 0.0)
	var hover_bg := Color(1.0, 0.972, 0.902, 1.0)
	var pressed_bg := Color(1.0, 0.932, 0.742, 1.0)
	var border := Color(0, 0, 0, 0)
	var shadow := Color(0, 0, 0, 0)
	if active:
		normal_bg = Color(1.0, 0.998, 0.988, 1.0)
		hover_bg = Color(1.0, 0.990, 0.948, 1.0)
		border = Color(0.965, 0.714, 0.243, 0.74)
		shadow = Color(0.360, 0.184, 0.047, 0.08)
	button.add_theme_stylebox_override("normal", _stylebox(normal_bg, border, 1 if active else 0, 9, 5, shadow, 2 if active else 0))
	button.add_theme_stylebox_override("hover", _stylebox(hover_bg, Color(0.780, 0.420, 0.137, 0.18), 1, 9, 5))
	button.add_theme_stylebox_override("pressed", _stylebox(pressed_bg, SETTINGS_ACCENT, 1, 9, 5))
	button.add_theme_stylebox_override("focus", _stylebox(Color(0, 0, 0, 0), SETTINGS_ACCENT, 2, 9, 5))
	button.add_theme_color_override("font_color", SETTINGS_TEXT if active else SETTINGS_MUTED)
	button.add_theme_color_override("font_hover_color", SETTINGS_TEXT)
	button.add_theme_color_override("font_pressed_color", SETTINGS_TEXT)


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
	var spin := SpinBox.new()
	spin.min_value = min_value
	spin.max_value = max_value
	spin.step = step
	spin.custom_minimum_size = Vector2(92, 32)
	_style_form_control(spin)
	parent.add_child(spin)
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
	var row := HBoxContainer.new()
	row.name = "TimeRow"
	row.custom_minimum_size = Vector2(148, 32)
	row.add_theme_constant_override("separation", 6)
	parent.add_child(row)
	var hour := _add_spin(row, 0, 23, 1)
	hour.custom_minimum_size = Vector2(64, 0)
	_add_label(row, ":")
	var minute := _add_spin(row, 0, 59, 1)
	minute.custom_minimum_size = Vector2(64, 0)
	return [hour, minute, row]


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
	_sync_switch_proxies()

	_populate_pet_list()
	_load_panel_checkboxes()
	_update_hours_preview()


func _populate_pet_list() -> void:
	pet_list.clear()
	var pets := PetManager.get_available_pets()
	var current_id := String(Config.get_value("pet_id", "cat_orange_v2"))
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
	var form_values := _collect_form_values()
	if not _has_form_changes(form_values):
		Platform.write_boot_log("settings_save_no_change")
		_set_save_status("没有需要保存的更改。")
		return
	var previous_config := Config.get_data_snapshot()
	var previous_external := _capture_external_state()
	if not _validate_form_values(form_values):
		Config.restore_data_snapshot(previous_config)
		_restore_external_state(previous_external, "pre_save_validation_failed")
		Platform.write_boot_log("settings_save_failed: reason=pre_save_apply_failed", "error")
		_set_save_status("保存失败：请查看不可用原因并重试。")
		return
	_apply_form_values(form_values)
	if not Config.save():
		var reason := Config.get_last_save_error()
		Config.restore_data_snapshot(previous_config)
		_restore_external_state(previous_external, reason)
		Platform.write_boot_log("settings_save_failed: reason=%s" % reason, "error")
		_set_save_status("保存失败：%s" % reason)
		return
	if not _apply_committed_external_state(form_values):
		Config.restore_data_snapshot(previous_config)
		var rollback_saved := Config.save()
		var rollback_external := _restore_external_state(previous_external, "external_apply_failed")
		Platform.write_error_log("settings_transaction_rollback: reason=external_apply_failed config=%s external=%s" % [str(rollback_saved), str(rollback_external)])
		_set_save_status("保存失败：外部设置未生效，已恢复原设置。")
		return
	Platform.write_boot_log("settings_save_success: changed_keys=%s" % str(Config.get_last_changed_keys()))
	_set_save_status("保存成功。")


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
	return {
		"monthly_salary": float(salary_input.value),
		"rest_mode": "single" if rest_mode_option.selected == 1 else "double",
		"work_start_time": "%02d:%02d" % [int(start_hour_input.value), int(start_min_input.value)],
		"work_end_time": "%02d:%02d" % [int(end_hour_input.value), int(end_min_input.value)],
		"work_hours_per_day": _calculate_work_hours(),
		"scale": scale_slider.value / 100.0,
		"opacity": opacity_slider.value / 100.0,
		"window_mode": "embed" if window_mode_option.selected == 1 else "top",
		"pure_pet_mode": pure_pet_mode_toggle.button_pressed and not pure_pet_mode_toggle.disabled,
		"debug_mode": debug_mode_toggle.button_pressed,
		"auto_start": auto_start_toggle.button_pressed,
		"minimize_to_tray": minimize_to_tray_toggle.button_pressed,
		"pet_id": _get_selected_pet_id(),
		"panel_items": {
			"earnings_today": show_today.button_pressed,
			"earnings_month": show_month.button_pressed,
			"hourly_rate": show_rate.button_pressed,
			"work_progress": show_progress.button_pressed,
			"status": show_state.button_pressed
		}
	}


func _current_settings_snapshot() -> Dictionary:
	return {
		"monthly_salary": float(Config.get_value("monthly_salary", 0)),
		"rest_mode": String(Config.get_value("rest_mode", "double")),
		"work_start_time": String(Config.get_value("work_start_time", "09:00")),
		"work_end_time": String(Config.get_value("work_end_time", "18:00")),
		"work_hours_per_day": float(Config.get_value("work_hours_per_day", 8.0)),
		"scale": float(Config.get_value("scale", 1.0)),
		"opacity": float(Config.get_value("opacity", 1.0)),
		"window_mode": String(Config.get_value("window_mode", "top")),
		"pure_pet_mode": bool(Config.get_value("pure_pet_mode", false)),
		"debug_mode": bool(Config.get_value("debug_mode", false)),
		"auto_start": bool(Config.get_value("auto_start", false)),
		"minimize_to_tray": bool(Config.get_value("minimize_to_tray", true)),
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
		"work_start_time",
		"work_end_time",
		"work_hours_per_day",
		"scale",
		"opacity",
		"window_mode",
		"pure_pet_mode",
		"debug_mode",
		"minimize_to_tray",
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
		var panel_color := Color(0.918, 0.980, 0.886, 0.98)
		var border_color := Color(0.427, 0.624, 0.447, 0.42)
		var text_color := ACCENT_MINT
		if message.find("失败") >= 0 or message.find("不可用") >= 0:
			panel_color = Color(1.0, 0.908, 0.858, 0.98)
			border_color = Color(0.640, 0.278, 0.220, 0.34)
			text_color = SETTINGS_ERROR
		elif message.find("重显") >= 0 or message.find("重启") >= 0 or message.find("没有") >= 0:
			panel_color = Color(1.0, 0.952, 0.842, 0.98)
			border_color = Color(0.965, 0.714, 0.243, 0.52)
			text_color = SETTINGS_WARN
		save_feedback_panel.add_theme_stylebox_override("panel", _stylebox(panel_color, border_color, 1, 12, 12))
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
		save_feedback_panel.visible = false
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
