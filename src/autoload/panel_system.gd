# src/autoload/panel_system.gd
extends Node

const HOVER_DELAY := 0.3
const LEAVE_DELAY := 0.5
const REFRESH_INTERVAL := 0.5

var _panel = null
var _collapsed: bool = true
var _hover_timer: float = 0.0
var _leave_timer: float = 0.0
var _mouse_over: bool = false
var _refresh_timer: float = 0.0


func register_panel(panel: Control) -> void:
	if _panel != null and is_instance_valid(_panel):
		if _panel.mouse_entered.is_connected(_on_panel_mouse_entered):
			_panel.mouse_entered.disconnect(_on_panel_mouse_entered)
		if _panel.mouse_exited.is_connected(_on_panel_mouse_exited):
			_panel.mouse_exited.disconnect(_on_panel_mouse_exited)

	_panel = panel
	_collapsed = true
	_hover_timer = 0.0
	_leave_timer = 0.0
	_mouse_over = false
	_refresh_timer = 0.0

	panel.mouse_entered.connect(_on_panel_mouse_entered)
	panel.mouse_exited.connect(_on_panel_mouse_exited)


func _process(delta: float) -> void:
	if _panel == null or not is_instance_valid(_panel):
		return

	if _mouse_over:
		_hover_timer += delta
		_leave_timer = 0.0
		if _hover_timer >= HOVER_DELAY and _collapsed:
			_panel.expand()
			_collapsed = false
	else:
		_leave_timer += delta
		_hover_timer = 0.0
		if _leave_timer >= LEAVE_DELAY and not _collapsed:
			_panel.collapse()
			_collapsed = true

	_refresh_timer += delta
	if _refresh_timer >= REFRESH_INTERVAL:
		_refresh_timer = 0.0
		_panel.refresh_values()


func _on_panel_mouse_entered() -> void:
	_mouse_over = true


func _on_panel_mouse_exited() -> void:
	_mouse_over = false


func force_refresh() -> void:
	if _panel != null and is_instance_valid(_panel):
		_panel.refresh_values()


func is_expanded() -> bool:
	return not _collapsed
