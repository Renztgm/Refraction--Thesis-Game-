extends Area3D

var dialogue_active: bool = false
var dialogue_triggered: bool = false

@export var dialogue_file_path: String = "res://dialogues/Chapter2Scene2TheReflection.json"
@export var npc_id: String = "Companion"

var player: Node = null

func _ready():
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0]

func start_dialogue():
	if dialogue_active or dialogue_triggered:
		return

	dialogue_active = true
	dialogue_triggered = true

	if player and player.has_method("freeze_player"):
		player.freeze_player()

	var dialogue_box = preload("res://scenes/UI/DialogueManager.tscn").instantiate()
	get_tree().current_scene.add_child(dialogue_box)

	dialogue_box.load_dialogue(dialogue_file_path, npc_id)
	dialogue_box.dialogue_finished.connect(_on_dialogue_finished)

func _on_dialogue_finished():
	dialogue_active = false
	if player and player.has_method("unfreeze_player"):
		player.unfreeze_player()		

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		var quest_completed = QuestManager.is_quest_completed("to_the_mirror_hall")
		if not quest_completed:
			QuestManager.complete_objective("to_the_mirror_hall","to_the_mirror_hall_1")
			ItemPopUp.show_message("Quest Completed: To the Mirror Hall", 0.84)
		start_dialogue()
		
		print(player)
