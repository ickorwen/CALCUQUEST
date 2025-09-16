extends Node

# Place this script on a singleton or autoload node to handle level transitions

@onready var loading_screen_scene = preload("res://loading_screen.tscn")
var loading_screen = null

# Example level paths - replace with your actual level paths
var levels = {
	"level_1": "res://demo.tscn",
	"level_2": "res://level_2.tscn"
}

func _ready() -> void:
	# Add your initialization code here
	pass

func load_level(level_key: String) -> void:
	# Make sure the level exists in our dictionary
	if not levels.has(level_key):
		push_error("Level not found: " + level_key)
		return
	
	# Create loading screen if it doesn't exist
	if not loading_screen:
		loading_screen = loading_screen_scene.instantiate()
		# Make sure it's on top of everything
		loading_screen.layer = 100
		get_tree().root.add_child(loading_screen)
	
	# Start loading the requested level
	loading_screen.start_loading(levels[level_key])

# Example usage:
# In any script where you want to change levels:
# 
# # Get the level loader (assuming it's an autoload named "LevelLoader")
# var loader = get_node("/root/LevelLoader")
# # Load level 2
# loader.load_level("level_2")