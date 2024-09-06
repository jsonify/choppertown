extends Node3D

@onready var grid_map: GridMap = $GridMap
var grid_size = 5
var min_height = 1
var max_height = 3

var building_meshes = []

func _ready():
	randomize()  # Initialize random number generator
	setup_building_meshes()
	randomize_building_heights()

func setup_building_meshes():
	# Assuming your GridMap mesh library has building meshes
	# You'll need to adjust these indices based on your actual mesh library
	for i in range(grid_map.mesh_library.get_item_list().size()):
		var mesh = grid_map.mesh_library.get_item_mesh(i)
		if mesh:
			building_meshes.append(mesh)

func randomize_building_heights():
	for x in range(grid_size):
		for z in range(grid_size):
			var cell_item = grid_map.get_cell_item(Vector3i(x, 0, z))
			if cell_item != -1 and cell_item < building_meshes.size():  # Valid cell with a building
				var random_height = randf_range(min_height, max_height)
				
				# Get the current orientation of the cell item
				var orientation = grid_map.get_cell_item_orientation(Vector3i(x, 0, z))
				
				# Create a new MeshInstance3D with the original mesh
				var mesh_instance = MeshInstance3D.new()
				var original_mesh = building_meshes[cell_item]
				mesh_instance.mesh = original_mesh
				
				# Scale the MeshInstance3D
				mesh_instance.scale = Vector3(1, random_height, 1)
				
				# Remove the GridMap cell and add the MeshInstance3D
				grid_map.set_cell_item(Vector3i(x, 0, z), -1)
				add_child(mesh_instance)
				mesh_instance.global_transform.origin = grid_map.map_to_local(Vector3i(x, 0, z))
				
				# Apply the orientation
				var basis = grid_map.get_basis_with_orthogonal_index(orientation)
				mesh_instance.global_transform.basis = basis

func _input(event):
	if event.is_action_pressed("ui_accept"):
		randomize_building_heights()
