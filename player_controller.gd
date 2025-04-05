extends MeshInstance3D

@export var speed: float = 10.0
@onready var ray_cast_sctipt = get_node("/root/Main/LilMan_camera_follower/RayCast3D")
var velocity = Vector3.ZERO
var camera_distance = -10

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
#^^^^^^^ => lock the mouse (dissabled for testing)
func _process(delta):
	var direction = Vector3.ZERO
	print(camera_distance)

	if Input.is_action_pressed("Forward"): 
		#$"../LilMan/CharacterBody3D".move_and_slide() 
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
	
	
	direction = direction.normalized()
	direction = direction.rotated(Vector3.UP, rotation.y)
	global_position += direction * speed * delta
	$"../LilMan".position = global_position
	
	var no_collision_distance= ray_cast_sctipt.no_collision_distance
	$Camera3D.position.z = no_collision_distance

func _input(event):
	if event is InputEventMouseMotion:
		rotation.y += event.relative.x * -0.01
		rotation.x = max(min(rotation.x + event.relative.y * 0.005, deg_to_rad(90)), deg_to_rad(-90))
		#print(rad_to_deg(rotation.x))
		$"../LilMan".rotation.y += event.relative[0] * -0.01

		
	
func _unhandled_input(event):
	if event is InputEventMouseButton:
		var no_collision_distance= ray_cast_sctipt.no_collision_distance
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			camera_distance = max(camera_distance -1, -20)
			$Camera3D.position.z = no_collision_distance
			print("assumed; ", no_collision_distance)
			
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			camera_distance = min(camera_distance +1, 0)
			$Camera3D.position.z = no_collision_distance

		
