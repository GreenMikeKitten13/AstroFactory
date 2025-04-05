extends RayCast3D

@export var default_distance_z: float = -10.0
@export var camera_zoom_speed: float = 1

var debug_counter = 0
var no_collision_distance = -10

func _process(delta):
	if is_colliding():
		$".".scale.y -= camera_zoom_speed #len
		
	else:
		no_collision_distance = $".".scale.y * -1
		$".".scale.y = default_distance_z * -1
	$"../Camera3D".position.z = no_collision_distance
