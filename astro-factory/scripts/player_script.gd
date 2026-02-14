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
var collision_distance = 40

var air_time = 0
var gravity_strength = 2

var build_mode = false

var collisioner = PhysicsServer3D
var cube_shape:RID = collisioner.box_shape_create()
@onready var RID_space = self.get_world_3d().space		#for collisions

@onready var camera_pivot: Node3D = $camera_pivot
@onready var Raycast:RayCast3D = camera_pivot.get_node("RayCast3D")

@onready var build_ui: RichTextLabel = $"Build UI"

func _ready() -> void:
	collisioner.shape_set_data(cube_shape, Vector3.ONE * 0.5)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

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
	
	if motion != Vector3.ZERO:
		for chunk_position:Vector3 in GlobalVariables.saved_chunk_collision.keys():
			if self.position.x - collision_distance < chunk_position.x and self.position.x + collision_distance > chunk_position.x && self.position.z - collision_distance < chunk_position.z and self.position.z + collision_distance > chunk_position.z:
				for block_position:Vector3 in GlobalVariables.saved_chunk_collision[chunk_position]:
					var collision:RID
					if GlobalVariables.collision_RID_pool.size() != 0:
						collision = GlobalVariables.collision_RID_pool.pop_front()
					else:
						collision = collisioner.body_create()
						GlobalVariables.collision_RID_pool.append(collision)
						
					collisioner.body_set_mode(collision, PhysicsServer3D.BODY_MODE_STATIC)
					collisioner.body_set_space(collision, RID_space)
					collisioner.body_add_shape(collision, cube_shape)
					var collision_transform:Transform3D = Transform3D(Basis.IDENTITY, block_position)
					collisioner.body_set_state(collision,PhysicsServer3D.BODY_STATE_TRANSFORM, collision_transform)
					
					
				GlobalVariables.saved_chunk_collision.erase(chunk_position)
			#else:
			#	for rid in GlobalVariables.active_collision_chunks[chunk_position]:
			#		PhysicsServer3D.body_clear_shapes(rid)
			#		PhysicsServer3D.body_set_space(rid, RID())
			#		GlobalVariables.collision_RID_pool.append(rid)
			#	GlobalVariables.active_collision_chunks.erase(chunk_position)
					
	self.velocity = motion
	self.move_and_slide()
