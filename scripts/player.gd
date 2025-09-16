extends CharacterBody3D

const SPEED = 3.0
const JUMP_VELOCITY = 4.5
const PATH_POINT_DISTANCE = 1.5
const MAX_PATH_POINTS = 5

var path_points: Array = []
var last_position: Vector3
var input_dir : Vector2
var thinking_path_points: Array = []
var can_move: bool = true  # New variable to control player movement
var is_in_dialogue: bool = false # Explicit dialogue state tracker
var anti_move_timer: Timer # Timer to prevent movement during restricted states

@onready var animation_tree: AnimationTree = $AnimationTree
@onready var player_sprite: Sprite3D = $PlayerSprite
@onready var think_bubble: StaticBody3D = $ThinkBubble
@onready var dialogue_manager = DialogueManager  # Reference to DialogueManager
@onready var movement_timer = $"Movement Timer"


func _ready() -> void:
	last_position = global_position
	animation_tree.active = true
	add_path_point(global_position)
	update_thinking_path_points()  # Initialize thinking path points
	
	# Connect to DialogueManager signals
	dialogue_manager.connect("dialogue_started", _on_dialogue_started)
	dialogue_manager.connect("dialogue_ended", _on_dialogue_ended)
	
	# Connect to Global thinking mode signals
	Global.thinking_mode_changed.connect(_on_thinking_mode_changed)
	
	start_game()

func start_game() -> void:
	can_move = false
	movement_timer.start()


 
func _physics_process(delta: float) -> void:
	
	# Check for restricted movement states - highest priority
	if is_in_dialogue or Global.is_thinking:
		# Hard override - complete movement lock during dialogue or thinking
		velocity = Vector3.ZERO
		input_dir = Vector2.ZERO
		# Still update animation parameters even when movement is locked
		update_parameters()
		# Skip remaining physics processing
		return
	
	# Normal physics processing when not in dialogue
	if not is_on_floor():
		velocity += _get_gravity() * delta
	
	# Allow player movement only if can_move is true (not in dialogue or thinking)
	if can_move:
		input_dir = Input.get_vector("Left", "Right", "Forward", "Backward")
	else:
		# Zero out input when movement is disabled (thinking mode)
		input_dir = Vector2.ZERO
	
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)
	
	if velocity.x < 0:
		if !input_dir.y > 0:
			player_sprite.rotation.y = deg_to_rad(180)
		else:
			player_sprite.rotation.y = 0
	else:
		player_sprite.rotation.y = 0
	update_parameters()
	move_and_slide()
	if global_position.distance_to(last_position) >= PATH_POINT_DISTANCE:
		add_path_point(global_position)
		NumManager.update_num_positions()


func _input(event: InputEvent) -> void:
	# Block movement keys during restricted states (dialogue or thinking)
	if is_in_dialogue or Global.is_thinking:
		# Capture ALL movement inputs and prevent them
		if event.is_action("Forward") or event.is_action("Backward") or \
		   event.is_action("Left") or event.is_action("Right"):
			# Mark input as handled so the game doesn't process it
			get_viewport().set_input_as_handled()
			# Force zero velocity whenever movement keys are pressed
			velocity = Vector3.ZERO
			input_dir = Vector2.ZERO
			# Only allow think action to pass through
			if !event.is_action("think"):
				return
	
	# Always allow the think toggle, regardless of movement state
	# This is important for exiting thinking mode
	if event.is_action_pressed("think"):
		# If camera isn't ready, force a re-initialization
		if !Global.think_cam or !is_instance_valid(Global.think_cam):
			# Force a re-initialization of the thinking camera
			print("Attempting to re-initialize ThinkCam...")
			Global._init_think_cam()
		
		# Only update thinking path points when entering thinking mode
		if !Global.is_thinking:
			update_thinking_path_points()
		
		Global.think()
		think_bubble.update_visibility()
	


func add_path_point(point: Vector3) -> void:
	path_points.append(point)
	last_position = point
	if path_points.size() > MAX_PATH_POINTS:
		path_points.pop_front()

func update_parameters():
	if Vector2(velocity.x, velocity.z).length() == 0:
		animation_tree["parameters/conditions/idle"] = true
		animation_tree["parameters/conditions/is_moving"] = false
	else:
		animation_tree["parameters/conditions/idle"] = false
		animation_tree["parameters/conditions/is_moving"] = true
		animation_tree["parameters/WALK/blend_position"] =  input_dir

func update_thinking_path_points() -> void:
	# Define thinking path points to the left of the player in a line
	thinking_path_points = [
		Vector3(global_position.x - 1, global_position.y, global_position.z - 1),
		Vector3(global_position.x - 1.75, global_position.y, global_position.z - 1),
		Vector3(global_position.x - 2.5, global_position.y, global_position.z - 1),
		Vector3(global_position.x - 3.25, global_position.y, global_position.z - 1),
		Vector3(global_position.x - 4, global_position.y, global_position.z - 1),
	]


func _get_gravity() -> Vector3:
	return Vector3(0, -9.8, 0)

func _on_collection_radius_body_entered(body: Node3D) -> void:
	if body is Num and not body.is_collected:
		print("Collecting Num with value: ", body.num_value)
		NumManager.collect_num(body)
	
	if body is Collectible:
		# Tell the collectible to start approaching the player
		print("Collectible detected, starting approach")
		body.start_approaching(self)

# Signal handlers for movement control

func _on_dialogue_started(_resource) -> void:
	# Mark that we're in dialogue
	is_in_dialogue = true
	# Disable movement
	can_move = false
	# Zero out velocity and input immediately
	velocity = Vector3.ZERO
	input_dir = Vector2.ZERO
	
	# Start the anti-movement timer
	_start_anti_movement_timer()
	
func _start_anti_movement_timer() -> void:
	# Stop any existing timer first
	_stop_anti_movement_timer()
	
	# Create a new timer that regularly resets velocity
	anti_move_timer = Timer.new()
	anti_move_timer.name = "AntiMoveTimer"
	anti_move_timer.wait_time = 0.02 # Very frequent checks
	anti_move_timer.one_shot = false
	anti_move_timer.autostart = true
	anti_move_timer.timeout.connect(_force_zero_velocity)
	add_child(anti_move_timer)

func _stop_anti_movement_timer() -> void:
	if anti_move_timer and is_instance_valid(anti_move_timer):
		anti_move_timer.stop()
		anti_move_timer.queue_free()
		anti_move_timer = null

func _force_zero_velocity() -> void:
	# This function is called regularly to ensure velocity is zero
	# during restricted movement states (dialogue or thinking)
	if is_in_dialogue or Global.is_thinking:
		velocity = Vector3.ZERO
		input_dir = Vector2.ZERO

func _on_dialogue_ended(_resource) -> void:
	# Mark that we're no longer in dialogue
	is_in_dialogue = false
	
	# Only enable movement if we're not in thinking mode
	if !Global.is_thinking:
		can_move = true
		_stop_anti_movement_timer()
	# If we're in thinking mode, keep the timer running
	
func _on_thinking_mode_changed(is_thinking: bool) -> void:
	# Disable movement when in thinking mode, enable otherwise
	can_move = !is_thinking
	
	if is_thinking:
		# Start the anti-movement timer when entering thinking mode
		_start_anti_movement_timer()
		# Immediately zero out velocity
		velocity = Vector3.ZERO
		input_dir = Vector2.ZERO
	else:
		# Only stop the timer if we're not in dialogue
		if !is_in_dialogue:
			_stop_anti_movement_timer()


func _on_movement_timer_timeout() -> void:
	can_move = true
