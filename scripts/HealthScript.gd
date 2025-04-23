extends ProgressBar

@onready var damageBar: ProgressBar = %DamageBar
@onready var playerBody: CharacterBody3D = get_parent()
@onready var tween = create_tween()
@onready var timer: Timer = %Timer

var health:float = 100

func _ready() -> void:
	playerBody.set_meta("health", 100.0)
	tween = create_tween()

func _process(_delta:float) -> void:
	if health < 100 and timer.is_stopped():
		timer.start()
	
	
	var target_health = playerBody.get_meta("health")
	if health != target_health:
		health = target_health
		value = health

		if tween.is_running():
			tween.kill()

		tween = create_tween()

		tween.tween_property(damageBar, "value", health, 0.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func onHealTimeOut() -> void:
	health += 0.5
	playerBody.set_meta("health", health)
	value = health
	if health >= 100:
		timer.stop()
