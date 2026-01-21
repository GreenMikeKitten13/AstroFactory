extends StaticBody3D

var forward = false
var backward = false
var left = false
var right = false

var movement_speed = 10
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

@onready var camera: Camera3D = $Camera3D
@onready var touching_ground_raycast: RayCast3D = $RayCast3D

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("forward"):
		forward = true
	elif event.is_action_released("forward"): forward = false
	
	if event.is_action_pressed("backward"):
		backward = true
	elif event.is_action_released("backward"): backward = false
	
	if event.is_action_pressed("left"):
		left = true
	elif event.is_action_released("left"): left = false
	
	if event.is_action_pressed("right"):
		right = true
	elif event.is_action_released("right"): right = false
	
	if event is InputEventMouseMotion:
		camera.rotate(Vector3.LEFT, event.relative.y * 0.01)
		camera.rotation.x = clamp(camera.rotation.x, -PI/3, PI/3)
		self.rotate(Vector3.DOWN, event.relative.x * 0.01)
	
	if event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _process(delta: float) -> void:
	var motion = Vector3.ZERO
	
	if !touching_ground_raycast.get_collider():
		self.position.y -= gravity * delta
	
	if forward:
		self.position += -global_transform.basis.z * delta * movement_speed
	if backward:
		self.position += global_transform.basis.z * delta * movement_speed
	if left:
		self.position += -global_transform.basis.x * delta * movement_speed
	if right:
		self.position += global_transform.basis.x * delta * movement_speed
	self.move_and_collide()
