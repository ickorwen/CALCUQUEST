extends Node
signal num_collected(num_value)
signal nums_updated()
const NUM = preload("res://num.tscn")
@export var max_collected_nums: int = 5
var collected_nums: Array[Num] = []
var player: Node3D

func _ready() -> void:
	# Clear any leftover data from previous sessions
	collected_nums.clear()
	
	# Use call_deferred to ensure the scene tree is fully loaded
	call_deferred("_setup_player_reference")

func _setup_player_reference() -> void:
	player = get_tree().get_first_node_in_group("Player")
	if not player:
		print("Warning: Player not found in scene tree")

func collect_num(num_node) -> void:
	# Validate num_node first
	if not is_instance_valid(num_node):
		print("Error: Invalid num_node passed to collect_num")
		return
		
	if collected_nums.has(num_node):
		return
	
	# Get fresh player reference if needed
	if not is_instance_valid(player):
		player = get_tree().get_first_node_in_group("Player")
		if not player:
			print("Error: Player not found!")
			return
	
	if collected_nums.size() < max_collected_nums:
		collected_nums.append(num_node)
		
		# Check if num_node has the collect method before calling it
		if num_node.has_method("collect"):
			# Make sure the num_node is still valid right before the call
			if is_instance_valid(num_node) and is_instance_valid(player):
				num_node.collect(player)
			else:
				print("Error: num_node or player became invalid")
				# Remove from collected_nums if it became invalid
				collected_nums.erase(num_node)
				return
		else:
			print("Error: num_node missing collect method")
			collected_nums.erase(num_node)
			return
			
		num_collected.emit(num_node.num_value)
		nums_updated.emit()
		print("Collected Num ", num_node.num_value, " (total: ", collected_nums.size(), ")")
		update_num_positions()
	else:
		print("Max Nums reached, can't collect more.")

func update_num_positions() -> void:
	if not is_instance_valid(player):
		return
		
	# Clean up any invalid collected_nums
	collected_nums = collected_nums.filter(func(num): return is_instance_valid(num))
	
	# Sort by num_value
	collected_nums.sort_custom(func(a, b): return a.num_value < b.num_value)
	
	# Use different path points based on thinking mode
	if Global.is_thinking:
		# In thinking mode, use the thinking_path_points
		for i in range(min(collected_nums.size(), player.thinking_path_points.size())):
			var num = collected_nums[i]
			if is_instance_valid(num):
				num.target_position = player.thinking_path_points[i]
	else:
		# In regular mode, use the regular path_points
		for i in range(min(collected_nums.size(), player.path_points.size())):
			var num = collected_nums[i]
			if is_instance_valid(num):
				var path_index = player.path_points.size() - 1 - i
				num.target_position = player.path_points[path_index]

func spawn_num(position : Vector3, value: int):
	var num = NUM.instantiate()
	num.num_value = value
	num.global_position = position
	
	# Find the main game node using a more robust approach
	var main_scene = get_tree().get_first_node_in_group("current_level")
	if not main_scene:
		# Fallback: try to find the main scene by searching through the root's children
		var root = get_tree().root
		for i in range(root.get_child_count()):
			var node = root.get_child(i)
			if node.get_class() == "Node3D" and node != self:
				main_scene = node
				break
	
	if main_scene:
		main_scene.add_child(num)
	else:
		# Last resort: add to the root
		get_tree().root.add_child(num)
		print("WARNING: Added num directly to root node as main scene wasn't found")

# Add cleanup function for scene changes
func _exit_tree() -> void:
	# Clear collected nums when the scene is being destroyed
	for num in collected_nums:
		if is_instance_valid(num):
			num.queue_free()
	collected_nums.clear()
	player = null

# Optional: Add this if NumManager is an autoload/singleton
func reset_manager() -> void:
	# Call this when restarting the game
	for num in collected_nums:
		if is_instance_valid(num):
			num.queue_free()
	collected_nums.clear()
	player = null
	call_deferred("_setup_player_reference")
