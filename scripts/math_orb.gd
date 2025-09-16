extends Collectible

var collected = false
@onready var animation_player: AnimationPlayer = $MathOrbAnimation

func _ready():
	# Connect to EventManager to listen for quiz events
	EventManager.connect("event_marked", _on_event_marked)
	if animation_player.has_animation("math_orb_float"):
		var idle_anim = animation_player.get_animation("math_orb_float")
		animation_player.speed_scale = 0.15
		idle_anim.loop_mode = 1  # 1 = Loop, 0 = None, 2 = PingPong
		animation_player.play("math_orb_float")

func collect():
	if not collected:
		collected = true
		EventManager.mark_event("math_orb_collected")
		# Don't queue_free immediately - wait for dialogue system to handle the event
		# The orb should remain in the scene until the quiz is answered

func _on_event_marked(event_name: String) -> void:
	# Only process events if this orb has been collected
	if collected:
		animation_player.stop()
		if event_name == "quiz_correct_math_orb":
			# Spawn the number 9 at the orb's position
			NumManager.spawn_num(global_position, 9)
			# Now we can remove the orb
			queue_free()
		elif event_name == "quiz_incorrect_math_orb" or event_name == "dialog_timeout_orb_absorb":
			# No num spawned for incorrect answers or timeout
			queue_free()
