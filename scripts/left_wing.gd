extends Collectible
@onready var animation_player: AnimationPlayer = $LeftWingAnimation
var dialogue := preload("res://dialogues/intro.dialogue")

func ready() -> void:
	if animation_player.has_animation("floating"):
		var idle_anim = animation_player.get_animation("floating")
		animation_player.speed_scale = 0.15
		idle_anim.loop_mode = 1  # 1 = Loop, 0 = None, 2 = PingPong
		animation_player.play("floating")
func collect() -> void:
	DialogueManager.show_dialogue_balloon(dialogue, "left_wing_retrieved")
	queue_free()
