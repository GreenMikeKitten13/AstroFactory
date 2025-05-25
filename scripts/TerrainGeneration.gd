extends  Node3D

#-------------settings-----------------
var worldSize:int = 30
var chunkSize:int = 10
var renderDistance:int = 30
var LLODR:int = renderDistance * 2 #Low Level Of Detail Range
#-------------neededThings-------------
var existingChunks:Array = []
#-------------noise--------------------
var terrainNoise:Noise = FastNoiseLite.new()
var extremeNoise:Noise = FastNoiseLite.new() #how extreme the mountains are or smt
var humidityNoise:Noise = FastNoiseLite.new()
var temperatureNoise:Noise = FastNoiseLite.new() #for biomes

var thread:Thread = Thread.new()

@onready var playerBody: CharacterBody3D = %PlayerBody
#@onready var notUsedBlocks: Node3D = %NotUsedBlocks

const blockPrefab = preload("res://Blocks/DirtBlock.tscn")

func _ready() -> void:
	makeNoise()
	makeChunkNodes()
	await get_tree().create_timer(0.05).timeout
	buildChunks(existingChunks)

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
			for yCoordinate in chunkSize:
				for xCoordinate in chunkSize:
					for zCoordinate in chunkSize:
						
						#var xPos = x + chunk_pos.x
						#var zPos = z + chunk_pos.z
						
						var block:StaticBody3D = blockPrefab.instantiate()
						var flatNoise = terrainNoise.get_noise_2d(xCoordinate + chunk.position.x, zCoordinate + chunk.position.z) * 10
						
						block.position = Vector3(xCoordinate, -yCoordinate + flatNoise, zCoordinate)
						block.get_child(0).visibility_range_end = LLODR
						
						
						print(block.name)
						chunk.add_child(block)
			chunk.set_meta("isBuilt", true)

func decideBlock():
	pass

func makeNoise():
	terrainNoise.seed = randi()
	terrainNoise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	terrainNoise.fractal_octaves = 4
	terrainNoise.fractal_gain = 0.4
	terrainNoise.frequency = 0.005
