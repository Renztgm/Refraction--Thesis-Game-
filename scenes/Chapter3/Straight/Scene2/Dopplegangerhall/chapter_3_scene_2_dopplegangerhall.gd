extends Control

var dialogue_active: bool = true

@export var dialogue_file_path: String = "res://dialogues/doppleganger.json"
@export var npc_id: String = "Stranger"
func _ready():
	start_dialogue()

func start_dialogue():
	print("starting Dialogue")
	var dialogue_box = preload("res://scenes/UI/DialogueManager.tscn").instantiate()
	get_tree().current_scene.add_child(dialogue_box)
	dialogue_box.load_dialogue(dialogue_file_path, npc_id)
	dialogue_box.dialogue_finished.connect(_on_dialogue_finished)

func _on_dialogue_finished():
	dialogue_active = false
	FadeOutCanvas.fade_out(1.5)
	get_tree().change_scene_to_file("res://scenes/Chapter3/Straight/Scene2/Mirror Hall/Chapter3Scene2CylinderStructure_MirrorHallChallenge.tscn")
