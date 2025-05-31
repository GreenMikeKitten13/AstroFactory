extends  Node3D

#-------------settings-----------------
var worldSize:int = 30
var chunkSize:int = 10
var renderDistance:int = 2
var LLODR:int = renderDistance * 2 #Low Level Of Detail Range
#-------------neededThings-------------
var existingChunks:Array = []
#-------------noise--------------------
var terrainNoise:Noise = FastNoiseLite.new()
var extremeNoise:Noise = FastNoiseLite.new() #how extreme the mountains are or smt
var humidityNoise:Noise = FastNoiseLite.new()
var temperatureNoise:Noise = FastNoiseLite.new() #for biomes
#-------------Dictionarys--------------
var BiomeChoosing:Dictionary = {"dry": {"hot" : "sand", "normal" : "dirt", "cold" : "snow"},
 "normally" : {"hot" : "grass", "normal" : "grass", "cold" : "stone"},
 "rainy" : {"hot" : "grass", "normal" : "grass", "cold" : "stone"},
 "snowy": {"hot" : "obsidian", "normal" : "stone", "cold" : "snow"} }

var BlockeToShaderIndex = {
	"grass" : 0,
	"dirt" : 1,
	"stone" : 2,
	"iron" : 3,
	"snow" : 4,
	"obsidian" : 5
}

var IndexToBlock = {
	0 : "grass",
	1 : "dirt",
	2 : "stone",
}

var Blocks = {}

var materialsForMesh:Dictionary = {}

var atlasTexture = preload("res://AtlasTextures/betterAtlasTexture.tres")

var thread:Thread = Thread.new()

@onready var playerBody: CharacterBody3D = %PlayerBody
#@onready var notUsedBlocks: Node3D = %NotUsedBlocks

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
	print(materialsForMesh)
	
	
	makeNoise()
	makeChunkNodes()
	await get_tree().create_timer(0.05).timeout
	buildChunks(existingChunks)
	useMultiMesh()

func _process(_delta: float) -> void:
	buildChunks(existingChunks)


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
			for yCoordinate in int(chunkSize/2.0):
				for xCoordinate in chunkSize:
					for zCoordinate in chunkSize:
						
						var block:StaticBody3D = blockPrefab.instantiate()
						var flatNoise = terrainNoise.get_noise_2d(xCoordinate + chunk.position.x, zCoordinate + chunk.position.z) * 10
						
						block.position = Vector3(xCoordinate, -yCoordinate + flatNoise, zCoordinate)
						var blockMesh:MeshInstance3D = block.get_child(0)
						blockMesh.visibility_range_end = 0
						var material = materialsForMesh[chooseMaterial(yCoordinate)]
						var Meta = IndexToBlock[chooseMaterial(yCoordinate)]
						
						block.set_meta("Material", Meta)
						blockMesh.set_surface_override_material(0, material)
						
						chunk.add_child(block)
			chunk.set_meta("isBuilt", true)
		#elif chunk.get_meta("isBuilt"):
		#	pass

func chooseMaterial(yCoordinate) ->int:
	if  yCoordinate == 0:
		return 0
	elif yCoordinate >= chunkSize-6:
		return 2
	elif yCoordinate <= chunkSize-6:
		return 1
	else:
		return 0

func chooseMaterialForMultiMesh(yCoordinate) ->int:
	if yCoordinate <= chunkSize-6:
		return 2
	elif yCoordinate >= chunkSize-6 and not yCoordinate == chunkSize-1:
		return 1
	else:
		return 0




func makeNoise() -> void:
	terrainNoise.seed = randi()
	terrainNoise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	terrainNoise.fractal_octaves = 4 #4
	terrainNoise.fractal_gain = 0.45 # 0.4
	terrainNoise.frequency = 0.025 #0.005


var MultiMeshGenerator

func useMultiMesh() -> void:
	for chunk in existingChunks:
		MultiMeshGenerator = MultiMeshInstance3D.new()
		chunk.add_child(MultiMeshGenerator)
		MultiMeshGenerator.reparent(chunk)
		#print(MultiMeshGenerator.get_parent())
		MultiMeshGenerator.position = Vector3(0, 0.5,0)
		#print("not updated MultiMesh")

		# Create the mesh and MultiMesh
		var mesh := BoxMesh.new()
		var mm := MultiMesh.new()

	
		var instance_count := chunkSize * chunkSize * chunkSize
		mm.mesh = mesh
		var shader := Shader.new()
		shader.code =  preload("res://shaders/shaderScript.gdshader").code

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
	
		# Fill the MultiMesh
		var i := 0
		for x in range(chunkSize):
			for y in range(chunkSize):
				for z in range(chunkSize):
					var height := terrainNoise.get_noise_2d(x + chunk.position.x, z + chunk.position.z ) * 10.0
					var pos := Vector3(x+0.05 , -y + height, z-0.05 )
					var bigTransform := Transform3D(Basis(), pos)
					
					mm.set_instance_transform(i, bigTransform)
				
					var color = Color(chooseMaterial(y) / 255.0, 0, 0, 1)
					mm.set_instance_custom_data(i, color)
					i += 1
