extends Node3D

var cell_scene = preload("res://cell.tscn")

var gridspacing_x : float = 1.2
var gridspacing_y : float = 1.2
var gridspacing_z : float = 1.2

var x_size = 100
var y_size = 100
var z_size = 100

var alive_cells = []
var cell_instances = []

var t : int = 0
var time_accumulated : float = 0
var time_interval : float = 0.1		# with this you can decide how fast or slow the evolution is



var instance_map : Dictionary[Vector3i, Cell]
var children_map: Dictionary[Vector3i,Cell] # I need this because I have to know which children are still represented graphically and which aren't
var neighbor_map : Dictionary[Vector3i, int]

var commands : Dictionary[String, Array]



func _ready() -> void:
	var alive = []
	for x in range(-10,15):
		alive.append(Vector3i(x,0,0))
	for z in range(-10,10):
		alive.append(Vector3i(0,0,z))
	for y in range(-10,10):
		alive.append(Vector3i(0,y,0))
	commands = {
	"alive" : alive,
	"dead" : []
	}
	
	
	
func _process(delta: float) -> void:
	
	time_accumulated += delta
	if time_accumulated >= time_interval:
		time_accumulated = 0.0
		
		print("t = " + str(t))

		execute_commands()		# Execute commands
		var next_deads : Array = await calculate_dead()			# Calculate which cells will stay alive, interrogate here each cell
		#var next_deads : Array = calculate_dead()				# Calculate which ones will be dead
		
		var next_alives = []
		commands = construct_commands(next_alives, next_deads)		# Make commands for the next time loop, 
		
		reset_cells()
		t += 1						# Progress timestamp


func _physics_process(delta) -> void:

	var gridspacing = Vector3(gridspacing_x+ %XSpacingSlider.value, gridspacing_y+%YSpacingSlider.value,gridspacing_z+%ZSpacingSlider.value)
	reposition_cells(gridspacing)

func calculate_dead():
	## for now this only calculates who STAYS dead, and not who is born...!!
	var out : Array[Vector3i] = []
	for key_pos in instance_map:
			
		var cell = instance_map[key_pos]
		
		if(cell.calculated_if_alive != true):
			await cell.calculation_finished
		if !cell.alive:
			out.append(key_pos)
	
	return out

func execute_commands() -> void :
	for alive_cell_pos in commands["alive"] :
		if !instance_map.has(alive_cell_pos):
			var cell_instance : Cell = cell_scene.instantiate()
			# populate the cell instance's properties
			cell_instance.gridposition = alive_cell_pos
			cell_instance.instance_map = instance_map
			instance_map[alive_cell_pos] = cell_instance
			
	for dead_cell_pos in commands["dead"] :
		instance_map[dead_cell_pos].queue_free()
		instance_map.erase(dead_cell_pos)
		
		
func construct_commands(next_alives, next_deads) -> Dictionary[String, Array] : 
	var new_commands : Dictionary[String, Array]
	new_commands = {
		"alive" : next_alives,
		"dead" : next_deads
	}
	
	return new_commands


func reposition_cells(gridspacing : Vector3) -> void : 
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
