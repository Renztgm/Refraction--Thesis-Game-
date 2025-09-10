# EntranceArea.gd
extends Area3D   # or Area3D if 3D

@export var target_scene: String = "res://scenes/NarativeScenes/Bookstore.tscn"

func _ready():
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	if body.is_in_group("player"):
		print("Player entered building -> switching to scene: ", target_scene)
		get_tree().change_scene_to_file(target_scene)
