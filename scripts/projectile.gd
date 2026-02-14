extends RigidBody3D
class_name Projectile

var team: int = 1
var damage: float = 20.0
var shooter: BaseUnit = null
var has_hit: bool = false
var launched: bool = false
var launch_velocity: Vector3 = Vector3.ZERO
var grace_timer: float = 0.0  # No friendly collision during grace period
var flight_distance: float = 0.0  # Horizontal distance to target (for grace calculation)

var mesh_instance: MeshInstance3D

func _ready() -> void:
	freeze = true

	_setup_visuals()
	_setup_collision()

	body_entered.connect(_on_body_entered)

	contact_monitor = true
	max_contacts_reported = 4

func _setup_visuals() -> void:
	mesh_instance = MeshInstance3D.new()
	var box_mesh = BoxMesh.new()
	box_mesh.size = GameConfig.projectile_size
	mesh_instance.mesh = box_mesh

	var material = StandardMaterial3D.new()
	material.albedo_color = GameConfig.get_unit_color(team, "projectile")
	mesh_instance.material_override = material

	add_child(mesh_instance)

func _setup_collision() -> void:
	var collision_shape = CollisionShape3D.new()
	var box_shape = BoxShape3D.new()
	box_shape.size = GameConfig.projectile_size
	collision_shape.shape = box_shape
	add_child(collision_shape)

	collision_layer = 8
	# During grace period, only collide with enemies (not friendlies)
	# Team 1 projectile hits team 2 (layer 4) + ground (layer 1)
	# Team 2 projectile hits team 1 (layer 2) + ground (layer 1)
	if team == 1:
		collision_mask = 4 | 1  # Enemy team + ground
	else:
		collision_mask = 2 | 1  # Enemy team + ground

func launch_at_target(from: Vector3, to: Vector3) -> void:
	var gravity = GameConfig.projectile_gravity
	var spd = GameConfig.projectile_speed

	var displacement = to - from
	var horizontal_dist = Vector2(displacement.x, displacement.z).length()
	var vertical_dist = displacement.y

	if horizontal_dist < 0.1:
		horizontal_dist = 0.1

	var horizontal_dir = Vector2(displacement.x, displacement.z).normalized()

	var speed_sq = spd * spd
	var g = gravity
	var x = horizontal_dist
	var y = vertical_dist

	var discriminant = speed_sq * speed_sq - g * (g * x * x + 2.0 * y * speed_sq)

	var angle: float
	if discriminant < 0:
		angle = PI / 4.0
	else:
		var sqrt_disc = sqrt(discriminant)
		angle = atan((speed_sq - sqrt_disc) / (g * x))

	var v_horizontal = spd * cos(angle)
	var v_vertical = spd * sin(angle)

	launch_velocity = Vector3(
		horizontal_dir.x * v_horizontal,
		v_vertical,
		horizontal_dir.y * v_horizontal
	)

	gravity_scale = gravity / 9.8

	# Calculate flight time and set grace period as a fraction of it
	flight_distance = horizontal_dist
	var estimated_flight_time = horizontal_dist / maxf(v_horizontal, 0.1)
	var grace_fraction = GameConfig.projectile_grace_fraction

	await get_tree().create_timer(0.05).timeout
	if is_instance_valid(self) and not has_hit:
		freeze = false
		linear_velocity = launch_velocity
		launched = true
		grace_timer = estimated_flight_time * grace_fraction

func _physics_process(delta: float) -> void:
	if not launched or has_hit:
		return

	# Grace period: only friendlies are ignored, enemies can be hit immediately
	if grace_timer > 0:
		grace_timer -= delta
		if grace_timer <= 0:
			collision_mask = 2 | 4 | 1  # Enable collision with all teams + ground

	if linear_velocity.length() > 0.1:
		look_at(global_position + linear_velocity.normalized(), Vector3.UP)

	if global_position.y < -5:
		queue_free()

func _on_body_entered(body: Node) -> void:
	if has_hit or not launched:
		return

	if body == shooter:
		return

	# During grace period, ignore friendly units entirely
	if body is BaseUnit:
		var unit = body as BaseUnit
		if unit.team == team and grace_timer > 0:
			return

	has_hit = true

	if body is BaseUnit:
		var unit = body as BaseUnit
		var valid_shooter = shooter if is_instance_valid(shooter) else null
		unit.take_damage(damage, valid_shooter)
		unit.apply_hit_stagger()
		_attach_to_unit(unit)
	else:
		_start_ground_despawn()

func _attach_to_unit(unit: BaseUnit) -> void:
	freeze = true
	collision_layer = 0
	collision_mask = 0

	var offset = global_position - unit.global_position
	var unit_rotation = unit.global_transform.basis

	var local_offset = unit_rotation.inverse() * offset
	var local_rotation = global_transform.basis

	call_deferred("_deferred_reparent", unit, local_offset, unit_rotation.inverse() * local_rotation)

func _deferred_reparent(unit: BaseUnit, local_offset: Vector3, local_basis: Basis) -> void:
	if not is_instance_valid(unit):
		queue_free()
		return

	get_parent().remove_child(self)
	unit.add_child(self)

	transform.origin = local_offset
	transform.basis = local_basis

	unit.unit_died.connect(_on_attached_unit_died)

func _on_attached_unit_died(_unit: BaseUnit) -> void:
	queue_free()

func _start_ground_despawn() -> void:
	freeze = true
	collision_layer = 0
	collision_mask = 0

	if mesh_instance and mesh_instance.material_override:
		var material = mesh_instance.material_override as StandardMaterial3D
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA

		var tween = create_tween()
		tween.tween_property(material, "albedo_color:a", 0.0, GameConfig.projectile_despawn_delay)
		tween.tween_callback(queue_free)
