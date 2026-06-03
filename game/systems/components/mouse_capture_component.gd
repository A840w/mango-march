@icon("uid://dwgvwhhl34vm")
extends Node
class_name MouseCaptureComponent

@export var mouse_sensitivity: float = 0.002
@export var invert_y: bool = false

var camera: Camera3D
var is_mouse_captured: bool = false


func _ready() -> void:
	# Find the camera in the player's children or get it from the parent
	_find_camera()


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if not is_mouse_captured:
			capture_mouse()
	
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		if is_mouse_captured:
			release_mouse()
	
	if event is InputEventMouseMotion and is_mouse_captured:
		_handle_mouse_look(event.relative)


func capture_mouse() -> void:
	is_mouse_captured = true
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func release_mouse() -> void:
	is_mouse_captured = false
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)


func _handle_mouse_look(relative: Vector2) -> void:
	if not camera:
		_find_camera()
		return
	
	# Apply mouse sensitivity
	var yaw: float = -relative.x * mouse_sensitivity
	var pitch: float = -relative.y * mouse_sensitivity
	
	if invert_y:
		pitch = -pitch
	
	# Rotate the player horizontally (Y axis)
	(get_parent() as Node3D).rotate_y(yaw)
	
	# Rotate the camera vertically (X axis)
	var current_rotation: Vector3 = camera.rotation_degrees
	current_rotation.x += rad_to_deg(pitch)
	
	# Clamp vertical rotation to prevent over-rotation
	current_rotation.x = clamp(current_rotation.x, -90.0, 90.0)
	
	camera.rotation_degrees = current_rotation


func _find_camera() -> void:
	# First try to find camera as child of the player
	if get_parent() is Node3D:
		for child in get_parent().get_children():
			if child is Camera3D:
				camera = child
				break
	
	# If no camera found, try to get the current camera from the viewport
	if not camera and get_viewport():
		camera = get_viewport().get_camera_3d()
