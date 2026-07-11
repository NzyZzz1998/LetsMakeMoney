class_name WindowPolicyCoordinator
extends RefCounted

func desired_taskbar_visible(debug_mode: bool, pure_pet_mode: bool, tray_ready: bool, native_capable: bool) -> bool:
	if debug_mode or not pure_pet_mode:
		return true
	return not (tray_ready and native_capable)

func should_enable_passthrough(modal_open: bool, popup_open: bool, configured: bool) -> bool:
	return configured and not modal_open and not popup_open
