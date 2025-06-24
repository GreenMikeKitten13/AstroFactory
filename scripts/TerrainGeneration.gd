extends  Node3D

#-------------settings-----------------
var worldSize:int = 10
var yMultiplier:int = 1
var chunkSize:int = 10
#-------------noise--------------------
var flatTerrainNoise:Noise = FastNoiseLite.new()
var normalTerrainNoise:Noise = FastNoiseLite.new()
var extremeTerrainNoise:Noise = FastNoiseLite.new()
var humidityNoise:Noise = FastNoiseLite.new()
var temperatureNoise:Noise = FastNoiseLite.new()
var caveNoise:Noise = FastNoiseLite.new()
#-------------Data---------------------
var BiomeChoosing:Dictionary = {"dry": {"hot" : "sand", "normal" : "dirt", "cold" : "snow"},
 "normally" : {"hot" : "grass", "normal" : "grass", "cold" : "stone"},
 "rainy" : {"hot" : "grass", "normal" : "grass", "cold" : "stone"},
 "snowy": {"hot" : "obsidian", "normal" : "stone", "cold" : "snow"} }
var threadRunning := false
#-------------shader things------------
var BlockeToShaderIndex:Dictionary = {
	"grass" : 0,
	"dirt" : 1,
	"stone" : 2,
	"iron" : 3,
	"snow" : 4,
	"obsidian" : 5,
	"sand" : 8
}

var IndexToBlock:Dictionary = {
	0 : "grass",
	1 : "dirt",
	2 : "stone",
	3 : "iron",
	4 : "snow",
	5 : "obsidian",
	8 : "sand"
}
var atlasTexture = preload("res://AtlasTextures/oldAtlasBackup.tres") #betterAtlasTexture / OldAtlasTextures
var materialsForMesh:Dictionary = {}
#-------------pooling------------------
var notNededBoxMeshes:Array  = []
var existingChunks:Array = []
var notNeededBlocks:Array = []
var blockPositions:Dictionary = {}
var shapesSaverRES:Array = []
#-------------objects------------------
@onready var playerBody: CharacterBody3D = %PlayerBody
var chunkThread: Thread = Thread.new()
#-------------functions----------------
func _ready() -> void:
	setMaterialUp()
	poolBoxMeshes()
	generateNoise()
	giveInfoToPlayer()
	makeChunkNodes()
	
	var chunksData = ChunksInfo(existingChunks)
	var playerY = playerBody.position.y
	start_chunk_thread(chunksData, playerY)
	useMultiMesh()


func _process(_delta: float) -> void:
	if not threadRunning:
		var chunksData = ChunksInfo(existingChunks)
		var playerY = playerBody.position.y
		start_chunk_thread(chunksData, playerY)
	useMultiMesh()


func start_chunk_thread(chunksData, playerY: float):
	threadRunning = true
	chunkThread.start(generateThreadedChunkData.bind([chunksData, playerY]))


func generateThreadedChunkData(args: Array):
	var chunksData = args[0]
	var playerY = args[1]
	var info = generateChunkInfo(chunksData, playerY)
	call_deferred("buildChunks", info)
	call_deferred("set_thread_not_running")


func set_thread_not_running():
	threadRunning = false

#-------------one use functions--------
func poolBoxMeshes() -> void:
	for notNeededBoxMeshID:int in range(10000):
		var notNeededBoxMesh:BoxMesh = BoxMesh.new()
		notNededBoxMeshes.append(notNeededBoxMesh)

func setMaterialUp() -> void:
	for block:int in BlockeToShaderIndex.values():
		var shader := Shader.new()
		shader.code =  preload("res://shaders + materials/shaderScript.gdshader").code
		
		var material = ShaderMaterial.new()
		material.shader = shader
		material.set_shader_parameter("atlas_tex", atlasTexture)
		material.set_shader_parameter("use_instance_data", false)
		material.set_shader_parameter("tile_index", block)
		
		materialsForMesh.set(block, material)

func giveInfoToPlayer() -> void:
	playerBody.set_meta("temperature", temperatureNoise.seed)
	playerBody.set_meta("humidity", humidityNoise.seed)

