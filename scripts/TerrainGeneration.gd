extends  Node3D

#-------------settings-----------------
var worldSize:int = 50
var yMultiplier:int = 1
var chunkSize:int = 10
var renderDistance:int = 2
#-------------neededThings-------------
var existingChunks:Array = []
#-------------noise--------------------
var terrainNoise:Noise = FastNoiseLite.new()
var extremeNoise:Noise = FastNoiseLite.new() #how extreme the mountains are or smt
var humidityNoise:Noise = FastNoiseLite.new()
var temperatureNoise:Noise = FastNoiseLite.new() #for biomes
var caveNoise:Noise = FastNoiseLite.new()
#-------------Dictionarys--------------
var BiomeChoosing:Dictionary = {"dry": {"hot" : "sand", "normal" : "dirt", "cold" : "snow"},
 "normally" : {"hot" : "grass", "normal" : "grass", "cold" : "stone"},
 "rainy" : {"hot" : "grass", "normal" : "grass", "cold" : "stone"},
 "snowy": {"hot" : "obsidian", "normal" : "stone", "cold" : "snow"} }

var blockPositions:Dictionary = {}

#0 : grass
#1 : dirt
#2 : stone
#
#4 : snow
#
#6 : iron oder so was
#7 : uranium
#8 : sand
#9 : coal

var BlockeToShaderIndex = {
	"grass" : 0,
	"dirt" : 1,
	"stone" : 2,
	"iron" : 3,
	"snow" : 4,
	"obsidian" : 5,
	"sand" : 8
}

var IndexToBlock = {
	0 : "grass",
	1 : "dirt",
	2 : "stone",
	3 : "iron",
	4 : "snow",
	5 : "obsidian",
	8 : "sand"
}

var click = 0

var notNeededBlocks = []

var notNededBoxMeshes  = []
var usedBoxMeshes = []

var materialsForMesh:Dictionary = {}

var atlasTexture = preload("res://AtlasTextures/oldAtlasBackup.tres")    #betterAtlasTexture / OldAtlasTextures

var thread:Thread = Thread.new()

@onready var playerBody: CharacterBody3D = %PlayerBody

const blockPrefab = preload("res://scenes/Block.tscn")

func _ready() -> void:
	for block:int in BlockeToShaderIndex.values():
		var shader := Shader.new()
		shader.code =  preload("res://shaders + materials/shaderScript.gdshader").code
		
		var material = ShaderMaterial.new()
		material.shader = shader
		material.set_shader_parameter("atlas_tex", atlasTexture)
		material.set_shader_parameter("use_instance_data", false)
		material.set_shader_parameter("tile_index", block)
		
		materialsForMesh.set(block, material)
	
	
	for notNeededBlockID:int in range(25000):
		var notNeededBlock:StaticBody3D = blockPrefab.instantiate()
		notNeededBlock.set_physics_process(false)
		notNeededBlocks.append(notNeededBlock)
	
	for notNeededBoxMeshID:int in range(10000):
		var notNeededBoxMesh:BoxMesh = BoxMesh.new()
		notNededBoxMeshes.append(notNeededBoxMesh)

	
	makeNoise()
	giveInfoToPlayer()
	makeChunkNodes()
	await get_tree().create_timer(0.05).timeout
	buildChunks(existingChunks)
	useMultiMesh()

func _process(_delta: float) -> void:
	buildChunks(existingChunks)
	click += 1
	useMultiMesh()
	if click == 10:
		var notNeededBlock2:StaticBody3D = blockPrefab.instantiate()
		notNeededBlock2.set_physics_process(false)
		notNeededBlocks.append(notNeededBlock2)


func makeChunkNodes() -> void:
	for x:int in worldSize:
		for z:int in worldSize:
			var chunk:Node3D = Node3D.new()
			var chunkPosX:int = x * chunkSize
			var chunkPosZ:int = z * chunkSize
			chunk.name = "chunk " + str(x)+ " "+ str(z)
			chunk.position = Vector3i(chunkPosX, 0, chunkPosZ)
			chunk.set_meta("isInRange", false)
			chunk.set_meta("isBuilt", false)
			chunk.set_meta("isInLLODRange", false)
			chunk.set_meta("isLLODBuilt", false)
			chunk.set_meta("isHalfBuilt", false)
			if x == 0 and z == 0:
				chunk.set_meta("isInRange",true)

			add_child(chunk)
			existingChunks.append(chunk)

