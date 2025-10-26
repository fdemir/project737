class_name Interactable
extends Node3D

@export_group("Interact Properties")
## The input map action string as defined in the Godot Project settings input map.
@export var input_map_action : String = "interact"
## The text that gets displayed in the HUD interaction prompt.
@export var interaction_text : String = "Pickup"


func _ready():
	add_to_group("interactable")
