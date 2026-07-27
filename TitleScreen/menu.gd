extends Control

var level = "res://World/world.tscn"

func _on_btn_play_click_end() -> void:
	# 1. Reset the global engine pause state so the new world can run!
	get_tree().paused = false
	
	# 2. Change to the world scene
	var _level = get_tree().change_scene_to_file(level)

func _on_btn_exit_click_end() -> void:
	get_tree().quit()
