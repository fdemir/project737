class_name PlayerSpawner extends MultiplayerSpawner

@export var player_scene: PackedScene

@export_category("Configurations")
@export var spawn_points: Array[NodePath]

@export var spawn_in_empty: bool

var players = {}

func _ready():
	spawn_function = spawn_player

	# Defer self-spawn so parent is finished setting up children
	if multiplayer.is_server():
		call_deferred("_spawn_self")
		multiplayer.peer_connected.connect(spawn)
		multiplayer.peer_disconnected.connect(remove_player)

func _spawn_self():
	# Spawn the host player with the correct authority id
	spawn(multiplayer.get_unique_id())

func spawn_player(data):
	var player = player_scene.instantiate()
	player.set_multiplayer_authority(data)
	players[data] = player

	var spawn_position: Vector3 = Vector3.ZERO

	if spawn_in_empty and spawn_points.size() > 0:
		for sp_path: NodePath in spawn_points:
			var sp := get_node_or_null(sp_path) as Node3D
			if sp and sp.get_child_count() == 0:
				spawn_position = sp.global_position
				sp.add_child.call_deferred(Node3D.new())
				break
		# Fallback to first spawn point
		if spawn_position == Vector3.ZERO:
			var first_sp := get_node_or_null(spawn_points[0]) as Node3D
			if first_sp:
				spawn_position = first_sp.global_position

	player.global_position = spawn_position
	return player

func remove_player(data):
	if players.has(data):
		if is_instance_valid(players[data]):
			players[data].queue_free()
		players.erase(data)
