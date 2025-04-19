extends StaticBody3D

var bodies_in_range := []
var last_shot_time : float = 0
var can_shoot : bool = true
var looking_pos : Vector3 = Vector3(0, 0, 0)
@onready var bullets: Node3D = %Bullets
@onready var bullet:RigidBody3D = bullets.get_child(0)

func _ready():
	
	bullet.physics_material_override = PhysicsMaterial.new()
	bullet.physics_material_override.bounce = 0
	bullet.physics_material_override.friction = 0
	bullet.collision_layer = 1
	bullet.collision_mask = 1
	$Timer.wait_time = 1.0
	$Timer.start()

func shoot():
	if can_shoot:
		can_shoot = false
		bullet.set_process(true)
		bullet.show()
		bullet.global_transform = global_transform
		bullet.reparent($"../../badGameEngineDesigna")
		bullet.linear_velocity = bullet.global_transform.basis.z.normalized() * -50 
		$Timer.start()
		await $Timer.timeout
		bullet.reparent(bullets)
		bullet.set_process(false)
		$GPUParticles3D.emitting = true
	
	$Timer.start()

func _on_timer_timeout():
	can_shoot = true

func _on_sentry_area_body_entered(body: Node3D) -> void:
	if body.is_in_group("target"):
		bodies_in_range.append(body)


func _on_sentry_area_body_exited(body: Node3D) -> void:
	if body in bodies_in_range:
		bodies_in_range.erase(body)


func _process(_delta):
	if bodies_in_range.size() > 0:
		
		var target_pos = bodies_in_range[0].global_transform.origin
		looking_pos = looking_pos.lerp(target_pos, 0.2)
		
		look_at(looking_pos)
		$"../TurretTower".rotation.y = $".".rotation.y
		if can_shoot:
			shoot()

func _on_area_3d_body_entered(body: Node3D) -> void:
	if body.name == "PlayerBody":
		body.set_meta("health", body.get_meta("health") - (abs(bullet.linear_velocity.x)+ abs(bullet.linear_velocity.y) + abs(bullet.linear_velocity.z))/10.0)
		
		bullet.linear_velocity = Vector3.ZERO
		bullet.set_process(false)
		
		bullet.hide()
		await get_tree().create_timer(0.5).timeout
		bullet.reparent(bullets)

func reparentBullet():
	bullet.reparent(bullets)
