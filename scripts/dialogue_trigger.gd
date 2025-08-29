extends Area3D

@export var dialogue := preload("res://dialogues/intro.dialogue")
@export var title := "start"


func _on_body_entered(body: Node3D) -> void:
	if body.name == "Player":
		
		DialogueManager.show_dialogue_balloon(dialogue, title)
		queue_free()
