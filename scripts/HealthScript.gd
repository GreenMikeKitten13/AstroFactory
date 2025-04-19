extends ProgressBar

@onready var damageBar: ProgressBar = %DamageBar
@onready var playerBody: CharacterBody3D = get_parent()
@onready var tween = create_tween()

var health:float = 100
var waited:bool = false

func _process(_delta:float) -> void:
	if !waited:
		await get_tree().create_timer(0.5).timeout
		waited = true
		
	var target_health = playerBody.get_meta("health")
	if health != target_health:
		
		health = target_health

		value = health

		if tween.is_running():
			tween.kill()

		tween = create_tween()
		tween.tween_property(damageBar, "value", health, 0.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
