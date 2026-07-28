extends Area2D

var target = null
var speed = -1

@onready var sprite = $Sprite2D
@onready var collision = $CollisionShape2D
@onready var sound = $snd_collected

func _physics_process(delta):
	if target != null:
		global_position = global_position.move_toward(target.global_position, speed)
		speed += 2*delta
		
func collect():
	sound.play()
	collision.call_deferred("set", "disabled", true)
	sprite.visible = false
	
	GlobalData.add_coins(1)
	
	# Optional: Tell player script to refresh HUD if you have a signal or method
	if target and target.has_method("update_coin_gui"):
		target.update_coin_gui()
		
	return 0

func _on_snd_collected_finished():
	queue_free()
