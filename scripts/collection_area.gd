extends Area3D

func _on_body_entered(body: Node3D) -> void:
	# Check if the body is a Num
	if body.is_in_group("Num") and not body.is_collected:
		if not body.is_collected:
			print("Collecting Num with value: ", body.num_value)
			if NumManager:
				NumManager.collect_num(body)
			else:
				# Direct collection if no manager
				body.collect()
