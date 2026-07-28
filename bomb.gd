extends Area2D

@export var damage: int = 50
@export var knockback_force: float = 100.0
var level: int = 1

var explosion_fx = preload("res://Enemy/explosion.tscn")

@onready var fuse_timer = $FuseTimer
@onready var blast_shape = $BlastRadius

func _ready() -> void:
	fuse_timer.timeout.connect(_on_fuse_timer_timeout)
	
	# Scale the physical collision radius based on level
	match level:
		1:
			blast_shape.shape.radius = 20.0
		2:
			blast_shape.shape.radius = 30.0
		3:
			blast_shape.shape.radius = 30.0
		4:
			blast_shape.shape.radius = 45.0

func _on_fuse_timer_timeout() -> void:
	explode()

func explode() -> void:
	var explosion = explosion_fx.instantiate()
	explosion.global_position = global_position
	
	var visual_scale = 1.0
	match level:
		1: visual_scale = 1.0
		2, 3: visual_scale = 1.5
		4: visual_scale = 2.2
		
	explosion.scale = Vector2(visual_scale, visual_scale)
	get_parent().add_child(explosion)
	
	var overlapping_targets = get_overlapping_areas() + get_overlapping_bodies()
	for target in overlapping_targets:
		# 1. EXPLICIT SAFEGUARD: Skip if the target is the player or belongs to the player
		if target.is_in_group("player") or (target.get_parent() and target.get_parent().is_in_group("player")):
			continue
			
		# 2. Damage enemies
		if target.has_method("_on_hurt_box_hurt"):
			var direction = global_position.direction_to(target.global_position)
			target._on_hurt_box_hurt(damage, direction, knockback_force)
		elif target.get_parent() and target.get_parent().has_method("_on_hurt_box_hurt"):
			var direction = global_position.direction_to(target.global_position)
			target.get_parent()._on_hurt_box_hurt(damage, direction, knockback_force)

	queue_free()
