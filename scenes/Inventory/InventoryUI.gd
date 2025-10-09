extends Control

@onready var slot_grid = $HBoxContainer/SlotGrid
@onready var item_icon = $HBoxContainer/ItemInfoPanel/ItemIcon
@onready var item_name = $HBoxContainer/ItemInfoPanel/ItemName
@onready var item_desc = $HBoxContainer/ItemInfoPanel/ItemDesc

var SlotScene = preload("res://scenes/Inventory/Slot.tscn")

func _ready():
	setup_inventory(InventoryManager.slot_count)
	load_inventory()

func setup_inventory(size: int):
	# Remove old slots
	for child in slot_grid.get_children():
		child.queue_free()
	
	# Add new slots
	for i in range(size):
		var slot = SlotScene.instantiate()
		slot.slot_id = i
		slot_grid.add_child(slot)
		# Connect the slot's button press
		slot.button.pressed.connect(_on_slot_pressed.bind(slot))

func load_inventory():
	var current_slot_index = 0
	
	# Load regular items
	var inv = InventoryManager.get_inventory()
	for row in inv:
		if current_slot_index >= slot_grid.get_child_count():
			break
		
		var slot = slot_grid.get_child(row["slot_id"])
		var item = InventoryManager.get_item(row["item_id"])
		if item.size() > 0:
			slot.set_item(item["name"], row["quantity"], item["icon_path"])
			current_slot_index = max(current_slot_index, row["slot_id"] + 1)
	
	# Load memory shards into remaining slots
	var memory_shards = InventoryManager.get_all_memory_shards()
	for shard in memory_shards:
		if current_slot_index >= slot_grid.get_child_count():
			break
		
		var slot = slot_grid.get_child(current_slot_index)
		slot.set_memory_shard(shard)
		current_slot_index += 1
	
	print("Loaded %d items and %d memory shards" % [inv.size(), memory_shards.size()])

# --------------------------
# Item Info Panel Handling
# --------------------------
func _on_slot_pressed(slot):
	# Check if it's a memory shard
	if slot.is_memory_shard:
		var shard = InventoryManager.get_memory_shard(slot.shard_name)
		if shard.size() > 0:
			# Load shard icon
			var icon_path = shard.get("icon_path", "")
			if icon_path != "":
				item_icon.texture = load(icon_path)
			else:
				item_icon.texture = null
			
			# Display shard info
			item_name.text = slot.shard_name.replace("_", " ").capitalize()
			item_desc.text = shard.get("description", "A fragment of a forgotten memory...")
			
			# Optional: Add location info
			var location = shard.get("scene_location", "")
			if location != "":
				item_desc.text += "\n\nFound at: " + location
	
	# Regular item
	elif slot.item_id != -1:
		var item = InventoryManager.get_item(slot.item_id)
		item_icon.texture = load(item["icon_path"])
		item_name.text = item["name"]
		item_desc.text = item["description"] if "description" in item else "No description."
	
	# Empty slot
	else:
		item_icon.texture = null
		item_name.text = ""
		item_desc.text = ""

# Optional: Refresh inventory (call this after collecting a new shard)
func refresh_inventory():
	load_inventory()
