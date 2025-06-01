extends  Node3D

#-------------settings-----------------
var worldSize:int = 10
var chunkSize:int = 10
var renderDistance:int = 2
var LLODR:int = renderDistance * 2 #Low Level Of Detail Range
#-------------neededThings-------------
var existingChunks:Array = []
#-------------noise--------------------
var terrainNoise:Noise = FastNoiseLite.new()
var extremeNoise:Noise = FastNoiseLite.new() #how extreme the mountains are or smt
var humidityNoise:Noise = FastNoiseLite.new()
var temperatureNoise:Noise = FastNoiseLite.new()
#-------------Dictionarys--------------
var BiomeChoosing:Dictionary = {"dry": {"hot" : "sand", "normal" : "dirt", "cold" : "snow"},
 								"normally" : {"hot" : "grass", "normal" : "grass", "cold" : "stone"},
 								"rainy" : {"hot" : "grass", "normal" : "grass", "cold" : "stone"},
 								"snowy": {"hot" : "obsidian", "normal" : "stone", "cold" : "snow"} }

@onready var characters: Node3D = %Characters

var BlockeToShaderIndex = {
	"grass" : 0,
	"dirt" : 1,
	"stone" : 2,
	"iron" : 3,
	"snow" : 4,
	"obsidian" : 5,
	"sand" : 9
}

var IndexToBlock = {
	0 : "grass",
	1 : "dirt",
	2 : "stone",
	3 : "iron",
	4 : "snow",
	5 : "obsidian", 
	9 : "sand"
}

var click = 0

var notNeededBlocks = []

var materialsForMesh:Dictionary = {}

var atlasTexture = preload("res://AtlasTextures/OldAtlasTextures.tres")    #betterAtlasTexture / OldAtlasTextures

var biomeNextThread:Thread = Thread.new()
var biomeNextNextThread:Thread = Thread.new()
var biomeNextNextNextThread:Thread = Thread.new()

@onready var playerBody: CharacterBody3D = %PlayerBody

const blockPrefab = preload("res://scenes/Block.tscn")

func _ready() -> void:
	
	for block:int in BlockeToShaderIndex.values():
		var shader := Shader.new()
		shader.code =  preload("res://shaders/shaderScript.gdshader").code
		
		var material = ShaderMaterial.new()
		material.shader = shader
		material.set_shader_parameter("atlas_tex", atlasTexture)
		material.set_shader_parameter("use_instance_data", false)
		material.set_shader_parameter("tile_index", block)
		
		materialsForMesh.set(block, material)
	
	
	for notNeededBlockID:int in range(2500): #5000
		var notNeededBlock:StaticBody3D = blockPrefab.instantiate()
		notNeededBlock.set_physics_process(false)
		notNeededBlocks.append(notNeededBlock)

	
	makeNoise()
	makeChunkNodes()
	await get_tree().create_timer(0.05).timeout
	buildChunks(existingChunks)
	useMultiMesh()

func _process(_delta: float) -> void:
	buildChunks(existingChunks)
	
	click += 1
	
	if click == 10 and len(notNeededBlocks) <= characters.get_child_count() * 7000:
		var notNeededBlock2:StaticBody3D = blockPrefab.instantiate()
		notNeededBlock2.set_physics_process(false)
		notNeededBlocks.append(notNeededBlock2)
		click = 0


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
			if x == 0 and z == 0:
				chunk.set_meta("isInRange",true)

			add_child(chunk)
			existingChunks.append(chunk)

func buildChunks(chunksToBuild:Array) -> void:
	for chunk:Node3D in chunksToBuild:
		if chunk.get_meta("isInRange") && !chunk.get_meta("isBuilt"):
			for yCoordinate in int(chunkSize/5.0):
				for xCoordinate in chunkSize:
					for zCoordinate in chunkSize:
						var block:StaticBody3D
						if len(notNeededBlocks) != 0:
							block = notNeededBlocks.get(0) #blockPrefab.instantiate()
							notNeededBlocks.erase(block)
						else:
							block = blockPrefab.instantiate()

						chunk.add_child(block)
						block.set_process(true)
						block.set_physics_process(true)
						block.disable_mode = CollisionObject3D.DISABLE_MODE_KEEP_ACTIVE
						block.collision_layer = 1
						block.collision_mask = 1
						var flatNoise = terrainNoise.get_noise_2d(xCoordinate + chunk.position.x, zCoordinate + chunk.position.z) * 10
						var humidity = humidityNoise.get_noise_2d(xCoordinate + chunk.position.x, zCoordinate + chunk.position.z) * 10
						var temperature = temperatureNoise.get_noise_2d(xCoordinate + chunk.position.x, zCoordinate + chunk.position.z) * 10
						
						block.position = Vector3(xCoordinate, -yCoordinate + flatNoise, zCoordinate)
						var Meta = IndexToBlock[chooseMaterial(yCoordinate, temperature, humidity)]
						
						block.set_meta("Material", Meta)

			chunk.set_meta("isBuilt", true)
		elif chunk.get_meta("isBuilt") and not chunk.get_meta("isInRange"):
			for child:Node3D in chunk.get_children():
				if child is StaticBody3D:
					child.set_process(false)
					child.set_physics_process(false)
					child.disable_mode = CollisionObject3D.DISABLE_MODE_REMOVE
					child.collision_layer = 0
					child.collision_mask = 0
					chunk.remove_child(child)
					notNeededBlocks.append(child)
			chunk.set_meta("isBuilt", false)

