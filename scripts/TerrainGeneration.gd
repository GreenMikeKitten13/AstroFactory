extends Node

#------------------commentMeanings---------------
# '#???' == have to think about it
# '~[]' == 'chunk'

#------------------settings----------------------
var renderDistance: int = 30
var detailRange: int = 0 # Placeholder
var worldSize: int = 30
var chunkSize: int = 15
#------------------blocks------------------------
var blockTypes: Dictionary = {
	"grass": preload("res://Blocks/GrassBlock.tscn"),
	"dirt": preload("res://Blocks/DirtBlock.tscn"),
	"stone": preload("res://Blocks/StoneBlock.tscn"),
	"copper": preload("res://Blocks/CopperBlock.tscn"),
	"iron": preload("res://Blocks/IronBlock.tscn"),
	"water": preload("res://Blocks/WaterBlock.tscn"),
	"sand": preload("res://Blocks/SandBlock.tscn"),
	"snow": preload("res://Blocks/SnowBlock.tscn"),
	"lava": preload("res://Blocks/LavaBlock.tscn"),
	"air": preload("res://Blocks/AirBlock.tscn")
}

#------------------other stuff-------------------
@onready var playerBody: CharacterBody3D = %PlayerBody
var chunkNodes: Array = []
var foundBlock: bool = false
var terrain_lookup = {
	"dry": { "hot": "sand", "normal": "dirt", "cold": "snow" },
	"normally": { "hot": "grass", "normal": "grass", "cold": "stone" },
	"rainy": { "hot": "grass", "normal": "grass", "cold": "stone" },
	"snowy": { "hot": "lava", "normal": "stone", "cold": "snow" }
}
var chunk_thread = Thread.new()
var thread_data: Array = []

#------------------noise-------------------------
var humidityNoise = FastNoiseLite.new()
var tempetureNoise = FastNoiseLite.new()
var extremeNoise = FastNoiseLite.new()
var terrainNoise = FastNoiseLite.new()
var ironNoise = FastNoiseLite.new()
var copperNoise = FastNoiseLite.new()
var caveNoise = FastNoiseLite.new()

#------------------functions---------------------
func _ready() -> void:
	randomize()
	
	humidityNoise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	humidityNoise.seed = randi()
	humidityNoise.frequency = 0.01
	
	tempetureNoise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	tempetureNoise.seed = randi()
	tempetureNoise.frequency = 0.01
	
	terrainNoise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	terrainNoise.seed = randi()
	terrainNoise.fractal_gain = 0.4
	
	extremeNoise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	extremeNoise.seed = randi()
	extremeNoise.frequency = 0.002
	extremeNoise.fractal_octaves = 2
	
	caveNoise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	caveNoise.seed = randi()

	copperNoise.noise_type = FastNoiseLite.TYPE_PERLIN
	copperNoise.seed = randi()
	copperNoise.frequency = 0.01
	copperNoise.fractal_gain = 0.5
	
	ironNoise.noise_type = FastNoiseLite.TYPE_PERLIN
	ironNoise.seed = randi()
	ironNoise.frequency = 0.01
	ironNoise.fractal_gain = 0.5

	generateChunkNodes()
	checkChunkRange()
	buildChunk()

func _process(_delta: float) -> void:
	if playerMoving():
		checkChunkRange()
		buildChunk()
		
	if chunk_thread.is_started() and not chunk_thread.is_alive():
		var result = chunk_thread.wait_to_finish()
		thread_data.append(result)
		
	if thread_data.size() > 0:
		var chunk_result = thread_data.pop_front()
		var parent_chunk = findChunkByPosition(chunk_result["chunk"])
		if parent_chunk:
			for block in chunk_result["blocks"]:
				var scene = blockTypes.get(block["name"])
				if scene:
					var inst = scene.instantiate()
					inst.position = block["pos"]
					inst.get_child(0).visibility_range_end = renderDistance
					parent_chunk.add_child(inst)
					inst.name = block["name"]



func playerMoving() -> bool:
	return playerBody.velocity.x != 0 or playerBody.velocity.z != 0

func checkChunkRange() -> void:
	var x1 = playerBody.position.x - renderDistance * 3
	var z1 = playerBody.position.z - renderDistance * 3
	var x2 = playerBody.position.x + renderDistance * 3
	var z2 = playerBody.position.z + renderDistance * 3
	
	for chunk in chunkNodes:
		if chunk.position.x >= x1 and chunk.position.x <= x2 and chunk.position.z >= z1 and chunk.position.z <= z2:
			chunk.set_meta("isInRange", true)

