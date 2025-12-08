extends Node3D

var quest_id: String = "rebuild_picture"
var quest_obj_array = ["piece_1","piece_2","piece_3","piece_4"]

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	FadeOutCanvas.fade_in(1)


## Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	var quest_objective_1 = QuestManager.is_objective_completed(quest_id,quest_obj_array[0])
	var quest_objective_2 = QuestManager.is_objective_completed(quest_id,quest_obj_array[1])
	var quest_objective_3 = QuestManager.is_objective_completed(quest_id,quest_obj_array[2])
	var quest_objective_4 = QuestManager.is_objective_completed(quest_id,quest_obj_array[3])
	if quest_objective_1 and quest_objective_2 and quest_objective_3 and quest_objective_4:
		show_go_back_quest("Go back on the Safehouse!")

func show_go_back_quest(quest_obj: String):
	await get_tree().create_timer(5).timeout
	ItemPopUp.show_message("Quest Update "+ quest_obj)
