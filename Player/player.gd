extends CharacterBody2D

var movement_speed = 40.0
var hp = 80
var maxhp = 80
var last_movement = Vector2.UP
var has_moved = false
var time = 0

var experience = 0
var experience_level = 1
var collected_experience = 0

# Time Slow Ability Attributes
var timeslow_level = 0
var timeslow_cooldown = 6.0       # Cooldown in real-world seconds
var timeslow_duration = 1.5       # Duration of slow motion
var timeslow_factor = 0.3         # 30% of normal engine speed
var is_timeslow_active = false
var is_timeslow_cooldown = false

# Attacks
var iceSpear = preload("res://Player/Attack/ice_spear.tscn")
var tornado = preload("res://Player/Attack/tornado.tscn")

# AttackNodes
@onready var iceSpearTimer = get_node("%IceSpearTimer")
@onready var iceSpearAttackTimer = get_node("%IceSpearAttackTimer")
@onready var tornadoTimer = get_node("%TornadoTimer")
@onready var tornadoAttackTimer = get_node("%TornadoAttackTimer")

# UPGRADES
var collected_upgrades = []
var upgrade_options = []
var armor = 0
var speed = 0
var spell_size = 0
var spell_cooldown = 0
var additional_attacks = 0 


# IceSpear
var icespear_ammo = 0
var icespear_baseammo = 0
var icespear_attackspeed = 1.5
var icespear_level = 0

# Tornado
var tornado_ammo = 0
var tornado_baseammo = 0
var tornado_attackspeed = 3
var tornado_level = 0

# Enemy Related
var enemy_close = []

@onready var sprite = $Sprite2D
@onready var walkTimer = get_node("%walkTimer")

# GUI
@onready var expBar = get_node("%ExperienceBar")
@onready var lblLevel = get_node("%lbl_level")
@onready var levelPanel = get_node("%LevelUp")
@onready var upgradeOptions = get_node("%UpgradeOptions")
@onready var itemOptions = preload("res://Utility/item_option.tscn")
@onready var sndLevelUp = get_node("%snd_levelup")
@onready var healthBar = get_node("%HealthBar")
@onready var lblTimer = get_node("%lblTimer")
@onready var collectedWeapons = get_node("%CollecteWeapons")
@onready var collectedUpgrades = get_node("%CollectedUpgrades")
@onready var itemContainer = preload("res://Player/GUI/item_container.tscn")
@onready var time_tint = get_node("../TimeSlowTint")
@onready var lblCooldown = get_node("%lblTimeSlowCooldown")

@onready var deathPanel = get_node("%DeathPanel")
@onready var lblResult = get_node("%lbl_Result")
@onready var sndVictory = get_node("%snd_victory")
@onready var sndLose = get_node("%snd_lose")

# Signal
signal playerdeath

func _ready():
	timeslow_level = 1 #temp
	upgrade_character("icespear1")
	attack()
	set_expbar(experience, calculate_experiencecap())
	update_health_bar()
	


func _physics_process(_delta):
	movement()
	
	# Only allow the ability if the player has unlocked it via levelup/upgrade
	if timeslow_level > 0 and Input.is_action_just_pressed("time_slow"):
		if not is_timeslow_active and not is_timeslow_cooldown:
			trigger_time_slow()
	
func movement():
	var x_mov = Input.get_action_strength("right") -  Input.get_action_strength("left")
	var y_mov = Input.get_action_strength("down") - Input.get_action_strength("up")
	var mov = Vector2(x_mov, y_mov)
	if mov.x > 0:
		#sprite.flip_h = true
		sprite.flip_h = false
	elif mov.x < 0:
		#sprite.flip_h = false
		sprite.flip_h = true
		
	if mov != Vector2.ZERO:
		last_movement = mov
		has_moved = true
		sprite.play("walk")
	else:
		if not has_moved:
			sprite.play("idle_south")
		else:
			sprite.play("idle")

	velocity = mov.normalized()*movement_speed
	move_and_slide()
	
func attack():
	if icespear_level > 0:
		iceSpearTimer.wait_time = icespear_attackspeed * (1-spell_cooldown)
		if iceSpearTimer.is_stopped():
			iceSpearTimer.start()
	if tornado_level > 0:
		tornadoTimer.wait_time = tornado_attackspeed * (1-spell_cooldown)
		if tornadoTimer.is_stopped():
			tornadoTimer.start()
	
func _on_hurt_box_hurt(damage, _angle, _knockback):
	hp -= clamp(damage-armor, 1.0, 999.0)
	update_health_bar()

	if hp <= 0:
		death()

func update_health_bar():
	healthBar.max_value = maxhp
	healthBar.value = hp
	var ratio = clamp(hp / float(maxhp), 0.0, 1.0)
	healthBar.tint_progress = Color.from_hsv(ratio * 0.333, 1.0, 1.0)


