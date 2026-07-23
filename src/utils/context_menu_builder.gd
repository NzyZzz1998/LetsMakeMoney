class_name ContextMenuBuilder
extends RefCounted

const MENU_FONT_NAMES := ["Segoe UI Variable", "Microsoft YaHei UI", "Microsoft YaHei", "Segoe UI"]
const SURFACE_PAPER := Color(1.000, 0.992, 0.980, 0.995)
const TEXT_INK := Color(0.188, 0.169, 0.149, 1.0)
const TEXT_MUTED := Color(0.463, 0.412, 0.365, 1.0)
const ACCENT_COIN := Color(0.949, 0.706, 0.227, 1.0)
const ACCENT_ORANGE := Color(0.914, 0.471, 0.196, 1.0)
const ACCENT_MINT := Color(0.439, 0.608, 0.455, 1.0)
const BORDER_WARM := Color(0.271, 0.208, 0.153, 0.13)
const SHADOW_WARM := Color(0.188, 0.169, 0.149, 0.12)

var _popup_menu_theme: Theme = null


func build_context_menu(pets: Array, current_pet_id: String, window_mode: String, handler: Callable) -> PopupMenu:
	var popup := PopupMenu.new()
	popup.add_item("隐藏到托盘", 600)
	popup.add_separator()
	_build_main_menu(popup, pets, current_pet_id, window_mode, handler)
	return popup


func build_tray_menu(pets: Array, current_pet_id: String, window_mode: String, handler: Callable) -> PopupMenu:
	var popup := PopupMenu.new()
	popup.add_item("显示/隐藏", 600)
	popup.add_separator()
	_build_main_menu(popup, pets, current_pet_id, window_mode, handler)
	return popup


func _build_main_menu(menu: PopupMenu, pets: Array, current_pet_id: String, window_mode: String, handler: Callable) -> void:
	_apply_menu_readability(menu)
	menu.add_item("今日详情", 102)
	menu.add_item("设置", 100)
	menu.add_item("重新运行向导", 101)
	menu.add_separator()

	var window_submenu := _build_window_mode_submenu(window_mode, handler)
	menu.add_child(window_submenu)
	menu.add_submenu_item("窗口模式", window_submenu.name)
	var pet_submenu := _build_pet_submenu(pets, current_pet_id, handler)
	menu.add_child(pet_submenu)
	menu.add_submenu_item("选择宠物", pet_submenu.name)

	menu.add_separator()
	menu.add_item("关于 LetsMakeMoney", 400)
	menu.add_separator()
	menu.add_item("退出", 500)
	menu.id_pressed.connect(handler)


func _build_window_mode_submenu(window_mode: String, handler: Callable) -> PopupMenu:
	var submenu := PopupMenu.new()
	submenu.name = "WindowModeSubmenu"
	_apply_menu_readability(submenu)
	submenu.add_check_item("置顶悬浮", 300)
	submenu.set_item_checked(submenu.item_count - 1, window_mode == "top")
	submenu.add_check_item("融入桌面", 301)
	submenu.set_item_checked(submenu.item_count - 1, window_mode == "embed")
	submenu.id_pressed.connect(handler)
	return submenu


func _build_pet_submenu(pets: Array, current_pet_id: String, handler: Callable) -> PopupMenu:
	var submenu := PopupMenu.new()
	submenu.name = "PetSubmenu"
	_apply_menu_readability(submenu)
	if pets.is_empty():
		submenu.add_item("暂无可用宠物", 299)
		submenu.set_item_disabled(submenu.item_count - 1, true)
	else:
		for i in range(pets.size()):
			submenu.add_check_item(pets[i].display_name, 200 + i)
			if pets[i].pet_id == current_pet_id:
				submenu.set_item_checked(submenu.item_count - 1, true)
	submenu.id_pressed.connect(handler)
	return submenu


func _apply_menu_readability(menu: PopupMenu) -> void:
	menu.theme = _get_popup_menu_theme()
	menu.transparent_bg = true
	menu.borderless = true
	menu.min_size = Vector2i(232, 0)
	menu.add_theme_font_size_override("font_size", 14)
	menu.add_theme_constant_override("item_min_height", 34)
	menu.add_theme_constant_override("item_start_padding", 14)
	menu.add_theme_constant_override("item_end_padding", 14)
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
	panel_style.set_corner_radius_all(10)
	panel_style.content_margin_left = 8
	panel_style.content_margin_top = 8
	panel_style.content_margin_right = 8
	panel_style.content_margin_bottom = 8
	panel_style.shadow_color = SHADOW_WARM
	panel_style.shadow_size = 7
	panel_style.shadow_offset = Vector2(0, 3)

	var hover_style := StyleBoxFlat.new()
	hover_style.bg_color = Color(0.945, 0.957, 0.937, 1.0)
	hover_style.border_color = Color(ACCENT_MINT.r, ACCENT_MINT.g, ACCENT_MINT.b, 0.16)
	hover_style.set_border_width_all(1)
	hover_style.set_corner_radius_all(8)
	hover_style.content_margin_left = 7
	hover_style.content_margin_top = 2
	hover_style.content_margin_right = 7
	hover_style.content_margin_bottom = 2

	var separator_style := StyleBoxFlat.new()
	separator_style.bg_color = BORDER_WARM
	separator_style.content_margin_top = 1
	separator_style.content_margin_bottom = 1

	var theme := Theme.new()
	theme.default_font = font
	theme.default_font_size = 14
	theme.set_font("font", "PopupMenu", font)
	theme.set_font_size("font_size", "PopupMenu", 14)
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
	theme.set_constant("item_start_padding", "PopupMenu", 14)
	theme.set_constant("item_end_padding", "PopupMenu", 14)
	theme.set_constant("h_separation", "PopupMenu", 8)
	theme.set_constant("v_separation", "PopupMenu", 2)
	theme.set_constant("indent", "PopupMenu", 8)
	_popup_menu_theme = theme
	return _popup_menu_theme
