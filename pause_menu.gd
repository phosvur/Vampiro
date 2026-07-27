extends ColorRect

var btn_resume: Button
var btn_home: Button
var btn_quit: Button

func _ready() -> void:
	# Start hidden so the game doesn't show the pause menu layout instantly
	hide() 
	
	# Automatically find buttons safely by name, bypassing strict path matching
	btn_resume = find_child("btnResume", true, false) as Button
	btn_home = find_child("btnHome", true, false) as Button
	btn_quit = find_child("btnQuit", true, false) as Button
	
	# Connect them only if they exist to prevent startup crashes
	if btn_resume: btn_resume.pressed.connect(_on_resume_clicked)
	if btn_home: btn_home.pressed.connect(_on_home_clicked)
	if btn_quit: btn_quit.pressed.connect(_on_quit_clicked)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"): 
		toggle_pause()

func toggle_pause() -> void:
	var new_pause_state = not get_tree().paused
	get_tree().paused = new_pause_state
	visible = new_pause_state
	
	# Look up the sound node relative to your PauseLayer position
	var music_player = get_node_or_null("../../snd_Music") 
	if music_player and music_player is AudioStreamPlayer:
		music_player.stream_paused = new_pause_state

func _on_resume_clicked() -> void:
	await get_tree().create_timer(0.15).timeout
	toggle_pause()

func _on_home_clicked() -> void:
	await get_tree().create_timer(0.15).timeout
	get_tree().paused = false
	get_tree().change_scene_to_file("res://TitleScreen/menu.tscn")

func _on_quit_clicked() -> void:
	await get_tree().create_timer(0.15).timeout
	get_tree().quit()
