extends CharacterBody3D


@export_category("node refrences")
@export var camera_pivot : Node3D
@export var camera : Camera3D
@export var ground_cast : RayCast3D
@export_group("Hands")
@export var arm_pivot : Node3D
@export_subgroup("Left Hand")
@export var left_arm : SpringArm3D
@export var left_hand : Sprite3D
@export var left_hand_collison : CollisionShape3D
@export_subgroup("Right Hand")
@export var right_arm : SpringArm3D
@export var right_hand : Sprite3D
@export var right_hand_collison : CollisionShape3D



const SPEED = 5.0
const JUMP_VELOCITY = 4.5


func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	move_and_slide()
# moving scripts