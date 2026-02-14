extends Node

signal wave_started(wave_number: int)
signal wave_completed(wave_number: int, reward: int)
signal countdown_updated(seconds_remaining: float)
signal all_enemies_dead()

var current_wave: int = 0
var wave_timer: float = 0.0
var wave_in_progress: bool = false
var enemies_alive: int = 0
var wave_active: bool = false

func _ready() -> void:
	pass

func start_waves() -> void:
	wave_active = true
	current_wave = 0
	wave_timer = GameConfig.first_wave_delay
	enemies_alive = 0
	wave_in_progress = false

func _process(delta: float) -> void:
	if not wave_active or GameManager.is_game_over:
		return

	if not wave_in_progress:
		wave_timer -= delta
		countdown_updated.emit(wave_timer)
		if wave_timer <= 0:
			_start_next_wave()

func _start_next_wave() -> void:
	current_wave += 1
	wave_in_progress = true
	wave_started.emit(current_wave)

	var composition = _get_wave_composition(current_wave)
	enemies_alive = 0

	# Count total enemies
	for entry in composition:
		enemies_alive += entry.count

	# Spawn enemies with staggered timing
	_spawn_wave(composition)

func _spawn_wave(composition: Array) -> void:
	var spawn_delay: float = 0.0
	for entry in composition:
		for i in range(entry.count):
			_spawn_enemy_delayed(entry.type, spawn_delay)
			spawn_delay += 0.5  # Stagger spawns by 0.5s

func _spawn_enemy_delayed(enemy_type: String, delay: float) -> void:
	if delay <= 0:
		_spawn_single_enemy(enemy_type)
	else:
		get_tree().create_timer(delay).timeout.connect(_spawn_single_enemy.bind(enemy_type))

func _spawn_single_enemy(enemy_type: String) -> void:
	if GameManager.is_game_over:
		return
	var unit = GameManager.spawn_enemy_unit(enemy_type, current_wave)
	if unit:
		unit.unit_died.connect(_on_enemy_died)

func _on_enemy_died(_unit: BaseUnit) -> void:
	enemies_alive -= 1
	if enemies_alive <= 0 and wave_in_progress:
		_complete_wave()

func _complete_wave() -> void:
	wave_in_progress = false

	var reward = _calculate_reward(current_wave)
	GameManager.add_gold(reward)
	wave_completed.emit(current_wave, reward)
	all_enemies_dead.emit()

	# Set timer for next wave
	var interval = maxf(
		GameConfig.first_wave_delay - current_wave * GameConfig.wave_interval_reduction,
		GameConfig.min_wave_interval
	)
	wave_timer = interval

func _calculate_reward(wave_number: int) -> int:
	var reward = GameConfig.base_wave_reward + wave_number * GameConfig.wave_reward_scaling
	if _is_boss_wave(wave_number):
		reward += GameConfig.boss_wave_bonus
	return reward

func _is_boss_wave(wave_number: int) -> bool:
	return wave_number % 5 == 0

func _get_wave_composition(wave_number: int) -> Array:
	var composition: Array = []

	# Grunts: base 3, +2 per wave
	var grunt_count = 3 + (wave_number - 1) * 2

	# Rangers: appear wave 3+
	var ranger_count = 0
	if wave_number >= 3:
		ranger_count = max(0, wave_number - 1)

	# Brutes: appear wave 7+
	var brute_count = 0
	if wave_number >= 7:
		brute_count = max(0, wave_number - 5)

	# Boss: every 5th wave
	var boss_count = 0
	if _is_boss_wave(wave_number):
		boss_count = 1

	# Adjust grunt count down as other types come in
	grunt_count = max(2, grunt_count - ranger_count - brute_count)

	composition.append({"type": "grunt", "count": grunt_count})

	if ranger_count > 0:
		composition.append({"type": "ranger", "count": ranger_count})

	if brute_count > 0:
		composition.append({"type": "brute", "count": brute_count})

	if boss_count > 0:
		composition.append({"type": "boss", "count": boss_count})

	return composition
