extends CharacterBody3D
class_name Player

const SPEED = 5.0
const JUMP_VELOCITY = 4.5

@export var mouse_capture: MouseCaptureComponent
@export var camera: Camera3D

func _ready() -> void:
	# Create and add the mouse capture component if not assigned
	if not mouse_capture:
		mouse_capture = MouseCaptureComponent.new()
		add_child(mouse_capture)
	
	# Set up the camera reference
	_find_or_create_camera()


func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir := Input.get_vector("left", "right", "up", "down")
	
	# Transform direction relative to player's rotation (now including Y rotation from mouse look)
	var forward := -transform.basis.z
	var right := transform.basis.x
	
	var direction := (forward * input_dir.y + right * input_dir.x).normalized()
	
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	move_and_slide()


func _find_or_create_camera() -> void:
	# Try to find existing camera
	for child in get_children():
		if child is Camera3D:
			mouse_capture.camera = child
			return
	
	# Create a camera if none exists
	var new_camera := Camera3D.new()
	new_camera.current = true
	add_child(new_camera)
	mouse_capture.camera = new_camera
	
	# Position camera at head height (adjust as needed)
	new_camera.position.y = 1.5