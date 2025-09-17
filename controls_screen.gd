extends Control

@onready var w_label: RichTextLabel = $Control/WLabel
@onready var a_label: RichTextLabel = $Control/ALabel
@onready var s_label: RichTextLabel = $Control/SLabel
@onready var d_label: RichTextLabel = $Control/DLabel

func _process(delta: float) -> void:
	if Input.is_action_pressed("Forward"):
		w_label.modulate = Color("#ffffffff")
	else:
		w_label.modulate = Color("#ffffff22")
		
	
	if Input.is_action_pressed("Backward"):
		s_label.modulate = Color("#ffffffff")
	else:
		s_label.modulate = Color("#ffffff22")
	
	if Input.is_action_pressed("Left"):
		a_label.modulate = Color("#ffffffff")
	else:
		a_label.modulate = Color("#ffffff22")
	
	if Input.is_action_pressed("Right"):
		d_label.modulate = Color("#ffffffff")
	else:
		d_label.modulate = Color("#ffffff22")
