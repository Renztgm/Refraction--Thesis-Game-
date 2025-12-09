extends Node3D

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	var quest_finished = QuestManager.is_quest_completed("follow_hum")
	var quest_active = QuestManager.is_quest_active("follow_hum")
	if not quest_finished:
		if not quest_active:
			QuestManager.import_quests_from_json("res://scenes/quest/resources/follow_the_sound.json")
			await get_tree().create_timer(0.5).timeout
			ItemPopUp.quest_show_message("Who is humming?")
		else: 
			push_warning("Quest is active")
	else: 
		push_warning("Quest is finished!")
