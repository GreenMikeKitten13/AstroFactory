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
var distance_traveled_since_last_chunk_build = 17
var air_time = 0
var gravity_strength = 2

var render_distance = global_variables.render_distance

var previewing = false
var build_mode = false
const PREVIEW_MATERIAL = preload("uid://b6plqgoenlkb4")
const block_1x1 = preload("uid://ddsctqvtlb4q")
var blocks:Array[PackedScene] =[block_1x1]

var collision_distance = global_variables.collision_distance

var collisioner = PhysicsServer3D
var cube_shape:RID = collisioner.box_shape_create()
@onready var RID_space = self.get_world_3d().space #for collisions

@onready var camera_pivot: Node3D = $camera_pivot
@onready var build_cast:RayCast3D = camera_pivot.get_node("RayCast3D")

@onready var build_ui: RichTextLabel = $"Build UI"

func _ready() -> void:
	camera_pivot.get_node("Camera3D").far = render_distance*2
	collisioner.shape_set_data(cube_shape, Vector3.ONE * 0.5)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		mouse_change = event.relative
	
	if event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	if event.is_action_pressed("Build mode"):
		build_mode = !build_mode
		if preview:
			preview.queue_free()
			preview = null

func _process(_delta: float) -> void:
	camera_pivot.rotate(Vector3.LEFT, mouse_change.y * mouse_sensetivity)
	camera_pivot.rotation.x = clamp(camera_pivot.rotation.x, -PI/3, PI/3)
	self.rotate(Vector3.DOWN, mouse_change.x * mouse_sensetivity)
	mouse_change = Vector2.ZERO
	if build_mode:
		build_ui.visible = true
		building()
	else:
		build_ui.visible= false
		previewing =  false

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
	
	if motion != Vector3.ZERO and distance_traveled_since_last_chunk_build > 20:
		distance_traveled_since_last_chunk_build = 0
		for chunk_position:Vector3 in global_variables.saved_chunk_position.keys():
			var in_collision_distance = self.position.x - collision_distance < chunk_position.x and self.position.x + collision_distance > chunk_position.x && self.position.z - collision_distance < chunk_position.z and self.position.z + collision_distance > chunk_position.z
			var in_render_distance = self.position.x - render_distance < chunk_position.x and self.position.x + render_distance > chunk_position.x && self.position.z - render_distance < chunk_position.z and self.position.z + render_distance > chunk_position.z
			
			if not generate_terrain.active_renders.has(chunk_position) and in_render_distance:
				generate_terrain.load_chunk(chunk_position)
			elif generate_terrain.active_renders.has(chunk_position) and not in_render_distance:
				generate_terrain.unload_chunk(chunk_position)
			
			if not generate_terrain.active_collisions.keys().has(chunk_position) and in_collision_distance:
				generate_terrain.load_collisions(chunk_position)
			elif generate_terrain.active_collisions.keys().has(chunk_position) and generate_terrain.active_collisions[chunk_position].size() > 0 and not in_collision_distance:
				generate_terrain.unload_collisions(chunk_position)
	
	if motion.x != 0 or motion.z != 0:
		distance_traveled_since_last_chunk_build += 1

	self.velocity = motion
	self.move_and_slide()

var preview

func building():
	if not previewing:
		previewing = true
		preview = blocks[0].instantiate()
		preview.get_node("collision").queue_free()
		preview.get_node("mesh").mesh.material = PREVIEW_MATERIAL
		preview.position = build_cast.get_collision_point()
		self.get_parent().add_child(preview)
	else:
		preview.position =  build_cast.get_collision_point()
