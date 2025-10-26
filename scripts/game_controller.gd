class_name GameController extends Node

@export var world: Node3D
@export var gui: Control

var current_world: Node3D
var current_gui: Control

@export var default_world_scene: String = ""
@export var default_gui_scene: String = ""

func _ready() -> void:
	Global.game_controller = self
	
	

	if default_world_scene != "":
		change_world_scene(default_world_scene)
	if default_gui_scene != "":
		change_gui_scene(default_gui_scene)
	

func change_gui_scene(new_scene: String, delete: bool = true, keep_running: bool = false) -> void:
	if current_gui != null:
		if delete:
			current_gui.queue_free()
		elif keep_running:
			current_gui.visible = false
		else:
			gui.remove_child(current_gui)

	var new_gui = load(new_scene).instantiate()
	gui.add_child(new_gui)
	current_gui = new_gui

func change_world_scene(new_scene: String, delete: bool = true, keep_running: bool = false) -> void:
	if current_world != null:
		if delete:
			current_world.queue_free()
		elif keep_running:
			current_world.visible = false
		else:
			world.remove_child(current_world)

	var new_world = load(new_scene).instantiate()
	world.add_child(new_world)
	current_world = new_world
