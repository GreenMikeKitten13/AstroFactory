extends CharacterBody3D

@export_group("Cammera")
@export_range(0.1, 1) var mouseSensetivity:float = 0.25

@export_group("Movement")
@export var speed :float= 8.0
@export var acceleration :float= 20.0
@export var rotationSpeed :float=12.0
@export var jumpImpulse :float=12.0


@onready var cameraPivot: Node3D = %Node3D
@onready var camera: Camera3D = %Camera3D
@onready var lilMan: MeshInstance3D = %LilMan

var lastMovementDirection:Vector3 = Vector3.BACK
var cameraInputDirection :Vector2= Vector2.ZERO
var Gravity :int= -30

func _ready() -> void:
	#Input.mouse_mode = Input.MOUSE_MODE_CONFINED_HIDDEN
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	add_to_group("target")
	%PlayerBody.set_meta("health", 100)


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if event.is_action_pressed("E"):
		position = Vector3(0,30,0)
	if event.is_action_pressed("left mouse click"):
		var collider = %RayCast3D.get_collider()
		if collider is StaticBody3D:
			collider.queue_free()

func _unhandled_input(event: InputEvent) -> void:
	#var isCameraMotion :bool= (
	#	event is InputEventMouseMotion and
	#	Input.get_mouse_mode() == Input.MOUSE_MODE_CONFINED_HIDDEN
	#)
	var isCameraMotion :bool = event is InputEventMouseMotion
	if event is InputEventMouseButton:
		if event.is_pressed():
			if event.button_index == MOUSE_BUTTON_WHEEL_UP && $Node3D/SpringArm3D.spring_length > 0:
				$Node3D/SpringArm3D.spring_length -= 0.1
			if event.button_index == MOUSE_BUTTON_WHEEL_DOWN && $Node3D/SpringArm3D.spring_length < 20:
				$Node3D/SpringArm3D.spring_length += 0.1
	
	if isCameraMotion:
		cameraInputDirection = event.screen_relative * mouseSensetivity


func _physics_process(delta: float) -> void:
	cameraPivot.rotation.x += cameraInputDirection.y * delta
	cameraPivot.rotation.x = clamp(cameraPivot.rotation.x, -PI/6, PI/3)
	cameraPivot.rotation.y -= cameraInputDirection.x * delta
	
	cameraInputDirection = Vector2.ZERO
	var rawInput :Vector2= Input.get_vector("Left","Right","Forward","Backward")
	var forward :Vector3= camera.global_basis.z
	var right :Vector3= camera.global_basis.x
	
	var moveDirection :Vector3= forward * rawInput.y + right * rawInput.x
	moveDirection.y = 0.0
	moveDirection = moveDirection.normalized()
	
	var yVelocity : float= velocity.y
	velocity.y = 0.0
	velocity = velocity.move_toward(moveDirection * speed, acceleration * delta)
	velocity.y = yVelocity + Gravity * delta
	
	var isStartingJump :bool = Input.is_action_just_pressed("Jump") and is_on_floor()
	if isStartingJump:
		velocity.y += jumpImpulse
	
	move_and_slide()
	
	if moveDirection.length() > 0.2:
		lastMovementDirection = moveDirection

	var targetAngle :float= Vector3.BACK.signed_angle_to(lastMovementDirection, Vector3.UP)
	lilMan.global_rotation.y = lerp_angle(lilMan.rotation.y, targetAngle, rotationSpeed * delta)
