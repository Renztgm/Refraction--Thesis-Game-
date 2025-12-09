extends Area3D

@onready var area_3d: Area3D = $"."
var next_scene_path = "res://scenes/Chapter3/Straight/Scene2/Chapter3Scene2A.tscn"
var fallback_scene = "res://scenes/UI/GameNotFinished.tscn"

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	area_3d.body_entered.connect(_on_area_3d_body_entered)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _on_area_3d_body_entered(body: Node3D) -> void:
	if body.is_in_group("player2"):
			FadeOutCanvas.fade_out(1.5)
				# ✅ Save current game state (player position, scene, etc.)
			if SaveManager:
				var saved := SaveManager.save_game()
				if saved:
					print("💾 Game state saved successfully")
				else:
					print("❌ Failed to save game state")
			# ✅ Log scene completion for branching system
			ItemPopUp.show_message("Saving...")
			if SaveManager:
				var scene_path = get_tree().current_scene.scene_file_path
				var branch_id = "Chapter2 Scene 1"  # You can use a meaningful ID like the BranchNode title or event name
				var logged := SaveManager.log_scene_completion(scene_path, branch_id)
				if logged:
					print("📌 Scene logged to game_path:", scene_path)
				else:
					print("ℹ️ Scene already logged or failed to log.")

			var t := Timer.new()
			t.wait_time = 3.0
			t.one_shot = true
			add_child(t)
			t.timeout.connect(func():
				var next_scene: PackedScene = load(next_scene_path)
				var instanced_scene: Node = next_scene.instantiate()

				if instanced_scene.get_child_count() == 0:
					# If the next scene has no children
					get_tree().change_scene_to_file(fallback_scene)
				else:
					# Otherwise go to the next scene
					get_tree().change_scene_to_file(next_scene_path)
			)
			t.start()
		
