extends Node

const AppVersionScript := preload("res://src/utils/app_version.gd")

signal modal_opened
signal modal_closed
signal popup_opened
signal popup_closed

const MODAL_WINDOW_SIZE := Vector2i(700, 530)
const MODAL_WINDOW_MARGIN := 24
const SETTINGS_DIALOG_SIZE := Vector2i(880, 640)
const WIZARD_DIALOG_SIZE := Vector2i(620, 460)
const MENU_FONT_NAMES := ["Microsoft YaHei UI", "Microsoft YaHei", "Segoe UI"]
const SURFACE_PAPER := Color(1.0, 0.965, 0.878, 0.99)
const SURFACE_PAPER_STRONG := Color(1.0, 0.945, 0.792, 1.0)
const TEXT_INK := Color(0.227, 0.153, 0.098, 1.0)
const TEXT_MUTED := Color(0.550, 0.420, 0.298, 1.0)
const ACCENT_COIN := Color(0.965, 0.714, 0.243, 1.0)
const ACCENT_ORANGE := Color(0.780, 0.420, 0.137, 1.0)
const ACCENT_MINT := Color(0.427, 0.624, 0.447, 1.0)
const BORDER_WARM := Color(0.416, 0.263, 0.122, 0.16)
const SHADOW_WARM := Color(0.360, 0.184, 0.047, 0.18)

var _window: Window = null
var _active_modal: Node = null
var _active_popups: Array[PopupMenu] = []
var _config_connected: bool = false
var _window_visible: bool = true
var _about_dialog: AcceptDialog = null
var _popup_menu_theme: Theme = null


func register_window(window: Window) -> void:
	_window = window
	_window_visible = window.visible
	if not _config_connected:
		Config.config_changed.connect(_on_config_changed)
		_config_connected = true
	_apply_window_mode(String(Config.get_value("window_mode", "top")))


func get_registered_window() -> Window:
	return _window


func is_window_visible() -> bool:
	return _window_visible


func move_window_to(pos: Vector2i) -> void:
	if _window:
		_window.position = pos


func save_position() -> void:
	if _window:
		Config.set_value("window_x", int(_window.position.x))
		Config.set_value("window_y", int(_window.position.y))
		Config.save()


func reset_window_position() -> void:
	if _window == null:
		return
	var size := _window.size
	var screen := Platform.get_screen_size()
	var pos := Vector2i(max(0, screen.x - size.x - 20), max(0, screen.y - size.y - 80))
	move_window_to(pos)
	save_position()


func set_window_visible(visible: bool) -> void:
	if _window == null:
		return
	if not visible:
		Platform.set_mouse_passthrough(_window, false, [])
	_window_visible = visible
	var native_ok := Platform.set_window_visible(_window, visible)
	Platform.write_boot_log("DragResizeSystem.set_window_visible: desired=%s native_ok=%s window_prop_before=%s" % [str(visible), str(native_ok), str(_window.visible)])
	if visible:
		_window.visible = true
		if _window.has_method("show"):
			_window.show()
	elif not native_ok:
		_window.visible = false
		if _window.has_method("hide"):
			_window.hide()
	if visible:
		_window.grab_focus()
	Platform.write_boot_log("DragResizeSystem.set_window_visible: desired=%s window_prop_after=%s" % [str(visible), str(_window.visible)])
	Platform.update_tray_menu(visible)


func toggle_window_visible() -> void:
	if _window != null:
		set_window_visible(not _window_visible)


func show_context_menu() -> void:
	var popup := PopupMenu.new()
	popup.add_item("隐藏到托盘", 600)
	popup.add_separator()
	_build_main_menu(popup)
	_popup_at_mouse(popup)


func show_tray_menu() -> void:
	var popup := PopupMenu.new()
	popup.add_item("显示/隐藏", 600)
	popup.add_separator()
	_build_main_menu(popup)
	_popup_at_mouse(popup)