func chooseMaterial(yCoordinate:float, temperature:float, humidity:float) ->int:
	var humidityString = ""
	var temperatureString = ""
	if 1.0/float(len(BiomeChoosing.keys())) >= humidity:
		humidityString = "dry"
	elif 2*(1.0/float(len(BiomeChoosing.keys()))) >= humidity:
		humidityString = "normally"
	elif 3*(1.0/float(len(BiomeChoosing.keys()))) >= humidity:
		humidityString = "rainy"
	else:
		humidityString = "snowy"
	
	if 1.0/float(len(BiomeChoosing["dry"].keys())) >= temperature:                             #"dry" can be anything ("normally", "rainy", "snowy")
		temperatureString = "hot"
	elif 2*(1.0/float(len(BiomeChoosing["dry"].keys()))) >= temperature:
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
	
	humidityNoise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH                #humidityNoise = smooth
	humidityNoise.fractal_octaves = 4
	humidityNoise.fractal_gain = 0.4
	humidityNoise.frequency = 0.005
	
	temperatureNoise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH             #temperatureNoise = smooth
	temperatureNoise.fractal_octaves = 4
	temperatureNoise.fractal_gain = 0.4
	temperatureNoise.frequency = 0.005
	
	extremeNoise.noise_type = FastNoiseLite.TYPE_PERLIN                         #extremeNoise = not so smooth
	extremeNoise.fractal_octaves = 4
	extremeNoise.fractal_gain = 0.45
	extremeNoise.frequency = 0.03


var MultiMeshGenerator

func useMultiMesh() -> void:
	for chunk in existingChunks:
		MultiMeshGenerator = MultiMeshInstance3D.new()
		chunk.add_child(MultiMeshGenerator)
		MultiMeshGenerator.reparent(chunk)
		MultiMeshGenerator.position = Vector3(0, 0,0)

		var mesh:BoxMesh = BoxMesh.new()
		var mm := MultiMesh.new()

	
		var instance_count := chunkSize * chunkSize * chunkSize
		mm.mesh = mesh
		var shader := Shader.new()
		shader.code =  preload("res://shaders/shaderScript.gdshader").code

		var material := ShaderMaterial.new()
		material.shader = shader
		material.set_shader_parameter("atlas_tex", atlasTexture)
		material.set_shader_parameter("use_instance_data", true)
		material.set_shader_parameter("block_scale", 2.0) # If BoxMesh size is 2
		
		mesh.material = material

		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.use_custom_data = true
		mm.instance_count = instance_count 
		mm.visible_instance_count = instance_count


	
		MultiMeshGenerator.multimesh = mm
	
		var i := 0
		for x in range(chunkSize):
			for y in range(round(chunkSize/2.0)):
				for z in range(chunkSize):
					var height := terrainNoise.get_noise_2d(x + chunk.position.x, z + chunk.position.z ) * 10.0
					var pos := Vector3(x ,-y + height, z )
					var bigTransform := Transform3D( Basis(), pos)
					var temperature = temperatureNoise.get_noise_2d(x + chunk.position.x, z + chunk.position.z )
					var humidity = humidityNoise.get_noise_2d(x + chunk.position.x, z + chunk.position.z )
					
					mm.set_instance_transform(i, bigTransform)
					
					#var biomeNextMaterial = biomeNextThread.start(chooseMaterial.bind(y, temperature, humidity))
				
					var color = Color(chooseMaterial(y, temperature, humidity) / 255.0, 0, 0, 1)
					
					mm.set_instance_custom_data(i, color)
					i += 1
