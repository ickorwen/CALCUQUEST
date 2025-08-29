extends Node

signal num_collected(num_value)
signal nums_updated()

const NUM = preload("res://num.tscn")
@export var max_collected_nums: int = 5
var collected_nums: Array[Num] = []
var player: Node3D


func _ready() -> void:
	player = get_tree().get_first_node_in_group("Player")

func collect_num(num_node) -> void:
	if collected_nums.has(num_node):
		return

	if collected_nums.size() < max_collected_nums:
		collected_nums.append(num_node)
		num_node.collect(player)
		num_collected.emit(num_node.num_value)
		nums_updated.emit()
		print("Collected Num ", num_node.num_value, " (total: ", collected_nums.size(), ")")
		update_num_positions()
	else:
		print("Max Nums reached, can’t collect more.")

func update_num_positions() -> void:
	if not player:
		return
	# Sort by num_value
	collected_nums.sort_custom(func(a, b): return a.num_value < b.num_value)
	
	# Use different path points based on thinking mode
	if Global.is_thinking:
		# In thinking mode, use the thinking_path_points
		for i in range(min(collected_nums.size(), player.thinking_path_points.size())):
			var num = collected_nums[i]
			num.target_position = player.thinking_path_points[i]
	else:
		# In regular mode, use the regular path_points
		for i in range(min(collected_nums.size(), player.path_points.size())):
			var num = collected_nums[i]
			var path_index = player.path_points.size() - 1 - i
			num.target_position = player.path_points[path_index]

func spawn_num(position : Vector3, value: int):
	var num = NUM.instantiate()
	num.num_value = value
	num.global_position = position
	get_node("../Demo").add_child(num)
