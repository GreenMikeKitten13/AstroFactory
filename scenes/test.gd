extends Node3D

func _ready():
	# Create the mesh you want to instance (a cube in this case)
	var box_mesh = BoxMesh.new()
	box_mesh.size = Vector3(1, 1, 1)

	# Create the MultiMesh
	var multimesh = MultiMesh.new()
	multimesh.mesh = box_mesh
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.instance_count = 100  # 10 x 10 grid

	# Create the MultiMeshInstance3D and assign the MultiMesh
	var mm_instance = MultiMeshInstance3D.new()
	mm_instance.multimesh = multimesh
	add_child(mm_instance)

	# Position each instance in a grid
	for i in range(multimesh.instance_count):
		var x = i % 10
		var z = i / 10.0
		var newTransform = Transform3D(Basis(), Vector3(x * 2, 0, z * 2))
		multimesh.set_instance_transform(i, newTransform)
