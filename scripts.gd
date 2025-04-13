extends Node

#------------------commentMeanings---------------
#   '#???' == have to think about it
#   '~[]' == 'chunk'
#   '<^>' == disabled debug
#   '<>' == enabled debug
#------------------settings----------------------
var renderDistance:int = 10 # know when to build ~[]
var detailRange:int                                        # ???
var worldSize:int = 30
var chunkSize:int = 10
#------------------bools-------------------------
var isInRange:bool        # true if ~[] is in 'renderDistance'
var isLoaded:bool         # true if ~[] is built
var hasDetails:bool       # true if ~[] is not made out of MultiMeshInstance3D
var isInDetailRange:bool  # true if ~[] is in 'detailRange'
#------------------blocks------------------------
@onready var grassBody: StaticBody3D = %GrassBody
@onready var dirtBody: StaticBody3D = %DirtBody
@onready var stoneBody: StaticBody3D = %StoneBody
@onready var copperBody: StaticBody3D = %CopperBody
@onready var ironBody: StaticBody3D = %IronBody

var blockTypes = {
	"grass": preload("res://Blocks/GrassBlock.tscn"),
	"dirt": preload("res://Blocks/DirtBlock.tscn"),
	"stone": preload("res://Blocks/StoneBlock.tscn"),
	"copper": preload("res://Blocks/CopperBlock.tscn"),
	"iron": preload("res://Blocks/IronBlock.tscn")
}
#------------------other stuff-------------------
@onready var playerBody: CharacterBody3D = %PlayerBody
var chunkNodes := []
var noise := FastNoiseLite.new()

#------------------functions---------------------

func _ready() -> void:
	noise.seed = randi()
	noise.noise_type = FastNoiseLite.TYPE_PERLIN
	noise.frequency = 0.1
	
	generateChunkNodes()
	checkChunkRange()
	buildChunk()

func _process(_delta: float) -> void:
	if playerMoving():
		checkChunkRange()
		buildChunk()

func playerMoving() -> bool:
	return playerBody.velocity.x != 0 or playerBody.velocity.z != 0

func checkChunkRange() -> void:
	var x1 := playerBody.position.x - renderDistance
	var z1 := playerBody.position.z - renderDistance
	var x2 := playerBody.position.x + renderDistance
	var z2 := playerBody.position.z + renderDistance

	for chunk: Node3D in chunkNodes:
		var chunkPos := chunk.position
		var inRange := chunkPos.x >= x1 and chunkPos.x <= x2 and chunkPos.z >= z1 and chunkPos.z <= z2
		chunk.set_meta("isInRange", inRange)

func generateChunkNodes() -> void:
	for x in range(worldSize):
		for z in range(worldSize):
			var newChunkNode = Node3D.new()
			newChunkNode.position = Vector3(x * chunkSize, 0, z * chunkSize)
			newChunkNode.name = str(x * chunkSize) + "_" + str(z * chunkSize) + "_chunk"
			newChunkNode.set_meta("isInRange", false)
			newChunkNode.set_meta("isLoaded", false)
			newChunkNode.set_meta("hasDetails", false)
			newChunkNode.set_meta("isInDetailRange", false)
			chunkNodes.append(newChunkNode)
			add_child(newChunkNode)

func buildChunk() -> void:
	for chunk in chunkNodes:
		if chunk.get_meta("isInRange") and not chunk.get_meta("isLoaded"):
			chunk.set_meta("isLoaded", true)
			for y in range(chunkSize / 4):
				for x in range(chunkSize):
					for z in range(chunkSize):
						var newBlock: StaticBody3D = blockTypes["grass"].instantiate()
						var worldX: int = int(chunk.position.x) + x
						var worldZ: int = int(chunk.position.z) + z
						var height: float = noise.get_noise_2d(worldX, worldZ) * 1.5
						newBlock.position = Vector3(x, y + height, z)
						chunk.add_child(newBlock)
