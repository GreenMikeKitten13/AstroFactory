extends ProgressBar

@onready var damageBar: ProgressBar = %DamageBar
@onready var damageTimer: Timer = %Timer

var health :float = 0 :set =  setHealth

func setHealth(newHealth):
	var prevHealth = health
	health = min(max_value, newHealth)
	value = health
	
	if health <= 0:
		queue_free()
	
	if health < prevHealth:
		damageTimer.start()
	else:
		damageBar.value = health

func getHealth(damageHealth):
	health  = damageHealth
	#max_value = health
	value = health
	#damageBar.max_value = health
	damageBar.value = health

func onTimerTimeout() -> void:
	damageBar.value = health
