extends Control

signal loading_completed

# Configuration
@export var min_load_time: float = 1.0  # Minimum time to show loading screen in seconds
@export var fade_in_time: float = 0.5
@export var fade_out_time: float = 0.5
@export var loading_phrases: Array[String] = [
	"Calculating equations...",
	"Preparing numbers...",
	"Generating puzzles...",
	"Initializing thinking caps...",
	"Energizing math orbs..."
]

# Properties
var _next_scene_path: String = ""
var _loading_thread: Thread
var _progress: Array[float] = []
var _is_loading: bool = false
var _load_start_time: float = 0.0
var _random = RandomNumberGenerator.new()

# Nodes (set these in _ready with appropriate paths to your UI elements)
@onready var progress_bar: ProgressBar = $ProgressBar
@onready var progress_label: Label = $ProgressLabel
@onready var loading_phrase_label: Label = $LoadingPhraseLabel
@onready var animation_player: AnimationPlayer = $AnimationPlayer

func _ready() -> void:
	# Hide the loading screen by default
	visible = false
	_random.randomize()
	
	# Connect signals if needed
	if animation_player:
		animation_player.animation_finished.connect(_on_animation_finished)
		
	# Ensure these nodes exist to prevent errors
	if not progress_bar:
		push_warning("Loading screen missing ProgressBar node")
	if not progress_label:
		push_warning("Loading screen missing ProgressLabel node")
	if not loading_phrase_label:
		push_warning("Loading screen missing LoadingPhraseLabel node")

func start_loading(next_scene_path: String) -> void:
	if _is_loading:
		push_warning("Already loading a scene")
		return
		
	_next_scene_path = next_scene_path
	_is_loading = true
	_load_start_time = Time.get_ticks_msec() / 1000.0
	
	# Show loading screen
	visible = true
	
	# Play fade in animation if available
	if animation_player and animation_player.has_animation("fade_in"):
		animation_player.play("fade_in")
	
	# Set a random loading phrase
	if loading_phrase_label and loading_phrases.size() > 0:
		loading_phrase_label.text = loading_phrases[_random.randi() % loading_phrases.size()]
	
	# Reset progress
	_progress.clear()
	_update_progress_display(0.0)
	
	# Start loading in a thread
	_loading_thread = Thread.new()
	_loading_thread.start(_load_scene_thread)

func _load_scene_thread() -> void:
	# Start the resource loader
	var loader = ResourceLoader.load_threaded_request(_next_scene_path)
	
	if loader == null:
		push_error("Could not load scene: " + _next_scene_path)
		call_deferred("_loading_failed")
		return
		
	# Wait until loading is complete
	var status = ResourceLoader.THREAD_LOAD_IN_PROGRESS
	while status == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
		await get_tree().create_timer(0.05).timeout
		status = ResourceLoader.load_threaded_get_status(_next_scene_path, _progress)
		call_deferred("_update_progress_display", _progress[0] if _progress.size() > 0 else 0.0)
		
	# Check load status
	if status == ResourceLoader.THREAD_LOAD_LOADED:
		# Loading succeeded
		var scene_resource = ResourceLoader.load_threaded_get(_next_scene_path)
		call_deferred("_loading_complete", scene_resource)
	else:
		# Loading failed
		push_error("Failed to load scene: " + _next_scene_path + ", status: " + str(status))
		call_deferred("_loading_failed")

func _update_progress_display(progress: float) -> void:
	if progress_bar:
		progress_bar.value = progress * 100
	
	if progress_label:
		progress_label.text = str(int(progress * 100)) + "%"

func _loading_complete(scene_resource: Resource) -> void:
	# Check if we've reached the minimum loading time
	var elapsed_time = Time.get_ticks_msec() / 1000.0 - _load_start_time
	
	if elapsed_time < min_load_time:
		# Wait until minimum time has passed
		await get_tree().create_timer(min_load_time - elapsed_time).timeout
	
	# Show 100% progress
	_update_progress_display(1.0)
	
	# Play fade out animation if available
	if animation_player and animation_player.has_animation("fade_out"):
		animation_player.play("fade_out")
		await animation_player.animation_finished
	
	# Instance and change to the new scene
	var new_scene = scene_resource.instantiate()
	get_tree().root.add_child(new_scene)
	get_tree().current_scene = new_scene
	
	# Emit signal
	loading_completed.emit()
	
	# Hide loading screen
	visible = false
	_is_loading = false
	
	# Clean up
	_loading_thread.wait_to_finish()
	
	# Remove the old scene
	var old_scene = get_tree().get_nodes_in_group("current_level")
	if old_scene.size() > 0:
		old_scene[0].queue_free()

func _loading_failed() -> void:
	push_error("Loading failed for scene: " + _next_scene_path)
	_is_loading = false
	
	# You might want to show an error message or retry option here
	if loading_phrase_label:
		loading_phrase_label.text = "Loading failed. Please restart the game."

func _on_animation_finished(_anim_name: String) -> void:
	# Handle any post-animation tasks if needed
	pass
