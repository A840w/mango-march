class_name Player
extends CharacterBody3D

@export_category("Nodes")
@export_group("reference nodes")
@export var camera_pivot: Node3D 
@export var camera: Camera3D 
@export var left_arm: SpringArm3D 
@export var right_arm: SpringArm3D 
@export var left_hand: Sprite3D  
@export var right_hand: Sprite3D 
@export var left_hand_collision: Area3D 
@export var right_hand_collision: Area3D 
@export var arm_pivot: Node3D
@export var climb_pivot: Marker3D
@export var ground_cast: RayCast3D
@export_group("MISC nodes")
@export var view_raycast: RayCast3D
@export var footstep_sound: AudioStreamPlayer3D
@export var falling_wind_sound: AudioStreamPlayer
@export var grab_clang_sound_left: AudioStreamPlayer3D
@export var grab_clang_sound_right: AudioStreamPlayer3D
@export var DeathSound: AudioStreamPlayer

@export_category("UI")
@export var ui: CanvasLayer
@export var HAND: Texture2D
@export var HAND_GRAB: Texture2D
@export var HAND_GRAB_VERTICAL : Texture2D
@export var left_box: ColorRect
@export var right_box: ColorRect
@export var l_hand_icon: Label
@export var r_hand_icon: Label


enum Hands{LEFT, RIGHT}

var speed
const WALK_SPEED = 3.0
const JUMP_VELOCITY = 4.5
const SENSITIVITY = 0.003


const BOB_FREQ = 2.0
const BOB_AMP = 0.08
var bob_time = 0.0


const BASE_FOV = 70.0
const FOV_CHANGE = 1.5

const MAX_ARM_LENGTH = 1.26
var left_hand_active: = false
var right_hand_active: = false
var left_hand_locked: = false
var right_hand_locked: = false
var left_hand_lock_pos: Vector3
var right_hand_lock_pos: Vector3
var keep_holding_left_hand: = false
var keep_holding_right_hand: = false



const CLIMB_SPEED: = 1.0
var has_lost_grip: = false
var default_climb_pivot_pos: = Vector3.ZERO
const CLIMB_PIVOT_OFFSET: = Vector3(0.0, 0.6, 0.0)
const CLIMB_HAND_DISTANCE_OFFSET: = Vector3(0.0, 0.0, 0.6)


var falling_sound_playing: = false

var gravity = 9.8
var is_falling: = false

var PAUSED_TEMP: = false



var icon_unused_color: = Color(1, 1, 1, 0.25)
var icon_used_color: = Color(1, 1, 1, 0.7)


var saved_view_collision

var can_control_at_all: = true:
	set(value):
		can_control_at_all = value
		if value: ui.show()
		else: ui.hide()


const DEATH_VELOCITY_THRESHOLD: = 11.0
var hand_shake_time: = 0.0
var death_fall: = false
var did_die: = false


var reload_position
var reload_pivot_rotation
var reload_camera_rotation
var reload_harness_position: = Vector3.ZERO


var unable_to_hold_hands: = false

var accepting_pause: = false

var was_on_floor: = false
@export var on_floor_grace_timer: Timer



func initialize():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	M
	

	ui.show()
	camera.current = true
	can_control_at_all = true
	default_climb_pivot_pos = climb_pivot.position

	on_floor_grace_timer.timeout.connect( func(): was_on_floor = false)

