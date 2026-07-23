extends SceneTree

const OverlayLifecycleScript := preload("res://src/utils/overlay_lifecycle.gd")
const TodayWindowPlacementScript := preload("res://src/utils/today_window_placement.gd")
const PetPanelLayoutScript := preload("res://src/utils/pet_panel_layout.gd")

var _failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_test_overlay_reference_count()
	_test_today_window_placement()
	_test_pet_panel_layout()
	await _test_panel_scale_contract()
	_test_r2_surface_contract()
	if _failures.is_empty():
		print("V09 window experience verification passed")
		quit(0)
		return
	for failure in _failures:
		push_error(failure)
	quit(1)


func _test_panel_scale_contract() -> void:
	var packed_scene := load("res://src/scenes/panel/panel.tscn") as PackedScene
	_expect(packed_scene != null, "Panel scene must load for scale verification")
	if packed_scene == null:
		return
	var panel = packed_scene.instantiate()
	root.add_child(panel)
	await process_frame
	for display_scale in [0.5, 0.58, 1.0, 1.5]:
		panel.collapse()
		panel.set_display_scale(display_scale)
		await process_frame
		await process_frame
		var collapsed_content: Control = panel.get_node("Collapsed/CollapsedContent")
		var collapsed_progress: Control = panel.get_node("Collapsed/CollapsedContent/CollapsedProgress")
		var expected_collapsed_width := roundf(268.0 * display_scale)
		_expect(is_equal_approx(collapsed_progress.custom_minimum_size.x, expected_collapsed_width), "collapsed progress width must scale at %.0f%%" % (display_scale * 100.0))
		_expect(collapsed_progress.size.x <= collapsed_content.size.x + 1.0, "collapsed progress must stay inside the shell at %.0f%%" % (display_scale * 100.0))
		panel.expand()
		await process_frame
		await process_frame
		var expanded: Control = panel.get_node("Expanded")
		for node_path in ["Expanded/TodayRow", "Expanded/MetricsRow", "Expanded/ProgressRow", "Expanded/Separator", "Expanded/ScheduleRow"]:
			var row: Control = panel.get_node(node_path)
			_expect(row.custom_minimum_size.x <= expanded.size.x + 1.0, "%s must stay inside the expanded shell at %.0f%%" % [node_path, display_scale * 100.0])
	panel.queue_free()
	await process_frame


func _test_overlay_reference_count() -> void:
	var lifecycle = OverlayLifecycleScript.new()
	var opened := [0]
	var closed := [0]
	lifecycle.modal_opened.connect(func() -> void: opened[0] += 1)
	lifecycle.modal_closed.connect(func() -> void: closed[0] += 1)
	var first := Node.new()
	var second := Node.new()
	lifecycle.register_modal(first)
	lifecycle.register_modal(second)
	_expect(lifecycle.has_modal(), "two registered modals should be active")
	_expect(opened[0] == 1, "modal_opened should emit once for the first modal")
	lifecycle.unregister_modal(first)
	_expect(lifecycle.has_modal(), "closing one modal must not clear the remaining modal")
	_expect(closed[0] == 0, "modal_closed must wait for the last modal")
	lifecycle.unregister_modal(second)
	_expect(not lifecycle.has_modal(), "last modal should clear the modal state")
	_expect(closed[0] == 1, "modal_closed should emit once for the last modal")
	first.free()
	second.free()


func _test_today_window_placement() -> void:
	var screen := Rect2i(0, 0, 1920, 1080)
	_expect(TodayWindowPlacementScript.sanitize(Vector2i(-500, 4000), Vector2i(420, 560), screen) == Vector2i(1476, 496), "off-screen window should return to bottom-right safe area")
	_expect(TodayWindowPlacementScript.sanitize(Vector2i(100, 120), Vector2i(420, 560), screen) == Vector2i(100, 120), "valid position should be preserved")
	_expect(TodayWindowPlacementScript.sanitize_size(Vector2i(5000, 5000), screen) == Vector2i(1872, 1032), "oversized detail window should fit the screen")


func _test_pet_panel_layout() -> void:
	var screen := Rect2i(0, 0, 1920, 1080)
	var left: Dictionary = PetPanelLayoutScript.resolve(Vector2i(20, 300), Vector2i(620, 380), screen)
	var right: Dictionary = PetPanelLayoutScript.resolve(Vector2i(1280, 300), Vector2i(620, 380), screen)
	_expect(not bool(left.pet_on_right), "left-side window should keep the pet on the left")
	_expect(bool(right.pet_on_right), "right-side window should flip the pet to the right")
	_expect(Vector2(right.panel_position).x < Vector2(right.pet_position).x, "right-side pet should keep the panel on its left")
	_expect(PetPanelLayoutScript.amount_font_size("¥0.00") == 38, "short amounts should retain the hero size")
	_expect(PetPanelLayoutScript.amount_font_size("¥123456789.00") < 38, "long amounts should shrink instead of clipping")


func _test_r2_surface_contract() -> void:
	var panel_scene := FileAccess.get_file_as_string("res://src/scenes/panel/panel.tscn")
	var panel_script := FileAccess.get_file_as_string("res://src/scenes/panel/panel.gd")
	var settings_script := FileAccess.get_file_as_string("res://src/scenes/settings/settings_dialog.gd")
	var wizard_script := FileAccess.get_file_as_string("res://src/scenes/wizard/wizard_dialog.gd")
	var today_scene := FileAccess.get_file_as_string("res://src/scenes/today/today_detail_window.tscn")
	var menu_script := FileAccess.get_file_as_string("res://src/utils/context_menu_builder.gd")
	_expect(panel_script.contains("COLLAPSED_BASE_SIZE := Vector2(300, 124)"), "collapsed Panel should use the readable R2 footprint")
	_expect(panel_script.contains("EXPANDED_BASE_SIZE := Vector2(344, 232)"), "expanded Panel should use the readable R2 footprint")
	_expect(not panel_scene.contains('text = "LMM"'), "Panel should start with today's earnings instead of a product header")
	_expect(panel_scene.contains('name="ProgressHeader"'), "expanded Panel should keep progress metadata on one compact row")
	_expect(panel_scene.contains('name="CollapsedFooter"'), "collapsed Panel should separate progress metadata from the amount")
	_expect(panel_script.contains("func _fit_dynamic_text"), "Panel should shrink long dynamic values before they clip")
	_expect(settings_script.contains("custom_minimum_size = Vector2(700, 520)"), "Settings should use one 700x520 shell")
	_expect(wizard_script.contains("WIZARD_SIZE := Vector2(720, 520)"), "Wizard should use one 720x520 shell")
	_expect(today_scene.contains("size = Vector2i(480, 600)"), "Today detail should use the 480x600 R1 baseline")
	_expect(menu_script.contains("menu.min_size = Vector2i(232, 0)"), "context menus should use the compact R1 width")
	_expect(menu_script.contains("panel_style.set_corner_radius_all(10)"), "context menus should use the R1 corner radius")


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
