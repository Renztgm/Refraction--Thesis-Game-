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
		var objectives = quest.get("objectives", {})

		# If quest is fully completed
		if quest.get("is_completed", false):
			dialogue_manager.show_node("quest_done")

		# If all pieces are collected, mark go_back_quest_1 as completed
		elif _all_pieces_collected(objectives):
			if objectives.has("go_back_quest_1"):
				objectives["go_back_quest_1"]["is_completed"] = true
				QuestManager.active_quests[quest_id]["objectives"] = objectives
				QuestManager.save_all_quests()
				print("✅ Objective completed: go_back_quest_1")

			# Now show quest_done dialogue since return objective is satisfied
			dialogue_manager.show_node("quest_done")

		else:
			# Quest is active but not all objectives done
			dialogue_manager.show_node("quest_active")
	else:
		# Quest not yet started
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
		
		var quest = QuestManager.active_quests.get(quest_id, {})
		var quest_title = quest.get("title", quest_id)
		print("🧭 Quest received: " + quest_id)
		ItemPopUp.show_message("🧭 New Quest Started: " + quest_title, 3.0, Color.CYAN)

	if QuestManager.active_quests.has(quest_id):
		var quest = QuestManager.active_quests[quest_id]
		var objectives: Array = quest.get("objectives", [])

		# ✅ If all pieces are collected, complete go_back_quest_1
		if _all_pieces_collected(objectives):
			for obj in objectives:
				if obj.get("id", "") == "go_back_quest_1" and not obj.get("is_completed", false):
					obj["is_completed"] = true
					print("✅ Objective completed: go_back_quest_1")

			QuestManager.active_quests[quest_id]["objectives"] = objectives
			QuestManager.save_all_quests()

			# ✅ If all objectives are now complete, mark quest as completed
			var all_done := true
			for obj in objectives:
				if not obj.get("is_completed", false):
					all_done = false
					break
			if all_done:
				quest["is_completed"] = true
				QuestManager.active_quests[quest_id] = quest
				var quest_title = quest.get("title", quest_id)
				QuestManager.save_all_quests()
				print("🎉 Quest completed: " + quest_id)
				ItemPopUp.show_message("🎉 Quest " + quest_title + " Completed")
				
		# Check if quest is fully completed
		if quest.get("is_completed", false):
			var next_scene_path = "res://scenes/Chapter2/Scene2/Chapter2Scene2.tscn"
			
			print("🎬 Transitioning to next scene: ", next_scene_path)
			
			await get_tree().create_timer(1.0).timeout
			
			SceneTransitionManager.transition_to_scene(next_scene_path)



func _all_pieces_collected(objectives: Array) -> bool:
	var required_pieces = ["piece_1", "piece_2", "piece_3", "piece_4"]
	for piece_id in required_pieces:
		var found := false
		for obj in objectives:
			if obj.get("id", "") == piece_id and obj.get("is_completed", false):
				found = true
				break
		if not found:
			return false
	return true
