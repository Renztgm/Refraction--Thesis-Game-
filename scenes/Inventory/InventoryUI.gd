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
	var inv = InventoryManager.get_inventory()
	for row in inv:
		var slot = slot_grid.get_child(row["slot_id"])
		var item = InventoryManager.get_item(row["item_id"])
		slot.set_item(item["name"], row["quantity"], item["icon_path"])

# --------------------------
# Item Info Panel Handling
# --------------------------
func _on_slot_pressed(slot):
	if slot.item_id != -1: # slot has an item
		var item = InventoryManager.get_item(slot.item_id)
		item_icon.texture = load(item["icon_path"])
		item_name.text = item["name"]
		item_desc.text = item["description"] if "description" in item else "No description."
	else:
		item_icon.texture = null
		item_name.text = ""
		item_desc.text = ""
