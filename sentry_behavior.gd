extends StaticBody3D

var bodies_in_range := []
var last_shot_time : float = 0
var can_shoot : bool = true
var looking_pos : Vector3 = Vector3(0, 0, 0)


func _ready():
	$Timer.wait_time = 1.0 # in sec
	$Timer.start()

func shoot():
	if can_shoot:
		can_shoot = false
	$Timer.start()
	
func _on_timer_timeout():
	can_shoot = true

func _on_sentry_area_body_entered(body: Node3D) -> void:
	if body.is_in_group("target"):
		bodies_in_range.append(body)


func _on_sentry_area_body_exited(body: Node3D) -> void:
	if body in bodies_in_range:
		bodies_in_range.erase(body)


func _process(_delta):
	if bodies_in_range.size() > 0:
		
		var target_pos = bodies_in_range[0].global_transform.origin
		looking_pos = looking_pos.lerp(target_pos, 0.2)
		look_at(looking_pos) # x,y,z rotation

		if can_shoot:
			shoot()
			
	
		
