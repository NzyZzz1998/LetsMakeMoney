extends SceneTree

var _failures: Array[String] = []
var _config: Node = null
var _platform: Node = null


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	await process_frame
	_config = root.get_node_or_null("/root/Config")
	_platform = root.get_node_or_null("/root/Platform")
	if _config == null or _platform == null:
		push_error("Config or Platform autoload not found")
		quit(1)
		return

	_check_native_scaffold_files()
	_check_config_defaults_and_migration()
	_check_platform_native_api()
	_check_native_health_model()
	_check_main_native_gates()
	_check_native_tray_bridge_model()
	_check_native_window_bridge_model()
	_check_native_passthrough_model()
	_check_pure_pet_mode_gate()
	_check_settings_v03_controls()

	if _failures.is_empty():
		print("v0.3 verification passed")
		quit(0)
	else:
		for failure in _failures:
			push_error(failure)
		quit(1)


func _check_native_scaffold_files() -> void:
	for path in [
		"res://native/windows/README.md",
		"res://native/windows/SConstruct",
		"res://native/windows/letsmakemoney_native.gdextension",
		"res://native/windows/src/register_types.h",
		"res://native/windows/src/register_types.cpp",
		"res://native/windows/src/lmm_native_bridge.h",
		"res://native/windows/src/lmm_native_bridge.cpp",
		"res://native/windows/src/tray_controller.h",
		"res://native/windows/src/tray_controller.cpp",
		"res://native/windows/src/window_controller.h",
		"res://native/windows/src/window_controller.cpp"
	]:
		_assert(FileAccess.file_exists(path), "missing native scaffold file: %s" % path)

	var gdextension := FileAccess.get_file_as_string("res://native/windows/letsmakemoney_native.gdextension")
	_assert(gdextension.contains("letsmakemoney_library_init"), "gdextension should declare entry symbol")
	_assert(gdextension.contains("letsmakemoney_native.dll"), "gdextension should reference Windows x86_64 dll")

	var bridge_header := FileAccess.get_file_as_string("res://native/windows/src/lmm_native_bridge.h")
	for method_name in [
		"get_health",
		"setup_tray",
		"poll_tray_command",
		"setup_pet_window",
		"set_window_visible",
		"set_mouse_passthrough",
		"set_taskbar_visible"
	]:
		_assert(bridge_header.contains(method_name), "native bridge header missing %s" % method_name)


func _check_config_defaults_and_migration() -> void:
	_assert(_config.has_method("merge_with_defaults"), "Config.merge_with_defaults missing")
	if not _config.has_method("merge_with_defaults"):
		return

	var merged: Dictionary = _config.call("merge_with_defaults", {})
	_assert(merged.get("config_version") == 3, "config_version default should be 3")
	_assert(merged.get("native_integration_enabled") == true, "native integration default should be true")
	_assert(merged.get("system_tray_enabled") == true, "system tray default should be true in v0.3")
	_assert(merged.get("transparent_pet_window_enabled") == true, "transparent pet window default should be true in v0.3")
	_assert(merged.get("mouse_passthrough_enabled") == true, "mouse passthrough default should be true in v0.3")
	_assert(merged.get("pure_pet_mode") == false, "pure pet mode default should be false")
	_assert(["cat_orange_v1", "cat_orange_v2"].has(merged.get("pet_id")), "default pet should remain an orange cat asset")
	_assert(FileAccess.file_exists("res://assets/pets/cat_orange_v1/cat_orange_v1_resource.tres"), "v0.3 orange cat fallback resource should remain available")

	var old_config := {
		"monthly_salary": 18888,
		"window_mode": "embed",
		"scale": 1.25,
		"panel_items": {
			"earnings_today": false
		}
	}
	var migrated: Dictionary = _config.call("merge_with_defaults", old_config)
	_assert(migrated.get("monthly_salary") == 18888, "migration should preserve salary")
	_assert(migrated.get("window_mode") == "embed", "migration should preserve window mode")
	_assert(migrated.get("scale") == 1.25, "migration should preserve scale")
	_assert(migrated.get("native_integration_enabled") == true, "migration should add native integration")
	_assert(migrated.get("pure_pet_mode") == false, "migration should add pure pet mode false")
	_assert(migrated.get("panel_items", {}).get("earnings_today") == false, "migration should preserve nested panel item")
	_assert(migrated.get("panel_items", {}).has("earnings_month"), "migration should fill nested panel defaults")
	_check_reset_display_defaults_scope(migrated)


