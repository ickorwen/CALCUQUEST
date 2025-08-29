extends Area3D
class_name OperandSlot

# Signal when a num is placed or removed
signal num_value_changed(value)

var current_num: Num = null
var slot_position: Vector3
var slot_name: String = ""

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Store the slot name for debugging
	slot_name = name
	
	# Wait a frame to ensure all nodes are properly positioned
	call_deferred("_initialize_slot_position")
	
	# Connect to thinking mode signal to clear slots when thinking ends
	if not Global.is_connected("thinking_mode_changed", Callable(self, "_on_thinking_mode_changed")):
		Global.thinking_mode_changed.connect(_on_thinking_mode_changed)
		
	print(slot_name + " initialized")

# Initialize slot position after all nodes are ready
func _initialize_slot_position() -> void:
	# Use our own position
	slot_position = global_position
	print("Operand slot position initialized at: ", slot_position)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	# Update slot position in case parent moves
	slot_position = global_position
	
	# If we have a num in the slot but it's no longer being dragged,
	# ensure it stays at the correct position
	if current_num != null and not current_num.dragging and current_num.in_slot:
		current_num.global_position = slot_position

func _on_operand_slot_body_entered(body: Node3D) -> void:
	# Check that this is the right kind of body
	if body is Num:
		print(slot_name + ": Num entered, value: ", body.num_value)
		
		# Update slot position each time to ensure it's current
		slot_position = global_position
		print(slot_name + ": Updated slot position to: ", slot_position)
		
		# If there's already a num in the slot
		if current_num != null and current_num != body:
			# Send the current num back to its original position in the thinking path
			release_current_num()
		
		# Set the new num as the current num
		current_num = body
		
		# Always set the current_slot reference so we know where to position 
		# when dragging ends
		body.current_slot = self
		
		# Only position the num and set in_slot flag if the player is not currently dragging
		if not body.dragging:
			# Position the num at the slot position
			body.global_position = slot_position
			print(slot_name + ": Positioning num at: ", slot_position)
			
			# Mark the num as being in a slot
			body.in_slot = true
			
			# Emit signal with the new value
			emit_signal("num_value_changed", body.num_value)

func _on_operand_slot_body_exited(body: Node3D) -> void:
	if body is Num and body == current_num:
		print(slot_name + ": Num exit, value: ", body.num_value)
		
		# If the num is being dragged out
		if body.dragging:
			print(slot_name + ": Num being dragged out")
			# When dragged out, immediately mark as no longer in the slot
			body.in_slot = false
			
			# Clear the current_num reference if we're dragging out
			current_num = null
			
			# Keep current_slot reference on the body temporarily
			# It will be cleared if the user releases the num outside any slot
			
			# Emit signal with value 0 (empty) as the slot is now empty
			emit_signal("num_value_changed", 0)
		else:
			# If not dragging and exiting, fully disconnect from the slot
			current_num = null
			body.in_slot = false
			body.current_slot = null
			
			# Emit signal with value 0 (empty)
			emit_signal("num_value_changed", 0)

func release_current_num() -> void:
	if current_num != null:
		print(slot_name + ": Releasing num: ", current_num.num_value)
		var released_num = current_num
		
		# Clear the slot first to avoid potential recursion issues
		current_num = null
		
		# Mark as no longer in a slot
		released_num.in_slot = false
		released_num.current_slot = null
		
		# Return to its position based on thinking mode
		var player = get_tree().get_first_node_in_group("Player")
		if player and NumManager.collected_nums.has(released_num):
			# Find its index in the collected_nums array
			var index = NumManager.collected_nums.find(released_num)
			
			if Global.is_thinking:
				# Return to thinking position
				if index >= 0 and index < player.thinking_path_points.size():
					released_num.target_position = player.thinking_path_points[index]
					print(slot_name + ": Returning num to thinking path position: ", player.thinking_path_points[index])
			else:
				# Return to following position
				if index >= 0 and index < player.path_points.size():
					var path_index = player.path_points.size() - 1 - index
					released_num.target_position = player.path_points[path_index]
					print(slot_name + ": Returning num to following position: ", player.path_points[path_index])
		
		# Emit signal with value 0 (empty)
		emit_signal("num_value_changed", 0)
		
# Public method to get the current value
func get_value() -> int:
	if current_num != null:
		return current_num.num_value
	return 0
	
# Handle thinking mode changes
func _on_thinking_mode_changed(is_thinking_now: bool) -> void:
	# If thinking mode turned off, release any nums in slots
	if not is_thinking_now and current_num != null:
		print(slot_name + ": Thinking mode ended, releasing num")
		release_current_num()
