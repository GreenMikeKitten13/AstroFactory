extends CharacterBody3D

@export_group("Cammera")
@export_range(0.1, 1) var mouseSensetivity:float = 0.25

@export_group("Movement")
@export var speed :float= 8.8
@export var acceleration :float= 22.0
@export var rotationSpeed :float=12.0
@export var jumpImpulse :float=12.0

@export var renderDistance:int = 40

@onready var cameraPivot: Node3D = %CameraFixPoint
@onready var camera: Camera3D = %Camera3D
@onready var lilMan: MeshInstance3D = %LilMan
@onready var DebugStuff: Control = %DebugStuff


var lastMovementDirection:Vector3 = Vector3.BACK
var cameraInputDirection :Vector2= Vector2.ZERO
var Gravity :int= -30
var chunks:Array = []

var thread:Thread = Thread.new()

var types:Dictionary = {
	"RigidBody3D" : RigidBody3D
}

var BiomeChoosing:Dictionary = {"dry": {"hot" : "desert", "normal" : "steppe", "cold" : "snow field"},
 "normally" : {"hot" : "jungle", "normal" : "grass field", "cold" : "mountain"},
 "rainy" : {"hot" : "big jungle", "normal" : "big grass field", "cold" : "rainy mountain"},
 "snowy": {"hot" : "vulcanic field", "normal" : "snowy mountain", "cold" : "snow field/mountain"} }

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

var temperatureSeed
var humiditySeed
@onready var humidityNoise = FastNoiseLite.new()
@onready var temperatureNoise = FastNoiseLite.new()

func _ready() -> void:
	set_meta("health", 100)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	add_to_group("target")
	
	await  get_tree().create_timer(0.25).timeout
	for chunk in %TerrainGeneration.get_children():
		chunks.append(chunk)
	
	#temperatureSeed = self.get_meta("temperature")
	#humiditySeed = self.get_meta("humidity")
	
	
	#humidityNoise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH                #humidityNoise = smooth
	#humidityNoise.fractal_octaves = 22         #4   
	#humidityNoise.fractal_gain = 0.025         #0.5    
	#humidityNoise.frequency =   0.003          #0.015  
	#humidityNoise.seed = humiditySeed
	
	#temperatureNoise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH             #temperatureNoise = smooth
	#temperatureNoise.fractal_octaves = 22
	#temperatureNoise.fractal_gain = 0.025
	#temperatureNoise.frequency = 0.003
	#temperatureNoise.seed = temperatureSeed



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
			for item:String in blocks.keys():
				print(item)
				if not collider.has_meta("Material"):
					return
				if item.begins_with(collider.get_meta("Material")):
					var itemName = blocks[item]
					inventory.set(itemName, inventory.get(itemName) +1)  # inventory[itemName]
					collider.queue_free()
	if event.is_action_pressed("F"):
		for item in %Area3D.get_overlapping_bodies():
			if item is RigidBody3D:
				for lookUpItem:String in blocks:
					#print(lookUpItem, item, " working")
					if not item.has_meta("Material"):
						return
						
					if lookUpItem.begins_with(item.get_meta("Material")):
						var itemName = blocks[lookUpItem]
						inventory.set(itemName, inventory.get(itemName) + 1)
						print(inventory)
						item.queue_free()

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
	cameraPivot.rotation.x = clamp(cameraPivot.rotation.x, -PI/2.2, PI/2.2)
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
	
	if not thread.is_alive():
		if thread.is_alive():
			return
		else:
			checkChunkRange(chunks, velocity)
			
	if moveDirection.length() > 0.2:
		lastMovementDirection = moveDirection

	var targetAngle :float= Vector3.BACK.signed_angle_to(lastMovementDirection, Vector3.UP)
	lilMan.global_rotation.y = lerp_angle(lilMan.rotation.y, targetAngle, rotationSpeed * delta)
	var biomeIndicator = DebugStuff.get_child(0)
	var positionIndicator = DebugStuff.get_child(1)
	var fpsIndicator = DebugStuff.get_child(-1)
	positionIndicator.text = str(round(self.position.x)) + ", " + str(round(self.position.y)) + ", " + str( round(self.position.z))
	biomeIndicator.text = chooseBiome(temperatureNoise.get_noise_2d(self.position.x, self.position.z), humidityNoise.get_noise_2d(self.position.x, self.position.z))
	fpsIndicator.text = str(Engine.get_frames_per_second())

func changeNodeType(oldType:Node3D, newType:String) -> void:
	var newThingy:Node3D = types[newType].new()
	$"..".add_child(newThingy)
	
	newThingy.position = oldType.position
	newThingy.rotation = oldType.rotation
	newThingy.name = oldType.name
	for metaData:String in oldType.get_meta_list():
		newThingy.set_meta(metaData, oldType.get_meta(metaData))
		
		
		
	for child:Node in oldType.get_children():
		child.reparent(newThingy)
		child.scale /=2
	oldType.queue_free()

func chooseBiome( temperature:float, humidity:float) ->String:
	var humidityString = ""
	var temperatureString = ""
	var biomeString = ""
	
	if (1.0/float(len(BiomeChoosing.keys()))) >= (humidity+1)/2:
		humidityString = "dry"
	elif 2*(1.0/float(len(BiomeChoosing.keys()))) >= (humidity+1)/2:
		humidityString = "normally"
	elif 3*(1.0/float(len(BiomeChoosing.keys()))) >= (humidity+1)/2:
		humidityString = "rainy"
	else:
		humidityString = "snowy"
	
	if (1.0/float(len(BiomeChoosing["dry"].keys()))) >= (temperature+1)/2:                         
		temperatureString = "hot"
	elif 2*(1.0/float(len(BiomeChoosing["dry"].keys()))) >= (temperature+1)/2:
		temperatureString = "normal"
	else:
		temperatureString = "cold"
		
	biomeString = BiomeChoosing[humidityString][temperatureString]
	
	return biomeString

var hitItems = []

func onBulletEntered(body: Node3D) -> void:
	if body.name.begins_with("bullet") || body.name.begins_with("Bullet") && body.linear_velocity != Vector3.ZERO:
		hitItems.append(body.linear_velocity)
		var bullet:RigidBody3D = body
		set_meta("health", get_meta("health") - (abs(bullet.linear_velocity.x) +abs(bullet.linear_velocity.z) + abs(bullet.linear_velocity.y)))
		await get_tree().create_timer(0.005).timeout
		bullet.linear_velocity = Vector3i.ZERO
		bullet.set_process(false)

func checkChunkRange(chunksToCheck: Array, playerVelocity: Vector3):
	if playerVelocity.x == 0 and playerVelocity.z == 0:
		return

	var buildRadius = max(round(renderDistance/ 2.0), 22)
	var LLODradius = round(renderDistance)
	var infoRadius = LLODradius + 15
	var playerXZ = Vector2(position.x, position.z)

	for chunk: Node3D in chunksToCheck:
		var chunkXZ = Vector2(chunk.position.x, chunk.position.z)
		var distance = playerXZ.distance_to(chunkXZ)

		chunk.set_meta("info",{"isInBuildRange" : distance <= buildRadius})
		chunk.set_meta("info",{"isInRenderRange" : distance <= LLODradius})
		chunk.set_meta("info",{"isInInfoRange" : distance <= infoRadius})
