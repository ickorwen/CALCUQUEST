extends Node

const NUM_SPRITES = [
	preload("res://assets/NUM0.png"),
	preload("res://assets/NUM1.png"),
	preload("res://assets/NUM2.png"),
	preload("res://assets/NUM3.png"),
	preload("res://assets/NUM4.png"),
	preload("res://assets/NUM5.png"),
	preload("res://assets/NUM6.png"),
	preload("res://assets/NUM7.png"),
	preload("res://assets/NUM8.png"),
	preload("res://assets/NUM9.png"),
]

signal thinking_mode_changed(is_thinking_now)

var is_thinking : bool = false
var think_cam : PhantomCamera3D

func _ready() -> void:
	# Use a timer to delay getting the camera reference to ensure scene is fully loaded
	var timer = Timer.new()
	timer.wait_time = 0.5  # Half a second delay to ensure scene is loaded
	timer.one_shot = true
	timer.timeout.connect(_init_think_cam)
	add_child(timer)
	timer.start()

func _init_think_cam() -> void:
	# First approach: try to find any Node called ThinkCam (most reliable)
	think_cam = find_node_by_name(get_tree().root, "ThinkCam")
	
	# Second approach: Check the scene tree directly for nodes with ThinkCam in the name
	if not think_cam:
		var node_list = get_tree().get_nodes_in_group("phantom_cameras")
		for node in node_list:
			if "ThinkCam" in node.name:
				think_cam = node
				break
	
	# Final attempt - look specifically in the current_level
	if not think_cam:
		var current_level = get_tree().get_nodes_in_group("current_level")
		if current_level.size() > 0:
			var potential_cam = current_level[0].find_child("ThinkCam", true, false)
			if potential_cam:
				think_cam = potential_cam
	
	# Call continuation function to check results
	_continue_init_think_cam()

# Helper function to find a node by name and class type in the tree
func find_node_by_name_and_type(root_node: Node, node_name: String, node_class: String) -> Node:
	if root_node.name == node_name and root_node.is_class(node_class):
		return root_node
	
	for child in root_node.get_children():
		var found = find_node_by_name_and_type(child, node_name, node_class)
		if found:
			return found
	
	return null

# Helper function to find a node by name in the tree
func find_node_by_name(root_node: Node, node_name: String) -> Node:
	if root_node.name == node_name:
		return root_node
	
	for child in root_node.get_children():
		var found = find_node_by_name(child, node_name)
		if found:
			return found
	
	return null

func _continue_init_think_cam() -> void:
	if think_cam:
		print("ThinkCam initialized successfully")
	else:
		print("WARNING: ThinkCam not found, thinking mode will be disabled")

func think():
	# Check if we need to search for the camera again (might have happened after scene reload)
	if not think_cam or not is_instance_valid(think_cam):
		_init_think_cam()
	
	# Safety check to prevent crashes
	if not think_cam or not is_instance_valid(think_cam):
		print("Cannot enter thinking mode: ThinkCam not found")
		return
	
	# Toggle thinking mode
	Global.is_thinking = !Global.is_thinking
	
	# Emit signal when thinking mode changes
	thinking_mode_changed.emit(is_thinking)
	
	# Try to set camera priority safely
	if is_thinking:
		# Check if the camera has a set_priority method (PhantomCamera3D)
		if think_cam.has_method("set_priority"):
			think_cam.set_priority(2)
		# Otherwise, try to enable it through other means
		else:
			# Enable the camera - assume it's a regular Camera3D if not a PhantomCamera3D
			if think_cam.has_method("make_current"):
				think_cam.make_current()
			elif think_cam is Node3D and think_cam.has_node("Camera3D"):
				think_cam.get_node("Camera3D").make_current()
	else:
		if think_cam.has_method("set_priority"):
			think_cam.set_priority(0)
		# If not a PhantomCamera, we don't need to explicitly disable it
	
	
	# Update Num positions when thinking mode changes
	if get_node_or_null("/root/NumManager") != null:
		NumManager.update_num_positions()
