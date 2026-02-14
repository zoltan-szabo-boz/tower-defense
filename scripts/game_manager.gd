extends Node

signal gold_changed(amount: int)
signal population_changed(current: int, cap: int)
signal base_hp_changed(current: float, max_hp: float)
signal game_over(waves_survived: int, enemies_killed: int, units_produced: int)
signal unit_spawned(unit_type: String)
signal enemy_killed()

var gold: int = 0
var population_cap: int = 10
var current_population: int = 0
var base_hp: float = 100.0
var base_max_hp: float = 100.0
var is_game_over: bool = false

# Stats tracking
var total_enemies_killed: int = 0
var total_units_produced: int = 0

var unit_scenes: Dictionary = {}

func _ready() -> void:
	unit_scenes = {
		"footman": preload("res://scenes/units/footman.tscn"),
		"cavalry": preload("res://scenes/units/cavalry.tscn"),
		"archer": preload("res://scenes/units/archer.tscn"),
		"flyer": preload("res://scenes/units/flyer.tscn"),
	}

func start_game() -> void:
	gold = GameConfig.starting_gold
	population_cap = GameConfig.starting_pop_cap
	current_population = 0
	base_hp = GameConfig.base_max_hp
	base_max_hp = GameConfig.base_max_hp
	is_game_over = false
	total_enemies_killed = 0
	total_units_produced = 0

	# Reset upgrade multipliers
	GameConfig.damage_multiplier = 1.0
	GameConfig.hp_multiplier = 1.0
	GameConfig.accuracy_multiplier = 1.0
	GameConfig.attack_speed_multiplier = 1.0
	GameConfig.armory_count = 0
	GameConfig.fortification_count = 0
	GameConfig.training_ground_count = 0
	GameConfig.war_college_count = 0

	gold_changed.emit(gold)
	population_changed.emit(current_population, population_cap)
	base_hp_changed.emit(base_hp, base_max_hp)

func can_afford(cost: int) -> bool:
	return gold >= cost

func spend_gold(amount: int) -> bool:
	if gold >= amount:
		gold -= amount
		gold_changed.emit(gold)
		return true
	return false

func add_gold(amount: int) -> void:
	gold += amount
	gold_changed.emit(gold)

func can_spawn_unit() -> bool:
	return current_population < population_cap

func add_population(amount: int = 1) -> void:
	current_population += amount
	population_changed.emit(current_population, population_cap)

func remove_population(amount: int = 1) -> void:
	current_population = max(0, current_population - amount)
	population_changed.emit(current_population, population_cap)

func increase_pop_cap(amount: int) -> void:
	population_cap += amount
	population_changed.emit(current_population, population_cap)

func damage_base(amount: float) -> void:
	if is_game_over:
		return
	base_hp -= amount
	base_hp = maxf(base_hp, 0)
	base_hp_changed.emit(base_hp, base_max_hp)
	if base_hp <= 0:
		_trigger_game_over()

func _trigger_game_over() -> void:
	is_game_over = true
	var waves = WaveManager.current_wave if WaveManager else 0
	game_over.emit(waves, total_enemies_killed, total_units_produced)

func spawn_player_unit(unit_type: String) -> BaseUnit:
	if not can_spawn_unit():
		return null
	if not unit_scenes.has(unit_type):
		push_error("Unknown unit type: " + unit_type)
		return null

	var unit = unit_scenes[unit_type].instantiate() as BaseUnit
	unit.team = 1

	var units_container = get_tree().root.get_node_or_null("Main/Units")
	if not units_container:
		push_error("Units container not found!")
		unit.queue_free()
		return null

	# Set position BEFORE adding to tree so first physics frame sees correct position
	var spawn_x = GameConfig.get_player_spawn_x()
	var half_depth = GameConfig.battlefield_depth / 2.0
	var spawn_z = randf_range(-half_depth + GameConfig.spawn_margin, half_depth - GameConfig.spawn_margin)
	var spawn_pos = Vector3(spawn_x, 0, spawn_z)

	if unit_type == "flyer":
		spawn_pos.y = GameConfig.flyer_altitude

	unit.position = spawn_pos
	units_container.add_child(unit)

	# Track population
	add_population()
	total_units_produced += 1
	unit_spawned.emit(unit_type)
	unit.unit_died.connect(_on_player_unit_died)

	return unit

func spawn_enemy_unit(unit_type: String, wave_number: int = 1) -> BaseUnit:
	var unit: BaseUnit
	var units_container = get_tree().root.get_node_or_null("Main/Units")
	if not units_container:
		push_error("Units container not found!")
		return null

	if unit_type == "boss":
		# Boss uses footman scene but with boss stats
		unit = unit_scenes["footman"].instantiate() as BaseUnit
		unit.unit_type = "boss"
	elif unit_type == "brute":
		unit = unit_scenes["footman"].instantiate() as BaseUnit
		unit.unit_type = "brute"
	elif unit_type == "ranger":
		unit = unit_scenes["archer"].instantiate() as BaseUnit
	elif unit_type == "grunt":
		unit = unit_scenes["footman"].instantiate() as BaseUnit
	else:
		unit = unit_scenes["footman"].instantiate() as BaseUnit

	unit.team = 2

	# Set position BEFORE adding to tree
	var spawn_x = GameConfig.get_enemy_spawn_x()
	var half_depth = GameConfig.battlefield_depth / 2.0
	var spawn_z = randf_range(-half_depth + GameConfig.spawn_margin, half_depth - GameConfig.spawn_margin)
	unit.position = Vector3(spawn_x, 0, spawn_z)
	units_container.add_child(unit)

	unit.unit_died.connect(_on_enemy_unit_died)

	return unit

func _on_player_unit_died(_unit: BaseUnit) -> void:
	remove_population()

func _on_enemy_unit_died(_unit: BaseUnit) -> void:
	total_enemies_killed += 1
	enemy_killed.emit()

func add_kill(_team: int) -> void:
	# Kill tracking is handled by _on_enemy_unit_died signal
	pass
