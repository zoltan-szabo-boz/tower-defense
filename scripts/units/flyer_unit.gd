extends BaseUnit
class_name FlyerUnit

var altitude: float = 4.0
var is_landed: bool = false
const LANDING_HEIGHT: float = 0.5
const ALTITUDE_LERP_SPEED: float = 8.0

func _ready() -> void:
	unit_type = "flyer"
	targeting_mode = TargetingMode.CLOSEST
	super._ready()

	var stats = GameConfig.get_unit_stats(unit_type)
	altitude = stats.altitude

	add_to_group("flyers")
	add_to_group("team_%d_flyers" % team)

	global_position.y = altitude

func _physics_process(delta: float) -> void:
	super._physics_process(delta)

	var target_y: float
	if is_landed:
		target_y = LANDING_HEIGHT
	else:
		target_y = altitude

	global_position.y = lerpf(global_position.y, target_y, ALTITUDE_LERP_SPEED * delta)

func is_flying() -> bool:
	return global_position.y > 1.5

func _find_target() -> void:
	var enemy_group = "team_2" if team == 1 else "team_1"
	var enemies = get_tree().get_nodes_in_group(enemy_group)

	if enemies.is_empty():
		target = null
		return

	var enemy_flyers: Array[BaseUnit] = []
	var enemy_archers: Array[BaseUnit] = []
	var other_enemies: Array[BaseUnit] = []

	for enemy in enemies:
		if not is_instance_valid(enemy):
			continue
		if enemy.unit_type == "flyer":
			enemy_flyers.append(enemy)
		elif enemy.unit_type == "archer":
			enemy_archers.append(enemy)
		else:
			other_enemies.append(enemy)

	if not enemy_flyers.is_empty():
		target = _get_closest_enemy(enemy_flyers)
		return

	if not enemy_archers.is_empty():
		target = _get_closest_enemy(enemy_archers)
		return

	if not other_enemies.is_empty():
		target = _get_closest_enemy(other_enemies)
		return

	target = null

func _move_towards_target(delta: float) -> void:
	if not is_instance_valid(target):
		state = UnitState.IDLE
		target = null
		return

	is_landed = false

	var target_pos = target.global_position
	var horizontal_dist = Vector2(global_position.x - target_pos.x, global_position.z - target_pos.z).length()

	if horizontal_dist <= attack_range:
		state = UnitState.ATTACKING
		return

	var direction = Vector3(target_pos.x - global_position.x, 0, target_pos.z - global_position.z).normalized()

	var avoidance = _get_friendly_avoidance_3d()
	direction = (direction + avoidance).normalized()

	velocity = direction * speed
	move_and_slide()

	if direction.length() > 0.01:
		look_at(global_position + direction, Vector3.UP)

func _get_friendly_avoidance_3d() -> Vector3:
	var avoidance := Vector3.ZERO
	var avoidance_radius: float = 2.5
	var avoidance_strength: float = 1.5

	var friendly_flyers_group = "team_%d_flyers" % team
	var friendly_flyers = get_tree().get_nodes_in_group(friendly_flyers_group)

	for friendly in friendly_flyers:
		if friendly == self or not is_instance_valid(friendly):
			continue

		var to_friendly = friendly.global_position - global_position
		var dist = to_friendly.length()

		if dist < avoidance_radius and dist > 0.01:
			var push_strength = (avoidance_radius - dist) / avoidance_radius
			avoidance -= to_friendly.normalized() * push_strength * avoidance_strength

	return avoidance

func _attack_target() -> void:
	velocity = Vector3.ZERO

	if not is_instance_valid(target):
		target = null
		is_landed = false
		_find_target()
		if target:
			state = UnitState.MOVING
		else:
			state = UnitState.IDLE
		return

	is_landed = target.unit_type != "flyer"

	var target_pos = target.global_position
	var horizontal_dist = Vector2(global_position.x - target_pos.x, global_position.z - target_pos.z).length()

	if horizontal_dist > attack_range * 1.5:
		state = UnitState.MOVING
		return

	var direction = Vector3(target_pos.x - global_position.x, 0, target_pos.z - global_position.z)
	if direction.length() > 0.01:
		look_at(global_position + direction, Vector3.UP)

	if attack_timer <= 0:
		_perform_attack()
		attack_timer = attack_delay

func _check_collision_engagement() -> void:
	pass

func _march_forward(delta: float) -> void:
	# Enemy flyers march toward player base
	is_landed = false
	_find_target()
	if target:
		state = UnitState.MOVING
		return

	if global_position.x <= GameConfig.base_zone_right:
		GameManager.damage_base(damage)
		die(-1)
		return

	var march_dir = Vector3(-1, 0, 0)
	var avoidance = _get_friendly_avoidance_3d()
	var direction = (march_dir + avoidance * 0.5).normalized()

	velocity = direction * speed
	move_and_slide()

	if direction.length() > 0.01:
		look_at(global_position + direction, Vector3.UP)

func _rally_to_base(_delta: float) -> void:
	# Player flyers hold position near base
	is_landed = false
	_find_target()
	if target:
		state = UnitState.MOVING
		return

	var rally_x = GameConfig.get_player_spawn_x()
	var diff_x = rally_x - global_position.x

	if absf(diff_x) < 3.0:
		velocity = Vector3.ZERO
		return

	var direction = Vector3(sign(diff_x), 0, 0)
	var avoidance = _get_friendly_avoidance_3d()
	var combined = direction + avoidance * 0.3
	if combined.length_squared() > 0.001:
		combined = combined.normalized()
	else:
		combined = direction

	velocity = combined * speed
	move_and_slide()
