extends Node

@onready var prefab := $"../DirtBody"
var gridSize := 30
var noise := FastNoiseLite.new()
var timeSinceCheck := 0.0
var terrainBlocks := []
var terrainBlocksNumber := 0
var chunkSize := 10
var chunks := 0
var chunksSavings := {}

func _ready():
	makeNoise()
	decideAndMakeTerrain()



func makeNoise():
	noise.seed = randi()
	noise.noise_type = FastNoiseLite.TYPE_PERLIN
	noise.frequency = 0.1


func decideAndMakeTerrain():
	for yCoordinate in range(int(gridSize / 2)):
		for zCoordinate in range(int(gridSize)):
			for xCoordinate in range(int(gridSize)):

				var height := noise.get_noise_2d(xCoordinate, zCoordinate) * 1.5
				var randomNumb = randf()

				# Default prefab logic
				if yCoordinate <= gridSize / 2 - 7:
					prefab = $"../StoneBody"
				else:
					prefab = $"../DirtBody"
				if yCoordinate == gridSize / 2 - 1:
					prefab = $"../GrassBody"
				if height < 0.005 and yCoordinate == gridSize / 2 - 1:
					prefab = $"../WaterBody"
				elif yCoordinate == gridSize / 2 - 1:
					prefab = $"../GrassBody"
				if prefab == $"../StoneBody" and randomNumb >= 0.9:
					prefab = $"../CopperBody"
				elif prefab == $"../StoneBody" and randomNumb >= 0.8:
					prefab = $"../IronBody"
				elif yCoordinate <= gridSize / 2 - 7:
					prefab = $"../StoneBody"

				var new_block = prefab.duplicate()
				new_block.position = Vector3(xCoordinate, height - 9 + yCoordinate, zCoordinate)

				# Get chunk position
				var chunk_x = int(xCoordinate / chunkSize)
				var chunk_z = int(zCoordinate / chunkSize)
				var chunk_key = str(chunk_x) + "_" + str(chunk_z)

				# Create chunk if needed
				if not chunksSavings.has(chunk_key):
					var chunk = Node3D.new()
					chunk.name = "Chunk_" + chunk_key
					chunk.position = Vector3.ZERO #(chunk_x * chunkSize, 0, chunk_z * chunkSize)
					add_child(chunk)
					chunksSavings[chunk_key] = chunk
					print(chunk) 

				# Add block to chunk
				chunksSavings[chunk_key].add_child(new_block)
				terrainBlocks.append(new_block)
				terrainBlocksNumber += 1
	



func _process(delta):
	timeSinceCheck += delta
	if timeSinceCheck + randf() > 0.08:
		timeSinceCheck = 0
		for block in terrainBlocks:
			if block.get_node("VisibleOnScreenNotifier3D").is_on_screen():
				for child in block.get_children():
					if child is MeshInstance3D:
						child.visible = true
			else:
				for child in block.get_children():
					if child is MeshInstance3D:
						child.visible = false
