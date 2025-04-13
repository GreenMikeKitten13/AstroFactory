extends Node

#------------------commentMeanings---------------
#   '#???' == have to think about it
#   '~[]' == 'chunk'
#------------------settings----------------------
var renderDistance:int = 20 #know, when to build ~[]
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

var blockTypes : Dictionary = {
	"grass" : preload("res://Blocks/GrassBlock.tscn"),
	"dirt" : preload("res://Blocks/DirtBlock.tscn"),
	"stone" : preload("res://Blocks/StoneBlock.tscn"),
	"copper" : preload("res://Blocks/CopperBlock.tscn"),
	"iron" : preload("res://Blocks/IronBlock.tscn")
}
#------------------other stuff-------------------
@onready var playerBody: CharacterBody3D = %PlayerBody
var chunkNodes : Array = []
var noise :Noise = FastNoiseLite.new()


#------------------functions---------------------

func _ready() -> void:
	noise.seed = randi()
	noise.noise_type = FastNoiseLite.TYPE_PERLIN
	noise.frequency = 0.1
	noise.fractal_octaves = 4    #-> for smoother biomes
	noise.fractal_gain = 0.5     #-> for smoother biomes
	
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
	var xRange1Coordinate:float = playerBody.position.x - renderDistance
	var zRange1Coordinate :float= playerBody.position.z - renderDistance
	var xRange2Coordinate :float= playerBody.position.x + renderDistance
	var zRange2Coordinate :float= playerBody.position.z + renderDistance
	
	var range1:Vector3 = Vector3(xRange1Coordinate,0, zRange1Coordinate)
	var range2:Vector3 = Vector3(xRange2Coordinate,0, zRange2Coordinate)
	
	for chunk:Node3D in chunkNodes:
		if chunk.position.x >= range1.x and chunk.position.x <= range2.x && chunk.position.z >= range1.z and chunk.position.z <= range2.z:
			chunk.set_meta("isInRange", true)


func generateChunkNodes() -> void:
	for xCoordinate in worldSize:
		for zCoordinate in worldSize:
			var newChunkNode :Node3D = Node3D.new()
			
			newChunkNode.position = Vector3(xCoordinate * 10,0,zCoordinate * 10)
			newChunkNode.name = str(xCoordinate * 10) + "_" + str(zCoordinate * 10) + "_chunk"
			newChunkNode.set_meta("isInRange", false)
			newChunkNode.set_meta("isLoaded", false)
			newChunkNode.set_meta("hasDetails", false)
			newChunkNode.set_meta("isInDetailRange", false)
			chunkNodes.append(newChunkNode)
			add_child(newChunkNode)

func buildChunk() -> void:
	for chunk :Node3D in chunkNodes:
		if chunk.get_meta("isInRange") && !chunk.get_meta("isLoaded"):
			chunk.set_meta("isLoaded", true)
			for yCoordinate in chunkSize/4:
				for xCoordinate in chunkSize:
					for zCoordinate in chunkSize:
						var newBlock:StaticBody3D = blockTypes["grass"].instantiate()
						var perlinNoise:float = noise.get_noise_2d(xCoordinate + chunk.position.x    , zCoordinate  + chunk.position.z ) * 1.75
						newBlock.position = Vector3(xCoordinate,yCoordinate + perlinNoise, zCoordinate)
						chunk.add_child(newBlock)


func _on_timer_timeout() -> void:
	pass # Replace with function body.
