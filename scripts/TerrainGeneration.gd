extends Node
#------------------commentMeanings---------------
#   '#???' == have to think about it
#   '~[]' == 'chunk'
#------------------settings----------------------
var renderDistance:int = 15 #know, when to build ~[]
var detailRange:int                                        #???
var worldSize:int = 30
var chunkSize:int = 10
#------------------blocks------------------------
var blockTypes : Dictionary = {
	"grass" : preload("res://Blocks/GrassBlock.tscn"),
	"dirt" : preload("res://Blocks/DirtBlock.tscn"),
	"stone" : preload("res://Blocks/StoneBlock.tscn"),
	"copper" : preload("res://Blocks/CopperBlock.tscn"),
	"iron" : preload("res://Blocks/IronBlock.tscn"),
	"water" : preload("res://Blocks/WaterBlock.tscn"),
	"sand" : preload("res://Blocks/SandBlock.tscn"),
	"snow" : preload("res://Blocks/snowBlock.tscn"),
	"lava" : preload("res://Blocks/LavaBlock.tscn")
}
#------------------other stuff-------------------
@onready var playerBody: CharacterBody3D = %PlayerBody
var chunkNodes : Array = []
#var timeBetweenBlockCreation:float = 0.000000000000000001
var foundBlock:bool = false
var terrain_lookup = {
	"dry": {
		"hot": "sand",         # desert
		"normal": "dirt",      # steppe
		"cold": "snow",        # antarctica
	},
	"normally": {
		"hot": "grass",        # jungle
		"normal": "grass",     # plains
		"cold": "stone",       # mountains
	},
	"rainy": {
		"hot": "grass",        # BIG jungle
		"normal": "grass",     # BIG plains
		"cold": "stone",       # mountains
	},
	"snowy": {
		"hot": "lava",         # volcanic
		"normal": "stone",     # mountains
		"cold": "snow",        # snowy biome
	}
}
#------------------noise-------------------------
var humidityNoise = FastNoiseLite.new()
var tempetureNoise = FastNoiseLite.new()
var extremeNoise = FastNoiseLite.new()
var terrainNoise = FastNoiseLite.new()
#------------------functions---------------------

func _ready() -> void:
	humidityNoise.noise_type =  FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	humidityNoise.seed = randi()
	humidityNoise.frequency = 0.01
	#humidityNoise.fractal_lacunarity = 0.01
	#humidityNoise.fractal_octaves = 5
	#humidityNoise.fractal_gain = 0.001
	
	terrainNoise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	terrainNoise.seed = randi()
	terrainNoise.fractal_gain = 0.4


	extremeNoise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	extremeNoise.seed = randi()
	extremeNoise.frequency = 0.002
	extremeNoise.fractal_octaves = 2

	
	tempetureNoise.noise_type =  FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	tempetureNoise.seed = randi()
	#tempetureNoise.fractal_octaves = 5
	tempetureNoise.frequency = 0.01
	#tempetureNoise.fractal_lacunarity = 0.01
	#tempetureNoise.fractal_gain = 0.001

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
	var xRange1Coordinate:float = playerBody.position.x - renderDistance*3
	var zRange1Coordinate :float= playerBody.position.z - renderDistance*3
	var xRange2Coordinate :float= playerBody.position.x + renderDistance*3
	var zRange2Coordinate :float= playerBody.position.z + renderDistance*3
	
	var range1:Vector3 = Vector3(xRange1Coordinate,0, zRange1Coordinate)
	var range2:Vector3 = Vector3(xRange2Coordinate,0, zRange2Coordinate)
	
	for chunk:Node3D in chunkNodes:
		if chunk.position.x >= range1.x and chunk.position.x <= range2.x && chunk.position.z >= range1.z and chunk.position.z <= range2.z:
			chunk.set_meta("isInRange", true)

func generateChunkNodes() -> void:
	for xCoordinate:int in worldSize:
		for zCoordinate:int in worldSize:
			var newChunkNode :Node3D = Node3D.new()
			
			newChunkNode.position = Vector3(xCoordinate * 10 ,0, zCoordinate * 10)
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
						#if randf() <= 0.01: await get_tree().create_timer(timeBetweenBlockCreation).timeout
						
						foundBlock = false
						var xPos :float = xCoordinate + chunk.position.x
						var zPos :float = zCoordinate + chunk.position.z
						
						var humidityFloat:float = humidityNoise.get_noise_2d(zPos*0.5, zPos * 0.5) * 5  # <-0.5 = dry; <0 = normal; < 0.5 = rain; <1 = snow
						var tempertureFloat:float = tempetureNoise.get_noise_2d(xPos*0.3, zPos*0.3)*5# <-0.66 = cold; <0.32 = normal; <1 = hot  
						var extremeFloat:float = extremeNoise.get_noise_2d(xPos, zPos) * 15
						var terrainFloat:float = terrainNoise.get_noise_2d(xPos, zPos)
						var dominantBiome :String = getDominantBiome(humidityFloat, tempertureFloat,extremeFloat)
						var neededBlock = blockTypes[chooseBlockType(dominantBiome, yCoordinate)]
		
						var newBlock =  neededBlock.instantiate()
						newBlock.position = Vector3(xCoordinate, yCoordinate + clamp(terrainFloat * amplifier(dominantBiome), terrainFloat*26,33), zCoordinate)
						newBlock.get_child(0).visibility_range_end = renderDistance
						chunk.add_child(newBlock)
						newBlock.name = chooseBlockType(dominantBiome, yCoordinate)


func getDominantBiome(humidity:float, temperature:float,extreme:float) -> String:
	var humidityFix = ""
	var temperatureFix = ""
	var biomeFix = ""
	if humidity <= -0.5:
		humidityFix = "dry"
	elif humidity <= 0.0:
		humidityFix = "normally"
	elif humidity <= 0.5:
		humidityFix  = "rainy"
	elif humidity <= 1:
		humidityFix = "snowy"
	
	if temperature <=-0.66:
		temperatureFix = "cold"
	elif temperature <= 0.32:
		temperatureFix = "normal"
	elif temperature <= 1:
		temperatureFix = "hot"
	
	if extreme <= -2: 
		biomeFix = "flat"
	elif extreme <= 15: 
		biomeFix = "hills"
	return humidityFix + " " + temperatureFix + " " + biomeFix



func chooseBlockType(biome: String, yPos: int) -> String:
	var biomeParts = biome.split(" ")
	var humidity = biomeParts[0]
	var temperature = biomeParts[1]
	var isSurface = chunkSize == yPos + 1
	var underGround = !isSurface && chunkSize < yPos + 5
	
	if isSurface:
		if humidity in terrain_lookup and temperature in terrain_lookup[humidity]:
			return terrain_lookup[humidity][temperature]
	elif underGround:
		if humidity in terrain_lookup and temperature in terrain_lookup[humidity]:
			if  terrain_lookup[humidity][temperature] == "sand":
				return "sand"
			elif   terrain_lookup[humidity][temperature] == "snow":
				return "snow"
			elif terrain_lookup[humidity][temperature] == "stone":
				return "stone"
			else:
				return "dirt"
	else:
		return "stone"
	return "stone"


func amplifier(biome:String) -> float:
	var prefixes = biome.split(" ")
	var extremity = prefixes[2]
	if extremity == "flat":
		return 20.0
	else:
		return 66.0
