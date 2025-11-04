extends Area3D

@export var item_id: int = 1
@export var objective_id: String = "piece_1"
@export var item_name: String = "First Fragment"
@export var item_description: String = "The First Fragment of the missing picture."

func _ready():
	add_to_group("quest_item")

	# ✅ Check if objective is already completed
	var is_completed := QuestManager.is_objective_completed("rebuild_picture", objective_id)
	if is_completed:
		print("🧼 Objective already completed:", objective_id)

		var minimap = get_node("root/Minimap/MinimapGridOverlay")
		if minimap and minimap.has_method("remove_quest_item"):
			print("📡 Found minimap:", minimap.name)
			minimap.remove_quest_item(self)
		else:
			print("⚠️ Minimap not found or missing method")



		queue_free()
		return

	connect("body_entered", Callable(self, "_on_body_entered"))

func _on_body_entered(body):
	print("👤 Body entered:", body.name)
	if body.is_in_group("player"):
		collect_item()

func collect_item():
	print("🎒 Collecting item:", item_id)

	var icon_path = "res://assets/icons/picturefragment1.png"
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

	QuestManager.complete_objective("rebuild_picture", str(objective_id))

	var ui = get_tree().get_nodes_in_group("inventory_ui")
	if ui.size() > 0 and ui[0].active_tab == "items":
		ui[0].load_inventory()

	# ✅ Notify minimap to remove this item
	var minimap = get_tree().get_first_node_in_group("minimap_overlay")
	if minimap:
		print("📡 Removing item from minimap (collected):", item_name)
		minimap.remove_quest_item(self)
	else:
		print("⚠️ Minimap not found in group 'minimap_overlay'")

	queue_free()
