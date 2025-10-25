extends Node3D
class_name BaseItem

# Signals for item events
signal item_equipped
signal item_unequipped
signal item_used

@export_group("Item Properties")
# Item name and description
@export var item_name: String = "Item"
# Item description
@export var item_description: String = ""
# Whether the item can be used
@export var can_use: bool = true
# Use cooldown
@export var use_cooldown: float = 0.5
# Whether the item can be equipped
@export var can_equip: bool = true
# Equip cooldown
@export var equip_cooldown: float = 0.5
# Whether the item can be unequipped
@export var can_unequip: bool = true

# # Network identity (optional). For placed world items, set this in the scene for deterministic matching across peers.
# @export var network_id: String = ""

# State variables
var is_equipped: bool = false
var cooldown_timer: float = 0.0
var steam_id: int = 0 # Steam ID of the owner

# # World-space position at the time of pickup (used to help late joiners remove world items reliably)
# var pickup_world_position: Vector3 = Vector3.ZERO

# References
var player_controller: Node = null

func _ready():
	set_process(false) # Only process when equipped
	add_to_group("items")
	
	# If a designer hasn't set a network_id, default to a locally-deterministic value
	# if network_id == "":
	# 	network_id = str(get_path())

func _process(delta):
	# Update cooldown
	if cooldown_timer > 0:
		cooldown_timer -= delta

# Called when item is equipped by player
func equip(player: CharacterBody3D, player_steam_id: int = 0):
	if is_equipped:
		return

	player_controller = player
	steam_id = player_steam_id
	is_equipped = true
	visible = true
	set_process(true)

	_on_equipped()
	item_equipped.emit()



# Called when item is unequipped
func unequip():
	if not is_equipped:
		return

	is_equipped = false
	visible = false
	set_process(false)

	_on_unequipped()
	item_unequipped.emit()

	player_controller = null
	steam_id = 0

# Called when player uses the item (e.g., left click)
func use_item():
	if not can_use or cooldown_timer > 0 or not is_equipped:
		return

	if not is_owner():
		return

	cooldown_timer = use_cooldown
	_on_use()
	item_used.emit()

# Called when player performs alternate action (e.g., right click)
func alternate_use():
	if not is_equipped or not is_owner():
		return
	_on_alternate_use()

# Virtual functions to override in child classes
func _on_equipped():
	pass

func _on_unequipped():
	pass

func _on_use():
	pass

func _on_alternate_use():
	pass

# Check if this client owns this item
func is_owner() -> bool:
	if not multiplayer.has_multiplayer_peer():
		return true
	return is_multiplayer_authority()
