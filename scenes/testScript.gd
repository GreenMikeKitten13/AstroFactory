extends Node3D

# IMPORTANT: Store references to prevent garbage collection
var shapes_res: Array[BoxShape3D]
var bodys_rid: Array[RID]

func _ready():
	for x in range(20):
		for z in range(20):
			# 1) Cache the physics space
			var space_rid = get_world_3d().space
			var newShape
			var newBody
			var mesh = MeshInstance3D.new()
			var box = BoxMesh.new()
			box.size = Vector3.ONE
			mesh.mesh = box
			mesh.scale = Vector3.ONE
			mesh.position = Vector3(x, 0, z)
			self.add_child(mesh)
			
			# 2) Create and store shape resource
			newShape = BoxShape3D.new()
			newShape.size = Vector3(1, 1, 1)
			var shape_rid = newShape.get_rid()
			shapes_res.append(newShape)
			
			# 3) Create physics body
			newBody = PhysicsServer3D.body_create()
			
			# 4) Add shape (without offset for simplicity)
			PhysicsServer3D.body_add_shape(newBody, shape_rid)
			
			# 5) Position at (0, 0, 0)
			var body_xform = Transform3D(Basis(), Vector3(x, 0, z))
			PhysicsServer3D.body_set_state(newBody, PhysicsServer3D.BODY_STATE_TRANSFORM, body_xform)
			
			# 6) Set as static
			PhysicsServer3D.body_set_mode(newBody, PhysicsServer3D.BODY_MODE_STATIC)
			
			# 7) Collision layers
			PhysicsServer3D.body_set_collision_layer(newBody, 1)
			PhysicsServer3D.body_set_collision_mask(newBody, 1)
			bodys_rid.append(newBody)
			
			# 8) Add to physics space
			PhysicsServer3D.body_set_space(newBody, space_rid)

# Clean up RIDs when node exits tree
func _exit_tree():
	for body in bodys_rid:
		if body != RID():
			PhysicsServer3D.free_rid(body)
