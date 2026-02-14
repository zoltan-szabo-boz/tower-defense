extends Node

signal building_placed(building_type: String, col: int, row: int)
signal placement_mode_changed(active: bool, building_type: String)

var grid: Array = []  # 2D array: grid[col][row] = building or null
var placement_mode: bool = false
var placement_building_type: String = ""
var preview_mesh: MeshInstance3D = null

func _ready() -> void:
	_init_grid()

func _init_grid() -> void:
	grid.clear()
	for col in range(GameConfig.grid_cols):
		var column: Array = []
		for row in range(GameConfig.grid_rows):
			column.append(null)
		grid.append(column)

func is_cell_free(col: int, row: int) -> bool:
	if not GameConfig.is_valid_grid_pos(col, row):
		return false
	return grid[col][row] == null

func occupy_cell(col: int, row: int, building: Node) -> void:
	if GameConfig.is_valid_grid_pos(col, row):
		grid[col][row] = building

func enter_placement_mode(building_type: String) -> void:
	placement_mode = true
	placement_building_type = building_type
	_create_preview()
	placement_mode_changed.emit(true, building_type)

func exit_placement_mode() -> void:
	placement_mode = false
	placement_building_type = ""
	_destroy_preview()
	placement_mode_changed.emit(false, "")

func _create_preview() -> void:
	_destroy_preview()
	preview_mesh = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = Vector3(GameConfig.grid_cell_size * 0.9, 2.0, GameConfig.grid_cell_size * 0.9)
	preview_mesh.mesh = box

	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0, 1, 0, 0.5)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	preview_mesh.material_override = material

	var main = get_tree().root.get_node_or_null("Main")
	if main:
		main.add_child(preview_mesh)
		preview_mesh.visible = false

func _destroy_preview() -> void:
	if preview_mesh and is_instance_valid(preview_mesh):
		preview_mesh.queue_free()
		preview_mesh = null

func update_preview(world_pos: Vector3) -> void:
	if not placement_mode or not preview_mesh:
		return

	var grid_pos = GameConfig.world_to_grid(world_pos)
	var snapped_pos = GameConfig.grid_to_world(grid_pos.x, grid_pos.y)
	snapped_pos.y = 1.0

	preview_mesh.global_position = snapped_pos
	preview_mesh.visible = true

	var material = preview_mesh.material_override as StandardMaterial3D
	if is_cell_free(grid_pos.x, grid_pos.y):
		material.albedo_color = Color(0, 1, 0, 0.5)
	else:
		material.albedo_color = Color(1, 0, 0, 0.5)

func try_place_building(world_pos: Vector3) -> bool:
	if not placement_mode:
		return false

	var grid_pos = GameConfig.world_to_grid(world_pos)
	if not is_cell_free(grid_pos.x, grid_pos.y):
		return false

	var cost = get_building_cost(placement_building_type)
	if not GameManager.can_afford(cost):
		return false

	GameManager.spend_gold(cost)

	var building = _create_building(placement_building_type, grid_pos.x, grid_pos.y)
	if building:
		occupy_cell(grid_pos.x, grid_pos.y, building)
		building_placed.emit(placement_building_type, grid_pos.x, grid_pos.y)

	exit_placement_mode()
	return true

func _create_building(building_type: String, col: int, row: int) -> Node3D:
	var building: Node3D
	var world_pos = GameConfig.grid_to_world(col, row)

	match building_type:
		"barracks":
			building = _create_production_building(building_type, "footman", GameConfig.barracks_interval, GameConfig.barracks_color)
		"archery_range":
			building = _create_production_building(building_type, "archer", GameConfig.archery_range_interval, GameConfig.archery_range_color)
		"stable":
			building = _create_production_building(building_type, "cavalry", GameConfig.stable_interval, GameConfig.stable_color)
		"aviary":
			building = _create_production_building(building_type, "flyer", GameConfig.aviary_interval, GameConfig.aviary_color)
		"armory":
			building = _create_upgrade_building(building_type, GameConfig.armory_color)
			GameConfig.armory_count += 1
			GameConfig.recalculate_upgrades()
		"fortification":
			building = _create_upgrade_building(building_type, GameConfig.fortification_color)
			GameConfig.fortification_count += 1
			GameConfig.recalculate_upgrades()
		"training_ground":
			building = _create_upgrade_building(building_type, GameConfig.training_ground_color)
			GameConfig.training_ground_count += 1
			GameConfig.recalculate_upgrades()
		"war_college":
			building = _create_upgrade_building(building_type, GameConfig.war_college_color)
			GameConfig.war_college_count += 1
			GameConfig.recalculate_upgrades()
		"gold_mine":
			building = _create_resource_building(building_type, GameConfig.gold_mine_color)
		"house":
			building = _create_population_building(building_type, GameConfig.house_color)
			GameManager.increase_pop_cap(GameConfig.pop_per_house)

	if building:
		building.position = world_pos
		building.position.y = 0
		var buildings_container = get_tree().root.get_node_or_null("Main/Buildings")
		if buildings_container:
			buildings_container.add_child(building)

	return building

