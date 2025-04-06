extends RayCast3D

@export var camera_zoom_speed: float = 1
@onready var LilMan_follower_script = get_node("/root/Main/LilMan_camera_follower")

var debug_counter = 0
var no_collision_distance = -10

func _process(delta):
	if is_colliding():
		var collider = $".".get_collider()
		if "Character" in str(collider) :
			return
		else:
			$".".scale.y -= camera_zoom_speed #len
			#print(collider)
		
	else:
		no_collision_distance = $".".scale.y * -1
		$".".scale.y = LilMan_follower_script.camera_distance * -1
	#print(LilMan_follower_script.camera_distance)
