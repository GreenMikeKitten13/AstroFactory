extends Node3D

var worldsize:int = 300
var chunkSize:int = 10
var yMultiplier:int = 1

var chunkThread:Thread = Thread.new()

var chunksDict:Dictionary = {}

var terrainFlatNoise:Noise = FastNoiseLite.new()
var terrainNormalNoise:Noise = FastNoiseLite.new()
var terrainExtremeNoise:Noise = FastNoiseLite.new()

func _ready() -> void:
	generateChunkNodes()


func _process(_delta: float) -> void:
	chunksDict = updateChunksDict(chunksDict)

func generateChunkNodes() -> void:
	for xCoordinate:int in worldsize:
		for zCoordinate:int in worldsize:
			var chunk:Node3D = Node3D.new()
			var chunkPos:Vector3i = Vector3i(xCoordinate, 0, zCoordinate)
			var info:Dictionary = {"position" : chunkPos, "isBuilt" : false, "isInBuildRange" :false, "IsInInfoRange" : false, "isInRenderRange" : false, "isRendered" : false, "blocks" : []}
			var chunkName:String = str(xCoordinate) + ", " + str(zCoordinate)
			chunk.position = chunkPos
			if chunkPos == Vector3i.ZERO:
				info["IsInInfoRange"] = true
				info["isInRenderRange"] = true
				info["isInBuildRange"] = true
			chunk.name = chunkName
			chunk.set_meta("info", info)
			chunksDict[chunkName] = info

func updateChunksDict(chunks:Dictionary) ->Dictionary:
	var newChunksDict:Dictionary = {}
	for chunkName:String in chunks:
		var realChunk:Node3D = self.find_child(chunkName)
		var realChunkInfo:Dictionary = realChunk.get_meta("info")
		newChunksDict[chunkName] = realChunkInfo

	return newChunksDict

func getBlocksInfo(chunks:Dictionary) -> Dictionary:
	var chunksBlocks:Dictionary = {}

	for chunkName:String in chunks:
		var blocksInChunk:Array = []

		for yCoordinate:int in range(chunkSize * yMultiplier):
			for xCoordinate:int in range(chunkSize):
				for zCoordinate:int in range(chunkSize):
					var terrainFlatFloat:float = terrainFlatNoise.get_noise_2d(xCoordinate, zCoordinate)
					var terrainNormalFloat:float = terrainNormalNoise.get_noise_2d(xCoordinate, zCoordinate)
					var terrainExtremeFloat:float = terrainExtremeNoise.get_noise_2d(xCoordinate, zCoordinate)
					var heightNoise:float = ((terrainExtremeFloat + terrainFlatFloat + terrainNormalFloat) / 3.0) / 10.0

					var blockPosition:Vector3 = Vector3(xCoordinate, yCoordinate + heightNoise, zCoordinate)
					blocksInChunk.append(blockPosition)

		chunksBlocks[chunkName] = blocksInChunk

	return chunksBlocks


#func generateChunks(chunks:Dictionary) -> void:
#	pass
