extends Node3D

@export var voice_player: RaytracedAudioPlayer3D
#@export var has_loopback: bool = false

#region Steam Voice Variables
var current_sample_rate: int = 48000
var network_playback: AudioStreamGeneratorPlayback = null
var network_voice_buffer: PackedByteArray = PackedByteArray()
var local_playback: AudioStreamGeneratorPlayback = null
var local_voice_buffer: PackedByteArray = PackedByteArray()
var is_recording: bool = false
#endregion

var steam_id: int = 0
var player_controller = null
var bus: String


func _ready() -> void:
	# Get reference to parent player controller
	player_controller = get_parent()

	if player_controller:
		steam_id = player_controller.steam_id
		print_debug("[VoiceChat] Initialized for Steam ID: %s" % steam_id)
	else:
		print_debug("[VoiceChat] WARNING: No player controller found!")

	# Setup voice player for network audio
	if voice_player:
		get_sample_rate()

		# Ensure voice_player has an AudioStreamGenerator
		if not voice_player.stream or not voice_player.stream is AudioStreamGenerator:
			var generator = AudioStreamGenerator.new()
			generator.mix_rate = current_sample_rate
			generator.buffer_length = 0.5 # 500ms buffer - larger for stability
			voice_player.stream = generator
			print_debug("[VoiceChat] Created new AudioStreamGenerator")
		else:
			voice_player.stream.mix_rate = current_sample_rate

		print_debug("[VoiceChat] Sample rate set to: %s Hz" % current_sample_rate)

		if is_multiplayer_authority():
			# Authority uses RaytracedAudioListener
			$RaytracedAudioListener.make_current()
			print_debug("[VoiceChat] Authority: RaytracedAudioListener activated")

			## Setup local playback for loopback if enabled
			#if has_loopback:
				## Make sure the player is stopped before playing
				#if voice_player.playing:
					#voice_player.stop()
#
				#voice_player.play()
				## Wait a frame for the stream to be ready
				#await get_tree().process_frame
				#local_playback = voice_player.get_stream_playback()
#
				#if local_playback:
					#var frames_avail = local_playback.get_frames_available()
					#print_debug("[VoiceChat] Loopback enabled - Playback ready: true, Initial frames available: %s" % frames_avail)
				#else:
					#print_debug("[VoiceChat] ERROR: Failed to get local playback stream!")
		else:
			# Disable remote listeners so they don't steal the current listener on this client
			if has_node("RaytracedAudioListener"):
				$RaytracedAudioListener.is_enabled = false
				$RaytracedAudioListener.current = false
			# Remote clients play network audio
			voice_player.play()
			await get_tree().process_frame
			network_playback = voice_player.get_stream_playback()
			print_debug("[VoiceChat] Remote client: Network playback ready")
	else:
		print_debug("[VoiceChat] WARNING: No voice_player assigned!")

	# Server doesn't need to play voice
	if multiplayer.get_unique_id() == 1:
		if voice_player:
			voice_player.stop()
		print_debug("[VoiceChat] Server mode: Voice playback disabled")

	# Start always-on voice recording for authority (if not disabled)
	if is_multiplayer_authority() and not OS.get_cmdline_args().has("--disable-vc"):
		record_voice(true)
		print_debug("[VoiceChat] Always-on voice recording enabled")


func _process(_delta: float) -> void:
	if is_multiplayer_authority():
		check_for_voice()


func record_voice(start_recording: bool) -> void:
	is_recording = start_recording
	Steam.setInGameVoiceSpeaking(steam_id, start_recording)

	if start_recording:
		Steam.startVoiceRecording()
		#print_debug("[VoiceChat] Steam voice recording started for Steam ID: %s" % steam_id)
	else:
		Steam.stopVoiceRecording()
		#print_debug("[VoiceChat] Steam voice recording stopped")


func check_for_voice() -> void:
	if not is_recording:
		return

	var voice_data: Dictionary = Steam.getVoice()
	if voice_data['result'] == Steam.VOICE_RESULT_OK and voice_data["written"] and Input.is_action_pressed("push-to-talk"):
		if BaseNetworkManager.get_peer_mode() == BaseNetworkManager.PeerMode.STEAM:
			pass
			#SteamManager.send_voice_data(voice_data['buffer'])
		elif BaseNetworkManager.get_peer_mode() == BaseNetworkManager.PeerMode.LOCAL:
			read_incoming_voice_data.rpc(voice_data['buffer'])
			pass
	
		# Optional loopback for testing
		#if has_loopback:
			#print_debug("[VoiceChat] Processing loopback audio")
			#process_voice_data(voice_data, "local")
	elif voice_data['result'] != Steam.VOICE_RESULT_OK:
		pass
		#print_debug("[VoiceChat] Voice capture error - Result: %s" % voice_data['result'])

@rpc("any_peer", "call_local", "unreliable")
func read_incoming_voice_data(data: PackedByteArray):
	if !is_multiplayer_authority():
		return
	print("Reading", Global.session_type, " ", data)
	pass

# @rpc("any_peer", "call_remote", "unreliable")
# func process_voice_data(voice_data: Dictionary, voice_source: String) -> void:
# 	get_sample_rate()
# 	#print_debug("[VoiceChat] Processing voice data from source: %s" % voice_source)


# 	var decompressed_voice: Dictionary
# 	if voice_source == "local":
# 		decompressed_voice = Steam.decompressVoice(voice_data['buffer'], current_sample_rate)
# 	elif voice_source == "network":
# 		decompressed_voice = Steam.decompressVoice(voice_data['voice_data'], current_sample_rate)

