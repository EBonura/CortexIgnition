extends Camera3D

@export var follow_distance := 1.5
@export var follow_height := 0.3
@export var follow_speed := 30.0
@export var look_ahead := 5.0

@export var base_lateral_offset := 0.0
@export var turn_offset_strength := 0.1
@export var turn_accumulation_rate := 5.0
@export var turn_decay_rate := 0.2
@export var max_accumulated_offset := 0.1
@export var offset_smooth_speed := 3.0

# Menu-specific rotation
@export var menu_rotation_speed := 0.3
var menu_rotation_angle := 0.0

var target: CharacterBody3D
var current_lateral_offset := 0.1
var accumulated_turn := 0.0

func _ready():
	target = $"../ship_player"
	current_lateral_offset = base_lateral_offset

func _process(delta):
	if GameState.current_mode == GameState.GameMode.MENU:
		# Rotate camera around the ship
		menu_rotation_angle += menu_rotation_speed * delta

		var radius = follow_distance
		var height = follow_height
		var target_pos = target.global_transform.origin

		var x = target_pos.x + radius * cos(menu_rotation_angle)
		var z = target_pos.z + radius * sin(menu_rotation_angle)
		var y = target_pos.y + height

		global_transform.origin = Vector3(x, y, z)
		look_at(target_pos, Vector3.UP)
		return

	# Gameplay camera logic
	var target_transform = target.global_transform
	var turn_velocity = target.current_turn_velocity if target.has_method("get") else 0.0

	accumulated_turn += turn_velocity * turn_accumulation_rate * delta
	if abs(turn_velocity) < 0.1:
		accumulated_turn = lerp(accumulated_turn, 0.0, delta * turn_decay_rate)
	accumulated_turn = clamp(accumulated_turn, -max_accumulated_offset, max_accumulated_offset)

	var immediate_turn_offset = -turn_velocity * turn_offset_strength
	var persistent_offset = -accumulated_turn
	var target_offset = base_lateral_offset + persistent_offset + immediate_turn_offset

	current_lateral_offset = lerp(current_lateral_offset, target_offset, delta * offset_smooth_speed)

	var desired_pos = target_transform.origin
	desired_pos -= target_transform.basis.z * follow_distance
	desired_pos.y += follow_height
	desired_pos += target_transform.basis.x * current_lateral_offset

	global_transform.origin = global_transform.origin.lerp(desired_pos, delta * follow_speed)

	var look_pos = target_transform.origin + target_transform.basis.z * look_ahead
	look_at(look_pos, Vector3.UP)
