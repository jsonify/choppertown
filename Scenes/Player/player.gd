class_name Player extends CharacterBody3D

@export var vertical_speed := 5.0
@export var forward_speed := 10.0
@export var rotation_speed := 2.0
@export var drift_speed := 5.0
@export var acceleration := 0.1
@export var deceleration := 0.05
@export var gravity := -9.8

var helicopter_body: Node3D
var camera_mount: Node3D

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
		add_child(helicopter_body)
	
	# Try to find the camera mount
	camera_mount = find_child("*Camera*", false, false)
	if not camera_mount:
		print("Warning: No node with 'Camera' in its name found. Creating a new CameraMount.")
		camera_mount = Node3D.new()
		camera_mount.name = "CameraMount"
		add_child(camera_mount)
		var camera = Camera3D.new()
		camera_mount.add_child(camera)

func _physics_process(delta: float) -> void:
	handle_input(delta)
	apply_movement(delta)
	update_camera_position()

func handle_input(delta: float) -> void:
	var input_dir := Vector3.ZERO
	
	# Vertical movement (lift)
	if Input.is_action_pressed("thrust"):
		input_dir.y += 1
	elif Input.is_action_pressed("descend"):
		input_dir.y -= 1
	
	# Forward movement
	if Input.is_action_pressed("forward"):
		input_dir.z -= 1
	
	# Yaw (turning)
	if Input.is_action_pressed("left"):
		current_rotation -= rotation_speed * delta
	elif Input.is_action_pressed("right"):
		current_rotation += rotation_speed * delta
	
	# Horizontal drift
	if Input.is_action_pressed("drift_left"):
		input_dir.x -= 1
	elif Input.is_action_pressed("drift_right"):
		input_dir.x += 1
	
	# Apply rotation to the entire node
	global_rotation.y = current_rotation
	
	# Calculate target velocity
	target_velocity = input_dir.rotated(Vector3.UP, global_rotation.y)
	target_velocity *= Vector3(drift_speed, vertical_speed, forward_speed)

func apply_movement(delta: float) -> void:
	# Apply basic gravity
	if not is_on_floor() and target_velocity.y <= 0:
		target_velocity.y += gravity * delta
	
	# Interpolate current velocity towards target velocity
	velocity = velocity.lerp(target_velocity, acceleration if target_velocity.length() > 0 else deceleration)
	
	# Apply movement
	move_and_slide()
	
	# Update helicopter body tilt
	if helicopter_body:
		var tilt = -velocity.z * 0.05  # Simple forward tilt based on forward speed
		helicopter_body.rotation.x = tilt

func update_camera_position() -> void:
	if camera_mount:
		var camera_offset = Vector3(0, 2, 5)  # Adjust these values as needed
		camera_mount.position = camera_offset
		camera_mount.rotation.x = -0.2  # Slight downward angle
