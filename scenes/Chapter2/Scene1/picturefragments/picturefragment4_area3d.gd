extends Area3D

@export var item_id: int = 4
@export var objective_id: String = "piece_4"
@export var item_name: String = "Fourth Fragment"
@export var item_description: String = "The Fourth Fragment of the missing picture."

func _ready():
	# ✅ Check if item is already in inventory
	for row in InventoryManager.get_inventory():
		if row.has("item_id") and int(row["item_id"]) == item_id:
			print("🧼 Item already in inventory:", item_id)
			queue_free()
			return

	# ✅ Optional: check if objective is completed
	if QuestManager.is_objective_completed("rebuild_picture", objective_id):
		print("🧼 Objective already completed:", objective_id)
		queue_free()
		return
	
	add_to_group("quest_item")
	connect("body_entered", Callable(self, "_on_body_entered"))

	# ✅ Debug: confirm setup
	print("📦 Quest item ready:", item_name, "ID:", item_id)


func _on_body_entered(body):
	print("👤 Body entered:", body.name)
	if body.is_in_group("player"):
		print("✅ Player detected, collecting item")
		collect_item()
	elif body.is_in_group("player2"):
		print("✅ Player detected, collecting item")
		collect_item()


func collect_item():
	print("🎒 Collecting item:", item_id)

		
	var icon_path = "res://assets/icons/picturefragment4.png"
	if not ResourceLoader.exists(icon_path):
		icon_path = "res://assets/icons/default.png"

	var item_data = {
		"id": item_id,
		"name": item_name,
		"description": item_description,
		"icon_path": icon_path,
		"stack_size": 1,
		"is_completed": true
	}

	InventoryManager.save_item_to_items_table(item_data)

	var slot_id = InventoryManager.get_next_available_slot()
	InventoryManager.add_item(slot_id, item_id, 1)

	QuestManager.complete_objective("rebuild_picture", objective_id)

	var ui = get_tree().get_nodes_in_group("inventory_ui")
	if ui.size() > 0 and ui[0].active_tab == "items":
		ui[0].load_inventory()

	# Notify minimap to remove this item
	var minimap = get_tree().get_first_node_in_group("minimap_overlay")
	if minimap:
		minimap.remove_quest_item(self)
	queue_free()
