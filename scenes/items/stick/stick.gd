class_name Stick extends BaseItem

func _ready():
	super._ready()

	item_name = "Stick"
	item_description = "A stick"
	can_use = true
	use_cooldown = 0.5
	equip_cooldown = 0.5

func _on_use():
	print("Stick used")

func _on_equipped():
	print("Stick equipped")

func _on_unequipped():
	print("Stick unequipped")
