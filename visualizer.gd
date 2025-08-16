extends Node3D

@onready var game_grid_gpu = $".."
var cell_scene = preload("res://cellgpu.tscn")

var gridspacing_x : float = 1.0
var gridspacing_y : float = 1.0
var gridspacing_z : float = 1.0

var instance_map = {}

func _process(_delta):
	pass


func _on_game_grid_gpu_update_view(data):
	reset_cells()
	reposition_cells(data)


func reposition_cells(data) -> void : 
	var gridspacing = Vector3(gridspacing_x+ %XSpacingSlider.value, gridspacing_y+%XSpacingSlider.value,gridspacing_z+%XSpacingSlider.value)
	var scale_matrix = Transform3D().scaled(gridspacing)
	
	for key_pos in data:
		var cell_instance = cell_scene.instantiate()
		instance_map[key_pos] = cell_instance
		cell_instance.position = scale_matrix*Vector3(key_pos)
		add_child(cell_instance)

func reset_cells() -> void :
	# First, queue all cells for deletion
	for cell in instance_map.values():
		cell.queue_free()
	
	# Then clear the dictionary
	instance_map.clear()