func _build_main_menu(menu: PopupMenu) -> void:
	_apply_menu_readability(menu)
	menu.add_item("设置", 100)
	menu.add_item("重新运行向导", 101)

	menu.add_separator()
	var window_submenu := _build_window_mode_submenu()
	menu.add_child(window_submenu)
	menu.add_submenu_item("窗口模式", window_submenu.name)
	var pet_submenu := _build_pet_submenu()
	menu.add_child(pet_submenu)
	menu.add_submenu_item("选择宠物", pet_submenu.name)

	menu.add_separator()
	menu.add_item("关于 LetsMakeMoney", 400)
	menu.add_separator()
	menu.add_item("退出", 500)

	menu.id_pressed.connect(_on_menu_id)


func _build_window_mode_submenu() -> PopupMenu:
	var submenu := PopupMenu.new()
	submenu.name = "WindowModeSubmenu"
	_apply_menu_readability(submenu)
	var window_mode := String(Config.get_value("window_mode", "top"))
	submenu.add_check_item("置顶悬浮", 300)
	submenu.set_item_checked(submenu.item_count - 1, window_mode == "top")
	submenu.add_check_item("融入桌面", 301)
	submenu.set_item_checked(submenu.item_count - 1, window_mode == "embed")
	submenu.id_pressed.connect(_on_menu_id)
	return submenu


func _build_pet_submenu() -> PopupMenu:
	var submenu := PopupMenu.new()
	submenu.name = "PetSubmenu"
	_apply_menu_readability(submenu)
	var pets := PetManager.get_available_pets()
	var current_id := String(Config.get_value("pet_id", "cat_orange_v2"))
	if pets.is_empty():
		submenu.add_item("暂无可用宠物", 299)
		submenu.set_item_disabled(submenu.item_count - 1, true)
	else:
		for i in range(pets.size()):
			submenu.add_check_item(pets[i].display_name, 200 + i)
			if pets[i].pet_id == current_id:
				submenu.set_item_checked(submenu.item_count - 1, true)
	submenu.id_pressed.connect(_on_menu_id)
	return submenu


func _apply_menu_readability(menu: PopupMenu) -> void:
	menu.theme = _get_popup_menu_theme()
	menu.transparent_bg = true
	menu.borderless = true
	menu.min_size = Vector2i(202, 0)
	menu.add_theme_font_size_override("font_size", 15)
	menu.add_theme_constant_override("item_min_height", 34)
	menu.add_theme_constant_override("item_start_padding", 12)
	menu.add_theme_constant_override("item_end_padding", 12)
	menu.add_theme_constant_override("h_separation", 8)
	menu.add_theme_constant_override("v_separation", 2)


func _get_popup_menu_theme() -> Theme:
	if _popup_menu_theme != null:
		return _popup_menu_theme

	var font := SystemFont.new()
	font.font_names = PackedStringArray(MENU_FONT_NAMES)
	font.antialiasing = TextServer.FONT_ANTIALIASING_LCD
	font.hinting = TextServer.HINTING_NORMAL
	font.subpixel_positioning = TextServer.SUBPIXEL_POSITIONING_AUTO

	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = SURFACE_PAPER
	panel_style.border_color = BORDER_WARM
	panel_style.border_width_left = 1
	panel_style.border_width_top = 1
	panel_style.border_width_right = 1
	panel_style.border_width_bottom = 1
	panel_style.set_corner_radius_all(14)
	panel_style.content_margin_left = 8
	panel_style.content_margin_top = 8
	panel_style.content_margin_right = 8
	panel_style.content_margin_bottom = 8
	panel_style.shadow_color = SHADOW_WARM
	panel_style.shadow_size = 10
	panel_style.shadow_offset = Vector2(0, 4)

	var hover_style := StyleBoxFlat.new()
	hover_style.bg_color = Color(0.965, 0.714, 0.243, 0.20)
	hover_style.set_corner_radius_all(10)
	hover_style.content_margin_left = 7
	hover_style.content_margin_top = 2
	hover_style.content_margin_right = 7
	hover_style.content_margin_bottom = 2

	var separator_style := StyleBoxFlat.new()
	separator_style.bg_color = BORDER_WARM
	separator_style.content_margin_left = 0
	separator_style.content_margin_top = 1
	separator_style.content_margin_right = 0
	separator_style.content_margin_bottom = 1

	var theme := Theme.new()
	theme.default_font = font
	theme.default_font_size = 15
	theme.set_font("font", "PopupMenu", font)
	theme.set_font_size("font_size", "PopupMenu", 15)
	theme.set_stylebox("panel", "PopupMenu", panel_style)
	theme.set_stylebox("hover", "PopupMenu", hover_style)
	theme.set_stylebox("separator", "PopupMenu", separator_style)
	theme.set_color("font_color", "PopupMenu", TEXT_INK)
	theme.set_color("font_hover_color", "PopupMenu", TEXT_INK)
	theme.set_color("font_disabled_color", "PopupMenu", Color(TEXT_MUTED.r, TEXT_MUTED.g, TEXT_MUTED.b, 0.58))
	theme.set_color("font_accelerator_color", "PopupMenu", TEXT_MUTED)
	theme.set_color("font_separator_color", "PopupMenu", TEXT_MUTED)
	theme.set_color("font_outline_color", "PopupMenu", Color(0, 0, 0, 0))
	theme.set_color("font_hover_pressed_color", "PopupMenu", TEXT_INK)
	theme.set_color("font_checked_color", "PopupMenu", ACCENT_ORANGE)
	theme.set_constant("item_min_height", "PopupMenu", 34)
	theme.set_constant("item_start_padding", "PopupMenu", 12)
	theme.set_constant("item_end_padding", "PopupMenu", 12)
	theme.set_constant("h_separation", "PopupMenu", 8)
	theme.set_constant("v_separation", "PopupMenu", 2)
	theme.set_constant("indent", "PopupMenu", 8)

	_popup_menu_theme = theme
	return _popup_menu_theme


