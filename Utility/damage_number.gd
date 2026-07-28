extends Label

func setup(amount: int, is_critical: bool = false) -> void:
	text = str(amount)
	
	# Color & Size Coding
	if is_critical:
		modulate = Color.RED
		scale = Vector2(1.3, 1.3) # Slightly bigger for heavy hits
	else:
		modulate = Color.WHITE
		scale = Vector2(1.0, 1.0)
	
	# Random horizontal offset so numbers spread out nicely
	var random_x = randf_range(-16.0, 16.0)
	var start_pos = global_position + Vector2(random_x, -10.0)
	var target_pos = start_pos + Vector2(randf_range(-8.0, 8.0), -25.0) # Floats upward
	
	global_position = start_pos
	
# 🌟 Perform Pop & Fade Animation via Tweens (Godot 4 Syntax)
	var tween = create_tween().set_parallel(true)
	
	# 1. Float upward using TRANS_QUAD and EASE_OUT
	tween.tween_property(self, "global_position", target_pos, 0.4)\
		.set_trans(Tween.TRANS_QUAD)\
		.set_ease(Tween.EASE_OUT)
		
	# 2. Fade out near the end
	tween.tween_property(self, "modulate:a", 0.0, 0.3)\
		.set_delay(0.1)\
		.set_trans(Tween.TRANS_LINEAR)
		
	# 3. Clean up node from memory once done
	tween.chain().tween_callback(queue_free)
