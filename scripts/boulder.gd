extends ConditionedObject


@onready var label_3d: Label3D = $Label3D
@onready var highlight: Sprite3D = $Sprite3D/Highlight
var current_num: Num = null
@onready var boulder_animation: AnimationPlayer = $BoulderAnimation

func _ready() -> void:
	# Make sure highlight is hidden initially
	highlight.hide()

func _process(_delta: float) -> void:
	# Check if we have a num and if it's still being dragged
	if current_num != null:
		if current_num.dragging:
			# Num is being dragged over us
			highlight.show()
		else:
			# Num was released over us
			if condition_check(current_num):
				_on_num_released(current_num)
			
			# Reset after processing
			highlight.hide()
			current_num = null

func _on_area_3d_body_entered(body: Node3D) -> void:
	print("Body entered: ", body.name, " (", body.get_class(), ")")
	
	if body.name == "Player":
		label_3d.visible = true
		print("Player entered tree area")
	
	if body is Num:
		# Store reference to the num
		current_num = body
		print("Num entered tree area: value=", current_num.num_value)
		
		# Check if it's being dragged
		if body.dragging:
			highlight.show()

func _on_area_3d_body_exited(body: Node3D) -> void:
	# Check for player first
	if body.name == "Player":
		label_3d.visible = false
		print("Player exited tree area")
	
	# Then check for Num
	elif body is Num and body == current_num:
		highlight.hide()
		current_num = null
		print("Num exited tree area")

# This is called when a num is released over the object
func _on_num_released(num: Num) -> void:
	# Execute the object's reaction
	boulder_animation.play("COLLAPSE")
	
	# Remove the num from NumManager's collection and queue_free it
	var num_manager = get_node("/root/NumManager")
	if num_manager and num_manager.has_method("remove_num"):
		num_manager.remove_num(num)
	else:
		# If no remove_num method exists, remove it from collected_nums array directly
		if num_manager and "collected_nums" in num_manager:
			num_manager.collected_nums.erase(num)
			num_manager.nums_updated.emit()
			
	# Queue free the num
	num.queue_free()


func _on_boulder_animation_animation_finished(anim_name: StringName) -> void:
	if anim_name == "COLLAPSE":
		queue_free()