func buildChunks(chunksToBuild:Array) -> void:
	for chunk:Node3D in chunksToBuild:
		if chunk.get_meta("isInRange"):
			for yCoordinate in clamp( round(-(playerBody.position.y -3)), 2, chunkSize ):
				for xCoordinate in chunkSize:
					for zCoordinate in chunkSize:
						var chunkX = chunk.position.x
						var chunkZ = chunk.position.z
						
						var flatNoise = terrainNoise.get_noise_2d(xCoordinate + chunkX, zCoordinate + chunkZ) * 10
						var blockY = -yCoordinate + flatNoise
						var globalPos = Vector3(xCoordinate + chunkX, blockY, zCoordinate + chunkZ)
						var key = globalPos.snapped(Vector3(0.1, 0.1, 0.1)) # Key for hashing
						
						if not blockPositions.has(key):
							var cave = (caveNoise.get_noise_3d(xCoordinate + chunkX, yCoordinate, zCoordinate + chunkZ)+1)/2
							
							if cave >= 0.45:
								var block:StaticBody3D
								if notNeededBlocks.is_empty():
									block = blockPrefab.instantiate()
								else:
									block = notNeededBlocks.pop_front()
								
								chunk.add_child(block)
								block.disable_mode = CollisionObject3D.DISABLE_MODE_KEEP_ACTIVE
								
								var humidity = humidityNoise.get_noise_2d(xCoordinate + chunkX, zCoordinate + chunkZ)
								var temperature = temperatureNoise.get_noise_2d(xCoordinate + chunkX, zCoordinate + chunkZ)
								
								
								
								block.position = Vector3(xCoordinate, blockY, zCoordinate) #.snapped(Vector3.ONE)
								var Meta = IndexToBlock[chooseMaterial(yCoordinate,temperature, humidity)]
								
								block.set_meta("Material", Meta)
								block.set_meta("isBuilt", true)
								blockPositions[key] = true
		elif not chunk.get_meta("isInRange"):
			for child:Node3D in chunk.get_children():
				if child is StaticBody3D:
					var searchKey =  Vector3(child.position.x + chunk.position.x, child.position.y, child.position.z + chunk.position.z).snapped(Vector3(0.1, 0.1, 0.1))    #chunk.to_global(child.position).snapped(Vector3.ONE)
					blockPositions.erase(searchKey)
					child.disable_mode = CollisionObject3D.DISABLE_MODE_REMOVE
					chunk.remove_child(child)
					notNeededBlocks.append(child)

func chooseMaterial(yCoordinate:float, temperature:float, humidity:float) ->int:
	var humidityString = ""
	var temperatureString = ""
	if (1.0/float(len(BiomeChoosing.keys()))) >= (humidity+1)/2:
		humidityString = "dry"
	elif 2*(1.0/float(len(BiomeChoosing.keys()))) >= (humidity+1)/2:
		humidityString = "normally"
	elif 3*(1.0/float(len(BiomeChoosing.keys()))) >= (humidity+1)/2:
		humidityString = "rainy"
	else:
		humidityString = "snowy"
	
	if (1.0/float(len(BiomeChoosing["dry"].keys()))) >= (temperature+1)/2:                             #"dry" can be anything ("normally", "rainy", "snowy")
		temperatureString = "hot"
	elif 2*(1.0/float(len(BiomeChoosing["dry"].keys()))) >= (temperature+1)/2:
		temperatureString = "normal"
	else:
		temperatureString = "cold"
	
	var BiomeChosen = BiomeChoosing[humidityString][temperatureString]
	var BiomeBlockID = BlockeToShaderIndex[BiomeChosen]

	if  yCoordinate == 0:
		return BiomeBlockID
	elif yCoordinate >= chunkSize-6:
		return 2
	elif yCoordinate <= chunkSize-6:
		return 1
	else:
		return 0


func makeNoise() -> void:
	terrainNoise.seed = randi()                                                 #terrainNoise = not so smooth
	terrainNoise.noise_type = FastNoiseLite.TYPE_PERLIN
	terrainNoise.fractal_octaves = 4 
	terrainNoise.fractal_gain = 0.45
	terrainNoise.frequency = 0.025 
	
	
	humidityNoise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH  
	humidityNoise.fractal_octaves = 22
	humidityNoise.fractal_gain = 0.025
	humidityNoise.frequency = 0.003
	humidityNoise.seed = randi()
	
	temperatureNoise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH             #temperatureNoise = smooth
	temperatureNoise.fractal_octaves = 22
	temperatureNoise.fractal_gain = 0.025
	temperatureNoise.frequency = 0.003 
	temperatureNoise.seed = randi()
	
	extremeNoise.noise_type = FastNoiseLite.TYPE_PERLIN                         #extremeNoise = not so smooth
	extremeNoise.fractal_octaves = 4
	extremeNoise.fractal_gain = 0.45
	extremeNoise.frequency = 0.03
	
	caveNoise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	caveNoise.seed = randi()
	caveNoise.frequency = 0.05
	caveNoise.fractal_octaves = 4
	caveNoise.fractal_gain = 0.55
	caveNoise.fractal_lacunarity = 2.0



