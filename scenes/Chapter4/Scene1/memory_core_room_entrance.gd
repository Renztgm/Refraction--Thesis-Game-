extends Area3D

var next_scene: String = "res://scenes/Chapter4/Scene2/Chapter4Scene2MemoryCoreRoom.tscn"
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		print("player is on the area")
		FadeOutCanvas.fade_out(1)
		await get_tree().create_timer(2.0).timeout
		var scene_log = "res://scenes/Chapter4/Scene1/Chapter4Scene1.tscn"
		if SaveManager:
			var saved := SaveManager.save_game()
			if saved:
				print("💾 Game state saved successfully")
			else:
				print("❌ Failed to save game state")

		# ✅ Log scene completion for branching system
		if SaveManager:
			var branch_id = "chapter_4_scene_1"
			var logged := SaveManager.log_scene_completion(scene_log, branch_id)
			if logged:
				print("logged:", scene_log)
			else:
				print(scene_log, " already logged or failed to log.")
		get_tree().change_scene_to_file(next_scene)
		
