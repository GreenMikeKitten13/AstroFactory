extends Node3D

#box_shape.size = Vector3(5, 5,  5)
	#for chunk:int in range(chunk_count):
	#	var cube_meshinstance:RID = renderer.instance_create()
	#	renderer.instance_set_base(cube_meshinstance, box_shape)
	#	renderer.instance_set_scenario(cube_meshinstance, RID_world)
	#	renderer.instance_set_transform(cube_meshinstance, Transform3D(Basis.IDENTITY, Vector3(chunk*5.1,15, 0)))

var renderer = RenderingServer
var chunk_count = 5
var default_chunk_size = Vector3(15, 30, 15)

var RID_pool = {} #IMPORTANT: RID's are saved as string ["RID"]

@onready var RID_world = self.get_world_3d().scenario

@onready var default_box_shape:BoxMesh

func _ready() -> void:
	default_box_shape  = BoxMesh.new()
	default_box_shape.size = Vector3.ONE
	create_chunk(Vector3.UP)

func create_default_cube(shape_position:Vector3 =Vector3.ONE):
	var cube_rid:RID = renderer.instance_create()
	renderer.instance_set_base(cube_rid, default_box_shape)
	renderer.instance_set_scenario(cube_rid, RID_world)
	renderer.instance_set_transform(cube_rid, Transform3D(Basis.IDENTITY, shape_position))

func create_chunk(chunk_position:Vector3,_chunk_size:Vector3=default_chunk_size):
	#var multimesh_instance:MultiMeshInstance3D = MultiMeshInstance3D.new()
	var multimesh_settings:MultiMesh = MultiMesh.new()
	
	multimesh_settings.transform_format = MultiMesh.TRANSFORM_3D
	multimesh_settings.use_colors = true
	multimesh_settings.use_custom_data = true
	multimesh_settings.instance_count = 1
	multimesh_settings.mesh = default_box_shape
	
	#multimesh_instance.multimesh = multimesh_settings
	
	var multimesh_rid:RID = renderer.instance_create()
	renderer.instance_set_base(multimesh_rid, multimesh_settings.get_rid())
	renderer.instance_set_scenario(multimesh_rid, RID_world)
	renderer.instance_set_transform(multimesh_rid, Transform3D(Basis.IDENTITY, chunk_position))
	
	multimesh_settings.set_instance_transform(0,Transform3D.IDENTITY)
	
	RID_pool[MultiMesh] = multimesh_settings
	RID_pool["RID"] = multimesh_rid
