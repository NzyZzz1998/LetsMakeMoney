extends Node

const AppVersionScript := preload("res://src/utils/app_version.gd")
const OverlayLifecycleScript := preload("res://src/utils/overlay_lifecycle.gd")
const ContextMenuBuilderScript := preload("res://src/utils/context_menu_builder.gd")
const TODAY_DETAIL_SCENE := preload("res://src/scenes/today/today_detail_window.tscn")

signal modal_opened
signal modal_closed
signal popup_opened
signal popup_closed

const MODAL_WINDOW_SIZE := Vector2i(700, 520)
const MODAL_WINDOW_MARGIN := 24
const SETTINGS_DIALOG_SIZE := Vector2i(700, 520)
const WIZARD_DIALOG_SIZE := Vector2i(720, 520)

var _window: Window = null
var _overlay_lifecycle: RefCounted = OverlayLifecycleScript.new()
var _config_connected: bool = false
var _window_visible: bool = true
var _about_dialog: AcceptDialog = null
var _context_menu_builder: RefCounted = ContextMenuBuilderScript.new()
var _today_detail_window: Window = null


func _ready() -> void:
	_overlay_lifecycle.modal_opened.connect(_forward_modal_opened)
	_overlay_lifecycle.modal_closed.connect(_forward_modal_closed)
	_overlay_lifecycle.popup_opened.connect(_forward_popup_opened)
	_overlay_lifecycle.popup_closed.connect(_forward_popup_closed)


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


func is_overlay_active() -> bool:
	return _overlay_lifecycle.has_modal() or _overlay_lifecycle.has_popups()


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
	var popup: PopupMenu = _context_menu_builder.build_context_menu(
		PetManager.get_available_pets(),
		String(Config.get_value("pet_id", "cat_orange_v2")),
		String(Config.get_value("window_mode", "top")),
		_on_menu_id
	)
	_popup_at_mouse(popup)


func show_tray_menu() -> void:
	var popup: PopupMenu = _context_menu_builder.build_tray_menu(
		PetManager.get_available_pets(),
		String(Config.get_value("pet_id", "cat_orange_v2")),
		String(Config.get_value("window_mode", "top")),
		_on_menu_id
	)
	_popup_at_mouse(popup)


func _popup_at_mouse(popup: PopupMenu) -> void:
	if _window == null:
		popup.queue_free()
		return
	Platform.set_mouse_passthrough(_window, false, [])
	_window.add_child(popup)
	_overlay_lifecycle.register_popup(popup)
	popup.position = DisplayServer.mouse_get_position() - _window.position
	popup.popup()
	popup.popup_hide.connect(_on_popup_hide.bind(popup))


func _on_popup_hide(popup: PopupMenu) -> void:
	_cleanup_popup(popup)


func _cleanup_popup(popup: PopupMenu) -> void:
	_overlay_lifecycle.unregister_popup(popup)
	if popup != null and is_instance_valid(popup):
		popup.queue_free()


func _on_menu_id(id: int) -> void:
	match id:
		102:
			show_today_detail()
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


func show_today_detail() -> void:
	if _today_detail_window != null and is_instance_valid(_today_detail_window):
		_today_detail_window.popup(Rect2i(_today_detail_window.position, _today_detail_window.size))
		_today_detail_window.grab_focus()
		return
	var root_window := get_tree().root
	var embed_subwindows := root_window.gui_embed_subwindows
	root_window.gui_embed_subwindows = false
	_today_detail_window = TODAY_DETAIL_SCENE.instantiate()
	root_window.add_child(_today_detail_window)
	root_window.gui_embed_subwindows = embed_subwindows
	_today_detail_window.tree_exited.connect(func() -> void: _today_detail_window = null)
	_today_detail_window.popup(Rect2i(_today_detail_window.position, _today_detail_window.size))
	_today_detail_window.grab_focus()
	Platform.write_info_log("today_detail_window_ready: embedded=%s window_id=%d position=%s size=%s" % [
		str(_today_detail_window.is_embedded()),
		_today_detail_window.get_window_id(),
		str(_today_detail_window.position),
		str(_today_detail_window.size),
	])


func _switch_pet_by_menu_id(id: int) -> void:
	var idx := id - 200
	var pets := PetManager.get_available_pets()
	if idx >= 0 and idx < pets.size():
		PetManager.switch_pet(pets[idx].pet_id)
		Config.save()


func _close_all_popups() -> void:
	_overlay_lifecycle.close_all_popups()


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
	_window.add_child(settings_view)
	settings_view.set_anchors_preset(Control.PRESET_FULL_RECT)
	settings_view.offset_left = 0
	settings_view.offset_top = 0
	settings_view.offset_right = 0
	settings_view.offset_bottom = 0
	settings_view.tree_exited.connect(_on_modal_tree_exited.bind(settings_view))
	_overlay_lifecycle.register_modal(settings_view)
	settings_view.grab_focus()


func close_active_modal() -> void:
	_overlay_lifecycle.close_active_modal()


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
	_window.add_child(wizard_view)
	wizard_view.set_anchors_preset(Control.PRESET_FULL_RECT)
	wizard_view.offset_left = 0
	wizard_view.offset_top = 0
	wizard_view.offset_right = 0
	wizard_view.offset_bottom = 0
	wizard_view.tree_exited.connect(_on_modal_tree_exited.bind(wizard_view))
	_overlay_lifecycle.register_modal(wizard_view)
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


func _fit_modal_window_on_screen(size: Vector2i) -> void:
	if _window == null:
		return
	var screen := Platform.get_screen_size()
	var max_x: int = int(max(MODAL_WINDOW_MARGIN, screen.x - size.x - MODAL_WINDOW_MARGIN))
	var max_y: int = int(max(MODAL_WINDOW_MARGIN, screen.y - size.y - MODAL_WINDOW_MARGIN))
	var x: int = int(clamp(_window.position.x, MODAL_WINDOW_MARGIN, max_x))
	var y: int = int(clamp(_window.position.y, MODAL_WINDOW_MARGIN, max_y))
	_window.position = Vector2i(x, y)


func _on_modal_tree_exited(modal: Node) -> void:
	_overlay_lifecycle.unregister_modal(modal)


func _forward_modal_opened() -> void:
	modal_opened.emit()


func _forward_modal_closed() -> void:
	modal_closed.emit()


func _forward_popup_opened() -> void:
	popup_opened.emit()


func _forward_popup_closed() -> void:
	popup_closed.emit()


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
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
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
