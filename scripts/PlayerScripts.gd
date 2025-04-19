extends CharacterBody3D

@export_group("Cammera")
@export_range(0.1, 1) var mouseSensetivity:float = 0.25

@export_group("Movement")
@export var speed :float= 8.8
@export var acceleration :float= 22.0
@export var rotationSpeed :float=12.0
@export var jumpImpulse :float=12.0

@onready var cameraPivot: Node3D = %Node3D
@onready var camera: Camera3D = %Camera3D
@onready var lilMan: MeshInstance3D = %LilMan


var lastMovementDirection:Vector3 = Vector3.BACK
var cameraInputDirection :Vector2= Vector2.ZERO
var Gravity :int= -30

var types:Dictionary = {
	"RigidBody3D" : RigidBody3D
}

var blocks:Dictionary = {
	"stone" : "Stone",
	"grass": "Grass",
	"snow": "Snow",
	"dirt": "Dirt",
	"copper": "Copper",
	"iront":"Iront",
	"sand":"Sand"
}

var inventory:Dictionary = {
	"Stone" : 0,
	"Grass" : 0,
	"Snow" : 0,
	"Dirt" : 0,
	"Copper" : 0,
	"Iron" : 0,
	"Sand" : 0
}

func _ready() -> void:
	set_meta("health", 100)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	add_to_group("target")


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if event.is_action_pressed("E"):
		position = Vector3(0,30,0)
	if event.is_action_pressed("left mouse click"):
		var collider = %RayCast3D.get_collider()
		if collider is StaticBody3D:
			changeNodeType(collider, "RigidBody3D")
		elif collider is RigidBody3D:
			for item:String in blocks:
				if collider.name.begins_with(item):
					var itemName = blocks[item]
					inventory.set(itemName, inventory.get(itemName) +1)  # inventory[itemName]
					print(inventory)
			collider.queue_free()

func _unhandled_input(event: InputEvent) -> void:
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
	cameraPivot.rotation.x = clamp(cameraPivot.rotation.x, -PI/2, PI/2)
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

func changeNodeType(oldType:Node3D, newType:String) -> void:
	var newThingy:Node3D = types[newType].new()
	$"..".add_child(newThingy)
	
	newThingy.position = oldType.position
	newThingy.rotation = oldType.rotation
	newThingy.name = oldType.name
	for child:Node3D in oldType.get_children():
		child.reparent(newThingy)
		child.scale /=2
	oldType.queue_free()
