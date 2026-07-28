extends Control

var level = "res://World/world.tscn"

func _on_btn_play_click_end() -> void:
	GlobalData.reset_run_coins() # Reset session coins to 0
	get_tree().paused = false
	var _level = get_tree().change_scene_to_file(level)

func _on_btn_exit_click_end() -> void:
	get_tree().quit()
