class_name NetworkManager extends Node

var peer

enum PeerMode {
	STEAM,
	LOCAL,
	NONE
}

func _ready() -> void:
	peer = ENetMultiplayerPeer.new()
	Global.network_manager = self

func get_peer():
	return peer as ENetMultiplayerPeer

func update_multiplayer_peer():
	multiplayer.multiplayer_peer = get_peer()

# TODO: going to be used when we want to setup steam
## Sets the peer mode for the multiplayer connection -> Steam OR Local
#func set_peer_mode(peer_mode: PeerMode):
	#peer = ENetMultiplayerPeer.new()
	#print_rich("Peer Mode Set To: [color=yellow]", PeerMode.keys()[peer_mode], "[/color]")

#func reset_peer():
	#set_peer_mode(PeerMode.NONE)