func _popup_at_mouse(popup: PopupMenu) -> void:
	if _window == null:
		popup.queue_free()
		return
	Platform.set_mouse_passthrough(_window, false, [])
	_window.add_child(popup)
	_active_popups.append(popup)
	popup.position = DisplayServer.mouse_get_position() - _window.position
	popup.popup()
	popup_opened.emit()
	popup.popup_hide.connect(_on_popup_hide.bind(popup))


func _on_popup_hide(popup: PopupMenu) -> void:
	_cleanup_popup(popup)


func _cleanup_popup(popup: PopupMenu) -> void:
	_active_popups.erase(popup)
	if popup != null and is_instance_valid(popup):
		popup.queue_free()
	if _active_popups.is_empty():
		popup_closed.emit()


func _on_menu_id(id: int) -> void:
	match id:
		100:
			open_settings()
		101:
			_open_wizard()
		300:
			Config.set_value("window_mode", "top")
			_apply_window_mode("top")
			Config.save()
		301:
			Config.set_value("window_mode", "embed")
			_apply_window_mode("embed")
			Config.save()
		400:
			show_about()
		500:
			quit_app()
		600:
			toggle_window_visible()
		_:
			if id >= 200 and id < 300:
				_switch_pet_by_menu_id(id)
	_close_all_popups()


func _switch_pet_by_menu_id(id: int) -> void:
	var idx := id - 200
	var pets := PetManager.get_available_pets()
	if idx >= 0 and idx < pets.size():
		PetManager.switch_pet(pets[idx].pet_id)
		Config.save()


func _close_all_popups() -> void:
	for popup in _active_popups.duplicate():
		if popup != null and is_instance_valid(popup):
			popup.hide()


func _apply_window_mode(mode: String) -> void:
	if _window == null:
		return
	if mode == "embed":
		Platform.set_window_embed_desktop(_window, true)
	else:
		Platform.set_window_topmost(_window, true)


func _on_config_changed() -> void:
	_apply_window_mode(String(Config.get_value("window_mode", "top")))


func open_settings() -> void:
	if _window == null:
		return
	set_window_visible(true)
	prepare_modal_window()
	var settings_scene := load("res://src/scenes/settings/settings_dialog.tscn")
	if settings_scene == null:
		OS.alert("设置面板加载失败。", "LetsMakeMoney")
		return
	var settings_view: Control = settings_scene.instantiate()
	_window.title = "设置"
	_active_modal = settings_view
	_window.add_child(settings_view)
	settings_view.set_anchors_preset(Control.PRESET_FULL_RECT)
	settings_view.offset_left = 0
	settings_view.offset_top = 0
	settings_view.offset_right = 0
	settings_view.offset_bottom = 0
	settings_view.tree_exited.connect(_on_modal_tree_exited)
	settings_view.grab_focus()


