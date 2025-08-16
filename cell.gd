class_name Cell

extends Node3D

signal calculation_finished

var gridposition : Vector3i
var alive : bool = true
var instance_map : Dictionary[Vector3i, Cell]

var alive_radius : int = 2
const neighbors_count_needed_to_stay_alive = 3

var dead_neighbor: Array[Vector3i] = []

var calculated_if_alive : bool = false
var allowed_to_calculate : bool = false



func _process(_delta) -> void:
	if !calculated_if_alive and allowed_to_calculate:
		check_if_alive()

func check_if_alive() -> void:
	var neighbor_count : int = 0
	dead_neighbor.clear() 
	
	for x in range(gridposition.x - alive_radius, gridposition.x + alive_radius+1):
			for y in range(gridposition.y - alive_radius, gridposition.y + alive_radius+1):
					for z in range(gridposition.z - alive_radius, gridposition.z + alive_radius+1):
						var neighbor_pos = Vector3i(x,y,z)
						if neighbor_pos != gridposition :
							if instance_map.has(neighbor_pos):
								neighbor_count += 1
							else:
								dead_neighbor.append(neighbor_pos)
								
	if neighbor_count >= neighbors_count_needed_to_stay_alive and neighbor_count<=neighbors_count_needed_to_stay_alive+1: #LOL name might be too long??
		alive = true
	else :
		$CSGBox3D.material_override = StandardMaterial3D.new()
		$CSGBox3D.material_override.albedo_color = Color.RED
		alive = false
	calculated_if_alive = true
	emit_signal("calculation_finished")

func reset()-> void:
	calculated_if_alive = false
	allowed_to_calculate = false
	dead_neighbor = []
