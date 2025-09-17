extends Collectible
@onready var level_border_1: Node3D = $"../LevelBorder_1"


func collect() -> void:
	EventManager.mark_event("gizmo_retrieved")
	level_border_1.queue_free();
	queue_free()
	