func close_active_modal() -> void:
	if _active_modal != null and is_instance_valid(_active_modal):
		_active_modal.queue_free()
	else:
		_active_modal = null
		modal_closed.emit()


func _open_wizard() -> void:
	if _window == null:
		return
	set_window_visible(true)
	prepare_modal_window(WIZARD_DIALOG_SIZE)
	var wizard_scene := load("res://src/scenes/wizard/wizard_dialog.tscn")
	if wizard_scene == null:
		OS.alert("首次启动向导加载失败。", "LetsMakeMoney")
		return
	var wizard_view: Control = wizard_scene.instantiate()
	_window.title = "开始配置"
	_active_modal = wizard_view
	_window.add_child(wizard_view)
	wizard_view.set_anchors_preset(Control.PRESET_FULL_RECT)
	wizard_view.offset_left = 0
	wizard_view.offset_top = 0
	wizard_view.offset_right = 0
	wizard_view.offset_bottom = 0
	wizard_view.tree_exited.connect(_on_modal_tree_exited)
	wizard_view.grab_focus()


func prepare_modal_window(target_size: Vector2i = MODAL_WINDOW_SIZE) -> void:
	if _window != null:
		_window.borderless = true
		_window.transparent_bg = true
		if DisplayServer.has_method("window_set_flag"):
			DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_TRANSPARENT, true, _window.get_window_id())
		_window.unresizable = true
		_window.min_size = target_size
		_window.size = target_size
		_fit_modal_window_on_screen(target_size)
		Platform.set_mouse_passthrough(_window, false, [])
	modal_opened.emit()


func _fit_modal_window_on_screen(size: Vector2i) -> void:
	if _window == null:
		return
	var screen := Platform.get_screen_size()
	var max_x: int = int(max(MODAL_WINDOW_MARGIN, screen.x - size.x - MODAL_WINDOW_MARGIN))
	var max_y: int = int(max(MODAL_WINDOW_MARGIN, screen.y - size.y - MODAL_WINDOW_MARGIN))
	var x: int = int(clamp(_window.position.x, MODAL_WINDOW_MARGIN, max_x))
	var y: int = int(clamp(_window.position.y, MODAL_WINDOW_MARGIN, max_y))
	_window.position = Vector2i(x, y)


func _on_modal_tree_exited() -> void:
	_active_modal = null
	modal_closed.emit()


func show_about() -> void:
	set_window_visible(true)
	if _window == null:
		return
	if _about_dialog != null and is_instance_valid(_about_dialog):
		_about_dialog.popup_centered(Vector2i(420, 280))
		_about_dialog.grab_focus()
		return

	_about_dialog = AcceptDialog.new()
	_about_dialog.title = "关于 LetsMakeMoney"
	_about_dialog.min_size = Vector2i(420, 280)
	_about_dialog.ok_button_text = "确定"

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_bottom", 16)
	_about_dialog.add_child(margin)

	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 10)
	margin.add_child(layout)

	var icon := TextureRect.new()
	icon.texture = load("res://icons/app_icon.png")
	icon.custom_minimum_size = Vector2(96, 96)
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	layout.add_child(icon)

	var title := Label.new()
	title.text = "LetsMakeMoney %s" % AppVersionScript.get_display_version()
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 22)
	layout.add_child(title)

	var body := Label.new()
	body.text = "极简生产力小工具 + 橘猫桌宠陪伴\n\n配置路径：%APPDATA%\\LetsMakeMoney\\config.json"
	body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	layout.add_child(body)

	_about_dialog.tree_exited.connect(func() -> void:
		_about_dialog = null
	)
	_window.add_child(_about_dialog)
	_about_dialog.popup_centered(Vector2i(420, 280))
	_about_dialog.grab_focus()

func quit_app() -> void:
	save_position()
	Config.save()
	if _window != null:
		Platform.set_mouse_passthrough(_window, false, [])
	Platform.shutdown_tray()
	get_tree().quit()
