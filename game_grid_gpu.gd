extends Node3D

######################################################################################################

@onready var debugInfo = $"../DebugInfo"

var x_size = 64
var y_size = 64
var z_size =64

var min_survive = 2
var max_survive = 5
var min_born = 5
var max_born = 5

var t: int = 0
var time_accumulated: float = 0.0
var time_interval: float = 0.2


var rd : RenderingDevice
var shader : RID
var pipeline : RID
var input_buffer : RID
var output_buffer : RID
var dimension_buffer : RID
var config_buffer : RID
var uniform_set : RID

var grid_size : int
var grid_data : PackedByteArray

signal update_view

func _ready():
	prepare_grid()
	initialize_resources()
	var data = prepare_data()
	update_view.emit(data)
	
	%GrindInfo.text = "grid_size : " +str(x_size)+"X"+str(y_size)+"X"+str(z_size)


func prepare_grid() -> void :
	grid_size = x_size*y_size*z_size  # Remove the +1 - this was causing buffer size mismatch
	grid_data = PackedByteArray()
	grid_data.resize(grid_size)
	for x in range(0,x_size) :
		for y in range(0,y_size) :
			for z in range(0,z_size) :
				var index = x + y * x_size + z * x_size*y_size
				grid_data[index] = 0
	'''var pulsar_cells = [
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
	]'''
	var cells = []
	for x in range(-10,10):
		cells.append([x,0,0])
		cells.append([0,x,0])
		cells.append([0,0,x])
		cells.append([x,x,x])
	
	print(cells)
	
	for cell in cells:
		var x_coord = cell[0] + x_size/2 
		var y_coord = cell[1] + y_size/2
		var z_coord = cell[2] + z_size/2

		if x_coord >= 0 and x_coord < x_size and y_coord >= 0 and y_coord < y_size and z_coord >= 0 and z_coord < z_size:
			var index = x_coord + y_coord * x_size + z_coord * x_size * y_size
			grid_data[index] = 1
	%CellCount.text = "cells : " + str(cells.size())
func initialize_resources()-> void :
	grid_size = x_size*y_size*z_size
	rd = RenderingServer.create_local_rendering_device()

	var shader_file = load("res://compute_shader.glsl")
	var shader_spirv: RDShaderSPIRV = shader_file.get_spirv()
	
	if shader_spirv.get_stage_compile_error(RenderingDevice.SHADER_STAGE_COMPUTE) != "":
		print("Shader compilation error: ", shader_spirv.get_stage_compile_error(RenderingDevice.SHADER_STAGE_COMPUTE))
		return
		
	shader = rd.shader_create_from_spirv(shader_spirv)
	if not shader.is_valid():
		print("Failed to create shader!")
		return
		
	pipeline = rd.compute_pipeline_create(shader)
	if not pipeline.is_valid():
		print("Failed to create pipeline!")
		return
	

		
	input_buffer = rd.storage_buffer_create(grid_data.size(), grid_data)
	
	var empty_data = PackedByteArray()
	empty_data.resize(grid_data.size())
	for i in range(empty_data.size()):
		empty_data[i] = 0
	output_buffer = rd.storage_buffer_create(empty_data.size(), empty_data)

	var dimension_data := PackedInt32Array([x_size, y_size, z_size, 0]).to_byte_array()  
	dimension_buffer = rd.uniform_buffer_create(dimension_data.size(),dimension_data)
	
	'''config:
		0 : minimum cells needed to stay alive
		1 : maximum cells to stay alive
		2 : minimum cells to be born
		3 : maximum cells to be born	
	'''
	var config_data := PackedInt32Array([min_survive, max_survive, min_born, max_born]).to_byte_array()  
	config_buffer = rd.uniform_buffer_create(config_data.size(),config_data)
	var input_data_uniform := RDUniform.new()
	input_data_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	input_data_uniform.binding = 0
	input_data_uniform.add_id(input_buffer)
	
	var output_data_uniform := RDUniform.new()
	output_data_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	output_data_uniform.binding = 1
	output_data_uniform.add_id(output_buffer)
	
	var dimensions_uniform := RDUniform.new()
	dimensions_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_UNIFORM_BUFFER
	dimensions_uniform.binding = 2
	dimensions_uniform.add_id(dimension_buffer)
	
	var config_uniform := RDUniform.new()
	config_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_UNIFORM_BUFFER
	config_uniform.binding = 3
	config_uniform.add_id(config_buffer)
	
	uniform_set = rd.uniform_set_create([input_data_uniform, output_data_uniform, dimensions_uniform,config_uniform], shader, 0)
	
	

func _process(delta) -> void:
	time_accumulated += delta
	time_interval = 3*0.607**(%IntervalSlider.value)
	if time_accumulated >= time_interval:
		time_accumulated = 0.0
		evolution_step()
		t += 1
		%GenerationCounter.text=str(t)
		var data = prepare_data()
		%CellCount.text = "cells : " + str(data.size())
		update_view.emit(data)
		

func prepare_data() -> Dictionary[Vector3i,bool] :

	var out :  Dictionary[Vector3i,bool] = {}
	for x in range(0,x_size) :
		for y in range(0,y_size) :
			for z in range(0,z_size) :
				var index = x + y * x_size + z * x_size*y_size
				var alive = grid_data[index]
				var key : Vector3i = Vector3i(x,y,z)-Vector3i(x_size/2,y_size/2,z_size/2)
				if alive==1 :
					out[key] = (alive==1) #TODO idk if this is good
	return out
	
	
func evolution_step() -> void :
	if not rd:
		return

	var compute_list := rd.compute_list_begin()
	rd.compute_list_bind_compute_pipeline(compute_list, pipeline)
	rd.compute_list_bind_uniform_set(compute_list, uniform_set,0)

	var work_groups_x = (x_size + 7) / 8  # Match 8×8×8 workgroup size
	var work_groups_y = (y_size + 7) / 8
	var work_groups_z = (z_size + 7) / 8

	rd.compute_list_dispatch(compute_list,work_groups_x,work_groups_y,work_groups_z)
	rd.compute_list_end()
	
	rd.submit()
	rd.sync()

	var output_bytes := rd.buffer_get_data(output_buffer)
	rd.buffer_update(input_buffer, 0, output_bytes.size(),output_bytes)
	grid_data = output_bytes
