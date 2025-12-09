extends Area3D

# Each pedestal sets its own word in the Inspector
var quest_id: String = "memory_core_room"
var quest_obj_id: String = "memory_core" # ID ng objective
@onready var label: Label3D = $Label3D
var player_in_area: Node

func _process(delta: float) -> void:
	if player_in_area and Input.is_action_just_pressed("interact"):
		_interact()

func _interact():
	var ui = preload("res://scenes/Chapter4/Scene1/MinigameChapter4Scene1/Password.tscn").instantiate()
	get_tree().root.add_child(ui)
	get_tree().paused = true

func remove_screen():
	pass

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		if not QuestManager.is_objective_completed(quest_id, quest_obj_id):
			player_in_area = body
			label.visible = true
			label.text = "PRESS E TO INTERACT"

func _on_body_exited(body: Node3D) -> void:
	label.visible = false
	player_in_area = null
