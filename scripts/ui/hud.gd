extends CanvasLayer

var wave_label: Label
var timer_label: Label
var gold_label: Label
var pop_label: Label
var base_hp_bar: ProgressBar
var base_hp_label: Label

func _ready() -> void:
	_create_hud()
	_connect_signals()

func _create_hud() -> void:
	# Top bar container
	var top_bar = HBoxContainer.new()
	top_bar.name = "TopBar"
	top_bar.set_anchors_preset(Control.PRESET_TOP_WIDE)
	top_bar.offset_bottom = 40
	top_bar.alignment = BoxContainer.ALIGNMENT_CENTER

	var panel = PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_bar.add_child(panel)

	var hbox = HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_theme_constant_override("separation", 30)
	panel.add_child(hbox)

	# Wave label
	wave_label = Label.new()
	wave_label.text = "Wave: 0"
	wave_label.add_theme_font_size_override("font_size", 18)
	hbox.add_child(wave_label)

	# Timer label
	timer_label = Label.new()
	timer_label.text = "Next Wave: --"
	timer_label.add_theme_font_size_override("font_size", 18)
	hbox.add_child(timer_label)

	# Gold label
	gold_label = Label.new()
	gold_label.text = "Gold: 0"
	gold_label.add_theme_font_size_override("font_size", 18)
	gold_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.0))
	hbox.add_child(gold_label)

	# Population label
	pop_label = Label.new()
	pop_label.text = "Pop: 0/10"
	pop_label.add_theme_font_size_override("font_size", 18)
	hbox.add_child(pop_label)

	add_child(top_bar)

	# Base HP bar (below top bar)
	var hp_container = HBoxContainer.new()
	hp_container.name = "HPContainer"
	hp_container.set_anchors_preset(Control.PRESET_TOP_WIDE)
	hp_container.offset_top = 40
	hp_container.offset_bottom = 65
	hp_container.offset_left = 10
	hp_container.offset_right = -10
	hp_container.alignment = BoxContainer.ALIGNMENT_CENTER
	hp_container.add_theme_constant_override("separation", 10)

	var hp_label_prefix = Label.new()
	hp_label_prefix.text = "Base HP:"
	hp_label_prefix.add_theme_font_size_override("font_size", 14)
	hp_container.add_child(hp_label_prefix)

	base_hp_bar = ProgressBar.new()
	base_hp_bar.custom_minimum_size = Vector2(200, 20)
	base_hp_bar.max_value = 100
	base_hp_bar.value = 100
	base_hp_bar.show_percentage = false
	hp_container.add_child(base_hp_bar)

	base_hp_label = Label.new()
	base_hp_label.text = "100/100"
	base_hp_label.add_theme_font_size_override("font_size", 14)
	hp_container.add_child(base_hp_label)

	add_child(hp_container)

func _connect_signals() -> void:
	GameManager.gold_changed.connect(_on_gold_changed)
	GameManager.population_changed.connect(_on_population_changed)
	GameManager.base_hp_changed.connect(_on_base_hp_changed)
	WaveManager.wave_started.connect(_on_wave_started)
	WaveManager.countdown_updated.connect(_on_countdown_updated)
	WaveManager.wave_completed.connect(_on_wave_completed)

func _on_gold_changed(amount: int) -> void:
	gold_label.text = "Gold: %d" % amount

func _on_population_changed(current: int, cap: int) -> void:
	pop_label.text = "Pop: %d/%d" % [current, cap]

func _on_base_hp_changed(current: float, max_hp: float) -> void:
	base_hp_bar.max_value = max_hp
	base_hp_bar.value = current
	base_hp_label.text = "%d/%d" % [int(current), int(max_hp)]

func _on_wave_started(wave_number: int) -> void:
	wave_label.text = "Wave: %d" % wave_number
	timer_label.text = "IN PROGRESS"

func _on_countdown_updated(seconds: float) -> void:
	if seconds < 0:
		timer_label.text = "BOSS ALIVE"
	elif seconds > 0:
		timer_label.text = "Next Wave: %ds" % int(ceil(seconds))
	else:
		timer_label.text = "Next Wave: NOW"

func _on_wave_completed(wave_number: int, reward: int) -> void:
	timer_label.text = "Wave %d complete! +%dg" % [wave_number, reward]
