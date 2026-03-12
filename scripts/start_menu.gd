extends Control

const OVER_SHOULDER_SCENE := "res://scenes/main.tscn"
const FREE_ROTATE_SCENE := "res://scenes/main_free_rotate.tscn"

@onready var _over_shoulder_button := $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/OverShoulderButton as Button
@onready var _free_rotate_button := $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/FreeRotateButton as Button

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_over_shoulder_button.pressed.connect(_on_over_shoulder_pressed)
	_free_rotate_button.pressed.connect(_on_free_rotate_pressed)
	_over_shoulder_button.grab_focus()

func _on_over_shoulder_pressed() -> void:
	_load_scene(OVER_SHOULDER_SCENE)

func _on_free_rotate_pressed() -> void:
	_load_scene(FREE_ROTATE_SCENE)

func _load_scene(scene_path: String) -> void:
	var error := get_tree().change_scene_to_file(scene_path)
	if error != OK:
		push_error("Failed to load scene: %s (error %d)" % [scene_path, error])
