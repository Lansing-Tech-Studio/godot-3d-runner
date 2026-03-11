extends Node3D

const ARENA_HALF_EXTENT := 200.0
const FLOOR_HEIGHT := 1.0
const WALL_HEIGHT := 18.0
const WALL_THICKNESS := 2.0
const STRIPE_SIZE := 16.0
const GRID_LINE_THICKNESS := 0.35
const GRID_SPACING := 10.0
const WALL_COLORS := [
	Color(0.95, 0.18, 0.18, 1.0),
	Color(0.96, 0.48, 0.14, 1.0),
	Color(0.96, 0.84, 0.16, 1.0),
	Color(0.24, 0.78, 0.28, 1.0),
	Color(0.18, 0.56, 0.96, 1.0),
	Color(0.34, 0.32, 0.90, 1.0),
	Color(0.78, 0.22, 0.82, 1.0)
]

func _ready() -> void:
	_ensure_environment()
	_ensure_floor()
	_ensure_floor_markers()
	_ensure_walls()
	_ensure_player_spawn()

func _ensure_environment() -> void:
	if not has_node("Sun"):
		var sun := DirectionalLight3D.new()
		sun.name = "Sun"
		sun.rotation_degrees = Vector3(-48.0, 35.0, 0.0)
		sun.light_energy = 3.0
		sun.shadow_enabled = true
		add_child(sun)

	if not has_node("WorldEnvironment"):
		var world_environment := WorldEnvironment.new()
		world_environment.name = "WorldEnvironment"

		var environment := Environment.new()
		environment.background_mode = Environment.BG_SKY
		environment.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
		environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC

		var sky := Sky.new()
		var sky_material := PhysicalSkyMaterial.new()
		sky_material.rayleigh_coefficient = 1.8
		sky_material.mie_coefficient = 0.01
		sky_material.sun_disk_scale = 1.0
		sky.sky_material = sky_material
		environment.sky = sky

		world_environment.environment = environment
		add_child(world_environment)

func _ensure_floor() -> void:
	if has_node("Floor"):
		return

	var floor := StaticBody3D.new()
	floor.name = "Floor"
	floor.position = Vector3(0.0, -FLOOR_HEIGHT * 0.5, 0.0)
	add_child(floor)

	var collision := CollisionShape3D.new()
	collision.name = "CollisionShape3D"
	var collision_shape := BoxShape3D.new()
	collision_shape.size = Vector3(ARENA_HALF_EXTENT * 2.2, FLOOR_HEIGHT, ARENA_HALF_EXTENT * 2.2)
	collision.shape = collision_shape
	floor.add_child(collision)

	var visual := MeshInstance3D.new()
	visual.name = "Visual"
	var mesh := BoxMesh.new()
	mesh.size = collision_shape.size
	visual.mesh = mesh

	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.18, 0.2, 0.22, 1.0)
	material.roughness = 0.95
	material.metallic = 0.0
	visual.material_override = material
	floor.add_child(visual)

func _ensure_floor_markers() -> void:
	if has_node("FloorMarkers"):
		return

	var markers := Node3D.new()
	markers.name = "FloorMarkers"
	add_child(markers)

	var line_count := int((ARENA_HALF_EXTENT * 2.0) / GRID_SPACING)
	for index in range(line_count + 1):
		var offset := -ARENA_HALF_EXTENT + index * GRID_SPACING
		_create_floor_line(markers, Vector3(offset, 0.03, 0.0), Vector3(GRID_LINE_THICKNESS, 0.06, ARENA_HALF_EXTENT * 2.0), _grid_color(index))
		_create_floor_line(markers, Vector3(0.0, 0.03, offset), Vector3(ARENA_HALF_EXTENT * 2.0, 0.06, GRID_LINE_THICKNESS), _grid_color(index + 1))

func _create_floor_line(parent: Node3D, line_position: Vector3, line_size: Vector3, color: Color) -> void:
	var line := MeshInstance3D.new()
	line.position = line_position

	var mesh := BoxMesh.new()
	mesh.size = line_size
	line.mesh = mesh

	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 1.0
	line.material_override = material
	parent.add_child(line)

func _grid_color(index: int) -> Color:
	if index % 5 == 0:
		return Color(0.78, 0.82, 0.88, 1.0)
	return Color(0.32, 0.35, 0.4, 1.0)

func _ensure_walls() -> void:
	if has_node("NorthWall"):
		return

	_create_rainbow_wall("NorthWall", Vector3(0.0, WALL_HEIGHT * 0.5, -ARENA_HALF_EXTENT), ARENA_HALF_EXTENT * 2.2, true)
	_create_rainbow_wall("SouthWall", Vector3(0.0, WALL_HEIGHT * 0.5, ARENA_HALF_EXTENT), ARENA_HALF_EXTENT * 2.2, true)
	_create_rainbow_wall("EastWall", Vector3(ARENA_HALF_EXTENT, WALL_HEIGHT * 0.5, 0.0), ARENA_HALF_EXTENT * 2.2, false)
	_create_rainbow_wall("WestWall", Vector3(-ARENA_HALF_EXTENT, WALL_HEIGHT * 0.5, 0.0), ARENA_HALF_EXTENT * 2.2, false)

func _create_rainbow_wall(wall_name: String, wall_position: Vector3, wall_length: float, along_x: bool) -> void:
	var wall := StaticBody3D.new()
	wall.name = wall_name
	wall.position = wall_position
	add_child(wall)

	var collision := CollisionShape3D.new()
	collision.name = "CollisionShape3D"
	var wall_shape := BoxShape3D.new()
	wall_shape.size = Vector3(wall_length, WALL_HEIGHT, WALL_THICKNESS) if along_x else Vector3(WALL_THICKNESS, WALL_HEIGHT, wall_length)
	collision.shape = wall_shape
	wall.add_child(collision)

	var stripe_count := int(ceil(wall_length / STRIPE_SIZE))
	for stripe_index in stripe_count:
		var stripe := MeshInstance3D.new()
		stripe.name = "Stripe_%02d" % stripe_index

		var stripe_mesh := BoxMesh.new()
		var segment_length := wall_length / float(stripe_count)
		stripe_mesh.size = Vector3(segment_length + 0.2, WALL_HEIGHT, WALL_THICKNESS * 0.75) if along_x else Vector3(WALL_THICKNESS * 0.75, WALL_HEIGHT, segment_length + 0.2)
		stripe.mesh = stripe_mesh

		var offset := -wall_length * 0.5 + segment_length * (stripe_index + 0.5)
		stripe.position = Vector3(offset, 0.0, 0.0) if along_x else Vector3(0.0, 0.0, offset)

		var material := StandardMaterial3D.new()
		material.albedo_color = WALL_COLORS[stripe_index % WALL_COLORS.size()]
		material.roughness = 0.8
		stripe.material_override = material
		wall.add_child(stripe)

func _ensure_player_spawn() -> void:
	var player := get_node_or_null("Player") as CharacterBody3D
	if player == null:
		return

	player.global_position = Vector3(0.0, 1.2, 0.0)
