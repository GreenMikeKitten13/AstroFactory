extends Node

@onready var copperPrefab = $"../CopperBody" # Replace with the actual node path

func _ready():
	var newCopper := copperPrefab.duplicate() # Creates a copy
	newCopper.position += Vector3(2, 0, 0) # Move slightly to avoid overlap
	add_child(newCopper) # Add to the scene
