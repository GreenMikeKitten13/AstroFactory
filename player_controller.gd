extends MeshInstance3D

@export var speed: float = 10.0

func _process(delta):

	if Input.is_action_pressed("Forward"): 
		global_position.z += speed * delta
	if Input.is_action_pressed("Backward"):  
		global_position.z -= speed * delta
	if Input.is_action_pressed("Left"):  
		global_position.x += speed * delta
	if Input.is_action_pressed("Right"):  
		global_position.x -= speed * delta
