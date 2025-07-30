extends Node3D

var cell_scene = preload("res://cell.tscn")

var gridspacing_x : float = 10.0
var gridspacing_y : float = 10.0
var gridspacing_z : float = 10.0


var x_size = 100
var y_size = 100
var z_size = 100
var canvas_matrix = []

# for each timestap t, it tracks which cells have changed state
# so it's supposed to be a list of lists
# cells are represented by their logic position Vector3(x,y,z)
var dirty_cells_per_matrix = []


var t : int = 0
var time_accumulated : float = 0

# with this you can decide how fast or slow the evolution is
var time_interval : float = 1.5

func _ready() -> void:
	birth(Vector3(0,0,0))
	
func _process(delta: float) -> void:
	time_accumulated += delta
	if time_accumulated >= time_interval:
		t += 1
		time_accumulated = 0.0
		print("t = " + str(t))
		### do changes to the grid here
	
func birth(pos : Vector3):
	## check if it's actually a certain class
	var cell_instance = cell_scene.instantiate()
	## use a class defined function to set the logical position
	## to set the real position of each one, have another function that repositions the
	## cubes in their representational position
	cell_instance.position = pos
	add_child(cell_instance)
	
func check_cell_status(pos):
	return 
