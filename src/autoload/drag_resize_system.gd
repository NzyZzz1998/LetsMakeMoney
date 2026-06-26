# src/autoload/drag_resize_system.gd
extends Node

var _window: Window = null
var _active_popups: Array[PopupMenu] = []
var _config_connected: bool = false


func register_window(window: Window) -> void:
	_window = window
	if not _config_connected:
		Config.config_changed.connect(_on_config_changed)
		_config_connected = true
	_apply_window_mode(String(Config.get_value("window_mode", "top")))


func move_window_to(pos: Vector2i) -> void:
	if _window:
		_window.position = pos


func save_position() -> void:
	if _window:
		Config.set_value("window_x", int(_window.position.x))
		Config.set_value("window_y", int(_window.position.y))
		Config.save()


func show_context_menu() -> void:
	var popup := PopupMenu.new()
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

	var pet_menu := PopupMenu.new()
	pet_menu.name = "PetMenu"
	_apply_menu_readability(pet_menu)
	var pets := PetManager.get_available_pets()
	var current_id := String(Config.get_value("pet_id", "cat"))
	for i in range(pets.size()):
		pet_menu.add_check_item(pets[i].display_name, 200 + i)
		if pets[i].pet_id == current_id:
			pet_menu.set_item_checked(i, true)
	menu.add_child(pet_menu)
	menu.add_submenu_item("切换角色", "PetMenu")

	var mode_menu := PopupMenu.new()
	mode_menu.name = "ModeMenu"
	_apply_menu_readability(mode_menu)
	mode_menu.add_check_item("置顶悬浮", 300)
	mode_menu.add_check_item("融入桌面", 301)
	var window_mode := String(Config.get_value("window_mode", "top"))
	mode_menu.set_item_checked(0, window_mode == "top")
	mode_menu.set_item_checked(1, window_mode == "embed")
	menu.add_child(mode_menu)
	menu.add_submenu_item("窗口模式", "ModeMenu")

	menu.add_separator()
	menu.add_item("关于 LetsMakeMoney", 400)
	menu.add_separator()
	menu.add_item("退出", 500)

	pet_menu.id_pressed.connect(_on_menu_id)
	mode_menu.id_pressed.connect(_on_menu_id)
	menu.id_pressed.connect(_on_menu_id)


func _apply_menu_readability(menu: PopupMenu) -> void:
	menu.add_theme_font_size_override("font_size", 18)
	menu.add_theme_constant_override("v_separation", 8)


func _popup_at_mouse(popup: PopupMenu) -> void:
	if _window == null:
		popup.queue_free()
		return
	_window.add_child(popup)
	_active_popups.append(popup)
	popup.position = DisplayServer.mouse_get_position() - _window.position
	popup.popup()
	popup.popup_hide.connect(_on_popup_hide.bind(popup))


func _on_popup_hide(popup: PopupMenu) -> void:
	_cleanup_popup(popup)


func _cleanup_popup(popup: PopupMenu) -> void:
	_active_popups.erase(popup)
	if popup != null and is_instance_valid(popup):
		popup.queue_free()


func _on_menu_id(id: int) -> void:
	match id:
		100:
			_open_settings()
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
			_show_about()
		500:
			_quit_app()
		600:
			if _window != null:
				_window.visible = not _window.visible
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


func _open_settings() -> void:
	if _window == null:
		return
	var settings_scene := load("res://src/scenes/settings/settings_dialog.tscn")
	if settings_scene == null:
		OS.alert("设置面板加载失败。", "LetsMakeMoney")
		return
	var dlg: ConfirmationDialog = settings_scene.instantiate()
	_window.add_child(dlg)
	dlg.popup_centered()


func _open_wizard() -> void:
	if _window == null:
		return
	var wizard_scene := load("res://src/scenes/wizard/wizard_dialog.tscn")
	if wizard_scene == null:
		OS.alert("首次启动向导加载失败。", "LetsMakeMoney")
		return
	var dlg: ConfirmationDialog = wizard_scene.instantiate()
	_window.add_child(dlg)
	dlg.popup_centered()
	dlg.grab_focus()


func _show_about() -> void:
	OS.alert("LetsMakeMoney v0.1 Beta\n赚钱模拟器桌面宠物", "关于")


func _quit_app() -> void:
	Config.save()
	get_tree().quit()
