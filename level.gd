extends Node3D

var building_scene = preload("res://building.tscn")
var grid_size = 5
@export var building_spacing = 2  # Adjust this value to set the space between buildings

func _ready():
	generate_building_grid()

func generate_building_grid():
	for x in range(grid_size):
		for z in range(grid_size):
			var building = building_scene.instantiate()
			
			# Calculate the position for each building
			var pos_x = x * building_spacing
			var pos_z = z * building_spacing
			
			building.translate(Vector3(pos_x, 0, pos_z))
			
			# Randomize building height (optional)
			var random_height = randf_range(2, 4)
			building.scale.y = random_height
			
			add_child(building)
