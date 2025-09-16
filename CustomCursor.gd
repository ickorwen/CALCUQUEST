extends Node

var _default_cursor: Texture2D
var _grab_cursor: Texture2D

func _ready():
	# Load cursor textures - make sure these paths are correct and files exist
	_default_cursor = load("res://Mouse Cursor/default.png")
	_grab_cursor = load("res://Mouse Cursor/grab.png")
	
	# Set custom cursors for various cursor shapes
	Input.set_custom_mouse_cursor(_default_cursor)
	Input.set_custom_mouse_cursor(
		load("res://36-CustomCursors/art/cursors/wait.png"),
		Input.CURSOR_WAIT
	)
	Input.set_custom_mouse_cursor(
		load("res://Mouse Cursor/drag.png"),
		Input.CURSOR_DRAG
	)
	Input.set_custom_mouse_cursor(
		load("res://36-CustomCursors/art/cursors/forbidden.png"),
		Input.CURSOR_FORBIDDEN
	)
	Input.set_custom_mouse_cursor(
		load("res://36-CustomCursors/art/cursors/i-beam.png"),
		Input.CURSOR_IBEAM
	)

func _input(event):
	if event is InputEventMouseButton:
		var mouse_event = event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_LEFT:
			if mouse_event.pressed:
				Input.set_custom_mouse_cursor(_grab_cursor)
			else:
				Input.set_custom_mouse_cursor(_default_cursor)
