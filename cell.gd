class_name Cell

extends Node3D

signal calculation_finished

var gridposition : Vector3i
var alive : bool = true
var instance_map : Dictionary[Vector3i, Cell]

var alive_radius : int = 1
var neighbors_count_needed_to_stay_alive = 2

var neighbors : Array = []
var calculated_if_alive : bool = false

#var empty_neightbors : Dictio
## calcualate if you can be alive
## give neighboring cells a value

func _process(delta) -> void:
	if !calculated_if_alive:
		check_if_alive()

func check_if_alive() -> void:
	var neighbor_count : int = 0
	
	for x in range(gridposition.x - alive_radius, gridposition.x + alive_radius+1):
			for y in range(gridposition.y - alive_radius, gridposition.y + alive_radius+1):
					for z in range(gridposition.z - alive_radius, gridposition.z + alive_radius+1):
						var neighbor_pos = Vector3i(x,y,z)
						if neighbor_pos != gridposition :
							if instance_map.has(neighbor_pos):
								neighbor_count += 1
	if neighbor_count >= neighbors_count_needed_to_stay_alive: #LOL??
		alive = true
	else :
		$CSGBox3D.material_override = StandardMaterial3D.new()
		$CSGBox3D.material_override.albedo_color = Color.RED
		alive = false
	calculated_if_alive = true
	emit_signal("calculation_finished")

func reset()-> void:
	calculated_if_alive = false
	neighbors = []