func _on_ice_spear_timer_timeout():
	icespear_ammo += icespear_baseammo + additional_attacks
	iceSpearAttackTimer.start()


func _on_ice_spear_attack_timer_timeout():
	if icespear_ammo > 0:
		var icespear_attack = iceSpear.instantiate()
		icespear_attack.position = position
		icespear_attack.target = get_random_target()
		icespear_attack.level = icespear_level
		add_child(icespear_attack)
		icespear_ammo -= 1
		if icespear_ammo > 0:
			iceSpearAttackTimer.start()
		else:
			iceSpearAttackTimer.stop()
			
func _on_tornado_timer_timeout():
	tornado_ammo += tornado_baseammo + additional_attacks
	tornadoAttackTimer.start()


func _on_tornado_attack_timer_timeout():
	if tornado_ammo > 0:
		var tornado_attack = tornado.instantiate()
		tornado_attack.position = position
		tornado_attack.last_movement = last_movement
		tornado_attack.level = tornado_level
		add_child(tornado_attack)
		tornado_ammo -= 1
		if tornado_ammo > 0:
			tornadoAttackTimer.start()
		else:
			tornadoAttackTimer.stop()
		
func get_random_target():
	if enemy_close.size() > 0:
		return enemy_close.pick_random().global_position
	else:
		return Vector2.UP


func _on_enemy_detection_area_body_entered(body):
	if not enemy_close.has(body):
		enemy_close.append(body)


func _on_enemy_detection_area_body_exited(body):
	if enemy_close.has(body):
		enemy_close.erase(body)

func death():
	deathPanel.visible = true
	emit_signal("playerdeath")
	get_tree().paused = true
	var tween = deathPanel.create_tween()
	tween.tween_property(deathPanel,"position",Vector2(220,50),3.0).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	tween.play()
	if time >= 200:
		lblResult.text = "You Win"
		sndVictory.play()
	else:
		lblResult.text = "You Lose"
		sndLose.play()


func _on_grab_area_area_entered(area: Area2D) -> void:
	if area.is_in_group("loot"):
		area.target = self

func _on_collect_area_area_entered(area: Area2D) -> void:
	if area.is_in_group("loot"):
		var gem_exp = area.collect()
		calculate_experience(gem_exp)
		
func calculate_experience(gem_exp):
	var exp_required = calculate_experiencecap()
	collected_experience += gem_exp
	if experience + collected_experience >= exp_required: # Level up
		collected_experience -= exp_required - experience
		experience_level += 1
		experience = 0
		exp_required = calculate_experiencecap()
		levelup()
	else:
		experience += collected_experience
		collected_experience = 0
	
	set_expbar(experience, exp_required)
	
func calculate_experiencecap():
	var exp_cap = experience_level
	if experience_level < 20:
		exp_cap = experience_level*5
	elif experience_level < 40:
		exp_cap + 95 * (experience_level-19)*8
	else:
		exp_cap = 255 + (experience_level - 39)*12
	return exp_cap
		 
func set_expbar(set_value = 1, set_max_value = 100):
	expBar.value = set_value
	expBar.max_value = set_max_value

func levelup():
	sndLevelUp.play()
	lblLevel.text = str("Level: ", experience_level)
	var tween = levelPanel.create_tween()
	tween.tween_property(levelPanel,"position",Vector2(220,50),0.2).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_IN)
	tween.play()
	levelPanel.visible = true
	var options = 0
	var optionsmax = 3
	while options < optionsmax:
		var option_choice = itemOptions.instantiate()
		option_choice.item = get_random_item()
		upgradeOptions.add_child(option_choice)
		options += 1
		
	get_tree().paused = true
	
func upgrade_character(upgrade):
	match upgrade:
		"icespear1":
			icespear_level = 1
			icespear_baseammo += 1
		"icespear2":
			icespear_level = 2
			icespear_baseammo += 1
		"icespear3":
			icespear_level = 3
		"icespear4":
			icespear_level = 4
			icespear_baseammo += 2
		"tornado1":
			tornado_level = 1
			tornado_baseammo += 1
		"tornado2":
			tornado_level = 2
			tornado_baseammo += 1
		"tornado3":
			tornado_level = 3
			tornado_attackspeed -= 0.5
		"tornado4":
			tornado_level = 4
			tornado_baseammo += 1
		#"javelin1":
			#javelin_level = 1
			#javelin_ammo = 1
		#"javelin2":
			#javelin_level = 2
		#"javelin3":
			#javelin_level = 3
		#"javelin4":
			#javelin_level = 4
		"armor1","armor2","armor3","armor4":
			armor += 1
		"speed1","speed2","speed3","speed4":
			movement_speed += 20.0
		"tome1","tome2","tome3","tome4":
			spell_size += 0.10
		"scroll1","scroll2","scroll3","scroll4":
			spell_cooldown += 0.05
		"ring1","ring2":
			additional_attacks += 1
		"food":
			hp += 20
			hp = clamp(hp,0,maxhp)
			update_health_bar()
		"timeslow1":
			timeslow_level = 1
		"timeslow2":
			timeslow_level = 2
			timeslow_duration = 2.0  # Upgrade the duration slightly
		"timeslow3":
			timeslow_level = 3
			timeslow_cooldown = 4.5  # Lower the cooldown
	adjust_gui_collection(upgrade)
	attack()
	var option_children = upgradeOptions.get_children()
	for i in option_children:
		i.queue_free()
	upgrade_options.clear()
	collected_upgrades.append(upgrade)
	levelPanel.visible = false
	levelPanel.position = Vector2(800,50)
	get_tree().paused = false
	calculate_experience(0)
	
