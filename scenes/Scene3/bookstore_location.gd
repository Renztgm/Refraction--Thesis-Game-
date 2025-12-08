extends Node3D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var quest_completed = QuestManager.is_quest_completed("follow_her")
	if not quest_completed:
		QuestManager.complete_objective("follow_her","follow_her_1")
		QuestManager.complete_objective("follow_her","follow_her_2")
	else:
		push_warning("the quest is completed! Follow her")
	var new_quest_completed = QuestManager.is_quest_completed("explore_the_bookstore")
	if not new_quest_completed:
		var quest_location: String = "res://scenes/quest/resources/explore_the_bookstore_quest.json"
		QuestManager.import_quests_from_json(quest_location)
		ItemPopUp.quest_show_message("Secrets in the Stacks")	
