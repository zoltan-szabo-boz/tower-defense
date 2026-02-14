extends Node
## Game Configuration - All tweakable values in one place

# =============================================================================
# BATTLEFIELD LAYOUT
# =============================================================================
# Total battlefield: 120 x 40
# Base zone: left 30% (x: -60 to -24)
# Combat zone: right 70% (x: -24 to +60)
@export var battlefield_width: float = 120.0
@export var battlefield_depth: float = 40.0
@export var base_zone_ratio: float = 0.3  # Left 30% is protected base zone
@export var spawn_margin: float = 2.0

# Derived positions (computed in _ready)
var base_zone_left: float  # Left edge of base zone (x)
var base_zone_right: float  # Right edge of base zone / combat zone boundary
var combat_zone_right: float  # Right edge of combat zone (enemy spawn)
var base_structure_x: float  # Position of the base HP structure

# =============================================================================
# GRID SYSTEM (for building placement in base zone)
# =============================================================================
@export var grid_cell_size: float = 4.0  # Each grid cell is 4x4 units
var grid_cols: int  # Computed in _ready
var grid_rows: int  # Computed in _ready
var grid_origin: Vector3  # World position of grid cell (0,0) bottom-left corner

# =============================================================================
# BASE HP
# =============================================================================
@export var base_max_hp: float = 100.0

# =============================================================================
# ECONOMY
# =============================================================================
@export var starting_gold: int = 150
@export var starting_pop_cap: int = 10
@export var pop_per_house: int = 5
@export var gold_mine_rate: float = 5.0  # Gold per second

# =============================================================================
# BUILDING COSTS
# =============================================================================
@export var barracks_cost: int = 50
@export var archery_range_cost: int = 75
@export var stable_cost: int = 100
@export var aviary_cost: int = 120
@export var armory_cost: int = 80
@export var fortification_cost: int = 80
@export var training_ground_cost: int = 100
@export var war_college_cost: int = 120
@export var gold_mine_cost: int = 60
@export var house_cost: int = 40

# =============================================================================
# PRODUCTION INTERVALS (seconds between unit spawns)
# =============================================================================
@export var barracks_interval: float = 10.0
@export var archery_range_interval: float = 14.0
@export var stable_interval: float = 16.0
@export var aviary_interval: float = 18.0

# =============================================================================
# UPGRADE BUILDING EFFECTS
# =============================================================================
# Diminishing returns: 1st = full, 2nd = 75%, 3rd = 50%, 4th+ = 25%
@export var armory_damage_bonus: float = 0.20  # +20% damage per stack
@export var fortification_hp_bonus: float = 0.20  # +20% HP per stack
@export var training_accuracy_bonus: float = 0.15  # +15% accuracy per stack (reduces aim deviation)
@export var war_college_speed_bonus: float = 0.10  # +10% attack speed per stack

# =============================================================================
# UNIT STATS - FOOTMAN
# =============================================================================
@export var footman_hp: float = 100.0
@export var footman_speed: float = 3.0
@export var footman_damage: float = 15.0
@export var footman_attack_delay: float = 1.0
@export var footman_attack_range: float = 1.5

# =============================================================================
# UNIT STATS - CAVALRY
# =============================================================================
@export var cavalry_hp: float = 80.0
@export var cavalry_speed: float = 6.0
@export var cavalry_damage: float = 25.0
@export var cavalry_attack_delay: float = 1.2
@export var cavalry_attack_range: float = 1.8

# =============================================================================
# UNIT STATS - ARCHER
# =============================================================================
@export var archer_hp: float = 50.0
@export var archer_speed: float = 2.0
@export var archer_damage: float = 20.0
@export var archer_attack_delay: float = 2.0

# =============================================================================
# UNIT STATS - FLYER (Eagle)
# =============================================================================
@export var flyer_hp: float = 60.0
@export var flyer_speed: float = 7.0
@export var flyer_damage: float = 18.0
@export var flyer_attack_delay: float = 1.5
@export var flyer_attack_range: float = 2.0
@export var flyer_altitude: float = 5.0

# =============================================================================
# ENEMY STATS - BRUTE
# =============================================================================
@export var brute_hp: float = 200.0
@export var brute_speed: float = 2.0
@export var brute_damage: float = 30.0
@export var brute_attack_delay: float = 1.5
@export var brute_attack_range: float = 2.0

# =============================================================================
# ENEMY STATS - BOSS (scaled brute)
# =============================================================================
@export var boss_hp_multiplier: float = 5.0
@export var boss_damage_multiplier: float = 2.0
@export var boss_size_multiplier: float = 2.0

