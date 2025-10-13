extends CanvasLayer

var next_scene_path = ""

func start_transition(scene_path: String):
	next_scene_path = scene_path
	$AnimationPlayer.play("fade_out")

func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	print("Animation finished:", anim_name, " -> scene path:", next_scene_path)
	
	
	if anim_name == "fade_out":
		# ✅ Log scene completion before transitioning
		if SaveManager:
			var current_scene = get_tree().current_scene.scene_file_path
			var branch_id = "scene_2"  # Use a meaningful ID for this scene
			var logged := SaveManager.log_scene_completion(current_scene, branch_id)
			if logged:
				print("📌 Scene 2 logged:", current_scene)
			else:
				print("ℹ️ Scene 2 already logged or failed to log.")

		get_tree().change_scene_to_file(next_scene_path)