# 	if decompressed_voice['result'] == Steam.VOICE_RESULT_OK and decompressed_voice['size'] > 0:
# 		print_debug("[VoiceChat] Voice decompressed - Size: %s bytes, Source: %s" % [decompressed_voice['size'], voice_source])
# 		#speaking.append(sender_username)

# 		if voice_source == "local" and local_playback:
# 			# Process local loopback audio
# 			local_voice_buffer = decompressed_voice['uncompressed']
# 			local_voice_buffer.resize(decompressed_voice['size'])
# 			var frames_available = local_playback.get_frames_available()
# 			var frames_to_push: int = mini(frames_available, local_voice_buffer.size() >> 1)

# 			# Check if voice_player is actually playing
# 			if not voice_player.playing:
# 				print_debug("[VoiceChat] WARNING: voice_player stopped playing! Restarting...")
# 				voice_player.play()
# 				await get_tree().process_frame
# 				local_playback = voice_player.get_stream_playback()
# 				frames_available = local_playback.get_frames_available() if local_playback else 0

# 			print_debug("[VoiceChat] Local playback - Frames available: %s, Pushing: %s frames, Buffer size: %s, Playing: %s" % [frames_available, frames_to_push, local_voice_buffer.size(), voice_player.playing])

# 			var frames_pushed = 0
# 			# If frames_available is 0, try to clear and restart the stream
# 			if frames_available == 0:
# 				print_debug("[VoiceChat] WARNING: No frames available, attempting to clear buffer...")
# 				local_playback.clear_buffer()
# 				await get_tree().process_frame
# 				frames_available = local_playback.get_frames_available()
# 				print_debug("[VoiceChat] After clear - Frames available: %s" % frames_available)

# 			while local_voice_buffer.size() >= 2 and local_playback.get_frames_available() > 0:
# 				var raw_value: int = local_voice_buffer[0] | (local_voice_buffer[1] << 8)
# 				raw_value = (raw_value + 32768) & 0xffff
# 				var amplitude: float = float(raw_value - 32768) / 32768.0
# 				local_playback.push_frame(Vector2(amplitude, amplitude))

# 				local_voice_buffer.remove_at(0)
# 				local_voice_buffer.remove_at(0)
# 				frames_pushed += 1

# 			print_debug("[VoiceChat] Pushed %s frames to local playback" % frames_pushed)

# 		elif voice_source == "network" and network_playback:
# 			# Process network audio from remote players
# 			var new_voice_data = decompressed_voice['uncompressed']
# 			new_voice_data.resize(decompressed_voice['size'])

# 			# Append new data to existing buffer
# 			network_voice_buffer.append_array(new_voice_data)

# 			var frames_available = network_playback.get_frames_available()

# 			# Check if voice_player is actually playing
# 			if not voice_player.playing:
# 				print_debug("[VoiceChat] WARNING: voice_player stopped playing! Restarting...")
# 				voice_player.play()
# 				await get_tree().process_frame
# 				network_playback = voice_player.get_stream_playback()
# 				frames_available = network_playback.get_frames_available() if network_playback else 0

# 			# If buffer is full (frames_available == 0), try to clear it
# 			if frames_available == 0:
# 				print_debug("[VoiceChat] WARNING: Network buffer full (0 frames available), clearing buffer...")
# 				network_playback.clear_buffer()
# 				await get_tree().process_frame
# 				frames_available = network_playback.get_frames_available()
# 				print_debug("[VoiceChat] After clear - Frames available: %s" % frames_available)

# 			print_debug("[VoiceChat] Network playback - Frames available: %s, Buffer size: %s bytes, Playing: %s" % [frames_available, network_voice_buffer.size(), voice_player.playing])

# 			var frames_pushed = 0
# 			while network_voice_buffer.size() >= 2 and network_playback.get_frames_available() > 0:
# 				var raw_value: int = network_voice_buffer[0] | (network_voice_buffer[1] << 8)
# 				raw_value = (raw_value + 32768) & 0xffff
# 				var amplitude: float = float(raw_value - 32768) / 32768.0
# 				network_playback.push_frame(Vector2(amplitude, amplitude))

# 				network_voice_buffer.remove_at(0)
# 				network_voice_buffer.remove_at(0)
# 				frames_pushed += 1

# 			print_debug("[VoiceChat] Pushed %s frames to network playback (remaining buffer: %s bytes)" % [frames_pushed, network_voice_buffer.size()])
# 		else:
# 			print_debug("[VoiceChat] WARNING: Playback stream not available for source: %s" % voice_source)
# 	else:
# 		print_debug("[VoiceChat] Voice decompression failed - Result: %s, Size: %s" % [decompressed_voice.get('result', 'N/A'), decompressed_voice.get('size', 0)])

func get_sample_rate(is_toggle: bool = true) -> void:
	var old_sample_rate = current_sample_rate

	if is_toggle:
		current_sample_rate = Steam.getVoiceOptimalSampleRate()
	else:
		current_sample_rate = 48000

	if old_sample_rate != current_sample_rate:
		print_debug("[VoiceChat] Sample rate changed: %s Hz -> %s Hz" % [old_sample_rate, current_sample_rate])

	if voice_player and current_sample_rate:
		#voice_player.stream.mix_rate = current_sample_rate
		current_sample_rate = 48000
	else:
		current_sample_rate = 48000
