extends Node

@onready var prefab := $"../DirtBody"
var gridSize := 30
var noise := FastNoiseLite.new()
var timeSinceCheck := 0.0
var terrainBlocks := []
var terrainBlocksNumber := 0
var chunkSize := 10
var chunks := 0
var terrainChunks := []
var chunksSavings := {}
@export var renderDistance := 20
@export var chunkConvertDistance := 60.0

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
				var prefab: Node3D
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
				
				for child in new_block.get_children():
					if child is MeshInstance3D:
						child.visibility_range_end = renderDistance
				
				#here ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

				# Get chunk position
				var chunk_x = int(xCoordinate / chunkSize)
				var chunk_z = int(zCoordinate / chunkSize)
				var chunk_key = str(chunk_x) + "_" + str(chunk_z)

				# Create chunk if needed
				if not chunksSavings.has(chunk_key):
					var chunk = Node3D.new()
					chunk.name = "Chunk_" + chunk_key
					chunk.position = Vector3.ZERO
					add_child(chunk)
					terrainChunks.append({
					
						"node": chunk,
						"position": chunk.position,
						"is_multimesh": false,
						"original_data": []
					})

					chunksSavings[chunk_key] = chunk

				# Add block to chunk
				chunksSavings[chunk_key].add_child(new_block)
				terrainBlocks.append(new_block)
				terrainBlocksNumber += 1

	



func _process(delta):
	timeSinceCheck += delta
	if timeSinceCheck + randf() > 0.08:
		timeSinceCheck = 0
		for chunk_data in terrainChunks:
			var chunk_node = chunk_data["node"]
			var chunk_pos = chunk_data["position"]
			var dist = $"../PlayerBody".global_position.distance_to(chunk_pos)

			if dist > chunkConvertDistance and not chunk_data["is_multimesh"]:
				var multimesh_instance = convert_chunk_to_multimesh(chunk_node)
				if multimesh_instance:
					chunk_data["original_data"] = capture_original_chunk_data(chunk_node)
					get_parent().add_child(multimesh_instance)
					chunk_data["node"] = multimesh_instance
					chunk_data["is_multimesh"] = true

			elif dist <= chunkConvertDistance and chunk_data["is_multimesh"]:
				var restored = restore_chunk_from_multimesh(chunk_data["original_data"])
				get_parent().add_child(restored)
				chunk_data["node"].queue_free()
				chunk_data["node"] = restored
				chunk_data["is_multimesh"] = false

			# Per-block visibility handling
			if not chunk_data["is_multimesh"]:
				for block in chunk_node.get_children():
					if block.get_node_or_null("VisibleOnScreenNotifier3D") and block.get_node("VisibleOnScreenNotifier3D").is_on_screen():
						for child in block.get_children():
							if child is MeshInstance3D:
								child.visible = true
					else:
						for child in block.get_children():
							if child is MeshInstance3D:
								child.visible = false


func convert_chunk_to_multimesh(chunk_node: Node3D) -> MultiMeshInstance3D:
	var multimesh := MultiMesh.new()
	var mesh_instance := MultiMeshInstance3D.new()
	var transforms := []

	var meshes = []
	
	for child in chunk_node.get_children():
		if child is MeshInstance3D:
			meshes.append(child.mesh)
			transforms.append(child.transform)

	# Use the first mesh as base (optional: split multimeshes by mesh type)
	if meshes.size() == 0:
		return null
	
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.instance_count = transforms.size()

	for i in transforms.size():
		multimesh.set_instance_transform(i, transforms[i])

	mesh_instance.multimesh = multimesh
	mesh_instance.mesh = meshes[0]  # assumes all same mesh for now
	chunk_node.queue_free()  # remove old node

	return mesh_instance


func capture_original_chunk_data(chunk_node: Node3D) -> Array:
	var data := []
	for block in chunk_node.get_children():
		var entry = {
			"scene": block, # Or prefab reference if instanced
			"transform": block.transform
		}
		data.append(entry)
	return data


func restore_chunk_from_multimesh(data):
	var chunk_node := Node3D.new()
	for block_data in data:
		var instance = block_data["scene"].instantiate()
		instance.transform = block_data["transform"]
		chunk_node.add_child(instance)
	return chunk_node