func makeChunkNodes() -> void:
	for x:int in worldSize:
		for z:int in worldSize:
			var chunk:Node3D = Node3D.new()
			var chunkPosX:int = x * chunkSize
			var chunkPosZ:int = z * chunkSize
			chunk.name = "chunk " + str(x)+ " "+ str(z)
			chunk.position = Vector3i(chunkPosX, 0, chunkPosZ)
			chunk.set_meta("isInBuildRange", false)
			chunk.set_meta("isBuilt", false)
			chunk.set_meta("isInRenderDistanceRange", false)
			chunk.set_meta("isLLODBuilt", false)
			chunk.set_meta("isHalfBuilt", false)
			chunk.set_meta("isInInfoRange", false)
			if x == 0 and z == 0:
				chunk.set_meta("isInBuildRange",true)
				chunk.set_meta("isInInfoRange", true)

			add_child(chunk)
			existingChunks.append(chunk)

func generateNoise() -> void:
	flatTerrainNoise.seed = randi()                                               
	flatTerrainNoise.noise_type = FastNoiseLite.TYPE_PERLIN
	flatTerrainNoise.fractal_octaves = 4 
	flatTerrainNoise.fractal_gain = 0.45
	flatTerrainNoise.frequency = 0.01  # 0.01   
	
	normalTerrainNoise.seed = randi()                                             
	normalTerrainNoise.noise_type = FastNoiseLite.TYPE_PERLIN
	normalTerrainNoise.fractal_octaves = 4 
	normalTerrainNoise.fractal_gain = 0.45
	normalTerrainNoise.frequency = 0.025 #0.025
	
	extremeTerrainNoise.seed = randi()                                             
	extremeTerrainNoise.noise_type = FastNoiseLite.TYPE_PERLIN
	extremeTerrainNoise.fractal_octaves = 4 
	extremeTerrainNoise.fractal_gain = 0.45
	extremeTerrainNoise.frequency = 0.04 # 0.04
	
	humidityNoise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH  
	humidityNoise.fractal_octaves = 22
	humidityNoise.fractal_gain = 0.025
	humidityNoise.frequency = 0.003
	humidityNoise.seed = randi()
	
	temperatureNoise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH           
	temperatureNoise.fractal_octaves = 22
	temperatureNoise.fractal_gain = 0.025
	temperatureNoise.frequency = 0.003 
	temperatureNoise.seed = randi()
	
	caveNoise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	caveNoise.seed = randi()
	caveNoise.frequency = 0.1#0.05
	caveNoise.fractal_octaves = 6#4
	caveNoise.fractal_gain = 1#0.55
	
	caveNoise.fractal_lacunarity = 0.2 # test value

#-------------process functions-------
func generateChunkInfo(chunksToGenerate: Array, playerY: float) -> Dictionary:
	var minY = clamp(round(-(playerY - 5)), 1, chunkSize)
	var blockInfo: Dictionary = {}

	for chunk: Dictionary in chunksToGenerate:
		if chunk["isInInfoRange"]:
			var chunkX = int(chunk["chunkPosition"].x)
			var chunkZ = int(chunk["chunkPosition"].z)
			var chunkKey = Vector3(chunkX, 0, chunkZ)

			blockInfo[chunkKey] = {
				"blockList": [],
				"isInBuildRange": chunk["isInBuildRange"]
			}

			for yCoordinate in range(minY):
				for xCoordinate in range(chunkSize):
					for zCoordinate in range(chunkSize):
						var globalX = xCoordinate + chunkX
						var globalZ = zCoordinate + chunkZ
						var holeNoise = (caveNoise.get_noise_3d(globalX, yCoordinate, globalZ) + 1) / 2.0
						var flatNoise = (
							flatTerrainNoise.get_noise_2d(globalX, globalZ) +
							normalTerrainNoise.get_noise_2d(globalX, globalZ) +
							extremeTerrainNoise.get_noise_2d(globalX, globalZ)
						) * 10.0
						var blockY = -yCoordinate + flatNoise
						var globalPos = Vector3(globalX, blockY, globalZ)

						blockInfo[chunkKey]["blockList"].append({
							"blockPos": globalPos,
							"cave": holeNoise <= 0.45
						})
	return blockInfo



