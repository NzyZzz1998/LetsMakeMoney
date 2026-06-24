# src/autoload/drag_resize_system.gd
extends Node

var _window: Window = null


func register_window(window: Window) -> void:
	_window = window


func move_window_to(pos: Vector2i) -> void:
	if _window:
		_window.position = pos


func save_position() -> void:
	if _window:
		Config.set_value("window_x", int(_window.position.x))
		Config.set_value("window_y", int(_window.position.y))
		Config.save()


func show_context_menu() -> void:
	# Task 3.3 将实现完整右键菜单，此处先打印占位
	print("[DragResizeSystem] show_context_menu called (placeholder)")
