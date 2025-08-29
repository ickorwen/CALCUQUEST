extends CharacterBody3D
class_name Num

const FOLLOW_SPEED = 4.0
const ARRIVAL_DISTANCE = 0.1

@export var num_value: int = 0

@onready var visual: Node3D = $Visual
@onready var num_sprites: Node3D = $Visual/NumSprites
@onready var value_sprite: Sprite3D = $Visual/ValueSprite
@onready var animation_player: AnimationPlayer = $AnimationPlayer

var target_position: Vector3 = Vector3.ZERO
var is_collected: bool = false
var follow_player: Node3D = null
var follow_index: int = 0

var anim_time = 0
var hop_height := 0.5  # how high it hops
var hop_speed := 12 #how fast it hops
# Dragging variables
var dragging := false
var drag_depth := 5.0  # distance from camera when dragging
var ground_y := 0.0  # Store the y-position for ground level

# Slot variables
var in_slot := false
var current_slot: Node = null

func _ready() -> void:
	setup_visuals()
	print("num created with value:", num_value)
	add_to_group("Num") # so the player’s Area3D can detect it
	ground_y = global_position.y

func _get_gravity() -> Vector3:
	return Vector3(0, -9.8, 0)

func _physics_process(delta: float) -> void:
	# When dragging, skip physics calculations
	if dragging:
		return
		
	# If in a slot, don't move
	if in_slot and current_slot != null:
		velocity = Vector3.ZERO
		return
		
	# If we have a current_slot reference but we're not actually in the slot,
	# make sure we're properly released from it
	if not in_slot and current_slot != null:
		# Clear the slot reference since we're not in it anymore
		current_slot = null
	
	if not is_collected and not is_on_floor():
		velocity += _get_gravity() * delta
	
	if is_collected and target_position != Vector3.ZERO:
		var direction = (target_position - global_position).normalized()
		var distance = global_position.distance_to(target_position)
		
		if distance > ARRIVAL_DISTANCE:
			velocity = direction * FOLLOW_SPEED
		else:
			velocity = Vector3.ZERO
	
	if visual:
		var horizontal_speed = Vector2(velocity.x, velocity.z).length()
		if horizontal_speed > 1:
			# When moving, continue the hopping animation
			anim_time += delta * hop_speed
			var hop_offset = max(0.0, sin(anim_time) * hop_height)
			visual.position.y = hop_offset
			# squash & stretch
			var scale_bounce = 1 + sin(anim_time) * 0.2
			visual.scale = Vector3(1 / scale_bounce, scale_bounce, 1 / scale_bounce)
			if velocity.x > 0:
				num_sprites.rotation.y = deg_to_rad(180)
			else:
				num_sprites.rotation.y = 0
		else:
			# Smoothly transition to rest position when stopped
			visual.position.y = lerp(visual.position.y, 0.0, delta * 5.0)
			visual.scale = visual.scale.lerp(Vector3.ONE, delta * 5.0)
	
	
	
	
	move_and_slide()

func setup_visuals() -> void:
	if value_sprite:
		value_sprite.frame = num_value
	
	if num_sprites:
		$Visual/NumSprites/Front.frame = num_value
		$Visual/NumSprites/Back.frame = num_value

func collect(player_node: Node3D) -> void:
	is_collected = true
	follow_player = player_node

const MAX_DRAG_DISTANCE = 5.0  # Maximum distance from player when dragging