func buildChunks(chunksToBuild: Dictionary) -> void:
	for chunkKey in chunksToBuild.keys():
		var chunkData = chunksToBuild[chunkKey]
		var blockList = chunkData["blockList"]
		var isInBuildRange = chunkData["isInBuildRange"]

		if isInBuildRange:
			var placedBlocks = []

			for blockData in blockList:
				var globalPos = blockData["blockPos"]
				var cave = blockData["cave"]
				var key = globalPos.snapped(Vector3(1, 1, 1))

				if not blockPositions.has(key) and not cave:
					var shape_rid
					var newBody
					var space_rid = get_world_3d().space

					if notNeededBlocks.is_empty():
						var newShape = SphereShape3D.new()
						newShape.radius = 0.5
						shape_rid = newShape.get_rid()
						shapesSaverRES.append(newShape)

						newBody = PhysicsServer3D.body_create()
						PhysicsServer3D.body_add_shape(newBody, shape_rid)
						PhysicsServer3D.body_set_state(newBody, PhysicsServer3D.BODY_STATE_TRANSFORM, Transform3D(Basis(), globalPos))
						PhysicsServer3D.body_set_mode(newBody, PhysicsServer3D.BODY_MODE_STATIC)
						PhysicsServer3D.body_set_collision_layer(newBody, 1)
						PhysicsServer3D.body_set_collision_mask(newBody, 1)
						PhysicsServer3D.body_set_space(newBody, space_rid)
					else:
						var notBlock = notNeededBlocks.pop_front()
						shape_rid = notBlock["shape_rid"]
						newBody = notBlock["body_rid"]
						PhysicsServer3D.body_set_state(newBody, PhysicsServer3D.BODY_STATE_TRANSFORM, Transform3D(Basis(), globalPos))
						PhysicsServer3D.body_set_space(newBody, space_rid)

					blockPositions[key] = {
						"shape_rid": shape_rid,
						"body_rid": newBody
					}
					placedBlocks.append(key)


			# You must store the placed blocks per chunk so you can unload later
			var chunk = get_node_or_null("chunk " + str(chunkKey.x / chunkSize) + " " + str(chunkKey.z / chunkSize))
			if chunk != null:
				chunk.set_meta("blocks", placedBlocks)

		else:
			# Unloading phases
			var chunk = get_node_or_null("chunk " + str(chunkKey.x / chunkSize) + " " + str(chunkKey.z / chunkSize))
			if chunk != null and chunk.has_meta("blocks"):
				var keys = chunk.get_meta("blocks")
				for key in keys:
					if blockPositions.has(key):
						var data = blockPositions[key]
						PhysicsServer3D.body_set_space(data["body_rid"], RID())
						notNeededBlocks.append(data)
						blockPositions.erase(key)
				chunk.set_meta("blocks", [])


func ChunksInfo(chunks:Array) -> Array:
	var chunksToGive:Array = []
	for chunk:Node3D in chunks:
		var isInInfoRange = chunk.get_meta("isInInfoRange")
		var isInBuildRange = chunk.get_meta("isInBuildRange")
		var chunkX = chunk.position.x
		var chunkZ = chunk.position.z
		
		chunksToGive.append({"isInInfoRange" : isInInfoRange, "chunkPosition" : Vector3(chunkX, 0, chunkZ), "isInBuildRange" : isInBuildRange})
	
	return chunksToGive

