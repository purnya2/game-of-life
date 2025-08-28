extends Node3D

######################################################################################################

var cell_scene = preload("res://cell.tscn")

var gridspacing_x : float = 1.0
var gridspacing_y : float = 1.0
var gridspacing_z : float = 1.0

var x_size = 100
var y_size = 100
var z_size = 100


var t : int = 0
var time_accumulated : float = 0
var time_interval : float = 0.5 # with this you can decide how fast or slow the evolution is



var instance_map : Dictionary[Vector3i, Cell] = {}
var children_map: Dictionary[Vector3i,Cell] = {} # I need this because I have to know which children are still represented graphically and which aren't


var commands : Dictionary[String, Array] = {}

var instance_map_history : Array[Dictionary]

######################################################################################################

func _cpuready() -> void:
	var alive = []
	var pulsar_cells = [
		[0, 0, 0], [1, 0, 0], [-1, 0, 0], [0, 1, 0], [0, -1, 0],
		[0, 0, 1], [0, 0, -1], [1, 1, 0], [-1, -1, 0], [1, -1, 0], [-1, 1, 0],
		[1, 0, 1], [-1, 0, -1], [0, 1, 1], [0, -1, -1],
		# Additional symmetrical expansions (improves stability)
		[1, 1, 1], [-1, -1, -1], [1, -1, 1], [-1, 1, -1],
		[1, 1, -1], [-1, -1, 1], [1, -1, -1], [-1, 1, 1],
		# Extend along axes (optional)
		[2, 0, 0], [-2, 0, 0], [0, 2, 0], [0, -2, 0], [0, 0, 2], [0, 0, -2],
		# Diagonal extensions (for larger structures)
		[2, 2, 0], [-2, -2, 0], [2, -2, 0], [-2, 2, 0],
		[2, 0, 2], [-2, 0, -2], [0, 2, 2], [0, -2, -2]
	]	
	for cell in pulsar_cells:
		alive.append(Vector3i(cell[0], cell[1], cell[2]))

			

	commands = {
	"alive" : alive,
	"dead" : []
	}

func _cpuprocess(delta: float) -> void:
	reposition_cells()
	time_accumulated += delta
	if time_accumulated >= time_interval:
		time_accumulated = 0.0
		print("t = " + str(t))

		execute_commands()	# Execute commands, populate instance map
		var next_cells : Array = await calculate_dead_and_alives()			# Calculate which cells will stay alive, interrogate here each cell
		commands = construct_commands(next_cells[0],next_cells[1])		# Make commands for the next time loop, 
		reset_cells()
		
		instance_map_history.append(instance_map.duplicate())
		t += 1						# Progress timestamp

######################################################################################################


func calculate_dead_and_alives():
	var neighbor_count_overlap_map : Dictionary[Vector3i, int] = {}
	var next_alives : Array[Vector3i] = []
	var next_deads : Array[Vector3i] = []
	
	for key_pos in instance_map:
			
		var cell = instance_map[key_pos]
		
		if(cell.calculated_if_alive != true):
			await cell.calculation_finished
		
		if !cell.alive :
			next_deads.append(key_pos)
			
		for dead_neighbor_pos in cell.dead_neighbor:
			if not neighbor_count_overlap_map.has(dead_neighbor_pos):
				neighbor_count_overlap_map[dead_neighbor_pos] = 1
			else:
				neighbor_count_overlap_map[dead_neighbor_pos] += 1
	
	for pos in neighbor_count_overlap_map:
		if neighbor_count_overlap_map[pos] == 5 :
			next_alives.append(pos)

	return [next_alives,next_deads]

func execute_commands() -> void :
	for alive_cell_pos in commands["alive"] :
		if !instance_map.has(alive_cell_pos):
			var cell_instance : Cell = cell_scene.instantiate()
			# populate the cell instance's properties
			cell_instance.gridposition = alive_cell_pos
			cell_instance.instance_map = instance_map
			instance_map[alive_cell_pos] = cell_instance
			
	for dead_cell_pos in commands["dead"] :
		if instance_map.has(dead_cell_pos):
			instance_map[dead_cell_pos].queue_free()
			instance_map.erase(dead_cell_pos)
			if children_map.has(dead_cell_pos):
				children_map.erase(dead_cell_pos)
	
	for cell in instance_map:
		instance_map[cell].allowed_to_calculate = true
		
func construct_commands(next_alives, next_deads) -> Dictionary[String, Array] : 
	var new_commands : Dictionary[String, Array]
	new_commands = {
		"alive" : next_alives,
		"dead" : next_deads
	}
	return new_commands

func reposition_cells() -> void : 
	var gridspacing = Vector3(gridspacing_x+ %XSpacingSlider.value, gridspacing_y+%XSpacingSlider.value,gridspacing_z+%XSpacingSlider.value)
	var scale_matrix = Transform3D().scaled(gridspacing)
	
	for key_pos in instance_map:
		
		if !children_map.has(key_pos):
			var cell_instance = instance_map[key_pos]
			cell_instance.position = scale_matrix*Vector3(key_pos)
			add_child(cell_instance)
			children_map[key_pos] = cell_instance
		else:
			children_map[key_pos].position = scale_matrix*Vector3(key_pos)

func reset_cells() -> void :
	for key_pos in instance_map:
		instance_map[key_pos].reset()
