extends Area3D


@onready var label3d: Label3D = $Label3D
# Reference to the player when inside
var player_in_area: Node = null
@export var objective_id: String = "go_to_market_shop"
@onready var player_node = get_tree().get_first_node_in_group("player")

func _ready() -> void:
	# Connect signals for entering/exitinga
	connect("body_entered", Callable(self, "_on_body_entered"))
	connect("body_exited", Callable(self, "_on_body_exited"))

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"): # Make sure your player is in "player" group
		player_in_area = body
		QuestManager.complete_objective("complete_picture", str(objective_id))
		print("Player(player) entered workbench area")
		show_text("Press E to interact")


func _on_body_exited(body: Node) -> void:
	if body == player_in_area:
		player_in_area = null
		print("Player left workbench area")
		hide_text()

func _process(delta: float) -> void:
	if player_in_area and Input.is_action_just_pressed("interact"):
		_interact()

func _interact() -> void:
	print("Workbench interaction triggered!")
	var has_scotch_tape: bool = InventoryManager.has_item(10)
	var quest_done: bool = QuestManager.is_quest_completed("complete_picture")
	var quest_exist: bool = QuestManager.quest_exists("complete_picture")
	var dialogue: String = "res://dialogues/complete_picture_dialogue.json"
	var dialogue_name = "You"
	
	var dialogue_manager = get_node("../../DialogueManager")
	
	#if not quest_exist:
		#dialogue_manager.load_dialogue(dialogue, dialogue_name)
		#dialogue_manager.show_node("quest_not_exist")
		#return
	#
	#if quest_done:
		#if dialogue_manager:
			#print("quest_done dialogue triggered")
			#dialogue_manager.load_dialogue(dialogue, dialogue_name)
			#dialogue_manager.show_node("quest_already_done")
		#return

	if not has_scotch_tape:
		if dialogue_manager:
			print("has_scotch_tape dialogue triggered")
			dialogue_manager.load_dialogue(dialogue, dialogue_name)
			dialogue_manager.show_node("need_scotch_tape")
		return



	# ✅ If both conditions pass → open workbench
	var ui = preload("res://scenes/Chapter2/Scene2/WorkingBench.tscn").instantiate()
	get_tree().root.add_child(ui)
	dialogue_manager.load_dialogue(dialogue, dialogue_name)
	dialogue_manager.show_node("complete_quest")
	player_node.freeze_player()
	if not dialogue_manager.is_connected("dialogue_finished", Callable(self, "_on_dialogue_finished")):
		dialogue_manager.connect("dialogue_finished", Callable(self, "_on_dialogue_finished"))

func _on_dialogue_finished():
	player_node.unfreeze_player()

func show_text(msg: String):
	label3d.text = msg
	label3d.visible = true

func hide_text():
	label3d.visible = false
