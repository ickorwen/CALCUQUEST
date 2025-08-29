extends StaticBody3D
class_name ConditionedObject

@export var condition_value : Condition = Condition.EQUAL
@export var target_value: int = 10

enum Condition { EQUAL, GREATER, LESS, GREATEREQUAL, LESSEREQUAL }

func condition_check(body: Num) -> bool:
	var num = body.num_value
		
	match condition_value:
		Condition.EQUAL:
			return num == target_value
		Condition.GREATER:
			return num > target_value
		Condition.LESS:
			return num < target_value
		Condition.GREATEREQUAL:
			return num >= target_value
		Condition.LESSEREQUAL:
			return num <= target_value
		_:
			return false