func _create_building_base(building_type: String, color: Color) -> StaticBody3D:
	var building = StaticBody3D.new()
	building.set_meta("building_type", building_type)

	# Collision - don't collide with anything meaningful
	building.collision_layer = 0
	building.collision_mask = 0

	var mesh = MeshInstance3D.new()
	var box = BoxMesh.new()
	var size = Vector3(GameConfig.grid_cell_size * 0.8, 2.0, GameConfig.grid_cell_size * 0.8)
	box.size = size
	mesh.mesh = box
	mesh.position.y = size.y / 2.0

	var material = StandardMaterial3D.new()
	material.albedo_color = color
	mesh.material_override = material

	building.add_child(mesh)

	var collision = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = size
	collision.shape = shape
	collision.position.y = size.y / 2.0
	building.add_child(collision)

	return building

func _create_production_building(building_type: String, unit_type: String, interval: float, color: Color) -> StaticBody3D:
	var building = _create_building_base(building_type, color)
	building.set_meta("unit_type", unit_type)
	building.set_meta("spawn_interval", interval)

	var timer = Timer.new()
	timer.wait_time = interval
	timer.autostart = true
	timer.name = "SpawnTimer"
	timer.timeout.connect(_on_production_timer.bind(unit_type))
	building.add_child(timer)

	return building

func _create_upgrade_building(building_type: String, color: Color) -> StaticBody3D:
	return _create_building_base(building_type, color)

func _create_resource_building(building_type: String, color: Color) -> StaticBody3D:
	var building = _create_building_base(building_type, color)

	var timer = Timer.new()
	timer.wait_time = 1.0
	timer.autostart = true
	timer.name = "GoldTimer"
	timer.timeout.connect(_on_gold_mine_tick)
	building.add_child(timer)

	return building

func _create_population_building(building_type: String, color: Color) -> StaticBody3D:
	return _create_building_base(building_type, color)

func _on_production_timer(unit_type: String) -> void:
	if GameManager.is_game_over:
		return
	if GameManager.can_spawn_unit():
		GameManager.spawn_player_unit(unit_type)

func _on_gold_mine_tick() -> void:
	if GameManager.is_game_over:
		return
	GameManager.add_gold(int(GameConfig.gold_mine_rate))

func get_building_cost(building_type: String) -> int:
	match building_type:
		"barracks": return GameConfig.barracks_cost
		"archery_range": return GameConfig.archery_range_cost
		"stable": return GameConfig.stable_cost
		"aviary": return GameConfig.aviary_cost
		"armory": return GameConfig.armory_cost
		"fortification": return GameConfig.fortification_cost
		"training_ground": return GameConfig.training_ground_cost
		"war_college": return GameConfig.war_college_cost
		"gold_mine": return GameConfig.gold_mine_cost
		"house": return GameConfig.house_cost
	return 999

func get_building_display_name(building_type: String) -> String:
	match building_type:
		"barracks": return "Barracks"
		"archery_range": return "Archery Range"
		"stable": return "Stable"
		"aviary": return "Aviary"
		"armory": return "Armory"
		"fortification": return "Fortification"
		"training_ground": return "Training Ground"
		"war_college": return "War College"
		"gold_mine": return "Gold Mine"
		"house": return "House"
	return building_type
