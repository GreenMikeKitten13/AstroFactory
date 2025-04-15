extends Node
#------------------commentMeanings---------------
#   '#???' == have to think about it
#   '~[]' == 'chunk'
#------------------settings----------------------
var renderDistance:int = 60 #know, when to build ~[]
var detailRange:int                                        #???
var worldSize:int = 30
var chunkSize:int = 10
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
	"iron" : preload("res://Blocks/IronBlock.tscn"),
	"water" : preload("res://Blocks/WaterBlock.tscn"),
	"sand" : preload("res://Blocks/SandBlock.tscn")
}
#------------------other stuff-------------------
@onready var playerBody: CharacterBody3D = %PlayerBody
var chunkNodes : Array = []
const BIOMES :Array = ["desert", "plains", "forest", "mountains"]
var timeBetweenBlockCreation:float = 0.00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001
#------------------noise-------------------------
var noise :Noise = FastNoiseLite.new()
var baseTerrainNoise: Noise = FastNoiseLite.new()
var desertNoise: Noise = FastNoiseLite.new()
var plainsNoise: Noise = FastNoiseLite.new()
var mountainNoise: Noise = FastNoiseLite.new()
var biomeBlendNoise: Noise = FastNoiseLite.new()
#------------------functions---------------------

func _ready() -> void:
	noise.seed = randi()
	noise.noise_type = FastNoiseLite.TYPE_PERLIN
	noise.frequency = 0.1
	
	# Biome selection noise
	biomeBlendNoise.seed = randi()
	biomeBlendNoise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	biomeBlendNoise.frequency = 0.01  # Bigger areas for biomes

	# Base terrain variation
	baseTerrainNoise.seed = randi()
	baseTerrainNoise.noise_type = FastNoiseLite.TYPE_PERLIN
	baseTerrainNoise.frequency = 0.1

	# Biome-specific shape
	desertNoise.seed = randi()
	desertNoise.noise_type = FastNoiseLite.TYPE_PERLIN
	desertNoise.frequency = 0.08

	plainsNoise.seed = randi()
	plainsNoise.noise_type = FastNoiseLite.TYPE_PERLIN
	plainsNoise.frequency = 0.1
	
	mountainNoise.seed = randi()
	mountainNoise.noise_type = FastNoiseLite.TYPE_PERLIN
	mountainNoise.frequency = 0.03  # Mountains = larger features
	
	generateChunkNodes()
	checkChunkRange()
	buildChunk()

func _process(_delta:float) -> void:
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
	for xCoordinate:int in worldSize:
		for zCoordinate:int in worldSize:
			var newChunkNode :Node3D = Node3D.new()
			
			newChunkNode.position = Vector3(xCoordinate * 10,0,zCoordinate * 10)
			newChunkNode.name = str(xCoordinate * 10) + "_" + str(zCoordinate * 10) + "_chunk"
			newChunkNode.set_meta("isInRange", false)
			newChunkNode.set_meta("isLoaded", false)
			newChunkNode.set_meta("hasDetails", false)
			newChunkNode.set_meta("isInDetailRange", false)
			newChunkNode.set_meta("renderDistance", renderDistance)
			chunkNodes.append(newChunkNode)
			add_child(newChunkNode)

func buildChunk() -> void:
	for chunk :Node3D in chunkNodes:
		if chunk.get_meta("isInRange") && !chunk.get_meta("isLoaded"):
			chunk.set_meta("isLoaded", true)
			for yCoordinate:int in chunkSize:
				for xCoordinate:int in chunkSize:
					for zCoordinate:int in chunkSize:
						if randf() <= 0.01: await get_tree().create_timer(timeBetweenBlockCreation).timeout
						
						var xPos :float = xCoordinate + chunk.position.x
						var zPos :float = zCoordinate + chunk.position.z
						
						var perlinNoise:float = noise.get_noise_2d(xPos, zPos) * 1.75
						var weights :Dictionary = get_biome_weights(xPos, zPos)
						
						var desertPossibility :float = desertNoise.get_noise_2d(xPos, zPos) * 1.2
						var plainsPossibility :float = plainsNoise.get_noise_2d(xPos, zPos) * 1.75
						var mountainPossibility :float = mountainNoise.get_noise_2d(xPos, zPos) * 3.0
						
						var height :float = (
									desertPossibility * weights["desert"] +
									plainsPossibility * weights["plains"] +
									mountainPossibility * weights["mountains"]
									 )
						var dominantBiome : String = ""
						var highestWeight :float = -INF

						for biome :String in weights.keys():
							if weights[biome] > highestWeight:
									highestWeight = weights[biome]
									dominantBiome = biome

																				
						var newBlock:StaticBody3D = blockTypes[chooseBlockType(height, yCoordinate,dominantBiome)].instantiate()
						var blockMesh : MeshInstance3D = newBlock.get_child(0)
						newBlock.position = Vector3(xCoordinate,yCoordinate + perlinNoise, zCoordinate)
						blockMesh.visibility_range_end = renderDistance/2.0
						chunk.add_child(newBlock)

func chooseBlockType(noiseNumb:float, yCoordinate:int, biomeType: String) -> String:
	if biomeType == "desert":
		if yCoordinate > chunkSize - 5:
			return "sand"
		elif randf() < 0.185:
			return "copper"
		else:
			return "stone"

	elif biomeType == "plains":
		if yCoordinate == chunkSize - 1 && noiseNumb > 0.45:
			return "water"
		elif yCoordinate == chunkSize - 1 && noiseNumb > 0.375 && noiseNumb < 0.45:
			return "sand"
		elif yCoordinate == chunkSize -1:
			return "grass"
		elif yCoordinate > chunkSize - 4:
			return "dirt"
		else:
			return "stone"

	elif biomeType == "mountains":
		if yCoordinate == chunkSize - 1:
			return "stone"
		elif yCoordinate > chunkSize - 7 && yCoordinate < chunkSize - 3 && randf() < 0.125:
			return "copper"
		elif yCoordinate < chunkSize - 5 && randf() < 0.25:
			return "iron"
		else:
			return "stone"

	return "stone"




func get_biome_weights(x: float, z: float) -> Dictionary:
	var blend :float = (biomeBlendNoise.get_noise_2d(x, z) + 1.0) / 2.0  # Normalize -1..1 to 0..1
	var weights : Dictionary= {}

	var biome_count :int = BIOMES.size()
	var step :float = 1.0 / (biome_count - 1)

	for i:int in BIOMES.size():
		var biome_name :String= BIOMES[i]
		var center :float = i * step
		var distance :float = abs(blend - center)
		
		# Smooth falloff, tweak 0.25 for wider/narrower blending
		var weight :float = clamp(1.0 - (distance / step), 0, 1)
		weights[biome_name] = weight

	# Normalize weights so total = 1
	var total :float = 0.0
	for w : float in weights.values():
		total += w
	if total > 0.0:
		for key :String in weights:
			weights[key] /= total

	return weights
