extends CharacterBody3D

# Control sensitivity
@export var tilt_sensitivity: float = 2.0
@export var yaw_sensitivity: float = 1.5
@export var lift_force: float = 20.0
@export var lateral_force: float = 15.0

# Maximum tilt angle in radians
@export var max_tilt_angle: float = PI / 6

# Gravity
@export var gravity: float = 9.8

# Model orientation (adjust these based on your model)
@export var forward_vector: Vector3 = Vector3.FORWARD
@export var right_vector: Vector3 = Vector3.RIGHT

# Current tilt
var current_tilt: Vector3 = Vector3.ZERO
@onready var camera_3d: Camera3D = $CameraMount/Camera3D

# Reference to the helicopter body
@onready var helicopter_body: Node3D = $HelicopterBody

func _ready():
	# Set the camera's position and rotation
	camera_3d.position = Vector3(-2, 0.748, 1)
	camera_3d.rotation_degrees = Vector3(-20, -90, 0)
	
	# Debug: Print initial camera position and rotation
	print("Initial camera position: ", camera_3d.position)
	print("Initial camera rotation: ", camera_3d.rotation_degrees)

func _physics_process(delta):
	# Get input values
	var forward_input = Input.get_action_strength("forward") - Input.get_action_strength("backwards")
	var strafe_input = Input.get_action_strength("right") - Input.get_action_strength("left")
	var yaw_input = Input.get_action_strength("yaw_right") - Input.get_action_strength("yaw_left")
	var thrust_input = Input.get_action_strength("thrust")
	
	# Calculate tilt direction based on input and model orientation
	var tilt_direction = (forward_vector * forward_input + right_vector * strafe_input).normalized()
	var target_tilt = tilt_direction * tilt_sensitivity
	target_tilt = target_tilt.normalized() * min(target_tilt.length(), max_tilt_angle)
	current_tilt = current_tilt.lerp(target_tilt, delta * 5)
	
	# Apply tilt to helicopter body (visual effect)
	helicopter_body.rotation = current_tilt
	
	# Apply yaw (left/right rotation)
	rotate_y(yaw_input * yaw_sensitivity * delta)
	
	# Get the current velocity
	var velocity = get_velocity()
	
	# Apply gravity
	velocity.y -= gravity * delta
	
	# Calculate total thrust force
	var total_thrust = lift_force * thrust_input
	
	# Decompose thrust into vertical and horizontal components based on tilt
	var tilt_magnitude = current_tilt.length()
	var vertical_thrust = total_thrust * cos(tilt_magnitude)
	var horizontal_thrust = total_thrust * sin(tilt_magnitude)
	
	# Apply vertical thrust
	velocity.y += vertical_thrust * delta
	
	# Calculate and apply horizontal movement
	if thrust_input > 0:
		var global_tilt_direction = global_transform.basis * tilt_direction
		velocity += global_tilt_direction * (horizontal_thrust + lateral_force * thrust_input) * delta
	
	# Apply the velocity
	set_velocity(velocity)
	move_and_slide()
