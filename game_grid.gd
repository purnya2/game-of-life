extends Node3D

var cell_scene = preload("res://cell.tscn")

var gridspacing_x : float = 2.0
var gridspacing_y : float = 2.0
var gridspacing_z : float = 2.0

var x_size = 100
var y_size = 100
var z_size = 100

var alive_cells = []
var cell_instances = []

var t : int = 0
var time_accumulated : float = 0
var time_interval : float = 0.5		# with this you can decide how fast or slow the evolution is



var instance_map : Dictionary[Vector3i, Cell]
var children_map: Dictionary[Vector3i,Cell]
var commands : Dictionary[String, Array]


func _ready() -> void:
	commands = {
	"alive" : [Vector3i(0,0,0),Vector3i(1,0,0),Vector3i(1,1,1),Vector3i(-1,-1,-1),Vector3i(0,0,-1)],
	"dead" : []
	}
	
	
	
func _process(delta: float) -> void:
	
	time_accumulated += delta
	if time_accumulated >= time_interval:
		time_accumulated = 0.0
		
		#print("t = " + str(t))


		execute_commands()		# Execute commands
		#reposition_cells()			# Reposition cells from Logical to Effective position
		#var next_alives : Array = calculate_alive()			# Calculate which cells will stay alive
		#var next_deads : Array = calculate_dead()				# Calculate which ones will be dead
		#construct_commands(next_alives, next_deads)		# Make commands for the next time loop
		t += 1						# Progress timestamp


func _physics_process(delta) -> void:

	var gridspacing = Vector3(gridspacing_x+ %XSpacingSlider.value, gridspacing_y+%YSpacingSlider.value,gridspacing_z+%ZSpacingSlider.value)
	reposition_cells(gridspacing)


func execute_commands() -> void :
	for alive_cell_pos in commands["alive"] :
		if !instance_map.has(alive_cell_pos):
			print("executing alive")
			var cell_instance = cell_scene.instantiate()
			#cell_instance.gridposition = alive_cell_pos
			instance_map[alive_cell_pos] = cell_instance
			
	for dead_cell_pos in commands["dead"] :
		instance_map[dead_cell_pos].queue_free()
		instance_map.erase(dead_cell_pos)
		
func reposition_cells(gridspacing : Vector3) -> void : 
	
	var scale_matrix = Transform3D().scaled(gridspacing)
	
	for key_pos in instance_map:
		
		if !children_map.has(key_pos):
			var cell_instance = instance_map[key_pos]
			cell_instance.position = scale_matrix*Vector3(key_pos)
			add_child(cell_instance)
			children_map[key_pos] = cell_instance
			print("adding!")
		else:
			children_map[key_pos].position = scale_matrix*Vector3(key_pos)

		

func birth(pos : Vector3):
	var cell_instance = cell_scene.instantiate()

	cell_instance.position = pos
	add_child(cell_instance)
	
func check_cell_status(pos):
	return 
