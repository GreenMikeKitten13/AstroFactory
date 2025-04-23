extends Node3D

# Settings
var renderDistance := 15
var chunkSize := 10
var worldSize := 15

# Scene and materials
var blockScene := preload("res://Blocks/DirtBlock.tscn")
@onready var playerBody := %PlayerBody
var baseMaterial := preload("res://Blocks/Textures+Objects/shaderTerrainGenerationScript.tres")

# Noise setup
var terrainNoise := FastNoiseLite.new()
var humidityNoise := FastNoiseLite.new()
var temperatureNoise := FastNoiseLite.new()
var extremeNoise := FastNoiseLite.new()

# Chunk tracking
var chunkNodes := []

# Block type mapping
var block_type_to_index := {
	"grass": 0,
	"dirt": 1,
	"stone": 2,
	"sand": 3,
	"copper": 4,
	"iron": 5,
	"snow": 6,
	"lava": 7
}

func _ready() -> void:
	terrainNoise.seed = randi()
	terrainNoise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	terrainNoise.fractal_gain = 0.4
	humidityNoise.seed = randi()
	temperatureNoise.seed = randi()
	extremeNoise.seed = randi()
	buildChunkNodes()
	updateChunks()

func _process(_delta: float) -> void:
	if playerBody.velocity.length() > 0.1:
		updateChunks()
		buildVisibleChunks()

func buildChunkNodes() -> void:
	for x in worldSize:
		for z in worldSize:
			var chunk := Node3D.new()
			var pos = Vector3(x * chunkSize, 0, z * chunkSize)
			chunk.position = pos
			chunk.name = "chunk_%d_%d" % [x, z]
			chunk.set_meta("loaded", false)
			add_child(chunk)
			chunkNodes.append(chunk)

func updateChunks() -> void:
	var px = playerBody.position.x
	var pz = playerBody.position.z
	for chunk in chunkNodes:
		var dx = abs(chunk.position.x - px)
		var dz = abs(chunk.position.z - pz)
		var in_range = dx < renderDistance * chunkSize and dz < renderDistance * chunkSize
		chunk.set_meta("in_range", in_range)

func buildVisibleChunks() -> void:
	for chunk in chunkNodes:
		if chunk.get_meta("in_range") and not chunk.get_meta("loaded"):
			chunk.set_meta("loaded", true)
			generateChunk(chunk)

func generateChunk(chunk: Node3D) -> void:
	for x in chunkSize:
		for z in chunkSize:
			var wx = x + chunk.position.x
			var wz = z + chunk.position.z
			var height := int(terrainNoise.get_noise_2d(wx, wz) * 10.0 + 15.0)
			for y in range(height):
				var block: StaticBody3D = blockScene.instantiate()
				block.position = Vector3(x, y, z)

				var mat = baseMaterial.duplicate()
				var humidity = humidityNoise.get_noise_2d(wx, wz)
				var temp = temperatureNoise.get_noise_2d(wx, wz)
				var extreme = extremeNoise.get_noise_2d(wx, wz)

				# Decide block type by depth
				var block_type := ""
				if y == height - 1:
					block_type = getSurfaceBlock(humidity, temp, extreme)
				elif y > height - 5:
					block_type = "dirt"
				else:
					block_type = "stone"

				var idx = block_type_to_index.get(block_type, 0)
				mat.set_shader_parameter("index", idx)
				block.get_child(0).material_override = mat
				chunk.add_child(block)

func getSurfaceBlock(h: float, t: float, _e: float) -> String:
	if h < -0.4:
		return "sand" if t > 0.2 else "stone"
	elif h < 0.3:
		return "dirt"
	elif h >= 0.3 and t < 0:
		return "snow"
	else:
		return "grass"
