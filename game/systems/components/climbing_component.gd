class_name ClimbingComponent
extends Node

@export_category("References")
@export var player: PlayerController
@export var camera: Camera3D
@export var left_hand: HandArmComponent
@export var right_hand: HandArmComponent

@export_category("Climbing Feel")
@export var climb_speed: float = 4.0
@export var anchor_pull_strength: float = 5.0
@export var max_anchor_pull_speed: float = 3.5
@export var camera_influence_strength: float = 2.25
@export var one_hand_gravity_sink: float = 0.35
@export var two_hand_vertical_speed: float = 2.2
@export var velocity_smoothing: float = 9.0
@export var comfortable_anchor_distance: float = 1.05

@export_category("Debug")
@export var debug_enabled: bool = false

var _climb_velocity: Vector3 = Vector3.ZERO
var _anchor: Vector3 = Vector3.ZERO


func _ready() -> void:
	if player == null:
		player = owner as PlayerController
	if camera == null and player != null:
		camera = player.camera

	if left_hand != null:
		left_hand.grabbed.connect(_on_hand_grabbed)
		left_hand.released.connect(_on_hand_released)
	if right_hand != null:
		right_hand.grabbed.connect(_on_hand_grabbed)
		right_hand.released.connect(_on_hand_released)


func update_climbing(delta: float) -> void:
	if left_hand != null:
		left_hand.update_hand(delta)
	if right_hand != null:
		right_hand.update_hand(delta)

	var target_velocity: Vector3 = _calculate_target_velocity()
	_climb_velocity = _climb_velocity.lerp(
		target_velocity,
		ClimbEnums.damped_weight(delta, velocity_smoothing)
	)

	if debug_enabled and get_attached_hand_count() > 0 and Engine.get_physics_frames() % 20 == 0:
		print("Climb anchor: ", _anchor, " target velocity: ", target_velocity)


func get_climb_velocity() -> Vector3:
	return _climb_velocity


func get_attached_hand_count() -> int:
	var count: int = 0
	if left_hand != null and left_hand.is_locked():
		count += 1
	if right_hand != null and right_hand.is_locked():
		count += 1
	return count


func has_any_hand_attached() -> bool:
	return get_attached_hand_count() > 0


func get_anchor_position() -> Vector3:
	return _anchor


func get_locked_hand_positions() -> Array[Vector3]:
	var positions: Array[Vector3] = []
	if left_hand != null and left_hand.is_locked():
		positions.append(left_hand.get_lock_position())
	if right_hand != null and right_hand.is_locked():
		positions.append(right_hand.get_lock_position())
	return positions


func _calculate_target_velocity() -> Vector3:
	if player == null:
		return Vector3.ZERO

	var locked_positions: Array[Vector3] = get_locked_hand_positions()
	if locked_positions.is_empty():
		_anchor = Vector3.ZERO
		return Vector3.ZERO

	_anchor = _average_positions(locked_positions)

	var chest_position: Vector3 = player.global_position + Vector3.UP * comfortable_anchor_distance
	var anchor_delta: Vector3 = _anchor - chest_position
	var distance_error: float = maxf(anchor_delta.length() - comfortable_anchor_distance, 0.0)
	var anchor_pull: Vector3 = Vector3.ZERO
	if anchor_delta.length_squared() > 0.0001:
		anchor_pull = anchor_delta.normalized() * minf(distance_error * anchor_pull_strength, max_anchor_pull_speed)

	var camera_forward: Vector3 = player.get_camera_forward()
	var look_pull: Vector3 = camera_forward * camera_influence_strength
	look_pull.y += player.get_camera_pitch_ratio() * two_hand_vertical_speed

	if locked_positions.size() == 1:
		look_pull *= 0.45
		look_pull.y -= one_hand_gravity_sink

	return (anchor_pull + look_pull).limit_length(climb_speed)


func _average_positions(positions: Array[Vector3]) -> Vector3:
	var total: Vector3 = Vector3.ZERO
	for position: Vector3 in positions:
		total += position
	return total / float(positions.size())


func _on_hand_grabbed(hand: HandArmComponent, grab_position: Vector3, _grabbed_node: Node3D) -> void:
	if debug_enabled:
		print("ClimbingComponent registered grab from ", hand.name, " at ", grab_position)


func _on_hand_released(hand: HandArmComponent) -> void:
	if debug_enabled:
		print("ClimbingComponent registered release from ", hand.name)
