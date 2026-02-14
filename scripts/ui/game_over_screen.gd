extends CanvasLayer

var panel: PanelContainer
var stats_label: Label

func _ready() -> void:
	_create_screen()
	visible = false
	GameManager.game_over.connect(_on_game_over)

func _create_screen() -> void:
	# Darken background
	var bg = ColorRect.new()
	bg.color = Color(0, 0, 0, 0.7)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	# Center panel
	panel = PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.offset_left = -200
	panel.offset_right = 200
	panel.offset_top = -150
	panel.offset_bottom = 150
	add_child(panel)

	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 15)
	panel.add_child(vbox)

	var title = Label.new()
	title.text = "GAME OVER"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 32)
	title.add_theme_color_override("font_color", Color(1, 0.3, 0.3))
	title.name = "Title"
	vbox.add_child(title)

	stats_label = Label.new()
	stats_label.name = "Stats"
	stats_label.text = ""
	stats_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stats_label.add_theme_font_size_override("font_size", 18)
	vbox.add_child(stats_label)

	var restart_btn = Button.new()
	restart_btn.text = "Restart"
	restart_btn.custom_minimum_size = Vector2(150, 50)
	restart_btn.pressed.connect(_on_restart)
	vbox.add_child(restart_btn)

func _on_game_over(waves_survived: int, enemies_killed: int, units_produced: int) -> void:
	visible = true
	stats_label.text = "Waves Survived: %d\nEnemies Killed: %d\nUnits Produced: %d" % [
		waves_survived, enemies_killed, units_produced
	]

func _on_restart() -> void:
	visible = false
	get_tree().reload_current_scene()
