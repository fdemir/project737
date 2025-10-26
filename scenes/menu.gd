extends Node


var local_host = "127.0.0.1"
var local_port = 3000
var local_max_players = 4

func _on_play_pressed() -> void:
	Global.game_controller.change_world_scene("res://scenes/worlds/level.tscn")

func _on_close_pressed() -> void:
	get_tree().quit()

func _on_host_pressed() -> void:
	BaseNetworkManager.get_multiplayer_peer().create_lobby()
	Global.game_controller.change_world_scene("res://scenes/worlds/level.tscn")
	
	
func _on_join_pressed() -> void:
	BaseNetworkManager.get_multiplayer_peer().join_lobby()
	Global.game_controller.change_world_scene("res://scenes/worlds/level.tscn")
