extends Area3D

@export var target_scene_path: String = "res://scenes/Chapter2/Scene2/Chapter2Scene2.tscn"
@export var default_scene_path: String = "res://scenes/Chapter2/Scene1/Chapter2Scene1Outside.tscn"
@export var required_quest_id: String = "rebuild_picture"

func _ready():
	body_entered.connect(_on_body_entered)
"res://scenes/Chapter2/Scene2/Chapter2Scene2.tscn"

func _on_body_entered(body: Node3D) -> void:
	if body.name != "Player3d":
		return

	var save_manager := get_node("/root/SaveManager")  # Adjust path if needed
	SceneTransitionManager.transition_to_scene(default_scene_path)
