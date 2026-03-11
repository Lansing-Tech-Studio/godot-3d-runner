extends CharacterBody3D

@export var walk_speed := 8.0
@export var reverse_speed := 4.5
@export var sprint_max_speed := 256.0
@export var speed_change_rate := 10.0
@export var reverse_deceleration_rate := 60.0
@export var turn_speed := 2.5
@export var gravity_scale := 1.0

var _forward_speed := 0.0
var _gravity := 9.8

func _ready() -> void:
	_gravity = float(ProjectSettings.get_setting("physics/3d/default_gravity", 9.8))
	_ensure_collision_shape()
	_ensure_visual()
	_ensure_camera()

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

	move_and_slide()

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

func _ensure_camera() -> void:
	var pivot: Node3D
	if has_node("CameraPivot"):
		pivot = get_node("CameraPivot") as Node3D
	else:
		pivot = Node3D.new()
		pivot.name = "CameraPivot"
		pivot.position = Vector3(0.0, 1.6, 0.0)
		pivot.rotation_degrees = Vector3(-18.0, 0.0, 0.0)
		add_child(pivot)

	if pivot.has_node("Camera3D"):
		return

	var camera := Camera3D.new()
	camera.name = "Camera3D"
	camera.position = Vector3(0.0, 2.8, 5.4)
	camera.current = true
	camera.fov = 75.0
	pivot.add_child(camera)
