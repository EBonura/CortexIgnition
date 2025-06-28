extends Label

# Reference to the ship - adjust the path as needed
@onready var ship = get_node("../../../ship_player")

func _ready():
	# Update the label every frame for real-time stats
	set_process(true)

func _process(delta):
	if ship:
		update_ship_stats()

func update_ship_stats():
	var stats_text = ""
	
	# Position & Orientation
	stats_text += "Position: (%.1f, %.1f, %.1f)\n" % [ship.global_position.x, ship.global_position.y, ship.global_position.z]
	stats_text += "Rotation: %.1f°\n" % rad_to_deg(ship.rotation.y)
	
	# Velocity & Speed
	var speed = ship.velocity.length()
	var speed_percent = (speed / ship.max_speed) * 100.0
	stats_text += "Speed: %.1f / %.1f (%.0f%%)\n" % [speed, ship.max_speed, speed_percent]
	stats_text += "Velocity: (%.1f, %.1f, %.1f)\n" % [ship.velocity.x, ship.velocity.y, ship.velocity.z]
	
	# Thrust System (Wipeout-style)
	var thrust_percent = (ship.current_thrust_magnitude / ship.max_thrust_magnitude) * 100.0
	stats_text += "Thrust Magnitude: %.1f / %.1f (%.0f%%)\n" % [ship.current_thrust_magnitude, ship.max_thrust_magnitude, thrust_percent]

	# Detailed Steering Info
	var turn_percent = (abs(ship.current_turn_velocity) / ship.max_turn_rate) * 100.0
	stats_text += "Turn Velocity: %.2f / %.1f (%.0f%%)\n" % [ship.current_turn_velocity, ship.max_turn_rate, turn_percent]
	stats_text += "Tilt Angle: %.1f°\n" % ship.current_tilt
	
	# Speed-based steering factor
	var speed_factor = clamp(1.0 - (speed / ship.max_speed), 0.3, 1.0)
	stats_text += "Speed Factor: %.2f\n" % speed_factor
	
	# Mode & Input
	stats_text += "Follow Path: %s\n" % ("ON" if ship.follow_path_mode else "OFF")
	
	# Input Status
	var thrust_input = Input.get_action_strength("ui_up")
	var brake_input = Input.get_action_strength("ui_down")
	var left_input = Input.is_action_pressed("ui_left")
	var right_input = Input.is_action_pressed("ui_right")
	
	stats_text += "Thrust Input: %.0f%%\n" % (thrust_input * 100.0)
	stats_text += "Brake Input: %.0f%%\n" % (brake_input * 100.0)
	stats_text += "Steering: %s\n" % ("LEFT" if left_input else ("RIGHT" if right_input else "NONE"))
	
	# Hover Status
	if ship.hover_ray and ship.hover_ray.is_colliding():
		var ground_distance = ship.global_position.y - ship.hover_ray.get_collision_point().y
		stats_text += "Ground Distance: %.1f\n" % ground_distance
		stats_text += "Target Height: %.1f\n" % ship.hover_height
	else:
		stats_text += "Ground: NOT DETECTED\n"
	
	# Performance
	var forward = ship.transform.basis.z.normalized()
	var alignment = forward.dot(ship.velocity.normalized()) if ship.velocity.length() > 0.1 else 1.0
	stats_text += "Alignment: %.0f%%\n" % (alignment * 100.0)
	
	# Apply the text to the label
	text = stats_text
