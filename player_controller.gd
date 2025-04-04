extends MeshInstance3D

@export var speed: float = 10.0

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _process(delta):

	if Input.is_action_pressed("Forward"): 
		$"../LilMan".position.z += speed * delta
		global_position.z += speed * delta
	if Input.is_action_pressed("Backward"):  
		global_position.z -= speed * delta
		$"../LilMan".position.z -= speed * delta
	if Input.is_action_pressed("Left"):  
		global_position.x += speed * delta
		$"../LilMan".position.x += speed * delta
	if Input.is_action_pressed("Right"):  
		global_position.x -= speed * delta
		$"../LilMan".position.x -= speed * delta

func _input(event):
	if event is InputEventMouseMotion:
		$"../LilMan".rotation.y += event.relative[0] * -0.01
		$".".rotation.x += event.relative[1] * 0.01
		$".".rotation.y += event.relative[0] * -0.01
