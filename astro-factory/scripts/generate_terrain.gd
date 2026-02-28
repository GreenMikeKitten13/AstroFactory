extends Node3D

var renderer = RenderingServer
var collisioner = PhysicsServer3D
var default_chunk_size = global_variables.chunk_size

var chunk_info = {}
var active_collisions = {}
var active_renders = []
var collision_distance = 12
var usable_threads = []
var chunk_volume = global_variables.chunk_size.x * global_variables.chunk_size.y * global_variables.chunk_size.z
var multimesh_pool = []


@onready var RID_world = self.get_world_3d().scenario	#for renderer
@onready var RID_space = self.get_world_3d().space		#for collisions

@onready var default_box_shape:BoxMesh= BoxMesh.new()
var cube_shape:RID = collisioner.box_shape_create()

@onready var noise:FastNoiseLite = FastNoiseLite.new()

func _ready() -> void:
	default_box_shape.size = Vector3.ONE
	collisioner.shape_set_data(cube_shape, Vector3.ONE * 0.5)
	create_chunks()
	
	for t in range(round(global_variables.collision_distance*0.35)):
		var thread:Thread = Thread.new()
		usable_threads.append(thread)
	
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise.fractal_octaves = 10
	noise.fractal_weighted_strength = 0.5
	
	for rid in range(1000):
		var new_collisioin = collisioner.body_create()
		collisioner.body_set_space(new_collisioin, RID_space)
		collisioner.body_add_shape(new_collisioin, cube_shape)
		global_variables.collision_RID_pool.append(new_collisioin)

func create_chunks():
	for x_chunk in range(global_variables.chunk_count):
		for y_chunk in range(global_variables.chunk_count):
			global_variables.saved_chunk_position[Vector3(x_chunk*10,-15,y_chunk*10)] = []

func load_chunk(chunk_position:Vector3,chunk_size:Vector3i=default_chunk_size):
	active_renders.append(chunk_position)
	var block_count =  chunk_size.x * chunk_size.z * chunk_size.y
	var multimesh_settings:MultiMesh
	if multimesh_pool.size() > 0:
		multimesh_settings = multimesh_pool.pop_back()
	else:
		multimesh_settings = MultiMesh.new()
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
				
	
				global_variables.saved_chunk_position[chunk_position].append(Vector3(x + chunk_position.x,y + height_noise + chunk_position.y,z + chunk_position.z))
				block += 1
	var multimesh_rid:RID
	
	if global_variables.render_RID_pool.size() > 5:
		multimesh_rid = global_variables.render_RID_pool.pop_back()
	else:
		multimesh_rid = renderer.instance_create()
	
	renderer.instance_set_base(multimesh_rid, multimesh_settings.get_rid())
	renderer.instance_set_scenario(multimesh_rid, RID_world)
	renderer.instance_set_transform(multimesh_rid, Transform3D(Basis.IDENTITY, Vector3.ZERO))
	chunk_info[chunk_position] = {"settings" : multimesh_settings, "RID" : multimesh_rid}

func unload_chunk(chunk_position):
	var multimesh_settings:MultiMesh = chunk_info[chunk_position]["settings"]
	var multimesh_rid:RID = chunk_info[chunk_position]["RID"]
	renderer.instance_set_scenario(multimesh_rid, RID())
	renderer.instance_set_base(multimesh_rid, RID())
	multimesh_pool.append(multimesh_settings)
	global_variables.render_RID_pool.append(multimesh_rid)
	active_renders.erase(chunk_position)
	global_variables.saved_chunk_position[chunk_position] = []

func load_collisions(chunk_position):
	active_collisions[chunk_position] = []
	var thread:Thread = usable_threads.pop_back()
	
	if not thread:
		print("all threads busy")
		return
	if thread.is_started():
		thread.wait_to_finish()
	
	var rid_array = []
	for block in chunk_volume:
		if global_variables.collision_RID_pool.size() > 0:
			rid_array.append(global_variables.collision_RID_pool.pop_back() )
		else:
			break
	thread.start(chunk_math_and_settings.bind(chunk_position, active_collisions, global_variables.saved_chunk_position[chunk_position], thread, rid_array))

func unload_collisions(chunk_position):
	for block:RID in active_collisions[chunk_position]:
		global_variables.collision_RID_pool.append(block)
		collisioner.body_set_space(block, RID())
	active_collisions.erase(chunk_position)

func chunk_math_and_settings(chunk_position:Vector3, active_collisions_while_thread, block_positions, thread, given_rids:Array):
	var built_blocks:Array[RID] = []
	active_collisions_while_thread[chunk_position] = []
	for block_position:Vector3 in block_positions:
		var collision:RID
		if given_rids and given_rids.size() > 0:
			collision = given_rids.pop_back()
		else:
			collision = collisioner.body_create()
			collisioner.body_add_shape(collision, cube_shape)
		
		collisioner.body_set_mode(collision, PhysicsServer3D.BODY_MODE_STATIC)
	
		var collision_transform:Transform3D = Transform3D(Basis.IDENTITY, block_position)
		collisioner.body_set_state(collision,PhysicsServer3D.BODY_STATE_TRANSFORM, collision_transform)
		built_blocks.append(collision)
	call_thread_safe("set_bodies_space", built_blocks, chunk_position)
	usable_threads.append(thread)

func set_bodies_space(bodies:Array[RID], chunk_position= null):
	for body:RID in bodies:
		collisioner.body_set_space(body, RID_space)
		if chunk_position:
			active_collisions[chunk_position].append(body)
