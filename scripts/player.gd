extends CharacterBody3D

const SPEED = 3.0
const JUMP_VELOCITY = 4.5
const PATH_POINT_DISTANCE = 1.5
const MAX_PATH_POINTS = 5

var path_points: Array = []
var last_position: Vector3
var input_dir : Vector2
var thinking_path_points: Array = []

@onready var animation_tree: AnimationTree = $AnimationTree
@onready var player_sprite: Sprite3D = $PlayerSprite
@onready var think_bubble: StaticBody3D = $ThinkBubble


func _ready() -> void:
	last_position = global_position
	animation_tree.active = true
	add_path_point(global_position)
	update_thinking_path_points()  # Initialize thinking path points
 
func _physics_process(delta: float) -> void:
	
	if not is_on_floor():
		velocity += _get_gravity() * delta
	
	if !Global.is_thinking:
		input_dir = Input.get_vector("Left", "Right", "Forward", "Backward")
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
	if event.is_action_pressed("think"):
		# Update thinking path points based on current position
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
