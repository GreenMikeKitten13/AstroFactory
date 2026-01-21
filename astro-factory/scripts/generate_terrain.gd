extends Node3D

var renderer = RenderingServer
var chunk_count = 5
var chunk_size = Vector3(15, 30, 15)

var RID_pool = []

@onready var RID_world = self.get_world_3d().scenario
@onready var box_shape:BoxMesh = BoxMesh.new()


func _ready() -> void:
	box_shape.size = Vector3(5, 5,  5)
	for chunk:int in range(chunk_count):
		var cube_meshinstance:RID = renderer.instance_create()
		renderer.instance_set_base(cube_meshinstance, box_shape)
		renderer.instance_set_scenario(cube_meshinstance, RID_world)
		renderer.instance_set_transform(cube_meshinstance, Transform3D(Basis.IDENTITY, Vector3(chunk*5.1,15, 0)))
		
