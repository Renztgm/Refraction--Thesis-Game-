extends Node3D

@export var dialogue_manager_scene: PackedScene
@export var dialogue_file: String = "res://dialogues/EchoBeast.json"
@export var npc_id: String = "EchoBeast"
var next_scene_path: String = "res://scenes/Chapter3/Straight/Scene1/Chapter3Scene1.tscn"

@onready var player = get_tree().get_first_node_in_group("player")

var quest_id: String = "go_to_mirror_district"
var quest_objective: String = "escape_the_beast"
@onready var dialogue_manager: Control = $DialogueManager

func _ready():
	start_dialogue()

func start_dialogue():
	player.freeze_player()
	var dialogue_manager = get_tree().root.get_node("Chapter3Scene1Dialogue/DialogueManager")
	QuestManager.complete_objective(quest_id, quest_objective)
	var quest_is = QuestManager.is_quest_completed(quest_id)
	if quest_is:
		ItemPopUp.show_message("📦 Collected: " + quest_objective, 2.0, Color.GREEN)

	dialogue_manager.load_dialogue(dialogue_file, npc_id)
	dialogue_manager.show_node("start")
	dialogue_manager.show()

	if not dialogue_manager.is_connected("dialogue_finished", Callable(self, "_on_dialogue_finished")):
		dialogue_manager.connect("dialogue_finished", Callable(self, "_on_dialogue_finished"))
		
func _on_dialogue_finished():
	player.unfreeze_player()

	FadeOutCanvas.fade_out(3.0)

	var t := Timer.new()
	t.wait_time = 3.0
	t.one_shot = true
	add_child(t)
	t.timeout.connect(func():
		get_tree().change_scene_to_file(next_scene_path)
	)
	t.start()
