extends CanvasLayer

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		visible = !visible


func _on_button_pressed() -> void:
	visible = !visible
	# Get the current scene's path
	var current_scene_path = get_tree().current_scene.scene_file_path
	
	# Create loading screen if it doesn't exist
	var loading_screen_scene = preload("res://loading_screen.tscn")
	var loading_screen = loading_screen_scene.instantiate()
	
	# Make sure it's on top of everything
	get_tree().root.add_child(loading_screen)
	
	# Start loading the current scene again
	loading_screen.start_loading(current_scene_path)
