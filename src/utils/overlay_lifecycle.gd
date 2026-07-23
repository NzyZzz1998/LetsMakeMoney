class_name OverlayLifecycle
extends RefCounted

signal modal_opened
signal modal_closed
signal popup_opened
signal popup_closed

var _active_modals: Array[Node] = []
var _active_popups: Array[PopupMenu] = []


func register_modal(modal: Node) -> void:
	_cleanup_invalid_modals()
	var was_open := has_modal()
	if not _active_modals.has(modal):
		_active_modals.append(modal)
	if not was_open:
		modal_opened.emit()


func unregister_modal(modal: Node = null) -> void:
	var had_modals := has_modal()
	if modal == null:
		_active_modals.clear()
	else:
		_active_modals.erase(modal)
	_cleanup_invalid_modals()
	if had_modals and _active_modals.is_empty():
		modal_closed.emit()


func close_active_modal() -> void:
	if has_modal():
		var modal: Node = _active_modals.back()
		if modal != null and is_instance_valid(modal):
			modal.queue_free()
	else:
		unregister_modal()


func has_modal() -> bool:
	_cleanup_invalid_modals()
	return not _active_modals.is_empty()


func _cleanup_invalid_modals() -> void:
	for modal in _active_modals.duplicate():
		if modal == null or not is_instance_valid(modal):
			_active_modals.erase(modal)


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