func _check_reset_display_defaults_scope(seed_config: Dictionary) -> void:
	var original_data: Dictionary = (_config.get("data") as Dictionary).duplicate(true)
	var test_data := seed_config.duplicate(true)
	test_data["monthly_salary"] = 23333
	test_data["rest_mode"] = "single"
	test_data["work_start_time"] = "10:00"
	test_data["work_end_time"] = "19:00"
	test_data["pet_id"] = "cat_orange_v1"
	test_data["panel_items"] = {"earnings_today": false}
	test_data["pure_pet_mode"] = true
	test_data["opacity"] = 0.42
	_config.set("data", test_data)
	_config.call("reset_display_defaults")
	var after: Dictionary = _config.get("data")
	_assert(after.get("monthly_salary") == 23333, "reset display defaults should preserve salary")
	_assert(after.get("rest_mode") == "single", "reset display defaults should preserve rest mode")
	_assert(after.get("work_start_time") == "10:00", "reset display defaults should preserve work start")
	_assert(after.get("work_end_time") == "19:00", "reset display defaults should preserve work end")
	_assert(after.get("pet_id") == "cat_orange_v1", "reset display defaults should preserve pet")
	_assert(after.get("panel_items", {}).get("earnings_today") == false, "reset display defaults should preserve panel items")
	_assert(after.get("pure_pet_mode") == false, "reset display defaults should reset pure pet mode")
	_assert(after.get("opacity") == 1.0, "reset display defaults should reset opacity")
	_config.set("data", original_data)


func _check_platform_native_api() -> void:
	for method_name in [
		"get_native_health",
		"get_native_window_handle",
		"setup_tray",
		"update_tray_menu",
		"shutdown_tray",
		"poll_tray_command",
		"set_taskbar_visible",
		"set_window_visible",
		"can_enable_pure_pet_mode"
	]:
		_assert(_platform.has_method(method_name), "Platform.%s missing" % method_name)

	var interface_script := FileAccess.get_file_as_string("res://src/platform/platform_interface.gd")
	_assert(interface_script.contains("func get_native_health"), "PlatformInterface should define get_native_health")
	_assert(interface_script.contains("func poll_tray_command"), "PlatformInterface should define poll_tray_command")
	_assert(interface_script.contains("func set_window_visible"), "PlatformInterface should define set_window_visible")
	_assert(interface_script.contains("func can_enable_pure_pet_mode"), "PlatformInterface should define pure pet mode gate")


func _check_native_health_model() -> void:
	if not _platform.has_method("get_native_health"):
		return
	var health: Dictionary = _platform.call("get_native_health")
	for key in [
		"native_loaded",
		"tray_supported",
		"window_supported",
		"passthrough_supported",
		"taskbar_supported",
		"last_error"
	]:
		_assert(health.has(key), "native health missing key: %s" % key)

	_assert(not bool(health.get("tray_supported", false)) or bool(health.get("native_loaded", false)), "tray support requires native loaded")
	_assert(not bool(health.get("taskbar_supported", false)) or bool(health.get("native_loaded", false)), "taskbar support requires native loaded")


func _check_main_native_gates() -> void:
	var script := FileAccess.get_file_as_string("res://src/scenes/main/main.gd")
	var project := FileAccess.get_file_as_string("res://project.godot")
	_assert(project.contains("window/size/transparent=true"), "project should enable transparent window size setting")
	_assert(project.contains("viewport/transparent_background=true"), "project should enable transparent viewport background")
	_assert(script.contains("native_integration_enabled"), "main should gate native features by native_integration_enabled")
	_assert(script.contains("get_native_health"), "main should read native health")
	_assert(script.contains("tray_supported"), "main should check native tray health")
	_assert(script.contains("passthrough_supported"), "main should check native passthrough health")
	_assert(script.contains("window_supported"), "main should check native window health")
	_assert(script.contains("_tray_ready = false"), "main should default tray readiness to false")

	var platform_script := FileAccess.get_file_as_string("res://src/autoload/platform.gd")
	_assert(not platform_script.contains("ClassDB.instantiate(\"StatusIndicator\")"), "Platform should not use Godot StatusIndicator in v0.3 native route")


