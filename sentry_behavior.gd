extends StaticBody3D

func _ready():
	$Timer.wait_time = 1.0 / 5.0 
	$Timer.start()

func shoot(shoot_enemy):
	print("shoot ", shoot_enemy)

func _on_timer_timeout() -> void: # only execute a set ammount of times per seconds for performance
	shoot(true)
