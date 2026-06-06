class_name HandArmComponent
extends Node

signal grabbed(hand: HandArmComponent, grab_position: Vector3, grabbed_node: Node3D)
signal released(hand: HandArmComponent)

@export_category("References")
@export var spring_arm: SpringArm3D
@export var hand_visual: Node3D
@export var hit_area: Area3D
@export var camera: Camera3D

@export_category("Hand")
@export var hand_side: ClimbEnums.HandSide = ClimbEnums.HandSide.LEFT
@export var mouse_button: MouseButton = MOUSE_BUTTON_LEFT
@export var rest_texture: Texture2D
@export var grab_texture: Texture2D

@export_category("Arm Feel")
@export var reach_distance: float = 1.6
@export var extension_speed: float = 10.0
@export var retraction_speed: float = 12.0
@export var hand_follow_speed: float = 20.0

@export_category("Debug")
@export var debug_enabled: bool = false

var state: ClimbEnums.HandState = ClimbEnums.HandState.IDLE
var lock_position: Vector3 = Vector3.ZERO
var locked_body: Node3D

var _candidate_body: Node3D
var _rest_local_position: Vector3 = Vector3.ZERO
var _target_length: float = 0.0


func _ready() -> void:
	if hand_visual != null:
		_rest_local_position = hand_visual.position
	if hit_area != null:
		hit_area.monitoring = false
		hit_area.body_entered.connect(_on_hit_area_body_entered)
		hit_area.body_exited.connect(_on_hit_area_body_exited)
		hit_area.area_entered.connect(_on_hit_area_area_entered)
		hit_area.area_exited.connect(_on_hit_area_area_exited)
	if spring_arm != null:
		spring_arm.spring_length = 0.0


func update_hand(delta: float) -> void:
	var pressed: bool = Input.is_mouse_button_pressed(mouse_button)

	if pressed:
		if state == ClimbEnums.HandState.IDLE or state == ClimbEnums.HandState.RETRACTING:
			state = ClimbEnums.HandState.REACHING
			_set_area_monitoring(true)
		if state == ClimbEnums.HandState.REACHING:
			_target_length = reach_distance
			_try_lock_to_climbable()
	else:
		if state == ClimbEnums.HandState.LOCKED:
			_unlock()
		if state != ClimbEnums.HandState.IDLE:
			state = ClimbEnums.HandState.RETRACTING
		_target_length = 0.0

	_update_arm_length(delta)
	_update_hand_visual(delta)

	if state == ClimbEnums.HandState.RETRACTING and spring_arm != null and spring_arm.spring_length <= 0.02:
		state = ClimbEnums.HandState.IDLE
		_set_area_monitoring(false)


func is_locked() -> bool:
	return state == ClimbEnums.HandState.LOCKED


func is_reaching() -> bool:
	return state == ClimbEnums.HandState.REACHING


func get_lock_position() -> Vector3:
	return lock_position


func force_release() -> void:
	if is_locked():
		_unlock()
	state = ClimbEnums.HandState.RETRACTING


func _update_arm_length(delta: float) -> void:
	if spring_arm == null:
		return
	var speed: float = extension_speed if _target_length > spring_arm.spring_length else retraction_speed
	
	spring_arm.spring_length = lerpf(spring_arm.spring_length, _target_length, speed * delta)


func _update_hand_visual(delta: float) -> void:
	if hand_visual == null:
		return

	if is_locked():
		hand_visual.global_position = lock_position
		return

	if hit_area != null and state == ClimbEnums.HandState.REACHING:
		hand_visual.global_position = hand_visual.global_position.lerp(
			hit_area.global_position,
			ClimbEnums.damped_weight(delta, hand_follow_speed)
		)
	else:
		hand_visual.position = hand_visual.position.lerp(
			_rest_local_position,
			ClimbEnums.damped_weight(delta, hand_follow_speed)
		)


func _try_lock_to_climbable() -> void:
	if _candidate_body == null or not ClimbEnums.is_climbable(_candidate_body):
		return

	var grab_position: Vector3 = _get_precise_grab_position(_candidate_body)
	state = ClimbEnums.HandState.LOCKED
	lock_position = grab_position
	locked_body = _candidate_body
	_target_length = spring_arm.spring_length if spring_arm != null else reach_distance

	if hand_visual is Sprite3D:
		var sprite: Sprite3D = hand_visual as Sprite3D
		if grab_texture != null:
			sprite.texture = grab_texture
		sprite.no_depth_test = true

	grabbed.emit(self, lock_position, locked_body)
	if debug_enabled:
		print(_debug_name(), " grabbed ", locked_body.name, " at ", lock_position)


func _unlock() -> void:
	if hand_visual is Sprite3D:
		var sprite: Sprite3D = hand_visual as Sprite3D
		if rest_texture != null:
			sprite.texture = rest_texture
		sprite.no_depth_test = false

	if debug_enabled:
		print(_debug_name(), " released")

	locked_body = null
	lock_position = Vector3.ZERO
	released.emit(self)


func _get_precise_grab_position(body: Node3D) -> Vector3:
	#if camera == null:
		#return hit_area.global_position if hit_area != null else global_position

	var space_state: PhysicsDirectSpaceState3D = camera.get_world_3d().direct_space_state
	var from: Vector3 = camera.global_position
	var to: Vector3 = from + (-camera.global_transform.basis.z.normalized() * reach_distance)
	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.collide_with_areas = true
	query.collide_with_bodies = true

	var result: Dictionary = space_state.intersect_ray(query)
	if result.has("collider") and result["collider"] == body:
		return result["position"] as Vector3

	return hit_area.global_position if hit_area != null else body.global_position


func _set_area_monitoring(enabled: bool) -> void:
	if hit_area != null:
		hit_area.monitoring = enabled


func _on_hit_area_body_entered(body: Node3D) -> void:
	if ClimbEnums.is_climbable(body):
		_candidate_body = body
		if debug_enabled:
			print(_debug_name(), " found climbable body: ", body.name)


func _on_hit_area_body_exited(body: Node3D) -> void:
	if body == _candidate_body and not is_locked():
		_candidate_body = null


func _on_hit_area_area_entered(area: Area3D) -> void:
	if ClimbEnums.is_climbable(area):
		_candidate_body = area
		if debug_enabled:
			print(_debug_name(), " found climbable area: ", area.name)


func _on_hit_area_area_exited(area: Area3D) -> void:
	if area == _candidate_body and not is_locked():
		_candidate_body = null


func _debug_name() -> String:
	return "LeftHand" if hand_side == ClimbEnums.HandSide.LEFT else "RightHand"
