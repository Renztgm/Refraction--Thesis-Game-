extends Control

@onready var slot_grid = $HBoxContainer/SlotGrid
@onready var item_icon = $HBoxContainer/ItemInfoPanel/ItemIcon
@onready var item_name = $HBoxContainer/ItemInfoPanel/ItemName
@onready var item_desc = $HBoxContainer/ItemInfoPanel/ItemDesc
@onready var close_button: Button = $CloseButton
@onready var item_tab_button: Button = $HBoxContainer2/Items
@onready var shard_tab_button: Button = $HBoxContainer2/Shards

var SlotScene = preload("res://scenes/Inventory/Slot.tscn")
var slot_list: Array = []
var active_tab: String = "items"  # "items" or "shards"

func _ready():
	add_to_group("inventory_ui")
	
	if close_button:
		close_button.pressed.connect(_on_close_button_pressed)
	else:
		push_error("CloseButton not found!")

	item_tab_button.pressed.connect(_on_item_tab_pressed)
	shard_tab_button.pressed.connect(_on_shard_tab_pressed)
	
	var items = InventoryManager.get_all_items()
	print("📚 Items table:", items)

	var inventory = InventoryManager.get_all_inventory_slots()
	print("📦 Inventory table:", inventory)
	
	setup_inventory(InventoryManager.slot_count)
	load_inventory()
	apply_tab_highlight()  # ✅ Apply highlight on open
	
func _on_close_button_pressed():
	var players = get_tree().get_nodes_in_group("player")
	if players.size() == 0:
		players = get_tree().get_nodes_in_group("player2")

	for player in players:
		if player.has_method("toggle_inventory"):
			player.toggle_inventory()
			break
		else:
			print("Node in group does not have toggle_inventory:", player)

	if players.size() == 0 or not players.any(func(p): return p.has_method("toggle_inventory")):
		visible = false

	print("Napindot ung close!")

func _on_item_tab_pressed():
	active_tab = "items"
	apply_tab_highlight()
	refresh_inventory()

func _on_shard_tab_pressed():
	active_tab = "shards"
	apply_tab_highlight()
	refresh_inventory()

func setup_inventory(size: int):
	slot_list.clear()
	for child in slot_grid.get_children():
		child.queue_free()

	for i in range(size):
		var slot = SlotScene.instantiate()
		slot.slot_id = i
		slot_grid.add_child(slot)
		slot.button.pressed.connect(_on_slot_pressed.bind(slot))
		slot_list.append(slot)

func load_inventory():
	# Clear existing slots
	for child in slot_grid.get_children():
		child.queue_free()
	slot_list.clear()

	# Create fresh slots
	for i in range(InventoryManager.slot_count):
		var slot = SlotScene.instantiate()
		slot.slot_id = i
		slot_grid.add_child(slot)
		slot.button.pressed.connect(_on_slot_pressed.bind(slot))
		slot_list.append(slot)

	var used_slots = []
	var current_slot_index = 0

	if active_tab == "items":
		var all_items = InventoryManager.get_all_items()
		var inventory = InventoryManager.get_inventory()

		for item in all_items:
			var objective_id = str(item["id"])
			var is_completed = QuestManager.is_objective_completed("rebuild_picture", objective_id)

			var is_in_inventory = false
			for row in inventory:
				if str(row["item_id"]) == objective_id:
					is_in_inventory = true
					break

			if not is_in_inventory:
				continue  # ✅ Only show items that are actually in inventory

			while current_slot_index in used_slots:
				current_slot_index += 1
			if current_slot_index >= slot_list.size():
				break

			var slot = slot_list[current_slot_index]
			slot.set_item(item["name"], 1, item["icon_path"])
			slot.item_id = item["id"]
			used_slots.append(current_slot_index)
			current_slot_index += 1



	elif active_tab == "shards":
		var memory_shards = InventoryManager.get_all_memory_shards()
		for shard in memory_shards:
			while current_slot_index in used_slots:
				current_slot_index += 1
			if current_slot_index >= slot_list.size():
				break

			var slot = slot_list[current_slot_index]
			slot.set_memory_shard(shard)
			used_slots.append(current_slot_index)
			current_slot_index += 1

	print("📦 Loaded tab:", active_tab)


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




func apply_tab_highlight():
	if active_tab == "items":
		item_tab_button.modulate = Color(0.7, 0.7, 0.7)  # Darker
		shard_tab_button.modulate = Color(1, 1, 1)       # Normal
	else:
		item_tab_button.modulate = Color(1, 1, 1)
		shard_tab_button.modulate = Color(0.7, 0.7, 0.7)


func refresh_inventory():
	load_inventory()
