extends CharacterBody3D
class_name BaseUnit

signal unit_died(unit: BaseUnit)

enum UnitState { IDLE, MOVING, ATTACKING, MARCHING, RALLYING }
enum TargetingMode { CLOSEST, FARTHEST }

@export var unit_type: String = "footman"
@export var team: int = 1
@export var targeting_mode: TargetingMode = TargetingMode.CLOSEST

var current_hp: float
var max_hp: float
var speed: float
var damage: float
var attack_delay: float
var attack_range: float
var stagger_resistance: float

var state: UnitState = UnitState.IDLE
var target: BaseUnit = null
var attack_timer: float = 0.0
var stagger_timer: float = 0.0
var mesh_instance: MeshInstance3D

func _ready() -> void:
	_load_stats()
	_setup_visuals()
	_setup_collision()
	add_to_group("units")
	add_to_group("team_%d" % team)

func _load_stats() -> void:
	var stats = GameConfig.get_unit_stats(unit_type)
	max_hp = stats.hp
	current_hp = max_hp
	speed = stats.speed
	damage = stats.damage
	attack_delay = stats.attack_delay
	attack_range = stats.attack_range
	stagger_resistance = stats.get("stagger_resistance", 0.0)

func _setup_visuals() -> void:
	var stats = GameConfig.get_unit_stats(unit_type)
	var size: Vector3 = stats.size

	mesh_instance = MeshInstance3D.new()
	var box_mesh = BoxMesh.new()
	box_mesh.size = size
	mesh_instance.mesh = box_mesh
	mesh_instance.position.y = size.y / 2.0

	var material = StandardMaterial3D.new()
	material.albedo_color = GameConfig.get_unit_color(team, unit_type)
	mesh_instance.material_override = material

	add_child(mesh_instance)

func _setup_collision() -> void:
	var stats = GameConfig.get_unit_stats(unit_type)
	var size: Vector3 = stats.size

	var collision_shape = CollisionShape3D.new()
	var box_shape = BoxShape3D.new()
	box_shape.size = size
	collision_shape.shape = box_shape
	collision_shape.position.y = size.y / 2.0
	add_child(collision_shape)

	if team == 1:
		collision_layer = 2
		collision_mask = 4 | 8
	else:
		collision_layer = 4
		collision_mask = 2 | 8

func _physics_process(delta: float) -> void:
	attack_timer -= delta
	stagger_timer -= delta

	if stagger_timer > 0:
		velocity = Vector3.ZERO
		_clamp_to_battlefield()
		return

	_check_collision_engagement()

	match state:
		UnitState.IDLE:
			velocity = Vector3.ZERO
			_find_target()
			if target:
				state = UnitState.MOVING
			elif team == 1:
				state = UnitState.RALLYING
			else:
				state = UnitState.MARCHING
		UnitState.MOVING:
			_move_towards_target(delta)
		UnitState.ATTACKING:
			_attack_target()
		UnitState.MARCHING:
			_march_forward(delta)
		UnitState.RALLYING:
			_rally_to_base(delta)

	_clamp_to_battlefield()

func _march_forward(delta: float) -> void:
	# Enemy units march left toward the player base
	_find_target()
	if target:
		state = UnitState.MOVING
		return

	# Check if enemy reached the base
	if global_position.x <= GameConfig.base_zone_right:
		GameManager.damage_base(damage)
		die(-1)
		return

	var march_dir = Vector3(-1, 0, 0)
	var avoidance = _get_friendly_avoidance()
	var direction = (march_dir + avoidance * 0.5).normalized()

	velocity = direction * speed
	move_and_slide()

	if direction.length() > 0.01:
		look_at(global_position + direction, Vector3.UP)

func _rally_to_base(_delta: float) -> void:
	# Player units hold position near the base zone boundary when no enemies
	_find_target()
	if target:
		state = UnitState.MOVING
		return

	var rally_x = GameConfig.get_player_spawn_x()
	var diff_x = rally_x - global_position.x

	if absf(diff_x) < 3.0:
		# Close enough to rally point — hold position
		velocity = Vector3.ZERO
		return

	# Move toward rally point
	var direction = Vector3(sign(diff_x), 0, 0)
	var avoidance = _get_friendly_avoidance()
	var combined = direction + avoidance * 0.3
	if combined.length_squared() > 0.001:
		combined = combined.normalized()
	else:
		combined = direction

	velocity = combined * speed
	move_and_slide()

func _clamp_to_battlefield() -> void:
	var half_depth = GameConfig.battlefield_depth / 2.0 - 0.5
	var half_width = GameConfig.battlefield_width / 2.0 - 0.5
	global_position.x = clampf(global_position.x, -half_width, half_width)
	global_position.z = clampf(global_position.z, -half_depth, half_depth)
	# Keep ground units on the ground
	if unit_type != "flyer":
		global_position.y = 0.0

func apply_hit_stagger() -> void:
	var duration = GameConfig.hit_stagger_duration * (1.0 - stagger_resistance)
	if duration > 0.0:
		stagger_timer = duration

