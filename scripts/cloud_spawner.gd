extends MeshInstance3D

@export var clouds_ammount : int = 10
@export var _cloud : PackedScene = preload("res://scenes/gpu_cloud_particles_3d.tscn")

func _ready():
	spawn_clouds()
	
var rng = RandomNumberGenerator.new()

func spawn_clouds():
	while clouds_ammount >= 0:
		clouds_ammount -= 1
		var aabb: AABB = mesh.get_aabb()
		var size: Vector3 = aabb.size
		
		var x : float = rng.randf_range(size.x / 2, -size.x /2 )
		var y : float = rng.randf_range(size.y / 2, -size.y /2 )
		var z : float = rng.randf_range(size.z / 2, -size.z /2 )
		
		
		var spawn_pos : Vector3 = Vector3(x, y, z)
		
		var cloud := _cloud.instantiate()
		cloud.amount = rng.randi_range(10, 30)
		cloud.process_material.emission_box_extents.x = rng.randi_range(int(round(cloud.amount / 10.0)), int(round(cloud.amount / 5.0)))
		#cloud.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		#cloud.process_material.set("flags_cast_shadow", false)
		#cloud.material_override = StandardMaterial3D.new()
		#cloud.material_override.depth_draw_mode = StandardMaterial3D.DEPTH_DRAW_ALWAYS
		#cloud.material_override.params_cull_mode = StandardMaterial3D.CULL_DISABLED
		add_child(cloud)
		cloud.global_position = self.global_position + spawn_pos
