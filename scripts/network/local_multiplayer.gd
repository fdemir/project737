class_name LocalMultiplayer
extends IMultiplayer

var local_port: int = 3000
var local_max_players: int = 4
var local_host: String = "127.0.0.1"

var peer: ENetMultiplayerPeer

func _init():
	peer = ENetMultiplayerPeer.new()

func create_lobby(lobby_name: String = ""):
	var err = peer.create_server(local_port, local_max_players)
	if err != OK: print(err)
	BaseNetworkManager.update_multiplayer_peer()

func join_lobby(lobby_id: String = ""):
	var err = peer.create_client(local_host, local_port)
	if err != OK: print(err)
	BaseNetworkManager.update_multiplayer_peer()

func leave_lobby(lobby_id: String = ""):
	peer.disconnect_peer(multiplayer.get_unique_id())
	BaseNetworkManager.update_multiplayer_peer()

func get_peer():
	return peer
