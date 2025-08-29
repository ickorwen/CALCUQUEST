extends Collectible

var collected = false

func _ready():
	# Connect to EventManager to listen for quiz events
	EventManager.connect("event_marked", _on_event_marked)

func collect():
	if not collected:
		collected = true
		EventManager.mark_event("math_orb_collected")
		# Don't queue_free immediately - wait for dialogue system to handle the event
		# The orb should remain in the scene until the quiz is answered

func _on_event_marked(event_name: String) -> void:
	# Only process events if this orb has been collected
	if collected:
		if event_name == "quiz_correct_math_orb":
			# Spawn the number 9 at the orb's position
			NumManager.spawn_num(global_position, 9)
			# Now we can remove the orb
			queue_free()
		elif event_name == "quiz_incorrect_math_orb" or event_name == "dialog_timeout_orb_absorb":
			# No num spawned for incorrect answers or timeout
			queue_free()
