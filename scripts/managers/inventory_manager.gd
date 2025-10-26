class_name InventoryManager extends Node

# Signals for UI/UX and gameplay hooks
signal slot_changed(slot_index: int, item: BaseItem)
signal active_slot_changed(prev_index: int, new_index: int)
signal item_picked_up(slot_index: int, item: BaseItem)
signal item_dropped(slot_index: int, item_scene: PackedScene)
signal item_used(slot_index: int)
signal item_alternate_used(slot_index: int)

@export_group("Inventory Settings")
# Number of hotbar slots. Kept flexible but default is 3 per spec
@export_range(1, 10, 1) var num_slots: int = 3
# Optional item scene registry for spawn-by-name
@export var item_registry: Dictionary = {}
# Owner player node; expected to be a CharacterBody3D (e.g., addons/fpc/character.gd)
@export var player: CharacterBody3D = null
# Where equipped item instances should be parented under the player (e.g., a hand socket)
@export var item_mount_path: NodePath = NodePath("")

# Internal state
var _slots: Array[BaseItem] = []
var _active_slot: int = 0

# Helpers
func _get_item_mount() -> Node3D:
	if player:
		if String(item_mount_path) != "":
			var n = player.get_node_or_null(item_mount_path)
			if n and n is Node3D:
				return n
		return player
	# Fallback: walk up to find a Node3D ancestor
	var p := get_parent()
	while p:
		if p is Node3D:
			return p
		p = p.get_parent()
	# Last resort: return a temporary Node3D (not added to tree)
	return Node3D.new()

func _ready():
	_resize_slots(num_slots)

	## for testing

# --- Public API ---

# Query API
func get_slots() -> Array[BaseItem]:
	return _slots.duplicate()

func get_active_slot_index() -> int:
	return _active_slot

func get_active_item() -> BaseItem:
	return _get_item(_active_slot)

func get_item(slot_index: int) -> BaseItem:
	return _get_item(slot_index)

func is_slot_empty(slot_index: int) -> bool:
	return _get_item(slot_index) == null

func first_empty_slot() -> int:
	for i in range(_slots.size()):
		if _slots[i] == null:
			return i
	return -1

# Slot management
func set_active_slot(slot_index: int) -> void:
	if slot_index < 0 or slot_index >= _slots.size():
		return
	if slot_index == _active_slot:
		return
	var prev := _active_slot
	_unequip_slot(prev)
	_active_slot = slot_index
	_equip_slot(slot_index)
	active_slot_changed.emit(prev, slot_index)

func cycle_active_slot(direction: int) -> void:
	if _slots.is_empty():
		return
	var next := int((_active_slot + direction) % _slots.size())
	if next < 0:
		next = _slots.size() - 1
	set_active_slot(next)

func swap_slots(a: int, b: int) -> void:
	if not _valid_index(a) or not _valid_index(b) or a == b:
		return
	var a_item := _slots[a]
	var b_item := _slots[b]
	var was_active_a := (a == _active_slot)
	var was_active_b := (b == _active_slot)
	if was_active_a:
		_unequip_slot(a)
	if was_active_b:
		_unequip_slot(b)
	_slots[a] = b_item
	_slots[b] = a_item
	slot_changed.emit(a, _slots[a])
	slot_changed.emit(b, _slots[b])
	if was_active_a:
		_equip_slot(b)
		_active_slot = b
	elif was_active_b:
		_equip_slot(a)
		_active_slot = a

func move_slot(from_index: int, to_index: int) -> void:
	if not _valid_index(from_index) or not _valid_index(to_index) or from_index == to_index:
		return
	var tmp := _slots[from_index]
	if tmp == null and _slots[to_index] == null:
		return
	var was_active_from := (from_index == _active_slot)
	if was_active_from:
		_unequip_slot(from_index)
	_slots[to_index] = tmp
	_slots[from_index] = null
	slot_changed.emit(from_index, null)
	slot_changed.emit(to_index, _slots[to_index])
	if was_active_from:
		_active_slot = to_index
		_equip_slot(to_index)

func clear_slot(slot_index: int, queue_free_item: bool = true) -> void:
	if not _valid_index(slot_index):
		return
	var item := _slots[slot_index]
	if item == null:
		return
	if slot_index == _active_slot:
		_unequip_slot(slot_index)
	_slots[slot_index] = null
	slot_changed.emit(slot_index, null)
	if queue_free_item and is_instance_valid(item):
		item.queue_free()

func clear_all(queue_free_items: bool = true) -> void:
	for i in range(_slots.size()):
		clear_slot(i, queue_free_items)

# Item acquisition
# Adds an already-instantiated item node into a given slot or first empty; returns final slot or -1
func add_item_instance(item: BaseItem, slot_index: int = -1) -> int:
	if item == null:
		return -1
	var target := slot_index if _valid_index(slot_index) else first_empty_slot()
	if target == -1:
		return -1
	if _slots[target] != null:
		return -1
	_attach_item_to_player(item)
	_slots[target] = item
	slot_changed.emit(target, item)
	item_picked_up.emit(target, item)
	# Auto-equip if this becomes the first item and is in active slot
	if target == _active_slot:
		_equip_slot(target)
	return target

