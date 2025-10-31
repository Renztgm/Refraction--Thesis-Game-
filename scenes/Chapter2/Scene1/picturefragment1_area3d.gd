extends Area3D  # or Area2D if you're in 2D

@export var item_id: int = 1
@export var item_name: String = "First Fragment"
@export var item_description: String = "The First Fragment of the missing picture."

func _ready():
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
	# ✅ Update quest
	QuestManager.complete_objective("rebuild_picture", str(item_id))


	# ✅ Refresh inventory UI
	var ui = get_tree().get_nodes_in_group("inventory_ui")
	if ui.size() > 0 and ui[0].active_tab == "items":
		ui[0].load_inventory()

	queue_free()
