## Interface for multiplayer peer implementations.
## Provides a common API for different multiplayer backends (e.g., Steam, Local/ENet).
## Implementations should handle lobby creation, joining, and peer management.

extends Node
class_name IMultiplayer

func get_peer():
	pass

func setup():
	pass
	
func create_lobby(lobby_name: String = ""):
	pass

func join_lobby(lobby_id: String = ""):
	pass

func leave_lobby(lobby_id: String = ""):
	pass
