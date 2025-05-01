extends  Node3D

#-------------settings-----------------
var worldSize:int = 30
var chunkSize:int = 10
var renderDistance:int = 10
var LLODR:int = renderDistance * 2 #Low Level Of Detail Range
#-------------neededThings-------------
var existingChunks:Array = []
#-------------noise--------------------
var terrainNoise:Noise = FastNoiseLite.new()
var extremeNoise:Noise = FastNoiseLite.new() #how extreme the mountains are or smt
var humidityNoise:Noise = FastNoiseLite.new()
var temperatureNoise:Noise = FastNoiseLite.new() #for biomes

@onready var playerBody: CharacterBody3D = %PlayerBody
@onready var notUsedBlocks: Node3D = %NotUsedBlocks

const blockPrefab = preload("res://Blocks/DirtBlock.tscn")

func _ready() -> void:
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
	for chunk in chunksToBuild:
		if chunk.get_meta("isInRange") && !chunk.get_meta("isBuilt"):
			for yCoordinate in chunkSize:
				for xCoordinate in chunkSize:
					for zCoordinate in chunkSize:
						var block:StaticBody3D = blockPrefab.instantiate()
						block.position = Vector3(xCoordinate, -yCoordinate, zCoordinate)
						block.get_child(0).visibility_range_end = LLODR
						chunk.add_child(block)
			chunk.set_meta("isBuilt", true)
