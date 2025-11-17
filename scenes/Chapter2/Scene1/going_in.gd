extends Area3D

@export var target_scene_path: String = "res://scenes/Chapter2/Scene1/Chapter2Scene1Inside.tscn"

func _ready():
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node3D) -> void:
	if body.name == "Player3d":
		# ✅ Log scene completion for branching system
		ItemPopUp.show_message("Saving...")
		if SaveManager:
			var scene_path = get_tree().current_scene.scene_file_path
			var branch_id = "Chapter2 Scene 3"  # You can use a meaningful ID like the BranchNode title or event name
			var logged := SaveManager.log_scene_completion(scene_path, branch_id)
			if logged:
				print("📌 Scene logged to game_path:", scene_path)
				SceneTransitionManager.transition_to_scene(target_scene_path)
			else:
				print("ℹ️ Scene already logged or failed to log.")