# Spawns an item by registry key or scene path and adds it to inventory
func spawn_and_add_item(id_or_path: String, slot_index: int = -1) -> int:
	var scene: PackedScene = null
	if item_registry.has(id_or_path):
		scene = item_registry[id_or_path]
	elif ResourceLoader.exists(id_or_path):
		scene = load(id_or_path)
	if scene == null:
		return -1
	var instance = scene.instantiate()
	if not (instance is BaseItem):
		instance.queue_free()
		return -1
	return add_item_instance(instance, slot_index)

# Consumption/Use
func use_active() -> void:
	var item := get_active_item()
	if item:
		item.use_item()
		item_used.emit(_active_slot)

func alternate_use_active() -> void:
	var item := get_active_item()
	if item:
		item.alternate_use()
		item_alternate_used.emit(_active_slot)

# Drop item back into the world at player's position/forward
# Optionally provide a PackedScene; if none, attempts to pack the instance's scene
func drop_slot(slot_index: int, drop_scene: PackedScene = null, impulse_forward: float = 0.0) -> void:
	if not _valid_index(slot_index):
		return
	var item := _slots[slot_index]
	if item == null:
		return
	if slot_index == _active_slot:
		_unequip_slot(slot_index)
	var scene := drop_scene
	if scene == null:
		# Try to pack from the item instance if possible
		if item.scene_file_path != "":
			scene = load(item.scene_file_path)
	if scene == null:
		# Cannot drop if we cannot instantiate a scene
		return
	# Remove from inventory
	_slots[slot_index] = null
	slot_changed.emit(slot_index, null)
	# Spawn into world
	var world_item = scene.instantiate()
	# Add to scene tree so it becomes active in the world
	var drop_parent := get_tree().current_scene
	if drop_parent == null:
		drop_parent = get_tree().root
	drop_parent.add_child(world_item)
	# Place in front of the player mount with matching orientation
	if world_item is Node3D:
		var mount := _get_item_mount()
		var basis := (mount as Node3D).global_transform.basis
		(world_item as Node3D).global_transform.basis = basis
		(world_item as Node3D).global_transform.origin = (mount as Node3D).global_transform.origin + basis.z * -0.5
		# Optional forward velocity for physics bodies
		if world_item is RigidBody3D and impulse_forward != 0.0:
			(world_item as RigidBody3D).linear_velocity = basis.z * -impulse_forward
	item_dropped.emit(slot_index, scene)
	# Free the inventory instance
	if is_instance_valid(item):
		item.queue_free()

# --- Save/Load ---
# Returns a plain representation of inventory state; consumers can persist as JSON
func serialize() -> Dictionary:
	var data: Dictionary = {
		"num_slots": _slots.size(),
		"active_slot": _active_slot,
		"items": []
	}
	for i in range(_slots.size()):
		var item := _slots[i]
		if item == null:
			data.items.append(null)
		else:
			data.items.append({
				"scene": item.scene_file_path,
				"name": item.item_name,
				"desc": item.item_description
			})
	return data

# Rebuilds inventory from serialized data. Does not clear existing unless clear_existing is true
func deserialize(data: Dictionary, clear_existing: bool = true) -> void:
	if clear_existing:
		clear_all(true)
	if data.has("num_slots"):
		_resize_slots(int(data.num_slots))
	if data.has("items") and data.items is Array:
		for i in range(min(_slots.size(), data.items.size())):
			var entry = data.items[i]
			if entry == null:
				continue
			if entry is Dictionary and entry.has("scene") and entry.scene != "":
				spawn_and_add_item(String(entry.scene), i)
	if data.has("active_slot"):
		set_active_slot(int(data.active_slot))

# --- Internal helpers ---
func _valid_index(i: int) -> bool:
	return i >= 0 and i < _slots.size()

func _get_item(i: int) -> BaseItem:
	if not _valid_index(i):
		return null
	return _slots[i]

func _resize_slots(count: int) -> void:
	var prev_active := _active_slot
	# Unequip active before resizing
	_unequip_slot(_active_slot)
	_slots.resize(count)
	for i in range(count):
		if _slots[i] == null:
			_slots[i] = null
	_active_slot = clamp(prev_active, 0, max(0, count - 1))
	# Re-equip after resize
	_equip_slot(_active_slot)

# Attach item to player
func _attach_item_to_player(item: BaseItem) -> void:
	var mount := _get_item_mount()
	# Remove item from its current parent (the scene)
	if item.get_parent():
		item.get_parent().remove_child(item)
	# Add item under the mount
	mount.add_child(item)
	if Engine.is_editor_hint():
		item.owner = mount.get_tree().edited_scene_root
	# Snap to mount
	if item is Node3D:
		(item as Node3D).transform = Transform3D.IDENTITY
	item.visible = false
	item.set_process(false)

func _equip_slot(slot_index: int) -> void:
	var item := _get_item(slot_index)
	if item == null:
		return
	item.equip(player)

func _unequip_slot(slot_index: int) -> void:
	var item := _get_item(slot_index)
	if item == null:
		return
	if item.is_equipped:
		item.unequip()

# --- Editor convenience ---
func _get_configuration_warnings() -> PackedStringArray:
	var warnings: PackedStringArray = []
	if player == null:
		warnings.append("Player reference is not set.")
	return warnings
