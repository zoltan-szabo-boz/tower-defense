extends CanvasLayer

var buttons: Dictionary = {}

const BUILDING_TYPES = [
	# Production buildings
	{"type": "barracks", "label": "Barracks", "desc": "Spawns Footmen"},
	{"type": "archery_range", "label": "Archery Range", "desc": "Spawns Archers"},
	{"type": "stable", "label": "Stable", "desc": "Spawns Cavalry"},
	{"type": "aviary", "label": "Aviary", "desc": "Spawns Flyers"},
	# Upgrade buildings
	{"type": "armory", "label": "Armory", "desc": "+20% damage"},
	{"type": "fortification", "label": "Fort", "desc": "+20% HP"},
	{"type": "training_ground", "label": "Training", "desc": "+15% accuracy"},
	{"type": "war_college", "label": "College", "desc": "+10% atk speed"},
	# Economy
	{"type": "gold_mine", "label": "Gold Mine", "desc": "+5g/s"},
	{"type": "house", "label": "House", "desc": "+5 pop cap"},
]

func _ready() -> void:
	_create_panel()
	GameManager.gold_changed.connect(_update_button_states)

func _create_panel() -> void:
	var bottom_panel = PanelContainer.new()
	bottom_panel.name = "BottomPanel"
	bottom_panel.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	bottom_panel.offset_top = -90

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_top", 5)
	margin.add_theme_constant_override("margin_bottom", 5)
	bottom_panel.add_child(margin)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	margin.add_child(vbox)

	# Row 1: Production buildings
	var row1 = HBoxContainer.new()
	row1.alignment = BoxContainer.ALIGNMENT_CENTER
	row1.add_theme_constant_override("separation", 8)
	vbox.add_child(row1)

	# Row 2: Upgrade + economy buildings
	var row2 = HBoxContainer.new()
	row2.alignment = BoxContainer.ALIGNMENT_CENTER
	row2.add_theme_constant_override("separation", 8)
	vbox.add_child(row2)

	for i in range(BUILDING_TYPES.size()):
		var info = BUILDING_TYPES[i]
		var cost = BuildingSystem.get_building_cost(info.type)

		var btn = Button.new()
		btn.custom_minimum_size = Vector2(120, 35)
		btn.text = "%s %dg" % [info.label, cost]
		btn.tooltip_text = info.desc
		btn.pressed.connect(_on_building_button_pressed.bind(info.type))
		buttons[info.type] = btn

		if i < 4:
			row1.add_child(btn)
		else:
			row2.add_child(btn)

	add_child(bottom_panel)

func _on_building_button_pressed(building_type: String) -> void:
	if BuildingSystem.placement_mode:
		if BuildingSystem.placement_building_type == building_type:
			BuildingSystem.exit_placement_mode()
			return
		BuildingSystem.exit_placement_mode()

	var cost = BuildingSystem.get_building_cost(building_type)
	if GameManager.can_afford(cost):
		BuildingSystem.enter_placement_mode(building_type)

func _update_button_states(_gold: int) -> void:
	for building_type in buttons:
		var btn = buttons[building_type] as Button
		var cost = BuildingSystem.get_building_cost(building_type)
		btn.disabled = not GameManager.can_afford(cost)
