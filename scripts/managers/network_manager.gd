class_name NetworkManager extends Node

var peer: IMultiplayer
var peer_mode: PeerMode

enum PeerMode {
	STEAM,
	LOCAL,
	NONE
}

func _init() -> void:
	peer_mode = PeerMode.LOCAL
	setup_peer_mode()

func get_peer():
	return peer.get_peer()

func get_multiplayer_peer():
	return peer

func get_peer_mode():
	return peer_mode

# Should be called when the multiplayer peer is changed
func update_multiplayer_peer():
	multiplayer.multiplayer_peer = get_peer()
	
func setup_peer_mode(peer_mode: PeerMode = PeerMode.LOCAL):
	match peer_mode:
		PeerMode.STEAM:
			# peer = SteamMultiplayerPeer.new()
			pass
		PeerMode.LOCAL:
			peer = LocalMultiplayer.new()
		PeerMode.NONE:
			peer = null
	

# TODO: going to be used when we want to setup steam
## Sets the peer mode for the multiplayer connection -> Steam OR Local
#func set_peer_mode(peer_mode: PeerMode):
	#peer = ENetMultiplayerPeer.new()
	#print_rich("Peer Mode Set To: [color=yellow]", PeerMode.keys()[peer_mode], "[/color]")

#func reset_peer():
	#set_peer_mode(PeerMode.NONE)
