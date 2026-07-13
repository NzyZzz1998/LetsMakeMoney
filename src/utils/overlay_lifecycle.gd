class_name OverlayLifecycle
extends RefCounted

signal modal_opened
signal modal_closed
signal popup_opened
signal popup_closed

var _active_modal: Node = null
var _active_popups: Array[PopupMenu] = []


func register_modal(modal: Node) -> void:
	var was_open := has_modal()
	_active_modal = modal
	if not was_open:
		modal_opened.emit()


func unregister_modal(modal: Node = null) -> void:
	if modal != null and _active_modal != modal:
		return
	var was_registered := _active_modal != null
	_active_modal = null
	if was_registered:
		modal_closed.emit()


func close_active_modal() -> void:
	if has_modal():
		_active_modal.queue_free()
	else:
		unregister_modal()


func has_modal() -> bool:
	return _active_modal != null and is_instance_valid(_active_modal)


func register_popup(popup: PopupMenu) -> void:
	_cleanup_invalid_popups()
	var was_empty := _active_popups.is_empty()
	if not _active_popups.has(popup):
		_active_popups.append(popup)
	if was_empty and not _active_popups.is_empty():
		popup_opened.emit()


func unregister_popup(popup: PopupMenu) -> void:
	var had_popups := not _active_popups.is_empty()
	_active_popups.erase(popup)
	_cleanup_invalid_popups()
	if had_popups and _active_popups.is_empty():
		popup_closed.emit()


func close_all_popups() -> void:
	for popup in _active_popups.duplicate():
		if popup != null and is_instance_valid(popup):
			popup.hide()


func has_popups() -> bool:
	_cleanup_invalid_popups()
	return not _active_popups.is_empty()


func _cleanup_invalid_popups() -> void:
	for popup in _active_popups.duplicate():
		if popup == null or not is_instance_valid(popup):
			_active_popups.erase(popup)
