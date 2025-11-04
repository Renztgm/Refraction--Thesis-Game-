extends Area3D

@export var target_scene_path: String = "res://scenes/Chapter2/Scene1/Chapter2Scene1Inside.tscn"

func _ready():
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node3D) -> void:
	if body.name == "Player3d":
		SceneTransitionManager.transition_to_scene(target_scene_path)
	