func useMultiMesh() -> void:
	for chunk:Node3D in existingChunks:
		if not chunk.get_meta("isLLODBuilt") and chunk.get_meta("isInRenderDistanceRange"):
			var meshInstance := MultiMeshInstance3D.new()
			chunk.add_child(meshInstance)
			meshInstance.position = Vector3.ZERO
			
			var mesh:BoxMesh
			if notNededBoxMeshes.is_empty():
				mesh = BoxMesh.new()
			else:
				mesh = notNededBoxMeshes.pop_front()
			
			var mm := MultiMesh.new()
			mm.mesh = mesh

			var shader := Shader.new()
			shader.code = preload("res://shaders + materials/shaderScript.gdshader").code

			var material := ShaderMaterial.new()
			material.shader = shader
			material.set_shader_parameter("atlas_tex", atlasTexture)
			material.set_shader_parameter("use_instance_data", true)
			mesh.material = material

			mm.transform_format = MultiMesh.TRANSFORM_3D
			mm.use_custom_data = true
			var instance_count := chunkSize * chunkSize * chunkSize * yMultiplier
			mm.instance_count = instance_count
			mm.visible_instance_count = instance_count
			meshInstance.multimesh = mm

			var i := 0
			for x in range(chunkSize):
				for y in range(chunkSize * yMultiplier):
					for z in range(chunkSize):
						var worldX = x + chunk.position.x
						var worldZ = z + chunk.position.z
						var height = (
							flatTerrainNoise.get_noise_2d(worldX, worldZ) +
							normalTerrainNoise.get_noise_2d(worldX, worldZ) +
							extremeTerrainNoise.get_noise_2d(worldX, worldZ)
						) * 10.0
						var cave = (caveNoise.get_noise_3d(worldX, y, worldZ) + 1) / 2.0

						if cave > 0.45:
							var pos = Vector3(x, -y + height, z)
							var bigTtransform = Transform3D(Basis(), pos)
							mm.set_instance_transform(i, bigTtransform)

							var humidity = humidityNoise.get_noise_2d(worldX, worldZ)
							var temperature = temperatureNoise.get_noise_2d(worldX, worldZ)
							var blockIndex = chooseMaterial(y, temperature, humidity)
							var color = Color(blockIndex / 255.0, 0, 0, 1)
							mm.set_instance_custom_data(i, color)

							i += 1

			#mm.instance_count = i
			#mm.visible_instance_count = i
			chunk.set_meta("isLLODBuilt", true)

		elif chunk.get_meta("isLLODBuilt") and not chunk.get_meta("isInRenderDistanceRange"):
			for child in chunk.get_children():
				if child is MultiMeshInstance3D:
					if child.multimesh and child.multimesh.mesh:
						notNededBoxMeshes.append(child.multimesh.mesh)
					child.queue_free()
			chunk.set_meta("isLLODBuilt", false)

func useMultiMeshsesFake() -> void:
	for chunk:Node3D in existingChunks:
		if not chunk.get_meta("isLLODBuilt") and chunk.get_meta("isInRenderDistanceRange"):
			var MultiMeshGenerator = MultiMeshInstance3D.new()
			chunk.add_child(MultiMeshGenerator)
			#MultiMeshGenerator.reparent(chunk)
			#MultiMeshGenerator.position = Vector3(0, 0,0)
			
			var mesh:BoxMesh
			if len(notNededBoxMeshes) == 0:
				mesh = BoxMesh.new()
			else:
				mesh = notNededBoxMeshes[0]
				notNededBoxMeshes.erase(mesh)
				#usedBoxMeshes.append(mesh)
			
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
						var globalX = x + chunk.position.x
						var globalZ  = z + chunk.position.z
						var height := (flatTerrainNoise.get_noise_2d(globalX, globalZ) + normalTerrainNoise.get_noise_2d(globalX, globalZ) + extremeTerrainNoise.get_noise_2d(globalX, globalZ) )* 10
						var pos := Vector3(x , -y + height, z )
						var cave = (caveNoise.get_noise_3d(globalX, y, z + globalZ)+1)/2
						var bigTransform 
						if cave <= 0.45:
							# Invisible block: scale to zero
							bigTransform = Transform3D(Basis().scaled(Vector3.ZERO), pos)
						else:
							# Visible block: normal scale
							bigTransform = Transform3D(Basis(), pos)
						
						
						
						var humidity = humidityNoise.get_noise_2d(globalX, z + globalZ)
						var temperature = temperatureNoise.get_noise_2d(globalX, z + globalZ)
						
						
						mm.set_instance_transform(i, bigTransform)
				
						var color = Color(chooseMaterial(y, temperature, humidity) / 255.0, 0, 0, 1)
						mm.set_instance_custom_data(i, color)
						i += 1
			chunk.set_meta("isLLODBuilt", true)
			
		elif chunk.get_meta("isLLODBuilt") and not chunk.get_meta("isInRenderDistanceRange"):
			for child:Node3D in chunk.get_children():
				if child is MultiMeshInstance3D:
					var MultiGenerator:MultiMeshInstance3D = child
					
					if MultiGenerator.multimesh != null and MultiGenerator.multimesh.mesh != null:
						notNededBoxMeshes.append(MultiGenerator.multimesh.mesh)
			
					MultiGenerator.multimesh = null
			chunk.set_meta("isLLODBuilt", false)

#-------------helper functions---------
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
	
	if (1.0/float(len(BiomeChoosing["dry"].keys()))) >= (temperature+1)/2:
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
