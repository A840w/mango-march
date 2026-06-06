class_name ClimbEnums
extends RefCounted

enum HandSide {
	LEFT,
	RIGHT,
}

enum HandState {
	IDLE,
	REACHING,
	LOCKED,
	RETRACTING,
}

const CLIMBABLE_GROUPS: PackedStringArray = [
	"ClimbableTree",
	"ClimbableBranch",
]


static func is_climbable(node: Node) -> bool:
	if node == null:
		return false
	for group_name: String in CLIMBABLE_GROUPS:
		if node.is_in_group(group_name):
			return true
	return false


static func damped_weight(delta: float, sharpness: float) -> float:
	return 1.0 - exp(-sharpness * delta)
