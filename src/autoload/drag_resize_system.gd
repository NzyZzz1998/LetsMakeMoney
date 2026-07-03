extends Node

signal modal_opened
signal modal_closed
signal popup_opened
signal popup_closed

const MODAL_WINDOW_SIZE := Vector2i(700, 560)
const MODAL_WINDOW_MARGIN := 24
const SETTINGS_DIALOG_SIZE := Vector2i(700, 560)

var _window: Window = null
var _active_modal: Node = null
var _active_popups: Array[PopupMenu] = []
var _config_connected: bool = false
var _window_visible: bool = true


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
	var pets := PetManager.get_available_pets()
	var current_id := String(Config.get_value("pet_id", "cat"))
	for i in range(pets.size()):
		menu.add_check_item("角色：%s" % pets[i].display_name, 200 + i)
		if pets[i].pet_id == current_id:
			menu.set_item_checked(menu.item_count - 1, true)

	menu.add_separator()
	var window_mode := String(Config.get_value("window_mode", "top"))
	menu.add_check_item("窗口模式：置顶悬浮", 300)
	menu.set_item_checked(menu.item_count - 1, window_mode == "top")
	menu.add_check_item("窗口模式：融入桌面", 301)
	menu.set_item_checked(menu.item_count - 1, window_mode == "embed")

	menu.add_separator()
	menu.add_item("关于 LetsMakeMoney", 400)
	menu.add_separator()
	menu.add_item("退出", 500)

	menu.id_pressed.connect(_on_menu_id)


func _apply_menu_readability(menu: PopupMenu) -> void:
	menu.add_theme_font_size_override("font_size", 18)
	menu.add_theme_constant_override("v_separation", 8)


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
	prepare_modal_window()
	var wizard_scene := load("res://src/scenes/wizard/wizard_dialog.tscn")
	if wizard_scene == null:
		OS.alert("首次启动向导加载失败。", "LetsMakeMoney")
		return
	var dlg: ConfirmationDialog = wizard_scene.instantiate()
	_active_modal = dlg
	_window.add_child(dlg)
	dlg.tree_exited.connect(_on_modal_tree_exited)
	dlg.popup_centered(SETTINGS_DIALOG_SIZE)
	dlg.grab_focus()


func prepare_modal_window() -> void:
	if _window != null:
		_window.borderless = false
		_window.transparent_bg = false
		_window.unresizable = false
		var target_size := Vector2i(max(_window.size.x, MODAL_WINDOW_SIZE.x), max(_window.size.y, MODAL_WINDOW_SIZE.y))
		_window.min_size = MODAL_WINDOW_SIZE
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
	OS.alert("LetsMakeMoney v0.2 Beta\n赚钱模拟器桌面宠物", "关于")


func quit_app() -> void:
	save_position()
	Config.save()
	if _window != null:
		Platform.set_mouse_passthrough(_window, false, [])
	Platform.shutdown_tray()
	get_tree().quit()
