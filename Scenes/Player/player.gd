class_name Player extends CharacterBody3D

@export var vertical_speed := 5.0
@export var forward_speed := 10.0
@export var rotation_speed := 2.0
@export var drift_speed := 5.0
@export var acceleration := 0.1
@export var deceleration := 0.05
@export var gravity := -6.50  # Reduced gravity for a more floaty feel

var helicopter_body: Node3D
var camera_mount: Node3D
var camera: Camera3D
var target_velocity := Vector3.ZERO
var current_rotation := 0.0

func _ready() -> void:
	print("Simplified Helicopter Player script initialized")
	setup_nodes()

func setup_nodes() -> void:
	# Try to find the helicopter body
	helicopter_body = find_child("*Body*", false, false)
	if not helicopter_body:
		print("Warning: No node with 'Body' in its name found. Creating a placeholder.")
		helicopter_body = Node3D.new()
		helicopter_body.name = "HelicopterBody"
		add_child(helicopter_body)
	
	# Try to find the camera mount
	camera_mount = find_child("*CameraMount*", false, false)
	if not camera_mount:
		print("Warning: No node with 'CameraMount' in its name found. Creating a new CameraMount.")
		camera_mount = Node3D.new()
		camera_mount.name = "CameraMount"
		add_child(camera_mount)
	
	# Try to find the camera
	camera = find_child("*Camera*", true, false) as Camera3D
	if not camera:
		print("Warning: No Camera3D node found. Creating a new Camera3D.")
		camera = Camera3D.new()
		camera.name = "Camera3D"
		camera_mount.add_child(camera)
	
	# Ensure camera is a child of camera_mount
	if camera.get_parent() != camera_mount:
		camera.get_parent().remove_child(camera)
		camera_mount.add_child(camera)
	
	# Set up initial camera position
	camera_mount.position = Vector3(0, 2, 5)
	camera.rotation.x = deg_to_rad(-20)  # Tilt camera down slightly

func _physics_process(delta: float) -> void:
	handle_input(delta)
	apply_movement(delta)
	update_camera_position(delta)

func handle_input(delta: float) -> void:
	var input_dir := Vector3.ZERO
	
	# Vertical movement (lift)
	input_dir.y = Input.get_action_strength("thrust") - Input.get_action_strength("descend")
	
	# Forward movement
	input_dir.z = -Input.get_action_strength("forward")
	
	# Yaw (turning)
	current_rotation += (Input.get_action_strength("right") - Input.get_action_strength("left")) * rotation_speed * delta
	
	# Horizontal drift
	input_dir.x = Input.get_action_strength("drift_right") - Input.get_action_strength("drift_left")
	
	# Apply rotation to the entire node
	global_rotation.y = current_rotation
	
	# Calculate target velocity
	target_velocity = input_dir.rotated(Vector3.UP, global_rotation.y)
	target_velocity.x *= drift_speed
	target_velocity.y *= vertical_speed
	target_velocity.z *= forward_speed

func apply_movement(delta: float) -> void:
	# Apply basic gravity if not moving upwards
	if target_velocity.y <= 0:
		target_velocity.y += gravity * delta
	
	# Interpolate current velocity towards target velocity
	velocity = velocity.lerp(target_velocity, acceleration if target_velocity.length() > 0 else deceleration)
	
	# Apply movement
	move_and_slide()
	
	# Update helicopter body tilt
	if helicopter_body:
		# Tilt for both forward/backward and side-to-side movement
		var forward_tilt = -velocity.z * 0.05  # Simple forward tilt based on forward speed
		var side_tilt = velocity.x * 0.05      # Simple side tilt based on drift
		helicopter_body.rotation.x = forward_tilt
		helicopter_body.rotation.z = side_tilt

func update_camera_position(delta: float) -> void:
	if camera_mount:
		# Smoothly move the camera mount to its position behind and above the helicopter
		var target_position = Vector3(0, 2, 5)
		camera_mount.position = camera_mount.position.lerp(target_position, 5 * delta)
		
		# Make the camera look at the helicopter
		camera.look_at(global_position, Vector3.UP)

# Add this function to help with debugging
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):  # Usually the Esc key
		print("Camera position:", camera.global_position)
		print("Camera rotation:", camera.global_rotation)
		print("Player position:", global_position)
		print("Player rotation:", global_rotation)
