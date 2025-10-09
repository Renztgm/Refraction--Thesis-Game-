extends Control

@onready var button = $Slot
@onready var icon = $Slot/TextureRect
@onready var label = $Slot/Label

var slot_id : int = -1
var item_id : int = -1
var quantity : int = 0
var is_memory_shard : bool = false
var shard_name : String = ""

# Set a regular inventory item
func set_item(item_name: String, new_quantity: int, icon_path: String):
	var result = InventoryManager.db.select_rows("items", "name = '%s'" % item_name, ["*"])
	if result.size() > 0:
		item_id = result[0]["id"]
	
	quantity = new_quantity
	is_memory_shard = false
	shard_name = ""
	icon.texture = load(icon_path)
	label.text = "%s x%d" % [item_name, quantity] if quantity > 1 else item_name

# Set a memory shard
func set_memory_shard(shard_data: Dictionary):
	is_memory_shard = true
	shard_name = shard_data.get("shard_name", "Unknown Shard")
	item_id = shard_data.get("id", -1)
	quantity = 1  # Shards don't stack
	
	var icon_path = shard_data.get("icon_path", "")
	if icon_path != "":
		icon.texture = load(icon_path)
	else:
		icon.texture = null
	
	# Display shard name (formatted nicely)
	var display_name = shard_name.replace("_", " ").capitalize()
	label.text = "🔷 " + display_name  # Optional: add icon/symbol

# Clear the slot
func clear_item():
	item_id = -1
	quantity = 0
	is_memory_shard = false
	shard_name = ""
	icon.texture = null
	label.text = ""

# Get info about what's in this slot
func get_slot_info() -> Dictionary:
	return {
		"slot_id": slot_id,
		"item_id": item_id,
		"quantity": quantity,
		"is_memory_shard": is_memory_shard,
		"shard_name": shard_name
	}
