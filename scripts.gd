extends Node

#------------------commentMeanings---------------
#   '#???' == have to think about it
#   '~[]' == 'chunk'
#   '<^>' == disabled debug
#   '<>' == enabled debug
#------------------settings----------------------
var renderDistance:int = 10 #know, when to build ~[]
var detailRange:int                                        #???
var worldSize:int = 30
var chunkSize:int = 10
#------------------bools-------------------------
var isInRange:bool #true if ~[] is in 'renderDistance'
var isLoaded:bool #true if ~[] is built
var hasDetails:bool #true if ~[] is not made out of 'MultiMeshInstance3D'
var isInDetailRange:bool #true if ~[] is in 'detailRange'
#------------------blocks------------------------
@onready var grassBody: StaticBody3D = %GrassBody
@onready var dirtBody: StaticBody3D = %DirtBody
@onready var stoneBody: StaticBody3D = %StoneBody
@onready var copperBody: StaticBody3D = %CopperBody
@onready var ironBody: StaticBody3D = %IronBody

var blockTypes = {
	"grass" : preload("res://Blocks/GrassBlock.tscn"),
	"dirt" : preload("res://Blocks/DirtBlock.tscn"),
	"stone" : preload("res://Blocks/StoneBlock.tscn"),
	"copper" : preload("res://Blocks/CopperBlock.tscn"),
	"iron" : preload("res://Blocks/IronBlock.tscn")
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
	

func _process(_delta) -> void:
	if playerMoving():
		checkChunkRange()
		buildChunk()




func playerMoving() -> bool:
	if playerBody.velocity.x != 0 || playerBody.velocity.z != 0:
		return true
	else: return false

func checkChunkRange() -> void:
	var xRange1Coordinate := playerBody.position.x - renderDistance
	var zRange1Coordinate := playerBody.position.z - renderDistance
	var xRange2Coordinate := playerBody.position.x + renderDistance
	var zRange2Coordinate := playerBody.position.z + renderDistance
	
	var range1 := Vector3(xRange1Coordinate,0, zRange1Coordinate)
	var range2 := Vector3(xRange2Coordinate,0, zRange2Coordinate)
	
	for chunk:Node3D in chunkNodes:
		if chunk.position.x >= range1.x and chunk.position.x <= range2.x && chunk.position.z >= range1.z and chunk.position.z <= range2.z:
			chunk.set_meta("isInRange", true)


func generateChunkNodes() -> void:
	for xCoordinate in worldSize:
		for zCoordinate in worldSize:
			var newChunkNode = Node3D.new()
			
			newChunkNode.position = Vector3(xCoordinate,0,zCoordinate)
			newChunkNode.name = str(xCoordinate) + "_" + str(zCoordinate) + "_chunk"
			newChunkNode.set_meta("isInRange", false)
			newChunkNode.set_meta("isLoaded", false)
			newChunkNode.set_meta("hasDetails", false)
			newChunkNode.set_meta("isInDetailRange", false)
			chunkNodes.append(newChunkNode)

func buildChunk() -> void:
	for chunk in chunkNodes:
		if chunk.get_meta("isInRange"):
			for yCoordinate in chunkSize/4:
				for xCoordinate in chunkSize:
					for zCoordinate in chunkSize:
						var newBlock:StaticBody3D = blockTypes["grass"].instantiate()
						var perlinNoise:float = noise.get_noise_2d(xCoordinate, zCoordinate) * 1.5
						newBlock.position = Vector3(xCoordinate,yCoordinate + perlinNoise, zCoordinate)
						chunk.add_child(newBlock)
