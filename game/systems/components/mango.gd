extends StaticBody3D

@export var score_value := 1

func pickup():
	# Optional: update score
	#GameManager.mango_count += score_value

	# Remove mango from scene
	get_parent().queue_free()