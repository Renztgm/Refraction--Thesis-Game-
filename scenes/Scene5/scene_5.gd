extends Node3D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var quest_completed = QuestManager.is_quest_completed("talk_to_companion")
	if not quest_completed:
		QuestManager.import_quests_from_json("")
		ItemPopUp.quest_show_message("")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