var MultiMeshGenerator:MultiMeshInstance3D

func useMultiMesh() -> void:
	for chunk:Node3D in existingChunks:
		if not chunk.get_meta("isLLODBuilt") and chunk.get_meta("isInLLODRange"):
			MultiMeshGenerator = MultiMeshInstance3D.new()
			chunk.add_child(MultiMeshGenerator)
			MultiMeshGenerator.reparent(chunk)
			MultiMeshGenerator.position = Vector3(0, 0,0)
			
			var mesh:BoxMesh
			if len(notNededBoxMeshes) == 0:
				mesh = BoxMesh.new()
			else:
				mesh = notNededBoxMeshes[0]
				notNededBoxMeshes.erase(mesh)
				usedBoxMeshes.append(mesh)
			
			var mm := MultiMesh.new()

	
			var instance_count := chunkSize * chunkSize * chunkSize * yMultiplier
			mm.mesh = mesh
			var shader := Shader.new()
			shader.code =  preload("res://shaders + materials/shaderScript.gdshader").code

			var material := ShaderMaterial.new()
			material.shader = shader
			material.set_shader_parameter("atlas_tex", atlasTexture)
			material.set_shader_parameter("use_instance_data", true)
			mesh.material = material  

			mm.transform_format = MultiMesh.TRANSFORM_3D
			mm.use_custom_data = true
			mm.instance_count = instance_count 
			mm.visible_instance_count = instance_count


	
			MultiMeshGenerator.multimesh = mm
	
			var i := 0
			for x in range(chunkSize):
				for y in range(chunkSize*yMultiplier):
					for z in range(chunkSize):
						var height := terrainNoise.get_noise_2d(x + chunk.position.x, z + chunk.position.z ) * 10.0
						var pos := Vector3(x , -y + height, z )
						var cave = (caveNoise.get_noise_3d(x + chunk.position.x, y, z + chunk.position.z)+1)/2
						var bigTransform 
						#var basis:Basis
						#print(cave)
						if cave <= 0.45:
							# Invisible block: scale to zero
							bigTransform = Transform3D(Basis().scaled(Vector3.ZERO), pos)
						else:
							# Visible block: normal scale
							bigTransform = Transform3D(Basis(), pos)
						
						
						
						var humidity = humidityNoise.get_noise_2d(x + chunk.position.x, z + chunk.position.z)
						var temperature = temperatureNoise.get_noise_2d(x + chunk.position.x, z + chunk.position.z)
						
						
						mm.set_instance_transform(i, bigTransform)
				
						var color = Color(chooseMaterial(y, temperature, humidity) / 255.0, 0, 0, 1)
						mm.set_instance_custom_data(i, color)
						i += 1
			chunk.set_meta("isLLODBuilt", true)
			
		elif chunk.get_meta("isLLODBuilt") and not chunk.get_meta("isInLLODRange"):
			for child:Node3D in chunk.get_children():
				if child is MultiMeshInstance3D:
					var MultiGenerator:MultiMeshInstance3D = child
					
					if MultiGenerator.multimesh != null and MultiGenerator.multimesh.mesh != null:
						notNededBoxMeshes.append(MultiGenerator.multimesh.mesh)
			
					MultiGenerator.multimesh = null
			chunk.set_meta("isLLODBuilt", false)

func giveInfoToPlayer() -> void:
	playerBody.set_meta("temperature", temperatureNoise.seed)
	playerBody.set_meta("humidity", humidityNoise.seed)

func isStaticbodyAtPosition(checkPosition: Vector3) -> bool:
	var space_state = get_world_3d().direct_space_state

	var box_shape = BoxShape3D.new()
	box_shape.size = Vector3(0.5, 0.5, 0.5) # Small box centered at position

	var query = PhysicsShapeQueryParameters3D.new()
	query.shape = box_shape
	query.transform.origin = checkPosition

	var results = space_state.intersect_shape(query, 10)
	for result in results:
		if result.collider is StaticBody3D:
			return true
	return false
