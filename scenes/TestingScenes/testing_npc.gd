extends Node3D

@export var npc_id: String = "old_man"
@export var dialogue_file: String = "res://dialogues/test.json"

var player_in_range = false

func _ready():
	$Area3D.body_entered.connect(_on_body_entered)
	$Area3D.body_exited.connect(_on_body_exited)

func _on_body_entered(body):
	if body.is_in_group("player"):
		player_in_range = true

func _on_body_exited(body):
	if body.is_in_group("player"):
		player_in_range = false

func _input(event):
	if player_in_range and event.is_action_pressed("interact"):
		start_dialogue()

func start_dialogue():
	var dialogue_manager = get_tree().root.get_node("TestingGrounds/CanvasLayer/DialogueManager")
	dialogue_manager.load_dialogue("res://dialogues/test.json", "Juan")
	dialogue_manager.show_node("start")
	dialogue_manager.show()
