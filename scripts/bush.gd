extends StaticBody3D
signal trampled

@export var stored_nums : Array[int] = [0]
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var timer: Timer = $Timer
@onready var sprite_3d: Sprite3D = $Sprite3D

func _ready():
	if animation_player.has_animation("idle"):
		var idle_anim = animation_player.get_animation("idle")
		animation_player.speed_scale = 0.35
		idle_anim.loop_mode = 1  # 1 = Loop, 0 = None, 2 = PingPong
		animation_player.play("idle")

func _on_area_3d_body_entered(body: Node3D) -> void:
	if body.name == "Player":
		animation_player.stop()
		animation_player.speed_scale = 1
		animation_player.play("COLLAPSE")
		for i in stored_nums.size():
			NumManager.spawn_num(global_position, stored_nums[i])
	

func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name == "COLLAPSE":
		emit_signal("trampled")
		queue_free()

func _on_trampled() -> void:
	var parent = get_parent()
	if parent.first_bush_trampled:
		pass
	else:
		DialogueManager.show_dialogue_balloon(preload("res://dialogues/intro.dialogue"), "jumpscare")
		parent.first_bush_trampled = true
