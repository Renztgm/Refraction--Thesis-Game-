extends Node3D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func _process(delta: float) -> void:
	var quest_completed = QuestManager.is_quest_completed("complete_picture")
	if quest_completed:
		await get_tree().create_timer(10).timeout
		ItemPopUp.quest_show_message("Go to Mirror District..")
		await get_tree().create_timer(5).timeout
		ItemPopUp.show_message("Take the back exit of the market!")
