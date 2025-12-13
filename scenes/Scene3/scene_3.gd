extends Node3D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var quest_completed = QuestManager.is_quest_completed("follow_companion")
	var quest_active = QuestManager.is_quest_active("follow_companion")
	if not quest_completed:
		if not quest_active:
			QuestManager.import_quests_from_json("res://scenes/quest/resources/follow_her_quest.json")
			await get_tree().create_timer(0.3).timeout
		else: 
			push_warning("quest is active!")
		QuestNotification.show_quest("The Learned Friend")
	else: 
		push_warning("quest is completed!")
