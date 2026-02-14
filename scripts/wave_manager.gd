extends Node

signal wave_started(wave_number: int)
signal wave_completed(wave_number: int, reward: int)
signal countdown_updated(seconds_remaining: float)
signal all_enemies_dead()

var current_wave: int = 0
var wave_timer: float = 0.0
var enemies_alive: int = 0
var wave_active: bool = false
var boss_alive: bool = false

# Track pending rewards per wave (wave_number -> enemy count remaining)
var _active_waves: Dictionary = {}

func _ready() -> void:
	pass

func start_waves() -> void:
	wave_active = true
	current_wave = 0
	wave_timer = GameConfig.first_wave_delay
	enemies_alive = 0
	boss_alive = false
	_active_waves.clear()

func _process(delta: float) -> void:
	if not wave_active or GameManager.is_game_over:
		return

	# Timer pauses only when a boss is alive
	if not boss_alive:
		wave_timer -= delta
		countdown_updated.emit(wave_timer)
		if wave_timer <= 0:
			_start_next_wave()
	else:
		countdown_updated.emit(-1.0)

func _start_next_wave() -> void:
	current_wave += 1
	wave_started.emit(current_wave)

	var composition = _get_wave_composition(current_wave)

	# Track enemies for this wave
	var wave_enemy_count: int = 0
	for entry in composition:
		wave_enemy_count += entry.count
	enemies_alive += wave_enemy_count
	_active_waves[current_wave] = wave_enemy_count

	# Check if this wave has a boss
	if _is_boss_wave(current_wave):
		boss_alive = true

	_spawn_wave(composition, current_wave)

	# Set timer for next wave immediately
	var interval = maxf(
		GameConfig.first_wave_delay - current_wave * GameConfig.wave_interval_reduction,
		GameConfig.min_wave_interval
	)
	wave_timer = interval

func _spawn_wave(composition: Array, wave_number: int) -> void:
	var spawn_delay: float = 0.0
	for entry in composition:
		for i in range(entry.count):
			_spawn_enemy_delayed(entry.type, spawn_delay, wave_number)
			spawn_delay += 0.5

func _spawn_enemy_delayed(enemy_type: String, delay: float, wave_number: int) -> void:
	if delay <= 0:
		_spawn_single_enemy(enemy_type, wave_number)
	else:
		get_tree().create_timer(delay).timeout.connect(_spawn_single_enemy.bind(enemy_type, wave_number))

func _spawn_single_enemy(enemy_type: String, wave_number: int) -> void:
	if GameManager.is_game_over:
		return
	var unit = GameManager.spawn_enemy_unit(enemy_type, wave_number)
	if unit:
		unit.unit_died.connect(_on_enemy_died.bind(wave_number, enemy_type))

func _on_enemy_died(unit: BaseUnit, wave_number: int, enemy_type: String) -> void:
	enemies_alive -= 1

	if enemy_type == "boss":
		boss_alive = _check_any_boss_alive(unit)

	# Track per-wave completion
	if _active_waves.has(wave_number):
		_active_waves[wave_number] -= 1
		if _active_waves[wave_number] <= 0:
			_complete_wave(wave_number)
			_active_waves.erase(wave_number)

	if enemies_alive <= 0:
		all_enemies_dead.emit()

func _check_any_boss_alive(dying_unit: BaseUnit = null) -> bool:
	var units = get_tree().get_nodes_in_group("team_2")
	for unit in units:
		if unit == dying_unit:
			continue
		if is_instance_valid(unit) and unit is BaseUnit and unit.unit_type == "boss":
			return true
	return false

func _complete_wave(wave_number: int) -> void:
	var reward = _calculate_reward(wave_number)
	GameManager.add_gold(reward)
	wave_completed.emit(wave_number, reward)

func _calculate_reward(wave_number: int) -> int:
	var reward = GameConfig.base_wave_reward + wave_number * GameConfig.wave_reward_scaling
	if _is_boss_wave(wave_number):
		reward += GameConfig.boss_wave_bonus
	return reward

func _is_boss_wave(wave_number: int) -> bool:
	return wave_number % 5 == 0

func _get_wave_composition(wave_number: int) -> Array:
	var composition: Array = []

	var grunt_count = 3 + (wave_number - 1) * 2

	var ranger_count = 0
	if wave_number >= 3:
		ranger_count = max(0, wave_number - 1)

	var brute_count = 0
	if wave_number >= 7:
		brute_count = max(0, wave_number - 5)

	var boss_count = 0
	if _is_boss_wave(wave_number):
		boss_count = 1

	grunt_count = max(2, grunt_count - ranger_count - brute_count)

	composition.append({"type": "grunt", "count": grunt_count})

	if ranger_count > 0:
		composition.append({"type": "ranger", "count": ranger_count})

	if brute_count > 0:
		composition.append({"type": "brute", "count": brute_count})

	if boss_count > 0:
		composition.append({"type": "boss", "count": boss_count})

	return composition