func generateChunkNodes() -> void:
	for x in worldSize:
		for z in worldSize:
			var newChunkNode = Node3D.new()
			newChunkNode.position = Vector3(x * chunkSize, 0, z * chunkSize)
			newChunkNode.name = str(x * chunkSize) + "_" + str(z * chunkSize) + "_chunk"
			newChunkNode.set_meta("isInRange", false)
			newChunkNode.set_meta("isLoaded", false)
			chunkNodes.append(newChunkNode)
			add_child(newChunkNode)

func buildChunk():
	if chunk_thread.is_alive():
		return
	for chunk in chunkNodes:
		if chunk.get_meta("isInRange") and !chunk.get_meta("isLoaded") and !chunk_thread.is_alive():
			await get_tree().create_timer(0.05).timeout
			if chunk_thread.is_alive(): return 
			if chunk_thread.is_alive(): chunk.set_meta("isLoaded", false)
			
			chunk.set_meta("isLoaded", true)
			chunk_thread.start(threaded_chunk_builder.bind(chunk.position))
			return

func findChunkByPosition(pos: Vector3) -> Node3D:
	for chunk in chunkNodes:
		if chunk.position == pos:
			return chunk
	return null

func getDominantBiome(humidity: float, temperature: float, extreme: float) -> String:
	var humidityFix = ""
	var temperatureFix = ""
	var biomeFix = ""
	
	if humidity <= -0.5:
		humidityFix = "dry"
	elif humidity <= 0.0:
		humidityFix = "normally"
	elif humidity <= 0.5:
		humidityFix = "rainy"
	else:
		humidityFix = "snowy"

	if temperature <= -0.66:
		temperatureFix = "cold"
	elif temperature <= 0.32:
		temperatureFix = "normal"
	else:
		temperatureFix = "hot"

	if extreme <= -2:
		biomeFix = "flat"
	else:
		biomeFix = "hills"

	return humidityFix + " " + temperatureFix + " " + biomeFix

func chooseBlockType(biome: String, yPos: int, iron: float, copper: float, cave: float) -> String:
	var biomeParts = biome.split(" ")
	var humidity = biomeParts[0]
	var temperature = biomeParts[1]
	var isSurface = chunkSize == yPos + 1
	var underGround = !isSurface and chunkSize < yPos + 5
	var oreMinSpawn = chunkSize > yPos + 2
	
	if isSurface:
		if cave < 2.6:
			return "air"
		if humidity in terrain_lookup and temperature in terrain_lookup[humidity]:
			return terrain_lookup[humidity][temperature]
	elif underGround:
		if cave < 2.2:
			return "air"
		if humidity in terrain_lookup and temperature in terrain_lookup[humidity]:
			var block = terrain_lookup[humidity][temperature]
			if block in ["sand", "snow", "stone"]:
				return block
			else:
				return "dirt"
	elif oreMinSpawn:
		if iron < -0.4:
			return "iron"
		elif copper < -0.2:
			return "copper"
		elif cave < 2.0:
			return "air"
	return "stone"

func amplifier(biome: String) -> float:
	var prefixes = biome.split(" ")
	var extremity = prefixes[2]
	return 20.0 if extremity == "flat" else 66.0

func threaded_chunk_builder(chunk_pos: Vector3) -> Dictionary:
	var blocks = []
	for y in chunkSize:
		for x in chunkSize:
			for z in chunkSize:
				var xPos = x + chunk_pos.x
				var zPos = z + chunk_pos.z

				var humidity = humidityNoise.get_noise_2d(zPos * 0.5, zPos * 0.5) * 5
				var temp = tempetureNoise.get_noise_2d(xPos * 0.3, zPos * 0.3) * 5
				var extreme = extremeNoise.get_noise_2d(xPos, zPos) * 15
				var terrainFloat = terrainNoise.get_noise_2d(xPos, zPos)
				var dominant = getDominantBiome(humidity, temp, extreme)

				var copper = copperNoise.get_noise_3d(x, y, z)
				var iron = ironNoise.get_noise_3d(x, y, z)
				var cave = ((caveNoise.get_noise_3d(x + chunk_pos.x, y, z + chunk_pos.z) + 1) / 2) * 5

				var block_name = chooseBlockType(dominant, y, iron, copper, cave)
				var height_offset = clamp(terrainFloat * amplifier(dominant), terrainFloat * 26, 33)

				blocks.append({
					"name": block_name,
					"pos": Vector3(x, y + height_offset, z)
				})

	return {
		"chunk": chunk_pos,
		"blocks": blocks
	}
