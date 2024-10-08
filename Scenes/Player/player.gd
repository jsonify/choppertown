extends CharacterBody3D

# Control sensitivity
@export var tilt_sensitivity: float = 2.0
@export var yaw_sensitivity: float = 1.5
@export var lift_force: float = 10.0
@export var move_speed: float = 5.0

# Maximum tilt angle in radians
@export var max_tilt_angle: float = PI / 6

# Gravity
@export var gravity: float = 9.8

# Current tilt
var current_tilt: Vector3 = Vector3.ZERO

# Reference to the helicopter body
@onready var helicopter_body: Node3D = $HelicopterBody

func _physics_process(delta):
	# Get input values
	var forward_input = Input.get_action_strength("forward") - Input.get_action_strength("backwards")
	var right_input = Input.get_action_strength("right") - Input.get_action_strength("left")
	var yaw_input = Input.get_action_strength("yaw_right") - Input.get_action_strength("yaw_left")
	var thrust_input = Input.get_action_strength("thrust")
	
	# Calculate tilt
	var target_tilt = Vector3(forward_input, 0, -right_input) * tilt_sensitivity
	target_tilt = target_tilt.normalized() * min(target_tilt.length(), max_tilt_angle)
	current_tilt = current_tilt.lerp(target_tilt, delta * 5)
	
	# Apply tilt to helicopter body
	helicopter_body.rotation.x = current_tilt.x
	helicopter_body.rotation.z = current_tilt.z
	
	# Apply yaw
	rotate_y(yaw_input * yaw_sensitivity * delta)
	
	# Calculate velocity
	var velocity = Vector3.ZERO
	
	# Vertical movement (lift)
	velocity.y = lift_force * thrust_input
	
	# Apply gravity when not thrusting
	if thrust_input < 0.1:
		velocity.y -= gravity * delta
	
	# Horizontal movement (based on tilt, not direct input)
	var tilt_direction = Vector3(current_tilt.x, 0, -current_tilt.z).normalized()
	var horizontal_speed = tilt_direction * move_speed * current_tilt.length() / max_tilt_angle
	velocity += horizontal_speed
	
	# Apply the velocity
	set_velocity(velocity)
	move_and_slide()
