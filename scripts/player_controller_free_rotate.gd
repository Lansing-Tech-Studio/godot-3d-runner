extends CharacterBody3D

@export var walk_speed := 8.0
@export var reverse_speed := 4.5
@export var sprint_max_speed := 256.0
@export var speed_change_rate := 10.0
@export var reverse_deceleration_rate := 60.0
@export var turn_speed := 2.5
@export var gravity_scale := 1.0
@export var mouse_sensitivity := 0.15
@export var min_pitch_degrees := -40.0
@export var max_pitch_degrees := 65.0

var _forward_speed := 0.0
var _gravity := 9.8
var _camera_yaw := 0.0
var _camera_pitch := -12.0
var _hint_label: Label

func _ready() -> void:
	_gravity = float(ProjectSettings.get_setting("physics/3d/default_gravity", 9.8))
	_ensure_collision_shape()
	_ensure_visual()
	_ensure_camera_rig()
	_ensure_hint_overlay()
	_input_capture(true)

func _exit_tree() -> void:
	if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_input_capture(false)
		return

	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_input_capture(true)
		return

	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		_camera_yaw -= event.relative.x * mouse_sensitivity
		_camera_pitch = clamp(_camera_pitch - event.relative.y * mouse_sensitivity, min_pitch_degrees, max_pitch_degrees)

func _physics_process(delta: float) -> void:
	var turn_input := Input.get_action_strength("turn_left") - Input.get_action_strength("turn_right")
	rotate_y(turn_input * turn_speed * delta)

	var forward_input := Input.get_action_strength("move_forward")
	var backward_input := Input.get_action_strength("move_backward")
	var target_speed := 0.0
	if forward_input > 0.0:
		target_speed = walk_speed * forward_input
		if Input.is_action_pressed("sprint"):
			target_speed = sprint_max_speed * forward_input
	elif backward_input > 0.0:
		target_speed = -reverse_speed * backward_input

	var change_rate := speed_change_rate
	if (_forward_speed > 0.0 and target_speed < 0.0) or (_forward_speed < 0.0 and target_speed > 0.0):
		change_rate = reverse_deceleration_rate

	_forward_speed = move_toward(_forward_speed, target_speed, change_rate * delta)

	var forward := -global_transform.basis.z
	forward.y = 0.0
	forward = forward.normalized()
	velocity.x = forward.x * _forward_speed
	velocity.z = forward.z * _forward_speed

	if not is_on_floor():
		velocity.y -= _gravity * gravity_scale * delta
	else:
		velocity.y = min(velocity.y, 0.0)

	_apply_camera_rotation()
	move_and_slide()

func _input_capture(captured: bool) -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if captured else Input.MOUSE_MODE_VISIBLE
	_update_hint_text()

func _ensure_collision_shape() -> void:
	if has_node("CollisionShape3D"):
		return

	var collision := CollisionShape3D.new()
	collision.name = "CollisionShape3D"
	collision.position = Vector3(0.0, 1.0, 0.0)

	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.45
	capsule.height = 1.2
	collision.shape = capsule

	add_child(collision)

func _ensure_visual() -> void:
	if has_node("Visual"):
		return

	var visual := MeshInstance3D.new()
	visual.name = "Visual"
	visual.position = Vector3(0.0, 1.0, 0.0)

	var mesh := CapsuleMesh.new()
	mesh.radius = 0.45
	mesh.height = 1.2
	visual.mesh = mesh

	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.92, 0.95, 0.98, 1.0)
	material.roughness = 0.85
	visual.material_override = material

	add_child(visual)

func _ensure_camera_rig() -> void:
	var rig: Node3D
	if has_node("CameraRig"):
		rig = get_node("CameraRig") as Node3D
	else:
		rig = Node3D.new()
		rig.name = "CameraRig"
		rig.position = Vector3(0.0, 1.6, 0.0)
		add_child(rig)

	var yaw_node: Node3D
	if rig.has_node("Yaw"):
		yaw_node = rig.get_node("Yaw") as Node3D
	else:
		yaw_node = Node3D.new()
		yaw_node.name = "Yaw"
		rig.add_child(yaw_node)

	var pitch_node: Node3D
	if yaw_node.has_node("Pitch"):
		pitch_node = yaw_node.get_node("Pitch") as Node3D
	else:
		pitch_node = Node3D.new()
		pitch_node.name = "Pitch"
		yaw_node.add_child(pitch_node)

	if not pitch_node.has_node("Camera3D"):
		var camera := Camera3D.new()
		camera.name = "Camera3D"
		camera.position = Vector3(0.0, 2.2, 6.0)
		camera.current = true
		camera.fov = 75.0
		pitch_node.add_child(camera)

func _apply_camera_rotation() -> void:
	var yaw_node := get_node_or_null("CameraRig/Yaw") as Node3D
	var pitch_node := get_node_or_null("CameraRig/Yaw/Pitch") as Node3D
	if yaw_node == null or pitch_node == null:
		return

	yaw_node.rotation_degrees.y = _camera_yaw
	pitch_node.rotation_degrees.x = _camera_pitch

func _ensure_hint_overlay() -> void:
	var hud := get_node_or_null("HUD") as CanvasLayer
	if hud == null:
		hud = CanvasLayer.new()
		hud.name = "HUD"
		add_child(hud)

	var label := hud.get_node_or_null("HintLabel") as Label
	if label == null:
		label = Label.new()
		label.name = "HintLabel"
		label.position = Vector2(16.0, 12.0)
		label.add_theme_color_override("font_color", Color(0.92, 0.94, 0.98, 1.0))
		label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.65))
		label.add_theme_constant_override("shadow_offset_x", 1)
		label.add_theme_constant_override("shadow_offset_y", 1)
		label.position.y = 52.0
		hud.add_child(label)

	_hint_label = label
	_update_hint_text()

func _update_hint_text() -> void:
	if _hint_label == null:
		return

	if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		_hint_label.text = "Free Rotate: Mouse look active | Esc release mouse | M menu"
	else:
		_hint_label.text = "Free Rotate: Left click capture mouse | M menu"
