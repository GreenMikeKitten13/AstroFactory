extends CharacterBody3D

var forward = false
var backward = false
var left = false
var right = false

var movement_speed = 10
var jump_strength = 10
var jump_timer = 0.75
var jumping = false
var can_jump = false
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
var mouse_change = Vector2.ZERO
var mouse_sensetivity = 0.01
var collision_distance = 30 #40, 10
var distance_traveled_since_last_chunk_build = 20
var chunk_size = GlobalVariables.chunk_size.x * GlobalVariables.chunk_size.y * GlobalVariables.chunk_size.z
var air_time = 0
var gravity_strength = 2

var build_mode = false

var active_chunks = {}

var usable_threads:Array[Thread] = []

var collisioner = PhysicsServer3D
var cube_shape:RID = collisioner.box_shape_create()
@onready var RID_space = self.get_world_3d().space #for collisions

@onready var camera_pivot: Node3D = $camera_pivot
@onready var Raycast:RayCast3D = camera_pivot.get_node("RayCast3D")

@onready var build_ui: RichTextLabel = $"Build UI"

func _ready() -> void:
	collisioner.shape_set_data(cube_shape, Vector3.ONE * 0.5)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	for t in GlobalVariables.chunk_count**2:
		var thread:Thread = Thread.new()
		usable_threads.append(thread)
	
	for rid in range(1000):
		var new_collisioin = collisioner.body_create()
		collisioner.body_set_space(new_collisioin, RID_space)
		collisioner.body_add_shape(new_collisioin, cube_shape)
		GlobalVariables.collision_RID_pool.append(new_collisioin)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		mouse_change = event.relative
	
	if event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	if event.is_action_pressed("Build mode"):
		build_mode = !build_mode

func _process(_delta: float) -> void:
	camera_pivot.rotate(Vector3.LEFT, mouse_change.y * mouse_sensetivity)
	camera_pivot.rotation.x = clamp(camera_pivot.rotation.x, -PI/3, PI/3)
	self.rotate(Vector3.DOWN, mouse_change.x * mouse_sensetivity)
	mouse_change = Vector2.ZERO
	if build_mode:
		build_ui.visible = true
		
	else:
		build_ui.visible= false

var last_rid_pool_size = GlobalVariables.collision_RID_pool.size()

func _physics_process(delta: float) -> void:
	var motion = Vector3.ZERO
	
	if Input.get_action_strength("forward"):
		motion += -global_transform.basis.z * movement_speed
	if Input.get_action_strength("backward"):
		motion += global_transform.basis.z * movement_speed
	if Input.get_action_strength("left"):
		motion += -global_transform.basis.x * movement_speed
	if Input.get_action_strength("right"):
		motion += global_transform.basis.x * movement_speed
	if can_jump and not jumping and Input.get_action_strength("jump"):
		jumping = true
		jump_timer = 0.25
		can_jump = false
	
	if jumping and jump_timer > 0:
		jump_timer -=  delta
		motion.y +=  (jump_timer+jump_strength) * 2
	elif jump_timer <= 0:
		jumping = false
	
	if !self.is_on_floor() and not jumping:
		can_jump= false
		air_time += delta
		motion.y -= gravity * air_time * gravity_strength
	elif self.is_on_floor():
			air_time = 0
			if not jumping:
				can_jump = true
	
	if motion != Vector3.ZERO and distance_traveled_since_last_chunk_build > 30:
		distance_traveled_since_last_chunk_build = 0
		for chunk_position:Vector3 in GlobalVariables.saved_chunk_collision.keys():
			var in_distance_check = self.position.x - collision_distance < chunk_position.x and self.position.x + collision_distance > chunk_position.x && self.position.z - collision_distance < chunk_position.z and self.position.z + collision_distance > chunk_position.z
			if not active_chunks.keys().has(chunk_position) and in_distance_check:
				active_chunks[chunk_position] = []
				var thread:Thread = usable_threads.pop_front()
				
				if thread.is_alive():
					usable_threads.append(thread)
					continue
				if thread.is_started():
					thread.wait_to_finish()
				
				var rid_array = []
				for block in chunk_size:
					if GlobalVariables.collision_RID_pool.size() > 0:
						rid_array.append(GlobalVariables.collision_RID_pool.pop_back() )
					else:
						break
				
				thread.start(chunk_math_and_settings.bind(chunk_position, active_chunks, GlobalVariables.saved_chunk_collision[chunk_position], thread, rid_array))
				
			elif active_chunks.keys().has(chunk_position) and active_chunks[chunk_position].size() != 0 and not in_distance_check:
				for block:RID in active_chunks[chunk_position]:
					GlobalVariables.collision_RID_pool.append(block)
					collisioner.body_set_space(block, RID())
				active_chunks.erase(chunk_position)
	
	if motion.x != 0 or motion.z != 0:
		distance_traveled_since_last_chunk_build += 1
	
	if GlobalVariables.collision_RID_pool.size() != last_rid_pool_size:
		last_rid_pool_size = GlobalVariables.collision_RID_pool.size()
		#print(GlobalVariables.collision_RID_pool.size())
	
	self.velocity = motion
	self.move_and_slide()


func chunk_math_and_settings(chunk_position:Vector3, active_chunks_while_thread, block_positions, thread, given_rids:Array):
	var built_blocks:Array[RID] = []
	active_chunks_while_thread[chunk_position] = []
	##print("before: ", collision_RID_pool.size())
	var start_frame = get_tree().get_frame()
	var blocks_created = 0
	var blocks_reused = 0
	var failed_reuses = 0
	for block_position:Vector3 in block_positions:
		var collision:RID
		if given_rids and given_rids.size() > 0:
			collision = given_rids.pop_back()
			blocks_reused += 1
		else:
			collision = collisioner.body_create()
			blocks_created += 1
			collisioner.body_add_shape(collision, cube_shape)
		
		collisioner.body_set_mode(collision, PhysicsServer3D.BODY_MODE_STATIC)
	
		var collision_transform:Transform3D = Transform3D(Basis.IDENTITY, block_position)
		collisioner.body_set_state(collision,PhysicsServer3D.BODY_STATE_TRANSFORM, collision_transform)
		built_blocks.append(collision)
	##print("after: ", collision_RID_pool.size())
	var end_frame = get_tree().get_frame()
	#var block_chunks = 0
	#for blocks:Array in GlobalVariables.saved_chunk_collision.values():
	#	if blocks.size() != 0:
	#		block_chunks += 1
	print("reused ", str(blocks_reused), " blocks\ncreated ", str(blocks_created), " blocks in ", str(end_frame-start_frame), " frames\nfailed attempts to reuse: ", str(failed_reuses), "\nrid_pool.size(): ", str(GlobalVariables.collision_RID_pool.size()), "\nactive chunks:", str(active_chunks.size()), "\n")
	call_thread_safe("set_bodies_space", built_blocks, chunk_position)
	usable_threads.append(thread)

func set_bodies_space(bodies:Array[RID], chunk_position= null):
	for body:RID in bodies:
		collisioner.body_set_space(body, RID_space)
		if chunk_position:
			active_chunks[chunk_position].append(body)
	##print(active_chunks[chunk_position].size())
