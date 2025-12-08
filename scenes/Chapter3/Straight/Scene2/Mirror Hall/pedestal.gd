extends Area3D

# Each pedestal sets its own word in the Inspector
@export var chosen_word: String = "DEFAULT"
@export var what_pedestal: String = "DEFAULT_PEDESTAL" # ID ng objective
@export var hint_text: String = "DEFAULT"
@onready var label: Label3D = $Label3D
var player_in_area: Node

func _process(delta: float) -> void:
	if player_in_area and Input.is_action_just_pressed("interact"):
		_interact()

func _interact():
	var ui = preload("res://scenes/Chapter3/Straight/Scene2/Mirror Hall/hangaroo_game.tscn").instantiate()
	ui.what_pedestal = what_pedestal
	ui.chosen_word = chosen_word
	ui.hint = hint_text
	get_tree().root.add_child(ui)
	get_tree().paused = true

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		if not QuestManager.is_objective_completed("reconstruction", what_pedestal):
			player_in_area = body
			label.visible = true
			label.text = "PRESS E TO INTERACT"

func _on_body_exited(body: Node3D) -> void:
	label.visible = false
	player_in_area = null
