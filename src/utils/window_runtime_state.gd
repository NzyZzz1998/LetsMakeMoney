class_name WindowRuntimeState
extends RefCounted

var debug_mode: bool = false
var pure_pet_mode: bool = false
var tray_ready: bool = false
var native_capable: bool = false
var window_visible: bool = true
var modal_open: bool = false
var popup_open: bool = false
var passthrough_configured: bool = true


func sync(
	debug: bool,
	pure_pet: bool,
	tray: bool,
	native: bool,
	visible: bool,
	modal: bool,
	popup: bool,
	passthrough: bool
) -> void:
	debug_mode = debug
	pure_pet_mode = pure_pet
	tray_ready = tray
	native_capable = native
	window_visible = visible
	modal_open = modal
	popup_open = popup
	passthrough_configured = passthrough


func set_overlay(modal: bool, popup: bool) -> void:
	modal_open = modal
	popup_open = popup


func snapshot() -> Dictionary:
	return {
		"debug_mode": debug_mode,
		"pure_pet_mode": pure_pet_mode,
		"tray_ready": tray_ready,
		"native_capable": native_capable,
		"window_visible": window_visible,
		"modal_open": modal_open,
		"popup_open": popup_open,
		"passthrough_configured": passthrough_configured
	}