func get_random_item():
	var dblist = []
	for i in UpgradeDb.UPGRADES:
		if i in collected_upgrades: # Find already collected upgrades
			pass
		elif i in upgrade_options: # If the upgrade is already an option
			pass
		elif UpgradeDb.UPGRADES[i]["type"] == "item": # Don't pick food
			pass
		elif UpgradeDb.UPGRADES[i]["prerequisite"].size() > 0: # Check for prerequisites
			#var to_add = true
			for n in UpgradeDb.UPGRADES[i]["prerequisite"]:
				if not n in collected_upgrades:
					pass
					#to_add = false
			#if to_add:
				#dblist.append(i)
		#else:
			#dblist.append(i)
		#if dblist.size() > 0:
			#var randomitem = dblist.pick_random()
			#upgrade_options.append(randomitem)
			#return randomitem
		#else:
			#return null
			
			
				else:
					dblist.append(i)
		else:
			dblist.append(i)
	if dblist.size() > 0:
		var randomitem = dblist.pick_random()
		upgrade_options.append(randomitem)
		return randomitem
	else:
		return null
		
func change_time(argtime = 0):
	time = argtime
	var get_m = int(time/60.0)
	var get_s = time % 60
	if get_m < 10:
		get_m = str(0,get_m)
	if get_s < 10:
		get_s = str(0,get_s)
	lblTimer.text = str(get_m,":",get_s)
	
func adjust_gui_collection(upgrade):
	var get_upgraded_displayname = UpgradeDb.UPGRADES[upgrade]["displayname"]
	var get_type = UpgradeDb.UPGRADES[upgrade]["type"]
	if get_type != "item":
		var get_collected_displaynames = []
		for i in collected_upgrades:
			get_collected_displaynames.append(UpgradeDb.UPGRADES[i]["displayname"])
		if not get_upgraded_displayname in get_collected_displaynames:
			var new_item = itemContainer.instantiate()
			new_item.upgrade = upgrade
			match get_type:
				"weapon":
					collectedWeapons.add_child(new_item)
				"upgrade":
					collectedUpgrades.add_child(new_item)


func _on_btn_menu_click_end() -> void:
	get_tree().paused = false
	var _level = get_tree().change_scene_to_file("res://TitleScreen/menu.tscn")
	
#func trigger_time_slow() -> void:
	#is_timeslow_active = true
	#
	## Turn on the cool time-slow visual tint
	#time_tint.color = Color("4a75a0") 
	#
	#GlobalTime.enemy_time_scale = timeslow_factor
	#await get_tree().create_timer(timeslow_duration).timeout
	#GlobalTime.enemy_time_scale = 1.0
	#
	## Restore normal, clear lighting
	#time_tint.color = Color.WHITE 
	#
	#is_timeslow_active = false
	#is_timeslow_cooldown = true
	#
	#await get_tree().create_timer(timeslow_cooldown).timeout
	#is_timeslow_cooldown = false
	#print("Time Slow Ready!")

func trigger_time_slow() -> void:
	is_timeslow_active = true
	time_tint.color = Color("4a75a0") 
	GlobalTime.enemy_time_scale = timeslow_factor
	
	# Update UI to show the ability is active
	lblCooldown.text = "ACTIVE"
	lblCooldown.modulate = Color.CYAN
	
	await get_tree().create_timer(timeslow_duration).timeout
	GlobalTime.enemy_time_scale = 1.0
	time_tint.color = Color.WHITE 
	
	is_timeslow_active = false
	is_timeslow_cooldown = true
	
	# Dynamic Cooldown Countdown Loop
	var time_left = timeslow_cooldown
	lblCooldown.modulate = Color.RED
	while time_left > 0:
		lblCooldown.text = str("COOLDOWN: ", snapping_round(time_left), "s")
		await get_tree().create_timer(0.1).timeout
		time_left -= 0.1
	
	is_timeslow_cooldown = false
	lblCooldown.text = "READY"
	lblCooldown.modulate = Color.GREEN

# Helper to keep the float numbers looking clean on screen
func snapping_round(num: float) -> String:
	return "%.1f" % num
	
