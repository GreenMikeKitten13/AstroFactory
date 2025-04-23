extends StaticBody3D

var bodies_in_range :Array= []
var can_shoot : bool = true
var looking_pos : Vector3 = Vector3(0, 0, 0)
@onready var chamber: Node = %Chamber

func _ready():
	$Timer.wait_time = 1.0
	$Timer.start()

func shoot():
	if can_shoot && chamber.get_child_count() != 0:
		var bullet:RigidBody3D = chamber.get_child(0)
		if bullet == null: bullet = chamber.get_child(0)
		can_shoot = false
		$smoke_particle.emitting = true
		$Shell_particle.emitting = true 
		$Timer.start()
		bullet.set_process(true)
		bullet.sleeping = false
		bullet.reparent($"../..")
		bullet.global_transform = global_transform
		bullet.show()
		bullet.linear_velocity = -bullet.global_transform.basis.z * 50

func _on_timer_timeout():
	if scale == Vector3.ONE:
		can_shoot = true

func _on_sentry_area_body_entered(body: Node3D) -> void:
	if body.is_in_group("target"):
		bodies_in_range.append(body)

func _on_sentry_area_body_exited(body: Node3D) -> void:
	if body in bodies_in_range:
		bodies_in_range.erase(body)

func _process(_delta):
	if bodies_in_range.size() > 0 && scale == Vector3.ONE:
		
		var target_pos = bodies_in_range[0].global_transform.origin
		looking_pos = looking_pos.lerp(target_pos, 0.2)
		
		look_at(looking_pos)
		$"../TurretTower".rotation.y = $".".rotation.y
		if can_shoot:
			shoot()

func onBulletEntered(body: Node3D) -> void:
	if body.name.begins_with("bullet"):
		body.reparent(chamber)
		body.hide()
		body.sleeping = true
		body.set_process(false)
		#body.get_child(0).mesh.material.albedo = "ffff00"
		body.linear_velocity = Vector3i.ZERO
