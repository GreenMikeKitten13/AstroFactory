extends Node

@onready var prefab = $"../DirtBody"
var gridSize := 40
var noise := FastNoiseLite.new()

func _ready():
	makeNoise()
	decideAndMakeTerrain()



func makeNoise():
	noise.seed = randi()
	noise.noise_type = FastNoiseLite.TYPE_PERLIN
	noise.frequency = 0.1


func decideAndMakeTerrain():
	for yCoordinate in gridSize/2:
		
		if yCoordinate <= gridSize/2 -7: prefab = $"../StoneBody" 
		else: prefab = $"../DirtBody" 
		
		if yCoordinate == gridSize/2 - 1: prefab = $"../GrassBody"
		
		for zCoorindate in gridSize:
			for xCoordinate in gridSize:
				var randomNumb = randf()
				var height := noise.get_noise_2d(xCoordinate, zCoorindate) * 1.5  # Scale height
				if height < 0.005 && yCoordinate == gridSize/2 - 1:
					prefab = $"../WaterBody"
				elif yCoordinate == gridSize/2 - 1:
					prefab = $"../GrassBody"
				
				if prefab == $"../StoneBody" && randomNumb >= 0.9:
					prefab = $"../CopperBody"
				elif prefab == $"../StoneBody" && randomNumb >= 0.8 && randomNumb < 0.9:
					prefab = $"../IronBody"
				elif yCoordinate <= gridSize/2 -7:
					prefab = $"../StoneBody"
				
				var newPrefab = prefab.duplicate()
				newPrefab.position = Vector3(xCoordinate, height - 9 + yCoordinate,zCoorindate)
				if randf() < 0.5:
					for child in newPrefab.get_children():
						if child is OccluderInstance3D:
							child.queue_free()
							break 

				add_child(newPrefab)
