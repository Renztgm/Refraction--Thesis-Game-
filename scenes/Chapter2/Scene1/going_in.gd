extends Area3D

@export var target_scene_path: String = "res://scenes/Chapter2/Scene1/Chapter2Scene1Inside.tscn"

func _ready():
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node3D) -> void:
	if body.name == "Player3d":
		# ✅ Log scene completion for branching system
		ItemPopUp.show_message("Saving...")
		# ✅ Save current game state (player position, scene, etc.)
		if SaveManager:
			var saved := SaveManager.save_game()
			if saved:
				print("💾 Game state saved successfully")
			else:
				print("❌ Failed to save game state")
		get_tree().change_scene_to_file("res://scenes/Chapter2/Scene1/Chapter2Scene1Inside.tscn")

	
