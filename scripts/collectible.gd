extends RigidBody3D
class_name Collectible

const APPROACH_SPEED = 10.0
var is_approaching_player = false
var target_player = null

func _ready() -> void:
	print("collectible created")
	# Disable gravity until we start approaching the player
	gravity_scale = 0.0
	
func _physics_process(delta: float) -> void:
	if is_approaching_player and target_player:
		# Move toward the player
		var direction = target_player.global_position - global_position
		if direction.length() > 0.75:
			# Apply force toward player
			apply_central_force(direction.normalized() * APPROACH_SPEED)
			
		else:
			# We're close enough to the player, time to collect
			collect()

# Called when player enters detection radius
func start_approaching(player: Node3D) -> void:
	is_approaching_player = true
	target_player = player
	# Enable gravity and make it move toward player
	gravity_scale = 0.2
	# Disable collision with player so it can reach the player
	collision_layer = 0
	collision_mask = 1  # Only collide with environment

# Called when the collectible reaches the player
func collect() -> void:
	# Play collection effect/animation if needed
	# Remove the collectible
	queue_free()
