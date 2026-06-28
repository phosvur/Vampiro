extends CharacterBody2D


@export var movement_speed = 20.0
@export var hp = 10
@export var knockback_recovery = 3.5
@export var experience = 1
@export var enemy_damage = 1
var knockback = Vector2.ZERO

@onready var player = get_tree().get_first_node_in_group("player")
@onready var loot_base = get_tree().get_first_node_in_group("loot")
@onready var sprite = $Sprite2D
@onready var anim = $AnimationPlayer
@onready var snd_hit = $snd_hit
@onready var hitBox = $HitBox

var death_anim = preload("res://Enemy/explosion.tscn")
var exp_gem = preload("res://Objects/experience_gem.tscn")

signal remove_from_array(object)

func _ready():
	anim.play("walk")
	hitBox.damage = enemy_damage

func _physics_process(_delta):
	# 1. Slow down knockback recovery when time is distorted
	var current_knockback_recovery = knockback_recovery * GlobalTime.enemy_time_scale
	knockback = knockback.move_toward(Vector2.ZERO, current_knockback_recovery)
	
	# 2. Track the player's direction
	var direction = global_position.direction_to(player.global_position)
	
	# 3. Apply GlobalTime to movement speed
	var current_speed = movement_speed * GlobalTime.enemy_time_scale
	velocity = direction * current_speed
	velocity += knockback
	move_and_slide()

	# 4. Dynamically slow down or speed up the animation frame rate
	anim.speed_scale = GlobalTime.enemy_time_scale

	if direction.x > 0.1:
		sprite.flip_h = true
	elif direction.x < -0.1:
		sprite.flip_h = false
		
func death():
	emit_signal("remove_from_array",self)
	var enemy_death = death_anim.instantiate()
	enemy_death.scale = sprite.scale
	enemy_death.global_position = global_position
	get_parent().call_deferred("add_child",enemy_death)
	var new_gem = exp_gem.instantiate()
	new_gem.global_position = global_position
	new_gem.experience = experience
	loot_base.call_deferred("add_child",new_gem)
	queue_free()
		
func _on_hurt_box_hurt(damage, angle, knockback_amount):
	hp -= damage
	knockback = angle * knockback_amount
	if hp <= 0:
		death()
	else:
		snd_hit.play()
