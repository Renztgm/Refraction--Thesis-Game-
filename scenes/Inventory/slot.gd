extends Control

@onready var button = $Slot
@onready var icon = $Slot/TextureRect
@onready var label = $Slot/Label

var slot_id : int = -1
var item_id : int = -1
var quantity : int = 0

func set_item(item_name: String, new_quantity: int, icon_path: String):
	var result = InventoryManager.db.select_rows("items", "name = '%s'" % item_name, ["*"])
	if result.size() > 0:
		item_id = result[0]["id"]
	quantity = new_quantity
	icon.texture = load(icon_path)
	label.text = "%s x%d" % [item_name, quantity] if quantity > 1 else item_name

func clear_item():
	item_id = -1
	quantity = 0
	icon.texture = null
	label.text = ""
