extends Node2D

@onready var fragments: Array[Sprite2D] = [
	$"../FragmentsContainer/Fragment1",
	$"../FragmentsContainer/Fragment2",
	$"../FragmentsContainer/Fragment3",
	$"../FragmentsContainer/Fragment4"
]

@onready var completion_label: Label = $"../CompletionLabel"
@export var objective_id: String = "assemble_picture"

var puzzle_solved: bool = false
var puzzle_locked: bool = false   # NEW FLAG

func _ready():
	completion_label.text = ""  
	disassemble_picture()  

func _process(delta):
	if not puzzle_solved and is_puzzle_complete():
		puzzle_solved = true
		puzzle_locked = true
		completion_label.text = ""
		ItemPopUp.show_message("Picture Obtained!")
		QuestManager.complete_objective("complete_picture", str(objective_id))
		remove_old_items()
		var workbench_root = get_parent()  # PuzzleManager is child of Workingbench
		if workbench_root:
			# Wait 10 seconds before starting fade
			await get_tree().create_timer(3.0).timeout

			# Fade out over 3 seconds
			FadeOutCanvas.fade_out(3.0)

			# Wait for fade to finish
			await get_tree().create_timer(3.0).timeout

			# Now free the UI
			workbench_root.queue_free()

			# Optional: fade back in if you want to return to gameplay
			FadeOutCanvas.fade_in(1.0)

func disassemble_picture():
	var rng = RandomNumberGenerator.new()
	rng.randomize()

	for frag in fragments:
		if frag == null:
			continue
		frag.position = Vector2(
			rng.randf_range(0, 512),   # scatter within puzzle area
			rng.randf_range(0, 512)
		)
		print("Scattered", frag.name, "to", frag.position)

func is_puzzle_complete() -> bool:
	for frag in fragments:
		if frag == null:
			continue
		# Compare against each fragment’s own correct_position
		if frag.position.distance_to(frag.correct_position) > 1.0:
			return false
	return true
	
func remove_old_items():
		InventoryManager.remove_item_id(1)
		InventoryManager.remove_item_id(2)
		InventoryManager.remove_item_id(3)
		InventoryManager.remove_item_id(4)
		InventoryManager.remove_item_id(10)
		picture_obtained()
		
func picture_obtained():
	var item_id = 11
	var item_name = "Picture of the Past"
	var item_description = "“One breathes without breathing,
		One watches without seeing.
		One lies in stillness,
		One walks in dreaming.
		When the path of the waking touches the path of the slept,
		There, your truth is kept.”"

	var icon_path = "res://assets/icons/default.png"
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

	ItemPopUp.show_message("📦 Collected: " + objective_id, 2.0, Color.GREEN)

	var ui = get_tree().get_nodes_in_group("inventory_ui")
	if ui.size() > 0 and ui[0].active_tab == "items":
		ui[0].load_inventory()
