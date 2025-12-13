extends Node3D

var has_shown_alley_quest = false
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if QuestManager.is_quest_active("complete_picture"):
		QuestNotification.show_quest("Complete the Picture")
	

func _process(delta: float) -> void:
	if not has_shown_alley_quest:
		var quest_completed = QuestManager.is_quest_completed("complete_picture")
		if quest_completed:
			has_shown_alley_quest = true
			await get_tree().create_timer(5).timeout
			QuestNotification.show_quest("Go to the Collapse Alley!")
