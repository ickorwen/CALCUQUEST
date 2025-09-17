extends Node3D

@onready var showcase_cam: PhantomCamera3D = $ShowcaseCam
@onready var level_animations: AnimationPlayer = $LevelAnimations
@onready var dialogue_manager = DialogueManager
@onready var wing_cam: PhantomCamera3D = $WingCam
@onready var dialog_timer: Timer = Timer.new()
@onready var orb_spawn_timer: Timer = $OrbSpawnTimer
@onready var math_orb: RigidBody3D = $Math_Orb

var dialogue = load("res://dialogues/intro.dialogue")
var orb = load("res://math_orb.tscn")
var current_dialog_type: String = ""
var is_dialogue_active: bool = false
var active_balloon: Node = null
var first_bush_trampled := false
var orb_spawn_position: Vector3

func _ready() -> void:
	level_animations.play("LEVELPAN")
	EventManager.connect("event_marked", _on_event_marked)
	dialogue_manager.connect("dialogue_ended", _on_dialogue_ended)
	dialogue_manager.connect("mutated", _on_dialogue_mutated)
	orb_spawn_position = math_orb.position
	
	# Setup dialog timer
	dialog_timer.one_shot = true
	dialog_timer.timeout.connect(_on_dialog_timeout)
	add_child(dialog_timer)


func _on_level_animations_animation_finished(anim_name: StringName) -> void:
	if anim_name == "LEVELPAN":
		
		
		dialogue_manager.show_dialogue_balloon(dialogue, "start")

func _on_event_marked(event_name: String):
	if event_name == "gizmo_retrieved":
		DialogueManager.show_dialogue_balloon(dialogue, "gizmo_retrieval")
		wing_cam.priority = 2
	
	if event_name == "math_orb_collected":
		show_timed_dialog(dialogue, "orb_absorb", 15.0) # More time for quiz questions
	
	if event_name == "left_wing_retrieved":
		var end_screen = preload("res://end.tscn")
		add_child(end_screen.instantiate())
	
	if event_name == "dialog_timeout_orb_absorb":
		orb_spawn_timer.start()

func _on_dialogue_ended(_resource: DialogueResource):
	is_dialogue_active = false
	# Player is listening to dialogue_ended signal directly
	active_balloon = null
	if wing_cam.priority == 2:
		wing_cam.priority = 0

func _on_dialog_timeout() -> void:
	if is_dialogue_active:
		# We can't directly end the dialogue, but we can mark it as done from our side
		is_dialogue_active = false
		# Player is listening for dialogue_ended signal
		dialogue_manager.dialogue_ended.emit(null)  # Emit dialogue_ended signal for the player
		EventManager.mark_event("dialog_timeout_" + current_dialog_type)
		
		# Force close the balloon if it still exists
		if active_balloon != null and is_instance_valid(active_balloon):
			active_balloon.queue_free()
			active_balloon = null

func _on_dialogue_mutated(mutation: Dictionary) -> void:
	# Handle dialogue mutations
	if mutation.has("function"):
		match mutation.function:
			"EventManager.mark_event":
				# The event is directly marked by the dialogue now
				# The math orb now handles spawning num 9 if the answer is correct
				pass
			_:
				pass  # Silently handle other mutations
			
func show_timed_dialog(dialog_res, dialog_id: String, time: float = 5.0) -> void:
	current_dialog_type = dialog_id
	is_dialogue_active = true
	# Dialogue manager will emit signals that the player listens to
	active_balloon = dialogue_manager.show_dialogue_balloon(dialog_res, dialog_id)
	
	# Give the balloon a moment to initialize
	await get_tree().create_timer(0.1).timeout
	
	# Set the timeout directly on our custom balloon
	if active_balloon:
		if active_balloon.has_method("set_timeout"):
			active_balloon.set_timeout(time)
			
			# Force show the timer if available
			if active_balloon.has_method("force_show_timer"):
				active_balloon.force_show_timer()
	
	# Keep our internal timer as backup
	dialog_timer.start(time)


func _on_orb_spawn_timer_timeout() -> void:
	var math_orb_instance = orb.instantiate()
	
	math_orb_instance.global_position = orb_spawn_position
	add_child(math_orb_instance)
