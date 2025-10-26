class_name  Interaction
extends RayCast3D

@onready var item_mount: Marker3D = $Head/Camera/ItemMount

signal interactable_dedected(item: Interactable)
signal interactable_undedected()

func _physics_process(delta: float) -> void:
	handle_item_interaction()

func handle_item_interaction():
	if self.is_colliding():
		var collider = self.get_collider()
		var item = _find_item_from_collider(collider)
		
		if !item:
			interactable_undedected.emit()
			return
			
		if item:
			interactable_dedected.emit(item)
			if Input.is_action_just_pressed(item.input_map_action):
				attempt_to_pick_up_item(item)
				
func attempt_to_pick_up_item(item: BaseItem):
	if Global.player.INVENTORY:
		var slot = Global.player.INVENTORY.add_item_instance(item)
		if slot != -1:
			Global.player.INVENTORY.set_active_slot(slot)
		else:
			print("Inventory full. Cannot pick up ", item.item_name)

func _find_item_from_collider(collider) -> BaseItem:
	var node = collider
	while node and !(node is BaseItem) and node is Node:
		node = node.get_parent()
	return node if (node and node is BaseItem and node.is_in_group("items")) else null
