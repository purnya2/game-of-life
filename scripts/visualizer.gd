extends Node3D

@onready var game_grid_gpu = $".."
@onready var multi_mesh_instance = $MultiMeshInstance3D
var grid_data : Dictionary[Vector3i,bool] = {}

var gridspacing_x : float = 1.0
var gridspacing_y : float = 1.0
var gridspacing_z : float = 1.0
var old_grispacing = Vector3(gridspacing_x,gridspacing_y,gridspacing_z)
var instance_map = {}
var multimesh : MultiMesh  # Store reference so it doesn't get garbage collected
var box_mesh = BoxMesh.new()

func _ready() -> void:
	multimesh = MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.mesh = box_mesh
	
	multimesh.instance_count = grid_data.size()
	multimesh.visible_instance_count = grid_data.size()

	for i in multimesh.visible_instance_count:
		multimesh.set_instance_transform(i, Transform3D(Basis(), Vector3(i * 3, 0, 0)))
	multi_mesh_instance.multimesh = multimesh

func _process(_delta):
	
	var gridspacing = lerp(old_grispacing,Vector3(gridspacing_x+ %SpacingSlider.value, gridspacing_y+%SpacingSlider.value,gridspacing_z+%SpacingSlider.value),0.2)
	old_grispacing = gridspacing
	
	var scale_matrix = Transform3D().scaled(gridspacing)

	var i = 0
	for key_pos in  grid_data:
		multimesh.set_instance_transform(i, Transform3D(Basis(), scale_matrix*Vector3(key_pos)))
		i+=1
	multi_mesh_instance.multimesh = multimesh


func _on_game_grid_gpu_update_view(data):
	grid_data = data
	multimesh.instance_count = grid_data.size()
	multimesh.visible_instance_count = grid_data.size()
