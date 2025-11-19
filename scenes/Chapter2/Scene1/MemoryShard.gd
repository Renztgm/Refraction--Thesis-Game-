extends Area3D

@export var shard_name: String = "memory_shard_2"
@export var shard_text: String = "A crumpled market receipt. The ink's mostly gone, but one line remains: 'Two apples. One promise.' You remember the crisp autumn air and the weight of a secret shared on a day of small purchases. Someone held your hand, their thumb tracing patterns on your skin. The memory is sharp with the bittersweet ache of a vow kept or broken."
@export var shard_texture: Texture2D = preload("res://addons/pngs/shard.png")
@export var quest_id: String = "collect_memory_shards" # optional if you use quests elsewhere
@export var objective_id: String = "memory_shard_2"     # optional
@export var shard_scene_location: String = "Outside"

func _ready():
	add_to_group("quest_item")

	# Ensure Area3D can detect overlaps
	monitoring = true
	monitorable = true

	# Safe check: if already collected, remove immediately
	if InventoryManager.has_memory_shard(shard_name):
		print("🧼 Shard already collected:", shard_name)
		remove_minimap_marker()
		queue_free()
		return

	connect("body_entered", Callable(self, "_on_body_entered"))

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		collect_shard()

func collect_shard() -> void:
	# Guard: InventoryManager autoload must exist
	if not InventoryManager:
		print("ERROR: Cannot save memory shard - InventoryManager not available")
		return

	# Double-check to avoid duplicates
	if InventoryManager.has_memory_shard(shard_name):
		print("⚠️ Shard already collected, skipping:", shard_name)
		queue_free()
		return

	print("💎 Collecting shard:", shard_name)

	var icon_path := shard_texture.resource_path if shard_texture else ""
	var success := InventoryManager.save_memory_shard(
		shard_name,
		shard_text,
		icon_path,
		shard_scene_location
	)

	if success:
		ItemPopUp.show_message("📦 Collected: " + shard_name, 2.0, Color.CYAN)
	else:
		print("⚠️ Shard already collected:", shard_name)

	# Optionally refresh inventory UI if open
	var ui := get_tree().get_nodes_in_group("inventory_ui")
	if ui.size() > 0 and ui[0].active_tab == "items":
		ui[0].load_inventory()

	remove_minimap_marker()
	queue_free()

func remove_minimap_marker() -> void:
	var minimap_root := get_tree().get_first_node_in_group("minimap")
	if not minimap_root:
		return

	for child in minimap_root.get_children():
		if child.is_in_group("minimap_overlay") and child.has_method("remove_quest_item"):
			child.remove_quest_item(get_parent())
			return
