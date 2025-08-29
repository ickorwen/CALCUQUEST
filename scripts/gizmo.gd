extends Collectible


func collect() -> void:
	EventManager.mark_event("gizmo_retrieved")
	
	queue_free()