# =============================================================================
# WAVE SYSTEM
# =============================================================================
@export var first_wave_delay: float = 45.0  # Seconds before first wave
@export var min_wave_interval: float = 25.0  # Minimum time between waves
@export var wave_interval_reduction: float = 1.0  # Seconds less per wave
@export var base_wave_reward: int = 30
@export var wave_reward_scaling: int = 10  # Extra gold per wave number
@export var boss_wave_bonus: int = 50

# =============================================================================
# PROJECTILE
# =============================================================================
@export var projectile_speed: float = 22.0
@export var projectile_gravity: float = 10.0
@export var projectile_despawn_delay: float = 2.5
@export var projectile_grace_time: float = 0.2  # Seconds before projectile can collide (passes through friendlies near archer)
@export_range(0.0, 45.0, 0.5) var archer_aim_deviation: float = 8.0
@export var hit_stagger_duration: float = 0.5

# =============================================================================
# VISUAL - UNIT SIZES
# =============================================================================
@export var footman_size: Vector3 = Vector3(0.8, 1.6, 0.8)
@export var cavalry_size: Vector3 = Vector3(1.2, 1.4, 2.0)
@export var archer_size: Vector3 = Vector3(0.7, 1.8, 0.7)
@export var flyer_size: Vector3 = Vector3(1.0, 0.4, 1.2)
@export var brute_size: Vector3 = Vector3(1.2, 2.0, 1.2)
@export var projectile_size: Vector3 = Vector3(0.2, 0.2, 0.8)

# =============================================================================
# VISUAL - TEAM COLORS (Team 1 = Player/Blue, Team 2 = Enemy/Red)
# =============================================================================
@export var team1_footman_color: Color = Color(0.3, 0.5, 0.9)
@export var team1_cavalry_color: Color = Color(0.2, 0.3, 0.8)
@export var team1_archer_color: Color = Color(0.1, 0.2, 0.6)
@export var team1_flyer_color: Color = Color(0.5, 0.7, 1.0)
@export var team1_projectile_color: Color = Color(0.4, 0.6, 1.0)

@export var team2_footman_color: Color = Color(0.9, 0.3, 0.3)
@export var team2_cavalry_color: Color = Color(0.8, 0.2, 0.2)
@export var team2_archer_color: Color = Color(0.6, 0.1, 0.1)
@export var team2_flyer_color: Color = Color(1.0, 0.6, 0.4)
@export var team2_projectile_color: Color = Color(1.0, 0.4, 0.4)

# Enemy-specific colors (using team 2 palette + extras)
@export var brute_color: Color = Color(0.7, 0.15, 0.15)
@export var boss_color: Color = Color(0.5, 0.0, 0.5)

# Building colors
@export var barracks_color: Color = Color(0.3, 0.5, 0.9)
@export var archery_range_color: Color = Color(0.1, 0.4, 0.2)
@export var stable_color: Color = Color(0.6, 0.4, 0.2)
@export var aviary_color: Color = Color(0.5, 0.7, 1.0)
@export var armory_color: Color = Color(0.6, 0.3, 0.3)
@export var fortification_color: Color = Color(0.5, 0.5, 0.5)
@export var training_ground_color: Color = Color(0.2, 0.6, 0.3)
@export var war_college_color: Color = Color(0.4, 0.2, 0.6)
@export var gold_mine_color: Color = Color(0.9, 0.75, 0.1)
@export var house_color: Color = Color(0.7, 0.6, 0.4)

# =============================================================================
# UPGRADE MULTIPLIERS (modified at runtime by upgrade buildings)
# =============================================================================
var damage_multiplier: float = 1.0
var hp_multiplier: float = 1.0
var accuracy_multiplier: float = 1.0  # Multiplier on aim deviation (lower = more accurate)
var attack_speed_multiplier: float = 1.0  # Multiplier on attack delay (lower = faster)

# Upgrade building counts (for diminishing returns)
var armory_count: int = 0
var fortification_count: int = 0
var training_ground_count: int = 0
var war_college_count: int = 0

func _ready() -> void:
	_compute_layout()

func _compute_layout() -> void:
	var half_w = battlefield_width / 2.0
	base_zone_left = -half_w
	base_zone_right = -half_w + battlefield_width * base_zone_ratio
	combat_zone_right = half_w
	base_structure_x = base_zone_left + 2.0  # Base structure near left edge

	# Grid covers the base zone (leaving margin for base structure)
	var grid_start_x = base_zone_left + 6.0  # Leave room for base structure
	var grid_end_x = base_zone_right - 2.0  # Small margin before combat zone
	var grid_start_z = -battlefield_depth / 2.0 + 2.0
	var grid_end_z = battlefield_depth / 2.0 - 2.0

	grid_cols = int((grid_end_x - grid_start_x) / grid_cell_size)
	grid_rows = int((grid_end_z - grid_start_z) / grid_cell_size)
	grid_origin = Vector3(grid_start_x, 0, grid_start_z)

