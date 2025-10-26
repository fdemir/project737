# Comm Test Rpc
#extends Node
#func _input(event: InputEvent) -> void:
#
	#
	#if event.is_action_released("crouch"):
		#receive_message.rpc("Player crouched!", multiplayer.get_unique_id(),  Global.session_type)
#
#@rpc("any_peer", "call_remote", "reliable")
#func receive_message(message: String, id, sender) -> void:
	#if !is_multiplayer_authority():
		#return
	#print("Received from player ", id, ": ", message, sender, "\n Running On " + Global.session_type)
