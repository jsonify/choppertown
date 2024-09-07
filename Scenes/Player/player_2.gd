extends CharacterBody3D

# Control sensitivity
@export var tilt_sensitivity: float = 2.0
@export var yaw_sensitivity: float = 1.5
@export var lift_force: float = 10.0
@export var move_speed: float = 5.0
@export var thrust_force: float = 15.0  # New variable for thrust force

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
	var strafe_input = Input.get_action_strength("right") - Input.get_action_strength("left")
	var yaw_input = Input.get_action_strength("yaw_right") - Input.get_action_strength("yaw_left")
	var thrust_input = Input.get_action_strength("thrust")
	
	# Calculate tilt (for visual feedback and movement direction)
	var target_tilt = Vector3(strafe_input, 0, -forward_input) * tilt_sensitivity
	target_tilt = target_tilt.normalized() * min(target_tilt.length(), max_tilt_angle)
	current_tilt = current_tilt.lerp(target_tilt, delta * 5)
	
	# Apply tilt to helicopter body (visual effect)
	helicopter_body.rotation.x = current_tilt.x  # Forward/backward tilt (pitch)
	helicopter_body.rotation.z = current_tilt.z  # Left/right tilt (roll)
	
	# Apply yaw (left/right rotation)
	rotate_y(yaw_input * yaw_sensitivity * delta)
	
	# Calculate velocity
	var velocity = Vector3.ZERO
	
	# Vertical movement (controlled by thrust button)
	velocity.y = lift_force * thrust_input - gravity
	
	# Apply thrust in the direction of tilt
	var thrust_direction = -global_transform.basis.z.rotated(Vector3.RIGHT, current_tilt.x).rotated(Vector3.FORWARD, current_tilt.z)
	velocity += thrust_direction * thrust_force * thrust_input
	
	# Apply the velocity
	set_velocity(velocity)
	move_and_slide()
