extends Node


var local_host = "127.0.0.1"
var local_port = 3000
var local_max_players = 4

func _on_play_pressed() -> void:
	Global.game_controller.change_world_scene("res://scenes/worlds/level.tscn")

func _on_close_pressed() -> void:
	get_tree().quit()

func _on_host_pressed() -> void:
	var err = Global.network_manager.get_peer().create_server(local_port, local_max_players)
	if err != OK: print(err)
	Global.network_manager.update_multiplayer_peer()
	Global.game_controller.change_world_scene("res://scenes/worlds/level.tscn")

	
	
func _on_join_pressed() -> void:
	var err = Global.network_manager.get_peer().create_client(local_host, local_port)
	if err != OK: print(err)
	Global.network_manager.update_multiplayer_peer()
	Global.game_controller.change_world_scene("res://scenes/worlds/level.tscn")
