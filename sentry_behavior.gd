extends StaticBody3D

var bodies_in_range := []
var last_shot_time : float = 0
var can_shoot : bool = true

func _ready():
	$Timer.wait_time = 1.0 # in sec
	$Timer.start()

func shoot():
	if can_shoot:
		print("shoot")
		can_shoot = false
	$Timer.start()
	
func _on_timer_timeout():
	can_shoot = true

func _on_area_3d_body_entered(body: Node3D) -> void:
	if body.is_in_group("target"):
		bodies_in_range.append(body)

func _on_area_3d_body_exited(body: Node3D) -> void:
	if body in bodies_in_range:
		bodies_in_range.erase(body)
		print("bye")

func _process(delta):
	if bodies_in_range.size() > 0:
		var self_pos = global_transform.origin
		var target_pos = bodies_in_range[0].global_transform.origin
		
		look_at(target_pos) # x,y,z rotation
		$".".rotation.z = 0 # lock z axis
		if can_shoot:
			shoot()		
			
		

		
