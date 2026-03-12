extends Node3D

const ARENA_HALF_EXTENT := 200.0
const FLOOR_HEIGHT := 1.0
const WALL_HEIGHT := 18.0
const WALL_THICKNESS := 2.0
const STRIPE_SIZE := 16.0
const GRID_LINE_THICKNESS := 0.35
const GRID_SPACING := 10.0
const START_MENU_SCENE := "res://scenes/start_menu.tscn"
# North, South, East, West
const WALL_COLORS := [
	Color(0.95, 0.18, 0.18, 1.0),
	Color(0.96, 0.48, 0.14, 1.0),
	Color(0.96, 0.84, 0.16, 1.0),
	Color(0.24, 0.78, 0.28, 1.0)
]

var _material_cache := {}

func _ready() -> void:
	_ensure_environment()
	_ensure_floor()
	_ensure_floor_markers()
	_ensure_walls()
	_ensure_player_spawn()
	_ensure_gameplay_hud()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("return_to_menu"):
		_go_to_start_menu()

func _go_to_start_menu() -> void:
	var error := get_tree().change_scene_to_file(START_MENU_SCENE)
	if error != OK:
		push_error("Failed to load scene: %s (error %d)" % [START_MENU_SCENE, error])

func _ensure_gameplay_hud() -> void:
	var hud := get_node_or_null("GameplayHUD") as CanvasLayer
	if hud == null:
		hud = CanvasLayer.new()
		hud.name = "GameplayHUD"
		add_child(hud)

	var hud_panel := hud.get_node_or_null("HudPanel") as PanelContainer
	if hud_panel == null:
		hud_panel = PanelContainer.new()
		hud_panel.name = "HudPanel"
		hud_panel.position = Vector2(12.0, 12.0)

		var style := StyleBoxFlat.new()
		style.bg_color = Color(0.02, 0.03, 0.05, 0.62)
		style.corner_radius_top_left = 8
		style.corner_radius_top_right = 8
		style.corner_radius_bottom_right = 8
		style.corner_radius_bottom_left = 8
		style.border_width_left = 1
		style.border_width_top = 1
		style.border_width_right = 1
		style.border_width_bottom = 1
		style.border_color = Color(1.0, 1.0, 1.0, 0.15)
		hud_panel.add_theme_stylebox_override("panel", style)
		hud.add_child(hud_panel)

	var margin := hud_panel.get_node_or_null("Margin") as MarginContainer
	if margin == null:
		margin = MarginContainer.new()
		margin.name = "Margin"
		margin.add_theme_constant_override("margin_left", 10)
		margin.add_theme_constant_override("margin_top", 8)
		margin.add_theme_constant_override("margin_right", 10)
		margin.add_theme_constant_override("margin_bottom", 8)
		hud_panel.add_child(margin)

	var hud_vbox := margin.get_node_or_null("HudVBox") as VBoxContainer
	if hud_vbox == null:
		hud_vbox = VBoxContainer.new()
		hud_vbox.name = "HudVBox"
		hud_vbox.add_theme_constant_override("separation", 6)
		margin.add_child(hud_vbox)

	var legacy_button := hud.get_node_or_null("MenuButton") as Button
	if legacy_button != null:
		legacy_button.queue_free()

	var menu_button := hud_vbox.get_node_or_null("MenuButton") as Button
	if menu_button == null:
		menu_button = Button.new()
		menu_button.name = "MenuButton"
		menu_button.text = "Menu (M)"
		hud_vbox.add_child(menu_button)

	if not menu_button.pressed.is_connected(_go_to_start_menu):
		menu_button.pressed.connect(_go_to_start_menu)

func _get_material(color: Color) -> StandardMaterial3D:
	var key = color.to_html()
	if not _material_cache.has(key):
		var material := StandardMaterial3D.new()
		material.albedo_color = color
		material.roughness = 0.8
		material.metallic = 0.0
		_material_cache[key] = material
	return _material_cache[key]

