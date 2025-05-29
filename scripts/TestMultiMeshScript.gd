extends MultiMeshInstance3D

var chunk_size := 10

func _ready():
	# Set up noise
	var terrain_noise := FastNoiseLite.new()
	terrain_noise.seed = randi()
	terrain_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	terrain_noise.fractal_octaves = 4
	terrain_noise.fractal_gain = 0.4
	terrain_noise.frequency = 0.05

	# Create the mesh and MultiMesh
	var mesh := BoxMesh.new()
	var mm := MultiMesh.new()
	
	var instance_count := chunk_size * chunk_size * chunk_size
	mm.mesh = mesh
	var shader := Shader.new()
	shader.code =  preload("res://shaders/shaderScript.gdshader").code

	var material := ShaderMaterial.new()
	material.shader = shader
	var atlas_texture = load("res://testAtlas.tres")  # Replace with real path
	material.set_shader_parameter("atlas_tex", atlas_texture)
	mesh.material = material  # Assign to the mesh

	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_custom_data = true
	mm.instance_count = instance_count
	mm.visible_instance_count = instance_count

	
	self.multimesh = mm
	
	# Fill the MultiMesh
	var i := 0
	for x in range(chunk_size):
		for y in range(chunk_size):
			for z in range(chunk_size):
				var height := terrain_noise.get_noise_2d(x, z) * 5.0
				var pos := Vector3(x, y - height, z)
				var bigTransform := Transform3D(Basis(), pos)
				mm.set_instance_transform(i, bigTransform)
				
				#var index = 1  # tile index in atlas
				var color = Color(chooseMaterial(y) / 255.0, 0, 0, 1)
				mm.set_instance_custom_data(i, color)

				i += 1


func chooseMaterial(yCoordinate) ->int:
	if yCoordinate <= chunk_size-6:
		return 2
	elif yCoordinate >= chunk_size-6 and not yCoordinate == chunk_size-1:
		return 1
	else:
		return 0
