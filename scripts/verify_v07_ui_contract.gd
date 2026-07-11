extends SceneTree

var failures: Array[String] = []

func _init() -> void:
	call_deferred("_run")

func _assert(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		push_error(message)

func _run() -> void:
	var settings_scene: PackedScene = load("res://src/scenes/settings/settings_dialog.tscn")
	var wizard_scene: PackedScene = load("res://src/scenes/wizard/wizard_dialog.tscn")
	_assert(settings_scene != null, "Settings scene must load")
	_assert(wizard_scene != null, "Wizard scene must load")
	if settings_scene != null:
		var settings := settings_scene.instantiate()
		root.add_child(settings)
		await process_frame
		for path in ["SettingsSurface", "SettingsRoot", "SettingsRoot/SettingsShellCenter/SettingsShell"]:
			_assert(settings.get_node_or_null(path) != null, "Settings node missing: %s" % path)
		for section in ["Salary", "Pet", "Display", "Panel", "General"]:
			_assert(settings.get_node_or_null("SettingsRoot/SettingsShellCenter/SettingsShell/SettingsShellColumn/SettingsContentMargin/SettingsContentPages/%s" % section) != null, "Settings page missing: %s" % section)
		settings.queue_free()
	if wizard_scene != null:
		var wizard := wizard_scene.instantiate()
		root.add_child(wizard)
		await process_frame
		for page in ["Welcome", "Salary", "PetSelect", "Confirm"]:
			_assert(wizard.get_node_or_null("WizardSurface/WizardOuterMargin/WizardRoot/WizardContentPages/%s" % page) != null, "Wizard page missing: %s" % page)
		wizard.queue_free()
	await process_frame
	if failures.is_empty():
		print("v0.7 UI contract passed")
		quit(0)
	else:
		quit(1)