func _get_grid_material(is_major: bool) -> StandardMaterial3D:
	var key = "grid_" + ("major" if is_major else "minor")
	if not _material_cache.has(key):
		var material := StandardMaterial3D.new()
		material.albedo_color = Color(0.78, 0.82, 0.88, 1.0) if is_major else Color(0.32, 0.35, 0.4, 1.0)
		material.roughness = 1.0
		material.metallic = 0.0
		_material_cache[key] = material
	return _material_cache[key]

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

	var floor_body := StaticBody3D.new()
	floor_body.name = "Floor"
	floor_body.position = Vector3(0.0, -FLOOR_HEIGHT * 0.5, 0.0)
	add_child(floor_body)

	var collision := CollisionShape3D.new()
	collision.name = "CollisionShape3D"
	var collision_shape := BoxShape3D.new()
	collision_shape.size = Vector3(ARENA_HALF_EXTENT * 2.2, FLOOR_HEIGHT, ARENA_HALF_EXTENT * 2.2)
	collision.shape = collision_shape
	floor_body.add_child(collision)

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
	floor_body.add_child(visual)

func _ensure_floor_markers() -> void:
	if has_node("FloorMarkers"):
		return

	var markers := Node3D.new()
	markers.name = "FloorMarkers"
	add_child(markers)

	var line_count := int((ARENA_HALF_EXTENT * 2.0) / GRID_SPACING)
	for index in range(line_count + 1):
		var offset := -ARENA_HALF_EXTENT + index * GRID_SPACING
		var is_major = (index % 5 == 0)

		_create_floor_line(markers, Vector3(offset, 0.03, 0.0), Vector3(GRID_LINE_THICKNESS, 0.06, ARENA_HALF_EXTENT * 2.0), is_major)
		_create_floor_line(markers, Vector3(0.0, 0.03, offset), Vector3(ARENA_HALF_EXTENT * 2.0, 0.06, GRID_LINE_THICKNESS), is_major)

func _create_floor_line(parent: Node3D, line_position: Vector3, line_size: Vector3, is_major: bool) -> void:
	var line := MeshInstance3D.new()
	line.position = line_position

	var mesh := BoxMesh.new()
	mesh.size = line_size
	line.mesh = mesh

	line.material_override = _get_grid_material(is_major)
	parent.add_child(line)

func _ensure_walls() -> void:
	if has_node("NorthWall"):
		return

	_create_rainbow_wall("NorthWall", Vector3(0.0, WALL_HEIGHT * 0.5, -ARENA_HALF_EXTENT), ARENA_HALF_EXTENT * 2.2, true, 0)
	_create_rainbow_wall("SouthWall", Vector3(0.0, WALL_HEIGHT * 0.5, ARENA_HALF_EXTENT), ARENA_HALF_EXTENT * 2.2, true, 1)
	_create_rainbow_wall("EastWall", Vector3(ARENA_HALF_EXTENT, WALL_HEIGHT * 0.5, 0.0), ARENA_HALF_EXTENT * 2.2, false, 2)
	_create_rainbow_wall("WestWall", Vector3(-ARENA_HALF_EXTENT, WALL_HEIGHT * 0.5, 0.0), ARENA_HALF_EXTENT * 2.2, false, 3)

func _create_rainbow_wall(wall_name: String, wall_position: Vector3, wall_length: float, along_x: bool, color_index: int) -> void:
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

	var visual := MeshInstance3D.new()
	visual.name = "Visual"
	var mesh := BoxMesh.new()
	mesh.size = Vector3(wall_length, WALL_HEIGHT, WALL_THICKNESS) if along_x else Vector3(WALL_THICKNESS, WALL_HEIGHT, wall_length)
	visual.mesh = mesh

	var wall_color = WALL_COLORS[color_index % WALL_COLORS.size()]
	visual.material_override = _get_material(wall_color)
	wall.add_child(visual)

func _ensure_player_spawn() -> void:
	var player := get_node_or_null("Player") as CharacterBody3D
	if player == null:
		return

	player.global_position = Vector3(0.0, 1.2, 0.0)
