extends Panel

var nodrag_area = false
func _process(delta):
	if get_global_rect().has_point(get_global_mouse_position()):
		nodrag_area=true
	else:
		nodrag_area=false
