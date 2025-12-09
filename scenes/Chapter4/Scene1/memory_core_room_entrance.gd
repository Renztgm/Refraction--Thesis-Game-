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
		
		get_tree().change_scene_to_file(next_scene)
		
