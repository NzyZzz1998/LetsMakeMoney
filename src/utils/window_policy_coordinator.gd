class_name WindowPolicyCoordinator
extends RefCounted

func desired_taskbar_visible(debug_mode: bool, pure_pet_mode: bool, tray_ready: bool, native_capable: bool) -> bool:
	if debug_mode or not pure_pet_mode:
		return true
	return not (tray_ready and native_capable)

func should_enable_passthrough(modal_open: bool, popup_open: bool, configured: bool) -> bool:
	return configured and not modal_open and not popup_open


func desired_taskbar_for_state(state: Dictionary) -> bool:
	return desired_taskbar_visible(
		bool(state.get("debug_mode", false)),
		bool(state.get("pure_pet_mode", false)),
		bool(state.get("tray_ready", false)),
		bool(state.get("native_capable", false))
	)


func should_enable_passthrough_for_state(state: Dictionary) -> bool:
	return bool(state.get("window_visible", true)) and should_enable_passthrough(
		bool(state.get("modal_open", false)),
		bool(state.get("popup_open", false)),
		bool(state.get("passthrough_configured", false))
	)
