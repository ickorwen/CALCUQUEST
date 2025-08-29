extends Collectible

var dialogue := preload("res://dialogues/intro.dialogue")

func collect() -> void:
	DialogueManager.show_dialogue_balloon(dialogue, "left_wing_retrieved")
	queue_free()
