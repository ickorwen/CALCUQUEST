extends StaticBody3D

@export var stored_nums : Array[int] = [0]
@onready var animation_player: AnimationPlayer = $AnimationPlayer

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_area_3d_body_entered(body: Node3D) -> void:
	if body.name == "Player":
		animation_player.play("COLLAPSE")
		for i in stored_nums.size():
			NumManager.spawn_num(global_position, stored_nums[i])



func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name == "COLLAPSE":
		queue_free()
