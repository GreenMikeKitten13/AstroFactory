extends MeshInstance3D

@export var speed: float = 10.0
var velocity = Vector3.ZERO

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
#^^^^^^^ => lock the mouse (dissabled for testing)
func _process(delta):
	var direction = Vector3.ZERO

	if Input.is_action_pressed("Forward"): 

		direction.z += 1
	if Input.is_action_pressed("Backward"):  
		direction.z -= 1
	if Input.is_action_pressed("Left"):  
		direction.x += 1
	if Input.is_action_pressed("Right"):  
		direction.x -= 1
	if Input.is_action_pressed("Escape"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		Input.set_mouse_mode(Input.MOUSE_MODE_MAX)
	if Input.is_action_pressed("E"):
		direction.y += 1
	if Input.is_action_pressed("Q"):
		direction.y -= 1
	
	
	#direction = direction.normalized()
	#direction = direction.rotated(Vector3.UP, rotation.y)
	#global_position += direction * speed * delta
	#$"../LilMan".position = global_position
	$CharacterBody3D2.move_and_slide(direction) 
	

func _input(event):
	if event is InputEventMouseMotion:
		rotation.y += event.relative.x * -0.01
		rotation.x = max(min(rotation.x + event.relative.y * 0.005, deg_to_rad(90)), deg_to_rad(-90))
		$"../LilMan".rotation.y += event.relative[0] * -0.01

		
	
