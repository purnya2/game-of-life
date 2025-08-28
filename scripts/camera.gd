extends Camera3D

var x_pos : float
var y_pos : float
var z_pos : float

var r : float = 40.0

var theta : float = 0.0
var phi : float = 1.2

var angle_x : float = 0.0
var angle_y : float = 0.0

var new_angle_x : float = 0.0
var new_angle_y : float = 0.0

var new_radius : float = r

func _process(_delta):
	
	angle_x = lerp(angle_x,new_angle_x,0.1)
	angle_y = lerp(angle_y,new_angle_y,0.1)
	
	r = lerp(r,new_radius,0.1)
	
	var quat_y = Quaternion(Vector3.UP, angle_y)
	var quat_x = Quaternion(Vector3.RIGHT, angle_x)
	var offset = quat_y * quat_x * Vector3(0,0,r)
	position = Vector3.ZERO+offset
	
	

	
	
	
	look_at(Vector3(0,0,0))
	
