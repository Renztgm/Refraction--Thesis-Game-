extends Node3D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	FadeOutCanvas.fade_in(1.5)
	quest_completed()

func quest_completed():
	var is_obj_completed = QuestManager.is_objective_completed("aligning_the_picture","go_inside_the_cylinder_structure")
	if not is_obj_completed: #true skip else proceed the if else...
		QuestManager.complete_objective("aligning_the_picture", "go_inside_the_cylinder_structure" )
		ItemPopUp.show_message("Quest Update: Align the picture")