func _input(event: InputEvent) -> void :
	if event is InputEventMouseMotion and can_control_at_all != false:
		camera_pivot.rotate_y( - event.relative.x * SENSITIVITY)

		if left_hand_locked and right_hand_locked:
			camera_pivot.rotation.y = clamp(camera_pivot.rotation.y, deg_to_rad(-85), deg_to_rad(85))
		elif left_hand_locked and not right_hand_locked:
			camera_pivot.rotation.y = clamp(camera_pivot.rotation.y, deg_to_rad(-165), deg_to_rad(85))
		elif not left_hand_locked and right_hand_locked:
			camera_pivot.rotation.y = clamp(camera_pivot.rotation.y, deg_to_rad(-85), deg_to_rad(165))

		left_box.visible = (rad_to_deg(camera_pivot.rotation.y) >= 84.0 and left_hand_locked)
		right_box.visible = (rad_to_deg(camera_pivot.rotation.y) <= -84.0 and right_hand_locked)


		camera.rotate_x( - event.relative.y * SENSITIVITY)
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-85), deg_to_rad(85))

	if event.is_action_pressed("pause") and accepting_pause:
		keep_holding_left_hand = left_hand_locked
		keep_holding_right_hand = right_hand_locked
		# pause_game.emit()

func _physics_process(delta: float) -> void :


	if not is_on_floor() and not (left_hand_locked or right_hand_locked):

		velocity.y -= (gravity * delta)

	if is_on_floor():
		was_on_floor = true
		on_floor_grace_timer.stop()
	else:
		if on_floor_grace_timer.is_stopped() and was_on_floor:
			on_floor_grace_timer.start()





	speed = WALK_SPEED

	var input_dir: = Input.get_vector("left", "right", "forward", "down")
	var direction: = (camera_pivot.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if can_control_at_all == false:
		input_dir = Vector2.ZERO
	if is_on_floor():
		if global_position.y <= 2.0 and direction.length() >= 0.1:
			if footstep_sound.playing == false:
				footstep_sound.play()
		else:
			footstep_sound.stop()

		has_lost_grip = false
		if direction:
			velocity.x = direction.x * speed
			velocity.z = direction.z * speed
		else:
			velocity.x = lerp(velocity.x, direction.x * speed, delta * 8.0)
			velocity.z = lerp(velocity.z, direction.z * speed, delta * 8.0)
	else:
		# if footstep_sound.playing:
			# footstep_sound.stop()
		velocity.x = lerp(velocity.x, direction.x * speed, delta * 2.0)
		velocity.z = lerp(velocity.z, direction.z * speed, delta * 2.0)

	var velocity_clamped = clamp(velocity.length(), 0.5, WALK_SPEED * 10)
	var target_fov = BASE_FOV + FOV_CHANGE * velocity_clamped
	if is_on_floor():
		camera.fov = lerp(camera.fov, target_fov, delta * 1.0)
	else:
		camera.fov = lerp(camera.fov, target_fov, delta * 0.2)

	handle_arms(delta)
	handle_climbing()

	if not has_lost_grip and not left_hand_locked and not right_hand_locked and not was_on_floor and not ground_cast.is_colliding():
		var fall_direction: = (camera_pivot.transform.basis * Vector3(0.0, -1.0, 1.0)).normalized()
		velocity += (fall_direction * 5.0)
		has_lost_grip = true

	is_falling = velocity.length() > 7.0
	if is_falling:
		if falling_sound_playing == false:
			falling_sound_playing = true
			falling_wind_sound.play()
		falling_wind_sound.volume_db = lerp(falling_wind_sound.volume_db, 10.0, delta)
	else:
		falling_wind_sound.volume_db = -25.0

		falling_wind_sound.stop()
		falling_sound_playing = false


	if velocity.length() > DEATH_VELOCITY_THRESHOLD :
		#EventBus.display_text.emit("", 0.0)
		death_fall = true
		hand_shake_time += delta * velocity.length()
		left_hand.position += hand_shake(hand_shake_time)
		right_hand.position += hand_shake(hand_shake_time)
		ui.hide()

	if is_on_floor() and death_fall and not did_die:
		death()
		print("Player has died from falling.")


	handle_interaction(delta)

	move_and_slide()
	





func handle_climbing():
	if rad_to_deg(camera.rotation.x) < -30:
		climb_pivot.position = default_climb_pivot_pos + CLIMB_PIVOT_OFFSET
	else:
		climb_pivot.position = default_climb_pivot_pos

	var climb_dir: = Vector3.ZERO
	var climb_point: = Vector3.ZERO
	if left_hand_locked and not right_hand_locked:
		climb_point = left_hand_lock_pos
	elif not left_hand_locked and right_hand_locked:
		climb_point = right_hand_lock_pos
	elif left_hand_locked and right_hand_locked:
		climb_point.x = (left_hand_lock_pos.x + right_hand_lock_pos.x) / 2
		climb_point.y = (left_hand_lock_pos.y + right_hand_lock_pos.y) / 2
		climb_point.z = (left_hand_lock_pos.z + right_hand_lock_pos.z) / 2
	if climb_point != Vector3.ZERO:
		climb_point += CLIMB_HAND_DISTANCE_OFFSET
		climb_dir = climb_pivot.global_position.direction_to(climb_point)
		velocity = climb_dir * climb_pivot.global_position.distance_to(climb_point) * 2


func headbob(time, is_harness: bool) -> Vector3:
	var pos: = Vector3.ZERO
	if not is_harness:
		pos.y = sin(time * BOB_FREQ) * BOB_AMP
		pos.x = cos(time * BOB_FREQ / 2) * BOB_AMP
	else:
		pos.y = sin(time * BOB_FREQ / 7) * BOB_AMP / 3
		pos.z = cos(time * BOB_FREQ / 9) * BOB_AMP
		pos.x = cos(time * BOB_FREQ / 8) * BOB_AMP
	return pos

func hand_shake(time) -> Vector3:
	var pos: = Vector3.ZERO
	pos.y = sin(time * BOB_FREQ) * BOB_AMP / 5
	pos.x = cos(time * BOB_FREQ / 2) * BOB_AMP / 5
	pos.z = cos(time * BOB_FREQ) * BOB_AMP / 5
	return pos

func handle_arms(delta: float):
	left_hand.global_position = lerp(left_hand.global_position, left_hand_collision.global_position, delta * 15)
	right_hand.global_position = lerp(right_hand.global_position, right_hand_collision.global_position, delta * 15)

	var is_holding_left = Input.is_action_pressed("LeftHand")
	var is_holding_right = Input.is_action_pressed("RightHand")
	if Input.is_action_pressed("LeftHand") and accepting_pause and keep_holding_left_hand:
		keep_holding_left_hand = false
		left_hand_locked = false

	if Input.is_action_pressed("RightHand") and accepting_pause and keep_holding_right_hand:
		keep_holding_right_hand = false
		right_hand_locked = false



	if can_control_at_all == false or unable_to_hold_hands:
		is_holding_left = false
		is_holding_right = false

	if keep_holding_left_hand: is_holding_left = keep_holding_left_hand
	if keep_holding_right_hand: is_holding_right = keep_holding_right_hand

	handle_individual_hand(Hands.LEFT, is_holding_left, delta)
	handle_individual_hand(Hands.RIGHT, is_holding_right, delta)


func handle_individual_hand(which_hand: Hands, is_held: bool, delta: float):
	var locked
	var lock_pos
	var hand
	var arm
	var icon

	match which_hand:
		Hands.LEFT:
			locked = left_hand_locked
			lock_pos = left_hand_lock_pos
			hand = left_hand
			arm = left_arm
			icon = l_hand_icon
		Hands.RIGHT:
			locked = right_hand_locked
			lock_pos = right_hand_lock_pos
			hand = right_hand
			arm = right_arm
			icon = r_hand_icon

	if is_held:
		match which_hand:
			Hands.LEFT:
				left_hand_active = true
				left_hand_collision.monitoring = true
			Hands.RIGHT:
				right_hand_active = true
				right_hand_collision.monitoring = true
		if locked:
			icon.modulate = icon_used_color
			hand.global_position = lock_pos
		else:
			arm.spring_length = lerp(arm.spring_length, MAX_ARM_LENGTH, delta * 5)
	else:
		match which_hand:
			Hands.LEFT:
				left_hand_locked = false
				left_hand_active = false
				left_hand_collision.monitoring = false

				if left_hand.texture != HAND:
					left_hand.texture = HAND


			Hands.RIGHT:
				right_hand_locked = false
				right_hand_active = false
				right_hand_collision.monitoring = false

				if right_hand.texture != HAND:
					right_hand.texture = HAND




		icon.modulate = icon_unused_color
		arm.spring_length = lerp(arm.spring_length, 0.0, delta * 6)



func handle_interaction(delta: float):
	if view_raycast.is_colliding():
		var collider = view_raycast.get_collider()

		if saved_view_collision != null and collider != saved_view_collision:
			saved_view_collision.in_player_view = false
			saved_view_collision = null

		# if collider is ThreatSightBox:
		#     collider.in_player_view = true
		#     saved_view_collision = collider
		#     return

		if collider != null:
			if "in_player_view" in collider:
				saved_view_collision = collider
				collider.in_player_view = true

			if not left_hand_locked: left_hand.no_depth_test = left_hand_active
			if not right_hand_locked: right_hand.no_depth_test = right_hand_active

			# if collider.has_method("is_interacting"):
			#     if harness.visible:
			#         collider.is_interacting(left_hand_active, right_hand_active, delta)
			#     else:
			#         EventBus.display_text.emit("I should harness myself before I begin the inspection", 3.0)
			# if "night_time" in collider:
			#     if collider.night_time:
			#         EventBus.display_text.emit("My work is done. I should go.", 3.0)

	else:
		if saved_view_collision:
			saved_view_collision.in_player_view = false
			saved_view_collision = null


# func _on_left_hand_collision_body_entered(body: Node3D) -> void :
# 	if left_hand_active and left_hand_locked == false and (body.is_in_group("ClimbableBranch") or body.is_in_group("ClimbableTree")) and velocity.length() < DEATH_VELOCITY_THRESHOLD:

# 		left_hand_locked = true
# 		left_hand_lock_pos = left_hand_collision.global_position


# 		has_lost_grip = false

# 		if body.is_in_group("ClimbableBranch"):
# 			left_hand.texture = HAND_GRAB
# 		if body.is_in_group("ClimbableTree"):
# 			left_hand.texture = HAND_GRAB_VERTICAL

		#grab_clang_sound_left.play()

func death():
	#EventBus.player_death.emit()
	can_control_at_all = false
	did_die = true
	DeathSound.play()
	ui.hide()

func end_game():
	can_control_at_all = false
	camera.current = false
	ui.hide()


func _on_right_handcollison_body_entered(body: Node3D) -> void:
	if right_hand_active and right_hand_locked == false and (body.is_in_group("ClimbableBranch") or body.is_in_group("ClimbableTree")) and velocity.length() < DEATH_VELOCITY_THRESHOLD:

		right_hand_locked = true
		right_hand_lock_pos = right_hand_collision.global_position


		has_lost_grip = false

		if body.is_in_group("ClimbableBranch"):
			right_hand.texture = HAND_GRAB
		elif body.is_in_group("ClimbableTree"):
			right_hand.texture = HAND_GRAB_VERTICAL

		grab_clang_sound_right.play()


func _on_left_handcollison_body_entered(body: Node3D) -> void:
	if left_hand_active and left_hand_locked == false and (body.is_in_group("ClimbableBranch") or body.is_in_group("ClimbableTree")) and velocity.length() < DEATH_VELOCITY_THRESHOLD:

		left_hand_locked = true
		left_hand_lock_pos = left_hand_collision.global_position


		has_lost_grip = false

		if body.is_in_group("ClimbableBranch"):
			left_hand.texture = HAND_GRAB
		if body.is_in_group("ClimbableTree"):
			left_hand.texture = HAND_GRAB_VERTICAL

		grab_clang_sound_left.play()
