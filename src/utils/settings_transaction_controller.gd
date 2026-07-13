class_name SettingsTransactionController
extends RefCounted

const STATUS_SUCCESS := "success"
const STATUS_NO_CHANGE := "no_change"
const STATUS_VALIDATION_FAILED := "validation_failed"
const STATUS_SAVE_FAILED := "save_failed"
const STATUS_EXTERNAL_FAILED := "external_failed"

const REQUIRED_OPERATIONS: Array[String] = [
	"has_changes",
	"capture_config",
	"capture_external",
	"validate",
	"apply_config",
	"save_config",
	"save_error",
	"apply_external",
	"restore_config",
	"restore_external",
	"changed_keys"
]


func execute(values: Dictionary, operations: Dictionary) -> Dictionary:
	for operation_name in REQUIRED_OPERATIONS:
		if not operations.has(operation_name) or not operations[operation_name] is Callable:
			return _result(STATUS_VALIDATION_FAILED, "missing_operation:%s" % operation_name)

	if not bool(operations.has_changes.call(values)):
		return _result(STATUS_NO_CHANGE)

	var previous_config: Dictionary = operations.capture_config.call()
	var previous_external: Dictionary = operations.capture_external.call()
	if not bool(operations.validate.call(values)):
		operations.restore_config.call(previous_config)
		var validation_external_ok := bool(operations.restore_external.call(previous_external, "pre_save_validation_failed"))
		return _result(STATUS_VALIDATION_FAILED, "pre_save_apply_failed", false, validation_external_ok)

	operations.apply_config.call(values)
	if not bool(operations.save_config.call()):
		var save_error := String(operations.save_error.call())
		operations.restore_config.call(previous_config)
		var save_external_ok := bool(operations.restore_external.call(previous_external, save_error))
		return _result(STATUS_SAVE_FAILED, save_error, false, save_external_ok)

	if not bool(operations.apply_external.call(values)):
		operations.restore_config.call(previous_config)
		var rollback_config_ok := bool(operations.save_config.call())
		var rollback_external_ok := bool(operations.restore_external.call(previous_external, "external_apply_failed"))
		return _result(STATUS_EXTERNAL_FAILED, "external_apply_failed", rollback_config_ok, rollback_external_ok)

	var result := _result(STATUS_SUCCESS)
	result["changed_keys"] = operations.changed_keys.call()
	return result


func _result(status: String, reason: String = "", rollback_config_ok: bool = true, rollback_external_ok: bool = true) -> Dictionary:
	return {
		"status": status,
		"reason": reason,
		"rollback_config_ok": rollback_config_ok,
		"rollback_external_ok": rollback_external_ok,
		"changed_keys": []
	}
