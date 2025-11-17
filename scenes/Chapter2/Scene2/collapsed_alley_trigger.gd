extends Area3D

# Path to the scene you want to load
@export var next_scene_path: String = "res://scenes/UI/endchapterscene.tscn"
var quest_id: String = "go_to_mirror_district"
func _ready() -> void:
	# Connect the signal when a body enters the Area3D
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player2"):
		var is_true: bool = QuestManager.quest_exists(quest_id)
		if is_true: 
			go_to_end_chapter()
			FadeOutCanvas.fade_in(5.0)
		else:
			ItemPopUp.show_message("Incorrect path taken please go to another one!" , 2.0, Color.DARK_RED)


func go_to_end_chapter():
	# Fade to black
	#if fade_overlay:
		#fade_overlay.color = Color(0, 0, 0, 0)
		#var tween = create_tween()
		#tween.tween_property(fade_overlay, "color", Color(0, 0, 0, 1), 1.5)
		#await tween.finished

	# ✅ Log scene completion
	if SaveManager:
		var scene_path = get_tree().current_scene.scene_file_path
		var branch_id = "chapter_2_scene_7"
		var logged := SaveManager.log_scene_completion(scene_path, branch_id)
		if logged:
			print("📌 Chapter 2 Scene 3 logged:", scene_path)
		else:
			print("ℹ️ Chapter 2 Scene 3 already logged or failed to log.")

		# ✅ Set chapter info for next scene
		SaveManager.set_current_chapter(2)
		SaveManager.set_next_scene_path("res://scenes/Chapter3/Straight/Scene1/Chapter3Scene1.tscn")

	# Load end chapter scene
	get_tree().change_scene_to_file("res://scenes/UI/endchapterscene.tscn")
