extends CanvasLayer

var next_scene_path = ""

func start_transition(scene_path: String):
	next_scene_path = scene_path
	$AnimationPlayer.play("fade_out")

func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	print("Animation finished:", anim_name, " -> scene path:", next_scene_path)
	if anim_name == "fade_out":
		get_tree().change_scene_to_file(next_scene_path)
