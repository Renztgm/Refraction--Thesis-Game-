extends Area3D

@onready var area_3d: Area3D = $"."
var next_scene_path = "res://scenes/Chapter3/Straight/Scene2/Chapter3Scene2.tscn"

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	area_3d.body_entered.connect(_on_area_3d_body_entered)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _on_area_3d_body_entered(body: Node3D) -> void:
	if body.is_in_group("player2"):
			FadeOutCanvas.fade_out(3.0)
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
				get_tree().change_scene_to_file(next_scene_path)
			)
			t.start()
		
