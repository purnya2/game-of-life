extends Node3D

var dragging: bool = false
var right_dragging: bool = false
var is_inside_no_drag_area : bool = false
var drag_position : Vector2


func _ready():
	Input.set_default_cursor_shape(Input.CURSOR_CAN_DROP)
	
func _process(delta: float) -> void:
	is_inside_no_drag_area = $"../Control/NoDrag".nodrag_area

func _input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not right_dragging and not is_inside_no_drag_area:
		if event.pressed and not dragging:
			Input.set_default_cursor_shape(Input.CURSOR_DRAG)
			drag_position = event.position
			dragging=true
			
		if dragging and not event.pressed:
			Input.set_default_cursor_shape(Input.CURSOR_CAN_DROP)
			dragging = false
			
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and not dragging and not is_inside_no_drag_area:
		if event.pressed and not right_dragging:
			Input.set_default_cursor_shape(Input.CURSOR_FDIAGSIZE)
			drag_position = event.position
			right_dragging=true
			
		if right_dragging and not event.pressed:
			Input.set_default_cursor_shape(Input.CURSOR_CAN_DROP)
			right_dragging = false
	
	if event is InputEventMouseMotion and dragging:
		var difference = event.position - drag_position

		$Camera.new_angle_y = $Camera.angle_y-difference.x/100
		$Camera.new_angle_x = $Camera.angle_x-difference.y/100
		drag_position=event.position
		
	if event is InputEventMouseMotion and right_dragging:
		var difference = event.position - drag_position

		$Camera.new_radius = $Camera.r-difference.y/3
		drag_position=event.position
