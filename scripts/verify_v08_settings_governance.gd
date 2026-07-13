extends SceneTree

const TransactionControllerScript := preload("res://src/utils/settings_transaction_controller.gd")
const SectionBuilderScript := preload("res://src/ui/settings_section_builder.gd")

var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_test_section_builder_contract()
	_test_transaction_success()
	_test_transaction_no_change()
	_test_transaction_save_failure_rolls_back()
	_test_transaction_external_failure_rolls_back_and_persists()
	if failures.is_empty():
		print("v0.8 settings governance passed")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)


func _test_section_builder_contract() -> void:
	var builder = SectionBuilderScript.new()
	var page: Control = builder.new_tab("Salary")
	_expect(page is ScrollContainer, "section builder must create scrollable settings pages")
	_expect(page.name == "Salary", "section builder must preserve page names")
	var box: VBoxContainer = builder.new_vbox(page)
	builder.add_page_heading(box, "工资设置", "收入小票的计算来源")
	builder.add_section_heading(box, "基础收入")
	var control := SpinBox.new()
	builder.add_control_row(box, "月薪", control)
	_expect(box.get_child_count() == 4, "section builder must create title, hint, section and row")
	_expect(control.get_parent() != null, "section builder must attach controls to a row")
	page.free()


func _test_transaction_success() -> void:
	var state := _new_transaction_state()
	var result: Dictionary = TransactionControllerScript.new().execute({"salary": 2000}, _operations(state))
	_expect(result.get("status") == "success", "successful settings transaction must report success")
	_expect(state.config.get("salary") == 2000, "successful settings transaction must keep proposed config")
	_expect(state.external.get("pet") == "new", "successful settings transaction must apply external state")


func _test_transaction_no_change() -> void:
	var state := _new_transaction_state()
	var operations := _operations(state)
	operations["has_changes"] = func(_values: Dictionary) -> bool: return false
	var result: Dictionary = TransactionControllerScript.new().execute({"salary": 1000}, operations)
	_expect(result.get("status") == "no_change", "unchanged settings must not start a transaction")
	_expect(int(state.get("save_calls", 0)) == 0, "unchanged settings must not save config")


func _test_transaction_save_failure_rolls_back() -> void:
	var state := _new_transaction_state()
	state.save_ok = false
	var result: Dictionary = TransactionControllerScript.new().execute({"salary": 2000}, _operations(state))
	_expect(result.get("status") == "save_failed", "failed config write must report save_failed")
	_expect(state.config.get("salary") == 1000, "failed config write must restore in-memory config")
	_expect(state.external.get("pet") == "old", "failed config write must restore external state")


func _test_transaction_external_failure_rolls_back_and_persists() -> void:
	var state := _new_transaction_state()
	state.external_ok = false
	var result: Dictionary = TransactionControllerScript.new().execute({"salary": 2000}, _operations(state))
	_expect(result.get("status") == "external_failed", "failed external apply must report external_failed")
	_expect(state.config.get("salary") == 1000, "failed external apply must restore config snapshot")
	_expect(state.external.get("pet") == "old", "failed external apply must restore external snapshot")
	_expect(int(state.get("save_calls", 0)) == 2, "failed external apply must persist the rollback")


func _new_transaction_state() -> Dictionary:
	return {
		"config": {"salary": 1000},
		"external": {"pet": "old"},
		"save_ok": true,
		"external_ok": true,
		"save_calls": 0
	}


func _operations(state: Dictionary) -> Dictionary:
	return {
		"has_changes": func(values: Dictionary) -> bool: return state.config != values,
		"capture_config": func() -> Dictionary: return state.config.duplicate(true),
		"capture_external": func() -> Dictionary: return state.external.duplicate(true),
		"validate": func(_values: Dictionary) -> bool: return true,
		"apply_config": func(values: Dictionary) -> void: state.config = values.duplicate(true),
		"save_config": func() -> bool:
			state.save_calls = int(state.save_calls) + 1
			return bool(state.save_ok),
		"save_error": func() -> String: return "mock write failed",
		"apply_external": func(_values: Dictionary) -> bool:
			if not bool(state.external_ok):
				return false
			state.external = {"pet": "new"}
			return true,
		"restore_config": func(snapshot: Dictionary) -> void: state.config = snapshot.duplicate(true),
		"restore_external": func(snapshot: Dictionary, _reason: String) -> bool:
			state.external = snapshot.duplicate(true)
			return true,
		"changed_keys": func() -> Array: return ["salary"]
	}


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
