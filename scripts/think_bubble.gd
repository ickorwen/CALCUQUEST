extends StaticBody3D

@onready var operator: Label3D = $Thought/Operator
var addition: bool = true
var result: int = 0
@onready var operand_slot: OperandSlot = $OperandSlot
@onready var operand_slot_2: OperandSlot = $OperandSlot2
@onready var thought: Sprite3D = $Thought

# Called when the node enters the scene tree
func _ready() -> void:
	update_visibility()
	# Initialize the operator display
	if addition:
		operator.text = "+"
	else:
		operator.text = "-"

func _process(_delta: float) -> void:
	# Update operator display
	if addition:
		operator.text = "+"
	else:
		operator.text = "-"
	

func solve() -> void:
	# Check if both slots have nums
	if operand_slot.current_num == null or operand_slot_2.current_num == null:
		print("Cannot solve: both slots need to have numbers")
		return
		
	# Get the values and calculate the result
	var num1 = operand_slot.current_num.num_value
	var num2 = operand_slot_2.current_num.num_value
	
	if addition:
		result = num1 + num2
	else:
		result = num1 - num2
	
	# Only spawn if result is within valid range
	if result >= 0 and result <= 9:
		# Spawn slightly in front of the think bubble to avoid collision
		var spawn_position = operator.global_position + Vector3(0, 0, -0.5)
		# Spawn the new num with the result
		NumManager.spawn_num(spawn_position, result)
		print("Spawned new Num with value: " + str(result) + " at " + str(spawn_position))
		despawn_nums()
		Global.think()
		# Update positions of remaining nums
		NumManager.update_num_positions()
		# Emit signal to update any UI elements
		NumManager.nums_updated.emit()
		
	else:
		print("Result " + str(result) + " is outside valid range (0-9)")
		
	update_visibility()

func despawn_nums():
			# Despawn (remove) the nums that were used in the calculation
		if operand_slot.current_num != null:
			# Store reference before clearing the slot
			var num_to_remove1 = operand_slot.current_num
			# Remove from slots first
			operand_slot.current_num = null
			num_to_remove1.current_slot = null
			num_to_remove1.in_slot = false
			# Remove from collected nums
			if NumManager.collected_nums.has(num_to_remove1):
				NumManager.collected_nums.erase(num_to_remove1)
			# Queue free to delete the node
			num_to_remove1.queue_free()
		if operand_slot_2.current_num != null:
			# Store reference before clearing the slot
			var num_to_remove2 = operand_slot_2.current_num
			# Remove from slots first
			operand_slot_2.current_num = null
			num_to_remove2.current_slot = null
			num_to_remove2.in_slot = false
			# Remove from collected nums
			if NumManager.collected_nums.has(num_to_remove2):
				NumManager.collected_nums.erase(num_to_remove2)
			
			# Queue free to delete the node
			num_to_remove2.queue_free()

func update_visibility():
	visible = Global.is_thinking
	
	var collision_shapes = find_children("*", "CollisionShape3D", true)
	for shape : CollisionShape3D in collision_shapes:
		shape.disabled = !Global.is_thinking

func _on_plus_nipple_input_event(_camera: Node, event: InputEvent, _event_position: Vector3, _normal: Vector3, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		print("Clicked Area3D via input_event: plus")
		addition = true

func _on_minus_nipple_input_event(_camera: Node, event: InputEvent, _event_position: Vector3, _normal: Vector3, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		print("Clicked Area3D via input_event: minus")
		addition = false

func _on_solve_button_input_event(_camera: Node, event: InputEvent, _event_position: Vector3, _normal: Vector3, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		solve()
