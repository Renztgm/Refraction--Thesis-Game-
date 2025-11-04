extends CharacterBody3D

@export var npc_id: String = "Lyra"
@export var dialogue_file: String = "res://dialogues/picture_fragment_quest.json"

@export var gives_quest: bool = true
@export var quest_json_path: String = "res://scenes/quest/resources/quest.json"
@export var quest_id: String = "rebuild_picture"

var player_in_range: bool = false
var dialogue_started: bool = false
var player_ref: Node = null

func _ready() -> void:
	$Area3D.body_entered.connect(_on_body_entered)
	$Area3D.body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		player_in_range = true
		player_ref = body

		if not dialogue_started:
			dialogue_started = true
			if player_ref.has_method("freeze_player"):
				player_ref.freeze_player()
			start_dialogue()

func _on_body_exited(body: Node) -> void:
	if body.is_in_group("player"):
		player_in_range = false

func _input(event: InputEvent) -> void:
	if player_in_range and event.is_action_pressed("interact") and not dialogue_started:
		dialogue_started = true
		if player_ref and player_ref.has_method("freeze_player"):
			player_ref.freeze_player()
		start_dialogue()

func start_dialogue() -> void:
	var dialogue_manager = get_tree().root.get_node_or_null("Chapter2Scene1/DialogueManager")
	if not dialogue_manager:
		push_error("❌ DialogueManager not found!")
		return

	dialogue_manager.load_dialogue(dialogue_file, npc_id)

	# ✅ Check quest status
	if QuestManager.active_quests.has(quest_id):
		var quest = QuestManager.active_quests[quest_id]
		if quest.get("is_completed", false):
			dialogue_manager.show_node("quest_done")
		else:
			dialogue_manager.show_node("quest_active")
	else:
		dialogue_manager.show_node("start")  

	dialogue_manager.show()

	if not dialogue_manager.is_connected("dialogue_finished", Callable(self, "_on_dialogue_finished")):
		dialogue_manager.connect("dialogue_finished", Callable(self, "_on_dialogue_finished"))

func _on_dialogue_finished() -> void:
	if player_ref and player_ref.has_method("unfreeze_player"):
		player_ref.unfreeze_player()

	if gives_quest and not QuestManager.active_quests.has(quest_id):
		QuestManager.import_quests_from_json(quest_json_path)
		QuestManager.load_all_quests()
		QuestManager.save_all_quests()

		if QuestManager.active_quests.has(quest_id):
			print("🧭 Quest received: " + quest_id)
