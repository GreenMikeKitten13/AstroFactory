extends Node3D

#box_shape.size = Vector3(5, 5,  5)
	#for chunk:int in range(chunk_count):
	#	var cube_meshinstance:RID = renderer.instance_create()
	#	renderer.instance_set_base(cube_meshinstance, box_shape)
	#	renderer.instance_set_scenario(cube_meshinstance, RID_world)
	#	renderer.instance_set_transform(cube_meshinstance, Transform3D(Basis.IDENTITY, Vector3(chunk*5.1,15, 0)))

var renderer = RenderingServer
var collisioner = PhysicsServer3D
var chunk_count = 5
var default_chunk_size = Vector3i(10, 20, 10)

var collision_RID_pool = {}
var render_RID_pool = {}

@onready var RID_world = self.get_world_3d().scenario	#for renderer
@onready var RID_space = self.get_world_3d().space		#for collisions

@onready var default_box_shape:BoxMesh= BoxMesh.new()
var cube_shape:RID = collisioner.box_shape_create()

@onready var noise:FastNoiseLite = FastNoiseLite.new()

func _ready() -> void:
	default_box_shape.size = Vector3.ONE
	collisioner.shape_set_data(cube_shape, Vector3.ONE * 0.5)
	
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise.fractal_octaves = 10
	noise.fractal_weighted_strength = 0.5
	for x_chunk in range(20):
		for y_chunk in range(20):
			create_chunk(Vector3i(x_chunk * 10, -15, y_chunk * 10))

func create_default_cube(shape_position:Vector3 =Vector3.ONE):
	var cube_rid:RID = renderer.instance_create()
	renderer.instance_set_base(cube_rid, default_box_shape)
	renderer.instance_set_scenario(cube_rid, RID_world)
	renderer.instance_set_transform(cube_rid, Transform3D(Basis.IDENTITY, shape_position))

func create_default_cube_collision(shape_position:Vector3=Vector3.ONE):  #not needed here, but don't forget to save the RID's in a pool
	var body = collisioner.body_create()
	collisioner.body_set_mode(body,PhysicsServer3D.BODY_MODE_STATIC)
	collisioner.body_set_space(body, RID_space)
	
	collisioner.body_add_shape(body, cube_shape)
	var shape_transform = Transform3D(Basis.IDENTITY, shape_position)
	collisioner.body_set_state(body, PhysicsServer3D.BODY_STATE_TRANSFORM, shape_transform)

func create_chunk(chunk_position:Vector3,chunk_size:Vector3i=default_chunk_size):
	var block_count =  chunk_size.x * chunk_size.z * chunk_size.y
	var multimesh_settings:MultiMesh = MultiMesh.new()
	
	multimesh_settings.transform_format = MultiMesh.TRANSFORM_3D
	multimesh_settings.use_colors = true
	multimesh_settings.use_custom_data = true
	multimesh_settings.instance_count = block_count
	multimesh_settings.mesh = default_box_shape
	
	var block = 0
	for x in range(chunk_size.x):
		for z in range(chunk_size.z):
			for y in range(chunk_size.y):
				var height_noise = noise.get_noise_2d(x + chunk_position.x, z + chunk_position.z) *25
				var block_transform:Transform3D = Transform3D(Basis.IDENTITY,Vector3(x + chunk_position.x,y + height_noise + chunk_position.y,z + chunk_position.z ))
				multimesh_settings.set_instance_transform(block, block_transform)
				
				var collision:RID = collisioner.body_create()
				collisioner.body_set_mode(collision, PhysicsServer3D.BODY_MODE_STATIC)
				collisioner.body_set_space(collision, RID_space)
				collisioner.body_add_shape(collision, cube_shape)
				var collision_transform:Transform3D = Transform3D(Basis.IDENTITY, Vector3(x + chunk_position.x , y + chunk_position.y + height_noise, z + chunk_position.z))
				collisioner.body_set_state(collision,PhysicsServer3D.BODY_STATE_TRANSFORM, collision_transform)
				block += 1
	var multimesh_rid:RID = renderer.instance_create()
	renderer.instance_set_base(multimesh_rid, multimesh_settings.get_rid())
	renderer.instance_set_scenario(multimesh_rid, RID_world)
	renderer.instance_set_transform(multimesh_rid, Transform3D(Basis.IDENTITY, Vector3.ZERO))
	
	#multimesh_settings.set_instance_transform(0,Transform3D.IDENTITY)
	
	render_RID_pool[multimesh_settings] = null
	render_RID_pool[multimesh_rid] = null
	
	
	
