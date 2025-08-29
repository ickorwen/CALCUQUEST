extends Node

const NUM_SPRITES = [
	preload("res://assets/NUM0.png"),
	preload("res://assets/NUM1.png"),
	preload("res://assets/NUM2.png"),
	preload("res://assets/NUM3.png"),
	preload("res://assets/NUM4.png"),
	preload("res://assets/NUM5.png"),
	preload("res://assets/NUM6.png"),
	preload("res://assets/NUM7.png"),
	preload("res://assets/NUM8.png"),
	preload("res://assets/NUM9.png"),
]

signal thinking_mode_changed(is_thinking_now)

var is_thinking : bool = false
var think_cam : PhantomCamera3D

func _ready() -> void:
	think_cam = get_node("/root/Demo/ThinkCam")

func think():
	Global.is_thinking = !Global.is_thinking
	# Emit signal when thinking mode changes
	thinking_mode_changed.emit(is_thinking)
	if is_thinking and think_cam:
		think_cam.set_priority(2)
	else:
		think_cam.set_priority(0)
	
	# Update Num positions when thinking mode changes
	if get_node_or_null("/root/NumManager") != null:
		NumManager.update_num_positions()