func _check_native_tray_bridge_model() -> void:
	var tray_header := FileAccess.get_file_as_string("res://native/windows/src/tray_controller.h")
	var tray_cpp := FileAccess.get_file_as_string("res://native/windows/src/tray_controller.cpp")
	var bridge_header := FileAccess.get_file_as_string("res://native/windows/src/lmm_native_bridge.h")
	var bridge_cpp := FileAccess.get_file_as_string("res://native/windows/src/lmm_native_bridge.cpp")
	var platform_script := FileAccess.get_file_as_string("res://src/autoload/platform.gd")
	var windows_platform_script := FileAccess.get_file_as_string("res://src/platform/windows_platform.gd")

	for command_name in [
		"COMMAND_TOGGLE",
		"COMMAND_SETTINGS",
		"COMMAND_ABOUT",
		"COMMAND_EXIT"
	]:
		_assert(tray_header.contains(command_name), "TrayController missing %s" % command_name)

	_assert(tray_cpp.contains("Shell_NotifyIconW"), "TrayController should use Shell_NotifyIconW")
	_assert(not tray_cpp.contains("HWND_MESSAGE"), "TrayController should use a hidden overlapped window, not a message-only window, for Shell_NotifyIcon callbacks")
	_assert(tray_cpp.contains("GetLastError()"), "TrayController should include Windows error codes when tray registration fails")
	_assert(tray_cpp.contains("TrackPopupMenu"), "TrayController should show a native popup menu")
	_assert(tray_cpp.contains("WM_LBUTTONUP"), "TrayController should handle left click")
	_assert(tray_cpp.contains("WM_LBUTTONDOWN"), "TrayController should handle tray left-button down as a toggle fallback")
	_assert(tray_cpp.contains("NIN_SELECT"), "TrayController should handle shell select events")
	_assert(tray_cpp.contains("LOWORD(lparam)"), "TrayController should handle shell callback events packed into LOWORD(lparam)")
	_assert(tray_cpp.contains("HIWORD(lparam)"), "TrayController should handle Shell_NotifyIcon v4 icon ids packed into HIWORD(lparam)")
	_assert(tray_cpp.contains("WM_CONTEXTMENU"), "TrayController should handle context menu tray notifications")
	_assert(tray_header.contains("_last_toggle_tick"), "TrayController should debounce paired left-button tray events")
	_assert(not tray_cpp.contains("NIM_SETVERSION"), "TrayController should avoid NOTIFYICON_VERSION_4 until tray callbacks are stable")
	_assert(tray_cpp.contains("WM_RBUTTONUP"), "TrayController should handle right click")
	_assert(bridge_header.contains("poll_tray_command"), "LMMNativeBridge should expose poll_tray_command")
	_assert(bridge_cpp.contains("ClassDB::bind_method(D_METHOD(\"poll_tray_command\")"), "poll_tray_command should be bound to Godot")
	_assert(windows_platform_script.contains("func poll_tray_command"), "WindowsPlatform should forward tray commands")
	_assert(platform_script.contains("func _poll_native_tray"), "Platform should poll native tray commands")
	_assert(platform_script.contains("tray_toggle_requested.emit()"), "Platform should emit tray toggle signal")
	_assert(platform_script.contains("tray_settings_requested.emit()"), "Platform should emit tray settings signal")
	_assert(platform_script.contains("tray_about_requested.emit()"), "Platform should emit tray about signal")
	_assert(platform_script.contains("tray_exit_requested.emit()"), "Platform should emit tray exit signal")