func get_unit_color(team: int, unit_type: String) -> Color:
	if team == 1:
		match unit_type:
			"footman": return team1_footman_color
			"cavalry": return team1_cavalry_color
			"archer": return team1_archer_color
			"flyer": return team1_flyer_color
			"projectile": return team1_projectile_color
	else:
		match unit_type:
			"footman": return team2_footman_color
			"cavalry": return team2_cavalry_color
			"archer": return team2_archer_color
			"flyer": return team2_flyer_color
			"brute": return brute_color
			"boss": return boss_color
			"projectile": return team2_projectile_color
	return Color.WHITE

func get_projectile_max_range() -> float:
	return (projectile_speed * projectile_speed / projectile_gravity) * 0.5

func get_unit_stats(unit_type: String) -> Dictionary:
	match unit_type:
		"footman":
			return {
				"hp": footman_hp * hp_multiplier,
				"speed": footman_speed,
				"damage": footman_damage * damage_multiplier,
				"attack_delay": footman_attack_delay * attack_speed_multiplier,
				"attack_range": footman_attack_range,
				"size": footman_size
			}
		"cavalry":
			return {
				"hp": cavalry_hp * hp_multiplier,
				"speed": cavalry_speed,
				"damage": cavalry_damage * damage_multiplier,
				"attack_delay": cavalry_attack_delay * attack_speed_multiplier,
				"attack_range": cavalry_attack_range,
				"size": cavalry_size
			}
		"archer":
			return {
				"hp": archer_hp * hp_multiplier,
				"speed": archer_speed,
				"damage": archer_damage * damage_multiplier,
				"attack_delay": archer_attack_delay * attack_speed_multiplier,
				"attack_range": get_projectile_max_range(),
				"size": archer_size
			}
		"flyer":
			return {
				"hp": flyer_hp * hp_multiplier,
				"speed": flyer_speed,
				"damage": flyer_damage * damage_multiplier,
				"attack_delay": flyer_attack_delay * attack_speed_multiplier,
				"attack_range": flyer_attack_range,
				"size": flyer_size,
				"altitude": flyer_altitude
			}
		"brute":
			return {
				"hp": brute_hp * hp_multiplier,
				"speed": brute_speed,
				"damage": brute_damage,
				"attack_delay": brute_attack_delay,
				"attack_range": brute_attack_range,
				"size": brute_size
			}
		"boss":
			return {
				"hp": brute_hp * boss_hp_multiplier,
				"speed": brute_speed * 0.8,
				"damage": brute_damage * boss_damage_multiplier,
				"attack_delay": brute_attack_delay,
				"attack_range": brute_attack_range,
				"size": brute_size * boss_size_multiplier
			}
	return {}

func grid_to_world(col: int, row: int) -> Vector3:
	return Vector3(
		grid_origin.x + col * grid_cell_size + grid_cell_size / 2.0,
		0,
		grid_origin.z + row * grid_cell_size + grid_cell_size / 2.0
	)

func world_to_grid(world_pos: Vector3) -> Vector2i:
	var col = int((world_pos.x - grid_origin.x) / grid_cell_size)
	var row = int((world_pos.z - grid_origin.z) / grid_cell_size)
	return Vector2i(col, row)

func is_valid_grid_pos(col: int, row: int) -> bool:
	return col >= 0 and col < grid_cols and row >= 0 and row < grid_rows

func get_player_spawn_x() -> float:
	return base_zone_right + 1.0

func get_enemy_spawn_x() -> float:
	return combat_zone_right - spawn_margin

func get_diminishing_bonus(base_bonus: float, count: int) -> float:
	# Returns total cumulative bonus for 'count' buildings
	# 1st = 100%, 2nd = 75%, 3rd = 50%, 4th+ = 25%
	var total: float = 0.0
	for i in range(count):
		var multiplier: float
		match i:
			0: multiplier = 1.0
			1: multiplier = 0.75
			2: multiplier = 0.5
			_: multiplier = 0.25
		total += base_bonus * multiplier
	return total

func recalculate_upgrades() -> void:
	damage_multiplier = 1.0 + get_diminishing_bonus(armory_damage_bonus, armory_count)
	hp_multiplier = 1.0 + get_diminishing_bonus(fortification_hp_bonus, fortification_count)
	accuracy_multiplier = 1.0 - get_diminishing_bonus(training_accuracy_bonus, training_ground_count)
	accuracy_multiplier = maxf(accuracy_multiplier, 0.1)  # Cap at 90% reduction
	attack_speed_multiplier = 1.0 - get_diminishing_bonus(war_college_speed_bonus, war_college_count)
	attack_speed_multiplier = maxf(attack_speed_multiplier, 0.3)  # Cap at 70% reduction
