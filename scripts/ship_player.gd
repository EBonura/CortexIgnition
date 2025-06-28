extends CharacterBody3D

# === MOVEMENT SETTINGS ===
@export var thrust_force := 30.0
@export var max_speed := 50.0
@export var mass := 1.0
@export var resistance_factor := 0.1
@export var turn_speed := 3.5
@export var steering_sharpness := 5.0
@export var drag_multiplier := 5.0

# === WIPEOUT-STYLE THRUST SYSTEM ===
@export var max_thrust_magnitude := 1000.0
@export var thrust_buildup_rate := 400.0
@export var thrust_decay_rate := 200.0
var current_thrust_magnitude := 0.0

# === STEERING RAMP SETTINGS ===
@export var max_turn_rate := 3.5
@export var turn_acceleration := 8.0
@export var turn_deceleration := 12.0

# === WIPEOUT-STYLE SPEED LOSS SETTINGS ===
@export var turn_speed_loss_factor := 0.3
@export var pitch_speed_loss_factor := 0.3

# === HOVER SETTINGS ===
@export var hover_height := 2.0
@export var hover_strength := 25.0
@export var gravity := -20.0

# === TILT SETTINGS ===
@export var tilt_angle := 15.0
@export var tilt_speed := 6.0

# === PATH FOLLOW SETTINGS ===
@export var path_follower: PathFollow3D
@export var target_indicator: MeshInstance3D
@export var follow_speed := 20.0
var follow_path_mode := false

# === THRUST VISUALS ===
@export var thrust_left: MeshInstance3D
@export var thrust_right: MeshInstance3D

# === INTERNALS ===
var acceleration := Vector3.ZERO
var current_tilt := 0.0
var current_turn_velocity := 0.0
var current_pitch_velocity := 0.0

# === NODES ===
var hover_ray: RayCast3D
var mesh_holder: Node3D
var collider: CollisionShape3D
@onready var thrust_bar: TextureProgressBar
@onready var thrust_value: Label

func _ready():
	hover_ray = $RayCast3D
	collider = $CollisionShape3D
	mesh_holder = $MeshHolder
	thrust_bar = $"../CanvasLayer/thrust_bar"
	thrust_value = $"../CanvasLayer/thrust_value"

func _physics_process(delta):
	follow_path_mode = GameState.current_mode == GameState.GameMode.MENU
#
	if follow_path_mode:
		if velocity.length() < follow_speed:
			velocity = velocity.move_toward(transform.basis.z * follow_speed, delta * 250.0)
			
		follow_path(delta)
		thrust_bar.visible = false
		thrust_value.visible = false
	else:
		handle_input(delta)
		thrust_bar.visible = true
		thrust_value.visible = true

	#handle_hover(delta)
	#handle_tilt(delta)
	move_and_slide()

