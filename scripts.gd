extends Node

@onready var prefab = $"../DirtBody"
var gridSize := 25
var noise = FastNoiseLite.new()
#var angles = [-90, 90, 180]

#var degree:Vector3

func _ready():
	noise.seed = randi()
	noise.noise_type = FastNoiseLite.TYPE_PERLIN
	noise.frequency = 0.1
	for yCoordinate in gridSize/2:
		
		if yCoordinate <= gridSize/2 -7: prefab = $"../StoneBody" 
		else: prefab = $"../DirtBody" 
		
		if yCoordinate == gridSize/2 - 1: prefab = $"../GrassBody"
		
		for zCoorindate in gridSize:
			for xCoordinate in gridSize:
				var height = noise.get_noise_2d(xCoordinate, zCoorindate) * 1  # Scale height
				var newCopper = prefab.duplicate()
				newCopper.position = Vector3(xCoordinate,-9 + height + yCoordinate,zCoorindate)
				#var degree = angles[randi() % angles.size()]
				#newCopper.rotation_degrees.y = degree
				add_child(newCopper)
