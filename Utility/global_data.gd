extends Node

var total_coins: int = 0
var current_run_coins: int = 0  # 🪙 New tracking variable
const SAVE_PATH = "user://save_data.cfg"

func _ready() -> void:
	load_game()

func reset_run_coins() -> void:
	current_run_coins = 0

func add_coins(amount: int = 1) -> void:
	current_run_coins += amount
	total_coins += amount
	save_game()

func save_game() -> void:
	var config = ConfigFile.new()
	config.set_value("Economy", "coins", total_coins)
	config.save(SAVE_PATH)

func load_game() -> void:
	var config = ConfigFile.new()
	var error = config.load(SAVE_PATH)
	
	if error == OK:
		total_coins = config.get_value("Economy", "coins", 0)