func handle_input(delta):
	var speed = velocity.length()
	var forward = transform.basis.z.normalized()

	var thrust_input = Input.get_action_strength("ui_up")
	var brake_input = Input.get_action_strength("ui_down")

	if thrust_input > 0.1:
		var thrust_percentage = current_thrust_magnitude / max_thrust_magnitude
		var buildup_multiplier = 1.0 - thrust_percentage
		current_thrust_magnitude += thrust_buildup_rate * buildup_multiplier * delta
	else:
		current_thrust_magnitude -= thrust_decay_rate * delta

	current_thrust_magnitude = clamp(current_thrust_magnitude, 0.0, max_thrust_magnitude)
	update_thrust_bar()
	update_thrust_visuals()

	var thrust_factor = current_thrust_magnitude / max_thrust_magnitude

	if thrust_input > 0.1:
		velocity += forward * (thrust_force * thrust_factor / mass) * delta
	elif brake_input > 0.1:
		velocity -= forward * (thrust_force * brake_input / mass) * delta

	var steer_input = 0.0
	if Input.is_action_pressed("ui_left"):
		steer_input = 1.0
	elif Input.is_action_pressed("ui_right"):
		steer_input = -1.0

	var target_turn_velocity = steer_input * max_turn_rate
	if abs(target_turn_velocity) > abs(current_turn_velocity):
		current_turn_velocity = move_toward(current_turn_velocity, target_turn_velocity, turn_acceleration * delta)
	else:
		current_turn_velocity = move_toward(current_turn_velocity, target_turn_velocity, turn_deceleration * delta)

	rotate_y(current_turn_velocity * delta)

	var pitch_input = 0.0
	if Input.is_action_pressed("ui_down"):
		pitch_input = 1.0
	elif Input.is_action_pressed("ui_up"):
		pitch_input = -1.0

	var target_pitch_velocity = pitch_input * max_turn_rate * 0.5
	current_pitch_velocity = move_toward(current_pitch_velocity, target_pitch_velocity, turn_acceleration * delta)


	var current_speed = velocity.length()
	if current_speed > 0.1:
		var turn_speed_loss = abs(current_speed * abs(current_turn_velocity) * turn_speed_loss_factor) * delta
		var pitch_speed_loss = abs(current_speed * abs(current_pitch_velocity) * pitch_speed_loss_factor) * delta
		var total_speed_loss = turn_speed_loss + pitch_speed_loss
		var new_speed = current_speed - total_speed_loss
		new_speed = max(new_speed, 0.0)
		if current_speed > 0.1:
			velocity = velocity.normalized() * new_speed

	var tilt_target = -(current_turn_velocity / max_turn_rate) * tilt_angle
	current_tilt = lerp(current_tilt, tilt_target, delta * tilt_speed)

	var alignment = forward.dot(velocity.normalized())
	if alignment < 1.0:
		velocity = velocity.lerp(forward * velocity.length(), delta * 2.0)

	if thrust_input < 0.1:
		var drag_force = velocity.normalized() * resistance_factor * drag_multiplier * velocity.length() * delta
		velocity -= drag_force

	if velocity.length() > max_speed:
		velocity = velocity.normalized() * max_speed

func handle_hover(delta):
	if hover_ray.is_colliding():
		var ground_y = hover_ray.get_collision_point().y
		var height_error = hover_height - (global_transform.origin.y - ground_y)
		velocity.y += height_error * hover_strength * delta
	else:
		velocity.y += gravity * delta

func handle_tilt(delta):
	var target_rotation = mesh_holder.rotation
	target_rotation.z = deg_to_rad(current_tilt)
	mesh_holder.rotation = target_rotation

func follow_path(delta):
	var curve = path_follower.get_parent().curve
	var ship_forward_pos = global_transform.origin + transform.basis.z * 2.0
	var closest_offset = curve.get_closest_offset(ship_forward_pos)
	var lookahead_distance = 5.0
	var target_offset = fmod(closest_offset + lookahead_distance, curve.get_baked_length())
	var target_pos = curve.sample_baked(target_offset)

	if target_indicator:
		target_indicator.global_transform.origin = target_pos

	var to_target = target_pos - global_transform.origin
	to_target.y = 0
	to_target = to_target.normalized()

func update_thrust_bar():
	if thrust_bar:
		var thrust_percentage = (current_thrust_magnitude / max_thrust_magnitude) * 100.0
		thrust_bar.value = thrust_percentage
		if thrust_value:
			thrust_value.text = str(int(thrust_percentage)) + "%"

func update_thrust_visuals():
	var thrust_opacity = current_thrust_magnitude / max_thrust_magnitude
	if thrust_left and thrust_left.mesh:
		var left_material = thrust_left.mesh.surface_get_material(0) as ShaderMaterial
		if left_material:
			left_material.set_shader_parameter("thrust_opacity", thrust_opacity)
	if thrust_right and thrust_right.mesh:
		var right_material = thrust_right.mesh.surface_get_material(0) as ShaderMaterial
		if right_material:
			right_material.set_shader_parameter("thrust_opacity", thrust_opacity)