func _check_native_window_bridge_model() -> void:
	var window_header := FileAccess.get_file_as_string("res://native/windows/src/window_controller.h")
	var window_cpp := FileAccess.get_file_as_string("res://native/windows/src/window_controller.cpp")
	var bridge_cpp := FileAccess.get_file_as_string("res://native/windows/src/lmm_native_bridge.cpp")
	var windows_platform_script := FileAccess.get_file_as_string("res://src/platform/windows_platform.gd")

	_assert(window_header.contains("setup_pet_window"), "WindowController should expose setup_pet_window")
	_assert(window_header.contains("set_window_visible"), "WindowController should expose set_window_visible")
	_assert(window_header.contains("set_taskbar_visible"), "WindowController should expose set_taskbar_visible")
	_assert(window_cpp.contains("SetWindowLongPtrW"), "WindowController should set Win32 window styles")
	_assert(window_cpp.contains("ShowWindow"), "WindowController should use native ShowWindow for tray hide/show")
	_assert(not window_cpp.contains("SetLayeredWindowAttributes"), "WindowController should not override Godot per-pixel transparency with constant alpha")
	_assert(window_cpp.contains("SWP_FRAMECHANGED"), "WindowController should refresh the native frame")
	_assert(bridge_cpp.contains("window_supported"), "native health should include window_supported")
	_assert(bridge_cpp.contains("setup_pet_window(p_hwnd"), "LMMNativeBridge should forward setup_pet_window")
	_assert(bridge_cpp.contains("set_window_visible(p_hwnd"), "LMMNativeBridge should forward set_window_visible")
	_assert(windows_platform_script.contains("window_get_native_handle"), "WindowsPlatform should request native window handle")
	_assert(windows_platform_script.contains("DisplayServer.WINDOW_HANDLE"), "WindowsPlatform should request WINDOW_HANDLE, not DISPLAY_HANDLE")
	_assert(windows_platform_script.contains("setup_pet_window"), "WindowsPlatform should call native setup_pet_window")
	_assert(windows_platform_script.contains("func set_window_visible"), "WindowsPlatform should expose native window visibility")
	_assert(windows_platform_script.contains("WINDOW_FLAG_TRANSPARENT"), "WindowsPlatform should explicitly set the transparent window flag")
	_assert(windows_platform_script.find("window.min_size = PET_WINDOW_SIZE") < windows_platform_script.find("window.size = PET_WINDOW_SIZE"), "WindowsPlatform should lower pet min_size before restoring pet window size")
	_assert(not windows_platform_script.contains("mouse_passthrough_polygon"), "WindowsPlatform should not use Godot polygon passthrough because it clips visible Panel content")


