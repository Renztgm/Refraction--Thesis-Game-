extends Area3D  # or Area2D if you're in 2D

@export var item_id: int = 3
@export var objective_id: String = "piece_3"
@export var item_name: String = "Third Fragment"
@export var item_description: String = "The First Fragment of the missing picture."

func _ready():
	# ✅ Check if item is already collected or objective completed
	var is_in_inventory = false
	for row in InventoryManager.get_inventory():
		if int(row["item_id"]) == item_id:
			is_in_inventory = true
			break

	var is_completed = QuestManager.is_objective_completed("rebuild_picture", objective_id)

	if is_in_inventory or is_completed:
		print("🧼 Item already collected or completed:", item_id)
		queue_free()  # ✅ Remove from scene
		return
		
	add_to_group("quest_item")
	connect("body_entered", Callable(self, "_on_body_entered"))


func _on_body_entered(body):
	#print("👤 Body entered:", body.name)
	if body.is_in_group("player"):
		print("player entered the area!")
		collect_item()
	
	if body.is_in_group("player2"):
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

	# ✅ Add to inventory
	var slot_id = InventoryManager.get_next_available_slot()
	InventoryManager.add_item(slot_id, item_id, 1)

	# ✅ Update quest
	QuestManager.complete_objective("rebuild_picture", str(objective_id))

	# ✅ Refresh inventory UIs
	var ui = get_tree().get_nodes_in_group("inventory_ui")
	if ui.size() > 0 and ui[0].active_tab == "items":
		ui[0].load_inventory()

	# Notify minimap to remove this item
	var minimap = get_tree().get_first_node_in_group("minimap_overlay")
	if minimap:
		minimap.remove_quest_item(self)
	queue_free()