func _check_collision_engagement() -> void:
	if unit_type == "archer":
		return

	if is_instance_valid(target) and global_position.distance_to(target.global_position) <= attack_range:
		return

	var enemy_group = "team_2" if team == 1 else "team_1"
	var enemies = get_tree().get_nodes_in_group(enemy_group)

	for enemy in enemies:
		if not is_instance_valid(enemy):
			continue
		if unit_type in ["footman", "cavalry", "brute", "boss"] and enemy.unit_type == "flyer":
			if enemy.is_flying():
				continue
		var dist = global_position.distance_to(enemy.global_position)
		if dist <= attack_range * 1.5:
			target = enemy
			state = UnitState.ATTACKING
			return

func _find_target() -> void:
	var enemy_group = "team_2" if team == 1 else "team_1"
	var enemies = get_tree().get_nodes_in_group(enemy_group)

	if enemies.is_empty():
		target = null
		return

	var targetable_enemies: Array = []
	for enemy in enemies:
		if not is_instance_valid(enemy):
			continue
		if unit_type in ["footman", "cavalry", "brute", "boss"] and enemy.unit_type == "flyer":
			if enemy.is_flying():
				continue
		targetable_enemies.append(enemy)

	if targetable_enemies.is_empty():
		target = null
		return

	match targeting_mode:
		TargetingMode.CLOSEST:
			target = _get_closest_enemy(targetable_enemies)
		TargetingMode.FARTHEST:
			target = _get_farthest_enemy(targetable_enemies)

func _get_closest_enemy(enemies: Array) -> BaseUnit:
	var closest: BaseUnit = null
	var closest_dist: float = INF

	for enemy in enemies:
		if not is_instance_valid(enemy):
			continue
		var dist = global_position.distance_to(enemy.global_position)
		if dist < closest_dist:
			closest_dist = dist
			closest = enemy

	return closest

func _get_farthest_enemy(enemies: Array) -> BaseUnit:
	var rearmost: BaseUnit = null
	var rearmost_score: float = -INF

	for enemy in enemies:
		if not is_instance_valid(enemy):
			continue

		var rear_score: float
		if enemy.team == 1:
			rear_score = -enemy.global_position.x
		else:
			rear_score = enemy.global_position.x

		if rear_score > rearmost_score + 1.0:
			rearmost_score = rear_score
			rearmost = enemy
		elif rear_score > rearmost_score - 1.0:
			if rearmost == null or global_position.distance_to(enemy.global_position) < global_position.distance_to(rearmost.global_position):
				rearmost_score = rear_score
				rearmost = enemy

	return rearmost

func _move_towards_target(delta: float) -> void:
	if not is_instance_valid(target):
		state = UnitState.IDLE
		target = null
		return

	var dist = global_position.distance_to(target.global_position)

	if dist <= attack_range:
		state = UnitState.ATTACKING
		return

	var direction = (target.global_position - global_position).normalized()
	direction.y = 0

	var avoidance = _get_friendly_avoidance()
	direction = (direction + avoidance).normalized()

	velocity = direction * speed
	move_and_slide()

	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		if collider is BaseUnit and collider.team != team:
			target = collider
			state = UnitState.ATTACKING
			return

	if direction.length() > 0.01:
		look_at(global_position + direction, Vector3.UP)

func _get_friendly_avoidance() -> Vector3:
	var avoidance := Vector3.ZERO
	var avoidance_radius: float = 2.0
	var avoidance_strength: float = 1.5

	var friendly_group = "team_%d" % team
	var friendlies = get_tree().get_nodes_in_group(friendly_group)

	for friendly in friendlies:
		if friendly == self or not is_instance_valid(friendly):
			continue

		var to_friendly = friendly.global_position - global_position
		to_friendly.y = 0
		var dist = to_friendly.length()

		if dist < avoidance_radius and dist > 0.01:
			var push_strength = (avoidance_radius - dist) / avoidance_radius
			avoidance -= to_friendly.normalized() * push_strength * avoidance_strength

	return avoidance

func _attack_target() -> void:
	velocity = Vector3.ZERO

	if not is_instance_valid(target):
		target = null
		_find_target()
		if target:
			state = UnitState.MOVING
		else:
			state = UnitState.IDLE
		return

	var dist = global_position.distance_to(target.global_position)
	var effective_range = attack_range * 1.5 if unit_type != "archer" else attack_range * 1.2

	if dist > effective_range:
		state = UnitState.MOVING
		return

	var direction = (target.global_position - global_position).normalized()
	direction.y = 0
	if direction.length() > 0.01:
		look_at(global_position + direction, Vector3.UP)

	if attack_timer <= 0:
		_perform_attack()
		attack_timer = attack_delay

func _perform_attack() -> void:
	if is_instance_valid(target):
		target.take_damage(damage, self)

func take_damage(amount: float, attacker: BaseUnit) -> void:
	current_hp -= amount

	var attacker_team: int = attacker.team if is_instance_valid(attacker) else -1

	if mesh_instance and mesh_instance.material_override:
		var original_color = GameConfig.get_unit_color(team, unit_type)
		mesh_instance.material_override.albedo_color = Color.WHITE
		await get_tree().create_timer(0.1).timeout
		if is_instance_valid(self) and mesh_instance and mesh_instance.material_override:
			mesh_instance.material_override.albedo_color = original_color

	if current_hp <= 0:
		die(attacker_team)

func die(killer_team: int) -> void:
	unit_died.emit(self)
	if killer_team > 0:
		GameManager.add_kill(killer_team)
	queue_free()
