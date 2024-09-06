class_name Player extends RigidBody3D

@export_range(750.0, 3500.0) var thrust := 1000.0
@export var torque_thrust := 2.0
@export var tilt_force := 500.0
@export var rotor_speed := 5.0
@export var max_tilt_angle := 20.0

@onready var helicoptor_body: Node3D = $HelicoptorBody
@onready var rotor: Node3D = $HelicoptorBody/Rotor
@onready var bullet_spawn: Marker3D = $HelicoptorBody/BulletSpawn
@onready var camera_3d: Camera3D = $CameraMount/Camera3D

var is_transitioning := false
var rotors_active := false
var can_restart_rotor := true
var current_tilt := 0.0

@export_group("Camera")
@export var camera_distance := 5.0
@export var camera_height := 2.0

var camera_offset := Vector3(0, 2, 5)
const BULLET = preload("res://Scenes/Player/bullet.tscn")
@export var fire_rate := 0.2
var can_fire := true

func _ready():
	call_deferred("update_camera_position")
	print("Initial player rotation: ", rotation_degrees)
	print("Initial helicoptor_body rotation: ", helicoptor_body.rotation_degrees)

func _physics_process(delta: float) -> void:
	if rotors_active:
		rotate_rotors(delta)
	
	handle_input(delta)
	
	if is_inside_tree():
		update_camera_position()
	
	# Apply tilt to the helicopter body
	var tilt_quat = Quaternion(Vector3.RIGHT, deg_to_rad(current_tilt))
	helicoptor_body.transform = Transform3D(tilt_quat) * helicoptor_body.transform.orthonormalized()
	
	print("Current tilt: ", current_tilt)
	print("Player rotation: ", rotation_degrees)
	print("Helicoptor body rotation: ", helicoptor_body.rotation_degrees)

func handle_input(delta):
	var tilt_direction = 0.0
	var move_direction = Vector3.ZERO

	if Input.is_action_pressed("thrust"):
		if can_restart_rotor and not rotors_active:
			start_rotor()
		apply_central_force(basis.y * delta * thrust)
	
	if Input.is_action_pressed("backwards"):
		tilt_direction += 1.0
		move_direction += -basis.z

	if Input.is_action_pressed("forward"):
		tilt_direction -= 1.0
		move_direction += basis.z

	# Update tilt
	current_tilt = move_toward(current_tilt, tilt_direction * max_tilt_angle, torque_thrust * delta)
	
	# Apply force in the direction of tilt
	if move_direction != Vector3.ZERO:
		apply_central_force(move_direction.normalized() * tilt_force * delta)

	if Input.is_action_pressed("fire") and can_fire:
		shoot()
		
	if Input.is_action_just_pressed("restart"):
		get_tree().reload_current_scene()

func rotate_rotors(delta: float):
	rotor.rotate_y(delta * rotor_speed)

func start_rotor():
	rotors_active = true
	can_restart_rotor = false
	var tween = create_tween()
	tween.tween_property(self, "rotor_speed", 25.0, 0.5)

func shoot():
	var bullet_instance = BULLET.instantiate()
	bullet_instance.global_transform = bullet_spawn.global_transform
	get_tree().root.add_child(bullet_instance)
	apply_central_impulse(-bullet_spawn.global_transform.basis.z * 5)
	can_fire = false
	await get_tree().create_timer(fire_rate).timeout
	can_fire = true

func update_camera_position():
	if not is_inside_tree():
		return
	
	camera_offset = Vector3(0, camera_height, camera_distance)
	var target_position = global_position + global_transform.basis * camera_offset
	camera_3d.global_position = camera_3d.global_position.lerp(target_position, 0.1)
	camera_3d.look_at(global_position + global_transform.basis.y * 2, global_transform.basis.y)

func _on_body_entered(body: Node) -> void:
	if is_transitioning:
		return

	match true:
		_ when body.is_in_group("Goal"):
			complete_level()
		_ when body.is_in_group("Hazard"):
			crash_sequence()
		_ when body.is_in_group("SafeLanding"):
			land()

func crash_sequence():
	print("YOU LOST IT!")
	helicoptor_body.visible = false
	set_process(false)
	is_transitioning = true
	var tween = create_tween()
	tween.tween_interval(2.5)
	tween.tween_callback(get_tree().reload_current_scene)

func complete_level():
	print("Level Complete")
	set_process(false)
	land()

func land():
	if rotors_active:
		var tween = create_tween()
		tween.tween_property(self, "rotor_speed", 0, 1.0)
		tween.tween_callback(func():
			rotors_active = false
			can_restart_rotor = true
		)