func _check_native_passthrough_model() -> void:
	var window_header := FileAccess.get_file_as_string("res://native/windows/src/window_controller.h")
	var window_cpp := FileAccess.get_file_as_string("res://native/windows/src/window_controller.cpp")
	var bridge_cpp := FileAccess.get_file_as_string("res://native/windows/src/lmm_native_bridge.cpp")
	var main_script := FileAccess.get_file_as_string("res://src/scenes/main/main.gd")

	_assert(window_header.contains("NativeRect"), "WindowController should define native interactive rects")
	_assert(window_header.contains("set_mouse_passthrough"), "WindowController should expose set_mouse_passthrough")
	_assert(window_header.contains("clear_mouse_passthrough"), "WindowController should expose clear_mouse_passthrough")
	_assert(not window_cpp.contains("SetWindowRgn"), "WindowController should not use SetWindowRgn because it clips visible Panel content")
	_assert(window_cpp.contains("WM_NCHITTEST"), "WindowController should use hit testing for blank area passthrough")
	_assert(window_cpp.contains("HTTRANSPARENT"), "WindowController should return HTTRANSPARENT outside interactive regions")
	_assert(window_cpp.contains("constexpr int HIT_TEST_PADDING = 2"), "Native hit test padding should stay small so nearby transparent areas pass through")
	_assert(window_cpp.contains("GetAsyncKeyState(VK_RBUTTON)"), "Native hit test should allow a larger pet context area only while right-clicking")
	_assert(window_cpp.contains("is_point_in_pet_context_rect"), "Native hit test should keep right-click context hit testing separate from normal passthrough")
	_assert(window_cpp.contains("WindowController::~WindowController"), "WindowController should restore passthrough subclass during native teardown")
	_assert(window_cpp.contains("SetWindowLongPtrW"), "WindowController should subclass the window procedure for hit testing")
	_assert(bridge_cpp.contains("to_native_rects"), "LMMNativeBridge should convert Godot Rect2 values")
	_assert(bridge_cpp.contains("passthrough_supported"), "native health should include passthrough_supported")
	_assert(main_script.contains("get_interactive_rects"), "Main should expose interactive rect calculation")
	_assert(main_script.contains("_last_passthrough_rects_hash"), "Main should avoid repeated passthrough native calls")
	_assert(main_script.contains("get_viewport().transparent_bg = enabled"), "Main should enable viewport transparency for transparent pet windows")
	_assert(main_script.contains("RenderingServer.set_default_clear_color(Color(0, 0, 0, 0)"), "Main should clear transparent windows with alpha 0")
	_assert(main_script.contains("_on_panel_layout_changed"), "Main should refresh native passthrough when the panel expands or collapses")
	var panel_script := FileAccess.get_file_as_string("res://src/scenes/panel/panel.gd")
	_assert(panel_script.contains("signal layout_changed"), "Panel should emit layout_changed after size changes")
	_assert(panel_script.contains("layout_changed.emit()"), "Panel should notify Main after background size updates")


func _check_pure_pet_mode_gate() -> void:
	var main_script := FileAccess.get_file_as_string("res://src/scenes/main/main.gd")
	var platform_script := FileAccess.get_file_as_string("res://src/autoload/platform.gd")
	var windows_platform_script := FileAccess.get_file_as_string("res://src/platform/windows_platform.gd")

	_assert(main_script.contains("func can_hide_to_tray"), "Main should expose can_hide_to_tray")
	_assert(main_script.contains("auto_accept_quit = false"), "Main should disable automatic quit so close can hide to tray")
	_assert(main_script.contains("NOTIFICATION_WM_CLOSE_REQUEST"), "Main should handle OS close requests")
	_assert(main_script.contains("can_hide_to_tray()"), "close request should use can_hide_to_tray")
	_assert(main_script.contains("DragResizeSystem.save_position()"), "Main should save window position before hiding to tray")
	_assert(main_script.contains("func _apply_pure_pet_mode"), "Main should apply pure pet mode")
	_assert(main_script.contains("Config.set_value(\"pure_pet_mode\", false)"), "pure pet mode should auto-disable on failure")
	_assert(main_script.contains("_set_taskbar_visible(true)"), "Main should restore taskbar visibility on fallback")
	_assert(platform_script.contains("func can_enable_pure_pet_mode"), "Platform should expose pure pet mode availability")
	_assert(platform_script.contains("func set_taskbar_visible"), "Platform should expose taskbar visibility")
	_assert(windows_platform_script.contains("taskbar_supported"), "WindowsPlatform should gate taskbar visibility by native health")


