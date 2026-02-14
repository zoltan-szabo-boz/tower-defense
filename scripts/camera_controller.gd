extends Camera3D

# Movement settings
@export var move_speed: float = 20.0
@export var zoom_speed: float = 5.0
@export var rotation_speed: float = 2.0
@export var vertical_speed: float = 15.0

# Limits
@export var min_height: float = 5.0
@export var max_height: float = 80.0
@export var min_zoom: float = 10.0
@export var max_zoom: float = 100.0
@export var boundary_margin: float = 20.0

# Internal state
var camera_distance: float = 55.0
var camera_angle: float = 0.0
var camera_pitch: float = -60.0
var pivot_point: Vector3 = Vector3.ZERO

func _ready() -> void:
	pivot_point = Vector3(0, 0, 0)
	camera_distance = 55.0
	camera_angle = 0.0
	_update_camera_transform()

func _process(delta: float) -> void:
	var moved = false

	var input_dir = Vector3.ZERO
	if Input.is_action_pressed("ui_up") or Input.is_key_pressed(KEY_W):
		input_dir.z -= 1
	if Input.is_action_pressed("ui_down") or Input.is_key_pressed(KEY_S):
		input_dir.z += 1
	if Input.is_key_pressed(KEY_A):
		input_dir.x -= 1
	if Input.is_key_pressed(KEY_D):
		input_dir.x += 1

	if input_dir.length() > 0:
		input_dir = input_dir.normalized()
		var rotated_dir = Vector3(
			input_dir.x * cos(camera_angle) - input_dir.z * sin(camera_angle),
			0,
			input_dir.x * sin(camera_angle) + input_dir.z * cos(camera_angle)
		)
		pivot_point += rotated_dir * move_speed * delta
		moved = true

	if Input.is_key_pressed(KEY_Q):
		camera_angle += rotation_speed * delta
		moved = true
	if Input.is_key_pressed(KEY_E):
		camera_angle -= rotation_speed * delta
		moved = true

	if Input.is_key_pressed(KEY_Z):
		pivot_point.y -= vertical_speed * delta
		moved = true
	if Input.is_key_pressed(KEY_C):
		pivot_point.y += vertical_speed * delta
		moved = true

	if moved:
		_clamp_position()
		_update_camera_transform()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse_event = event as InputEventMouseButton
		if mouse_event.pressed:
			if mouse_event.button_index == MOUSE_BUTTON_WHEEL_UP:
				camera_distance -= zoom_speed
				camera_distance = clamp(camera_distance, min_zoom, max_zoom)
				_update_camera_transform()
			elif mouse_event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				camera_distance += zoom_speed
				camera_distance = clamp(camera_distance, min_zoom, max_zoom)
				_update_camera_transform()

func _clamp_position() -> void:
	var half_w = GameConfig.battlefield_width / 2.0 + boundary_margin
	var half_d = GameConfig.battlefield_depth / 2.0 + boundary_margin

	pivot_point.x = clamp(pivot_point.x, -half_w, half_w)
	pivot_point.z = clamp(pivot_point.z, -half_d, half_d)
	pivot_point.y = clamp(pivot_point.y, 0, max_height - min_height)

func _update_camera_transform() -> void:
	var pitch_rad = deg_to_rad(camera_pitch)

	var offset = Vector3(
		sin(camera_angle) * cos(pitch_rad) * camera_distance,
		-sin(pitch_rad) * camera_distance,
		cos(camera_angle) * cos(pitch_rad) * camera_distance
	)

	var new_position = pivot_point + offset
	new_position.y = max(new_position.y, min_height)

	global_position = new_position
	look_at(pivot_point, Vector3.UP)