func _input(event: InputEvent) -> void:
	# Stop dragging if Num is no longer collected
	if dragging and not is_collected:
		dragging = false
		return
	
	# Stop dragging if thinking mode ends and num is in a slot
	if dragging and not Global.is_thinking and in_slot and current_slot:
		dragging = false
		
		# Reset in slot state
		in_slot = false
		
		# Clear slot reference
		var old_slot = current_slot
		current_slot = null
		
		# Notify the slot that the num is leaving
		if old_slot.has_method("release_current_num"):
			old_slot.release_current_num()
		return
	
	# Skip event processing if not dragging and not starting drag
	if not dragging and not (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
		return
		
	if event is InputEventMouseButton:
		# Handle dragging end
		if event.button_index == MOUSE_BUTTON_LEFT:
			if not event.pressed:
				dragging = false
				
				# Force distance check to ensure we're actually over the slot
				var should_snap_to_slot = false
				
				if current_slot != null:
					# Check if we're actually close enough to the slot to snap to it
					var distance_to_slot = global_position.distance_to(current_slot.slot_position)
					should_snap_to_slot = distance_to_slot < 0.5 # Use a reasonable threshold
					
					if should_snap_to_slot:
						# Now that we've stopped dragging and we're close to the slot, position in the slot
						in_slot = true
						global_position = current_slot.slot_position
						print("Released in slot: positioning at ", current_slot.slot_position)
						
						# Emit signal with the new value through the slot
						if current_slot.has_method("emit_signal"):
							current_slot.emit_signal("num_value_changed", num_value)
					else:
						# We're not close enough to the slot, clear the reference
						print("Released too far from slot, not snapping")
						current_slot = null
				
				# If not in a slot or not close enough to snap to it, return to following position
				if not in_slot or not should_snap_to_slot:
					# Find this num's index in collected_nums
					var index = NumManager.collected_nums.find(self)
					if index >= 0:
						var player = get_tree().get_first_node_in_group("Player")
						if player and Global.is_thinking:
							# Return to thinking position
							if index < player.thinking_path_points.size():
								target_position = player.thinking_path_points[index]
						else:
							# Return to following position
							if index < player.path_points.size():
								var path_index = player.path_points.size() - 1 - index
								target_position = player.path_points[path_index]
				
				# Re-enable physics
				if not is_collected:
					velocity = Vector3.ZERO
		
		# Handle scroll wheel for depth adjustment
		elif dragging and event.pressed:
			var camera = get_viewport().get_camera_3d()
			if camera:
				# Adjust depth with scroll wheel
				if event.button_index == MOUSE_BUTTON_WHEEL_UP:
					drag_depth -= 1.0  # Move closer
				elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
					drag_depth += 1.0  # Move farther
				
				# Ensure drag_depth stays positive and reasonable
				drag_depth = clamp(drag_depth, 1.0, 50.0)
	
	if event is InputEventMouseMotion and dragging:
		# Get the camera
		var camera = get_viewport().get_camera_3d()
		if camera:
			# Project mouse to a ray
			var from = camera.project_ray_origin(event.position)
			var dir = camera.project_ray_normal(event.position)
			
			# Create space state for collision detection
			var space_state = get_world_3d().direct_space_state
			
			# Set up physics query for world collision
			var world_query = PhysicsRayQueryParameters3D.new()
			world_query.from = from
			world_query.to = from + dir * 100.0  # Use a long ray
			world_query.exclude = [self]  # Don't detect self
			world_query.collision_mask = 1  # Adjust to your collision layers
			
			# Check for collisions in the world
			var collision = space_state.intersect_ray(world_query)
			
			# Determine target position
			var drag_target
			if collision:
				# Get ray from camera to collision
				var camera_to_collision = collision.position - from
				var distance_to_collision = camera_to_collision.length()
				
				# Position it in front of anything else at that mouse position
				# Use a shorter distance to ensure it's in front of the collision
				var shorter_distance = max(1.0, distance_to_collision * 0.9)
				drag_target = from + dir * shorter_distance
			else:
				# No collision, use a default depth
				drag_target = from + dir * drag_depth
			
			# Check if the drag target is within allowed distance from player
			var player = get_tree().get_first_node_in_group("Player")
			if player:
				var distance_to_player = drag_target.distance_to(player.global_position)
				if distance_to_player > MAX_DRAG_DISTANCE:
					# Beyond allowed range, limit to maximum distance in that direction
					var direction_to_target = (drag_target - player.global_position).normalized()
					drag_target = player.global_position + direction_to_target * MAX_DRAG_DISTANCE
					# Visual feedback that we're at the limit could go here
			
			# Directly set position - for exact mouse following
			global_position = drag_target
			
			# Zero out velocity to prevent additional movement in physics process
			velocity = Vector3.ZERO
			

func _on_drag_detect_input_event(_camera: Node, event: InputEvent, _event_position: Vector3, _normal: Vector3, _shape_idx: int) -> void:
	# Only allow dragging if the Num is collected (no longer thinking mode restricted)
	if not is_collected:
		return
		
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		print("dragging: ", num_value)
		dragging = true
		
		# If this Num was in a slot, notify the slot that it's being removed
		if in_slot and current_slot != null:
			print("Dragging num out of slot: ", num_value)
			# Call the exit function directly to ensure the slot knows the Num is leaving
			if current_slot.has_method("_on_operand_slot_body_exited"):
				current_slot._on_operand_slot_body_exited(self)
			else:
				# Fallback in case the method isn't found
				current_slot.emit_signal("num_value_changed", 0)
				in_slot = false
		
		# Get the camera and store current depth
		var camera = get_viewport().get_camera_3d()
		if camera:
			# Simply use the current distance from camera to object
			drag_depth = camera.global_position.distance_to(global_position)