func _check_settings_v03_controls() -> void:
	var settings_script := FileAccess.get_file_as_string("res://src/scenes/settings/settings_dialog.gd")
	var settings_scene := FileAccess.get_file_as_string("res://src/scenes/settings/settings_dialog.tscn")
	_assert(settings_script.contains("extends Control"), "Settings should be a single-window content view, not a nested ConfirmationDialog")
	_assert(not settings_script.contains("extends ConfirmationDialog"), "Settings should not create a dialog inside the host window")
	_assert(settings_scene.contains("type=\"Control\""), "Settings scene root should fill the host settings window")
	_assert(settings_script.contains("rest_mode_option = OptionButton.new()"), "Settings should keep rest mode as a dropdown")
	_assert(settings_script.contains("rest_mode_option.add_item(\"双休\", 0)"), "Rest mode dropdown should include double rest")
	_assert(settings_script.contains("rest_mode_option.add_item(\"单休\", 1)"), "Rest mode dropdown should include single rest")
	_assert(not settings_script.contains("rest_mode_option.visible = false"), "Rest mode dropdown should be visible and clickable")
	_assert(settings_script.contains("window_mode_option = OptionButton.new()"), "Settings should keep window mode as a dropdown")
	_assert(settings_script.contains("window_mode_option.add_item(\"置顶悬浮\", 0)"), "Window mode dropdown should include top mode")
	_assert(settings_script.contains("window_mode_option.add_item(\"融入桌面（实验）\", 1)"), "Window mode dropdown should include desktop embed mode")
	_assert(not settings_script.contains("window_mode_option.visible = false"), "Window mode dropdown should be visible and clickable")
	_assert(settings_script.contains("pure_pet_mode_toggle"), "Settings should expose pure pet mode")
	_assert(settings_script.contains("native_status_label"), "Settings should show native capability status")
	_assert(settings_script.contains("_update_native_status_label"), "Settings should refresh native status text")
	_assert(settings_script.contains("Platform.can_enable_pure_pet_mode"), "Settings should disable pure pet mode when native gate fails")
	_assert(settings_script.contains("DragResizeSystem.get_registered_window()"), "Settings should evaluate pure pet capability against the host pet window")
	_assert(settings_script.contains("SettingsRoot"), "Settings should use an anchored root layout so controls stay clickable")
	_assert(settings_script.contains("TopActionRow") or settings_script.contains("WinSettingsHeader"), "Settings should keep a top action row visible across sections")
	_assert(settings_script.contains("SaveButton"), "Settings should provide an explicit in-window save button")
	_assert(settings_script.contains("CancelButton"), "Settings should provide an explicit in-window cancel button")
	if settings_script.contains("ActionRow"):
		_assert(settings_script.contains("CloseButton"), "v0.4 settings should move close to the header when bottom actions are visible")
		_assert(settings_script.contains("ScrollContainer.new()"), "v0.4 settings should scroll long pages inside the content area")
	var drag_script := FileAccess.get_file_as_string("res://src/autoload/drag_resize_system.gd")
	var menu_script := FileAccess.get_file_as_string("res://src/utils/context_menu_builder.gd")
	var main_script := FileAccess.get_file_as_string("res://src/scenes/main/main.gd")
	_assert(drag_script.contains("signal modal_closed"), "DragResizeSystem should notify Main after settings popups close")
	_assert(drag_script.contains("signal modal_opened"), "DragResizeSystem should notify Main before modal settings are shown")
	_assert(drag_script.contains("signal popup_opened"), "DragResizeSystem should notify Main when context menus disable passthrough")
	_assert(drag_script.contains("signal popup_closed"), "DragResizeSystem should notify Main when context menus can restore passthrough")
	_assert(main_script.contains("DragResizeSystem.popup_opened.connect(_on_popup_opened)"), "Main should suspend passthrough while context menus are open")
	_assert(main_script.contains("DragResizeSystem.popup_closed.connect(_on_popup_closed)"), "Main should restore passthrough after context menus close")
	_assert(drag_script.contains("func get_registered_window"), "DragResizeSystem should expose the registered host window for settings capability checks")
	_assert(drag_script.contains("Platform.set_window_visible(_window, visible)"), "DragResizeSystem should use native window visibility for tray hide/show")
	_assert(menu_script.contains("popup.add_item(\"隐藏到托盘\", 600)"), "Context menu should expose a manual hide-to-tray entry")
	_assert(drag_script.contains("MODAL_WINDOW_SIZE"), "DragResizeSystem should expand the host window before modal settings")
	_assert(drag_script.contains("SETTINGS_DIALOG_SIZE"), "DragResizeSystem should keep settings dialogs large enough for action buttons")
	_assert(drag_script.contains("settings_view.set_anchors_preset(Control.PRESET_FULL_RECT)"), "Settings content should fill the host settings window")
	_assert(drag_script.contains("func close_active_modal"), "DragResizeSystem should allow the host close button to close settings content")
	_assert(drag_script.contains("func prepare_modal_window"), "DragResizeSystem should expose a shared modal-window preparation helper")
	_assert(drag_script.contains("_fit_modal_window_on_screen"), "DragResizeSystem should keep modal windows on screen")
	_assert(drag_script.contains("_window.size = target_size"), "DragResizeSystem should resize the host window so settings buttons are visible")
	_assert(
		drag_script.contains("_window.borderless = false") or drag_script.contains("_window.borderless = true"),
		"DragResizeSystem should explicitly set modal host border mode while settings are open"
	)
	_assert(drag_script.contains("Platform.set_mouse_passthrough(_window, false, [])"), "DragResizeSystem should clear passthrough before modal settings")
	_assert(drag_script.contains("Platform.set_mouse_passthrough(_window, false, [])\n\tPlatform.shutdown_tray()"), "DragResizeSystem should clear passthrough before native shutdown")
	_assert(main_script.contains("DragResizeSystem.prepare_modal_window()"), "First-run wizard should use the same modal preparation path")
	_assert(main_script.contains("DragResizeSystem.modal_opened.connect(_on_modal_opened)"), "Main should enter modal mode when settings open")
	_assert(main_script.contains("func _on_modal_opened"), "Main should handle modal-open state")
	_assert(main_script.contains("DragResizeSystem.close_active_modal()"), "Main should close settings content when the host settings window close button is pressed")
	_assert(main_script.contains("_apply_viewport_transparency(true)"), "Main should keep the modal host transparent so rounded settings corners do not show black")
	_assert(main_script.contains("_set_primary_content_visible(false)"), "Main should hide pet and panel behind modal settings")
	_assert(main_script.contains("if _runtime_state.modal_open:"), "Main should keep passthrough disabled while modal settings are open")
	_assert(main_script.contains("PET_HIT_PADDING"), "Main native passthrough pet hit rect should be derived from the visible sprite with padding")
	_assert(main_script.contains("PET_CONTEXT_PADDING"), "Main should keep a larger pet context rect for right-click menu reliability")
	_assert(main_script.contains("get_pet_context_rect"), "Main should expose a right-click context rect without enlarging normal left-click passthrough")
	_assert(main_script.contains("context menu via pet context rect"), "Main should log right-click context menu fallback events")
	_assert(main_script.contains("_pet_sprite_bounds_at_position(s, pet.position)"), "Main should center passthrough hit rect on the scaled visible pet")
	var pet_script := FileAccess.get_file_as_string("res://src/scenes/pet/pet.gd")
	var pet_scene := FileAccess.get_file_as_string("res://src/scenes/pet/pet.tscn")
	_assert(pet_script.contains("func get_interaction_rect"), "Pet input hit rect should be exposed for sprite-derived hit testing")
	_assert(pet_script.contains("_sync_hit_geometry"), "Pet should sync the Area2D collision shape to the visible sprite")
	_assert(pet_script.contains("_schedule_return_after_hold"), "Pet long-press feedback should remain visible briefly after release")
	_assert(pet_script.contains("_return_token"), "Pet delayed return timers should be guarded by a token")
	_assert(pet_script.contains("_cancel_pending_return()"), "Pet should cancel stale return timers when a new press or drag starts")
	_assert(pet_script.contains("token != _return_token or _mouse_pressed or _dragging"), "Pet delayed returns should not override an active press or drag")
	_assert(pet_script.contains("_long_press_triggered = false"), "Pet should clear long-press semantics when drag takes priority")
	_assert(not pet_script.contains("PetManager.current_interaction != PetManager.PetInteraction.CLICKED_HOLD"), "Pet should not restore clicked_hold while dragging in the current interaction model")
	_assert(pet_scene.contains("size = Vector2(234, 230)"), "Pet collision shape should cover the v2 visible sprite footprint")
	_assert(settings_script.contains("rest_mode_option.selected == 1"), "Rest mode save should read the dropdown selection")
	_assert(settings_script.contains("window_mode_option.selected == 1"), "Window mode save should read the dropdown selection")


func _assert(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
