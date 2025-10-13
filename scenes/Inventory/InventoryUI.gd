extends Control

@onready var slot_grid = $HBoxContainer/SlotGrid
@onready var item_icon = $HBoxContainer/ItemInfoPanel/ItemIcon
@onready var item_name = $HBoxContainer/ItemInfoPanel/ItemName
@onready var item_desc = $HBoxContainer/ItemInfoPanel/ItemDesc
@onready var close_button: Button = $CloseButton  # Adjust path if needed


var SlotScene = preload("res://scenes/Inventory/Slot.tscn")

func _ready():
	setup_inventory(InventoryManager.slot_count)
	load_inventory()

	if close_button:
		close_button.pressed.connect(_on_close_button_pressed)
	else:
		push_error("CloseButton not found!")
		
	setup_inventory(InventoryManager.slot_count)
	load_inventory()

func _on_close_button_pressed():
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		players[0].toggle_inventory()
	else:
		visible = false  # fallback: just hide the UI




var slot_list: Array = []

func setup_inventory(size: int):
	slot_list.clear()
	for child in slot_grid.get_children():
		child.queue_free()

	for i in range(size):
		var slot = SlotScene.instantiate()
		slot.slot_id = i
		slot_grid.add_child(slot)
		slot.button.pressed.connect(_on_slot_pressed.bind(slot))
		slot_list.append(slot)  # ✅ Store reference



func load_inventory():
	var used_slots = []
	var inv = InventoryManager.get_inventory()

	for row in inv:
		var slot_id = row["slot_id"]
		if slot_id >= slot_list.size():
			continue

		var slot = slot_list[slot_id]
		var item = InventoryManager.get_item(row["item_id"])
		if item.size() > 0:
			slot.set_item(item["name"], row["quantity"], item["icon_path"])
			used_slots.append(slot_id)

	var memory_shards = InventoryManager.get_all_memory_shards()
	var current_slot_index = 0

	for shard in memory_shards:
		while current_slot_index in used_slots:
			current_slot_index += 1

		if current_slot_index >= slot_list.size():
			break

		var slot = slot_list[current_slot_index]
		slot.set_memory_shard(shard)
		used_slots.append(current_slot_index)
		current_slot_index += 1

	print("Loaded %d items and %d memory shards" % [inv.size(), memory_shards.size()])

# --------------------------
# Item Info Panel Handling
# --------------------------
func _on_slot_pressed(slot):
	print("Slot clicked:", slot.get_slot_info())

	if slot.is_memory_shard:
		var shard = InventoryManager.get_memory_shard(slot.shard_name)
		if shard.size() > 0:
			var icon_path = shard.get("icon_path", "")
			item_icon.texture = load(icon_path) if icon_path != "" else null
			item_name.text = slot.shard_name.replace("_", " ").capitalize()
			item_desc.text = shard.get("description", "A fragment of a forgotten memory...")
			
			var location = shard.get("scene_location", "")
			if location != "":
				item_desc.text += "\n\nFound at: " + location
	
	elif slot.item_id != -1:
		var item = InventoryManager.get_item(slot.item_id)
		item_icon.texture = load(item["icon_path"])
		item_name.text = item["name"]
		item_desc.text = item.get("description", "No description.")
	
	else:
		item_icon.texture = null
		item_name.text = ""
		item_desc.text = ""

# Optional: Refresh inventory (call this after collecting a new shard)
func refresh_inventory():
	load_inventory()
