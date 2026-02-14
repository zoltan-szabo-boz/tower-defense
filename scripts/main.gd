extends Node3D

var camera: Camera3D
var base_structure: Node3D
var base_mesh: MeshInstance3D
var grid_lines: Node3D

func _ready() -> void:
	_setup_battlefield()
	_setup_grid_visuals()
	_setup_base_structure()
	_setup_spawn_markers()

	GameManager.start_game()
	WaveManager.start_waves()

	GameManager.base_hp_changed.connect(_on_base_hp_changed)

func _setup_battlefield() -> void:
	var ground = $Battlefield/Ground as StaticBody3D
	var mesh = ground.get_node("MeshInstance3D") as MeshInstance3D
	var collision = ground.get_node("CollisionShape3D") as CollisionShape3D

	# Resize ground to match battlefield config
	var box_mesh = mesh.mesh as BoxMesh
	box_mesh.size = Vector3(GameConfig.battlefield_width, 0.2, GameConfig.battlefield_depth)

	var box_shape = collision.shape as BoxShape3D
	box_shape.size = Vector3(GameConfig.battlefield_width, 0.2, GameConfig.battlefield_depth)

	# Add base zone visual tint (slightly different color for base zone)
	var base_zone_ground = StaticBody3D.new()
	base_zone_ground.collision_layer = 0
	base_zone_ground.collision_mask = 0

	var base_mesh_inst = MeshInstance3D.new()
	var base_box = BoxMesh.new()
	var base_width = GameConfig.battlefield_width * GameConfig.base_zone_ratio
	base_box.size = Vector3(base_width, 0.21, GameConfig.battlefield_depth)
	base_mesh_inst.mesh = base_box

	var base_mat = StandardMaterial3D.new()
	base_mat.albedo_color = Color(0.25, 0.35, 0.25, 1)
	base_mesh_inst.material_override = base_mat

	base_zone_ground.add_child(base_mesh_inst)
	base_zone_ground.position = Vector3(
		GameConfig.base_zone_left + base_width / 2.0,
		0.005,
		0
	)
	$Battlefield.add_child(base_zone_ground)

func _setup_grid_visuals() -> void:
	grid_lines = Node3D.new()
	grid_lines.name = "GridLines"
	$Battlefield.add_child(grid_lines)

	var grid_mat = StandardMaterial3D.new()
	grid_mat.albedo_color = Color(0.6, 0.6, 0.6, 0.4)
	grid_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA

	# Draw grid lines
	var cell = GameConfig.grid_cell_size
	var origin = GameConfig.grid_origin

	# Vertical lines (along X)
	for col in range(GameConfig.grid_cols + 1):
		var x = origin.x + col * cell
		var z_start = origin.z
		var z_end = origin.z + GameConfig.grid_rows * cell
		_draw_line(Vector3(x, 0.15, z_start), Vector3(x, 0.15, z_end), grid_mat)

	# Horizontal lines (along Z)
	for row in range(GameConfig.grid_rows + 1):
		var z = origin.z + row * cell
		var x_start = origin.x
		var x_end = origin.x + GameConfig.grid_cols * cell
		_draw_line(Vector3(x_start, 0.15, z), Vector3(x_end, 0.15, z), grid_mat)

func _draw_line(from: Vector3, to: Vector3, material: StandardMaterial3D) -> void:
	var mesh_inst = MeshInstance3D.new()
	var im = ImmediateMesh.new()

	im.surface_begin(Mesh.PRIMITIVE_LINES)
	im.surface_add_vertex(from)
	im.surface_add_vertex(to)
	im.surface_end()

	mesh_inst.mesh = im
	mesh_inst.material_override = material
	grid_lines.add_child(mesh_inst)

func _setup_base_structure() -> void:
	base_structure = Node3D.new()
	base_structure.name = "BaseStructure"

	var mesh = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = Vector3(3.0, 4.0, 8.0)
	mesh.mesh = box
	mesh.position.y = 2.0

	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.2, 0.5, 0.8)
	mesh.material_override = mat
	base_mesh = mesh

	base_structure.add_child(mesh)
	base_structure.position = Vector3(GameConfig.base_structure_x, 0, 0)

	# Add collision for base (layer 1 = ground)
	var body = StaticBody3D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	var coll = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = Vector3(3.0, 4.0, 8.0)
	coll.shape = shape
	coll.position.y = 2.0
	body.add_child(coll)
	base_structure.add_child(body)

	add_child(base_structure)

func _setup_spawn_markers() -> void:
	# Visual markers at enemy spawn edge
	var marker_mat = StandardMaterial3D.new()
	marker_mat.albedo_color = Color(1.0, 0.3, 0.3, 0.5)
	marker_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA

	for i in range(5):
		var marker = MeshInstance3D.new()
		var box = BoxMesh.new()
		box.size = Vector3(0.5, 3.0, 0.5)
		marker.mesh = box
		marker.material_override = marker_mat
		marker.position = Vector3(
			GameConfig.combat_zone_right - 0.5,
			1.5,
			-GameConfig.battlefield_depth / 2.0 + (i + 1) * GameConfig.battlefield_depth / 6.0
		)
		add_child(marker)

func _on_base_hp_changed(current: float, _max_hp: float) -> void:
	if base_mesh and base_mesh.material_override:
		var mat = base_mesh.material_override as StandardMaterial3D
		var hp_ratio = current / GameConfig.base_max_hp
		mat.albedo_color = Color(
			lerp(0.8, 0.2, hp_ratio),
			lerp(0.1, 0.5, hp_ratio),
			lerp(0.1, 0.8, hp_ratio)
		)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse_event = event as InputEventMouseButton
		if mouse_event.pressed and mouse_event.button_index == MOUSE_BUTTON_LEFT:
			if BuildingSystem.placement_mode:
				var world_pos = _get_mouse_world_position()
				if world_pos != Vector3.INF:
					BuildingSystem.try_place_building(world_pos)
		elif mouse_event.pressed and mouse_event.button_index == MOUSE_BUTTON_RIGHT:
			if BuildingSystem.placement_mode:
				BuildingSystem.exit_placement_mode()

	if event is InputEventMouseMotion and BuildingSystem.placement_mode:
		var world_pos = _get_mouse_world_position()
		if world_pos != Vector3.INF:
			BuildingSystem.update_preview(world_pos)

	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_ESCAPE:
			if BuildingSystem.placement_mode:
				BuildingSystem.exit_placement_mode()

func _get_mouse_world_position() -> Vector3:
	var cam = get_viewport().get_camera_3d()
	if not cam:
		return Vector3.INF

	var mouse_pos = get_viewport().get_mouse_position()
	var from = cam.project_ray_origin(mouse_pos)
	var dir = cam.project_ray_normal(mouse_pos)

	# Intersect with Y=0 plane
	if abs(dir.y) < 0.001:
		return Vector3.INF

	var t = -from.y / dir.y
	if t < 0:
		return Vector3.INF

	return from + dir * t
