extends Node3D

var dialogue_active: bool = false
var dialogue_triggered: bool = false

@export var dialogue_file_path: String = "res://dialogues/Chapter3Scene2.json"
@export var npc_id: String = "Companion"

@export var dialogue_area_path: NodePath
@export var interact_label_path: NodePath

@onready var dialogue_area: Area3D = get_node_or_null(dialogue_area_path)
@onready var interact_label: Node = get_node_or_null(interact_label_path)

var player: Node = null

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	FadeOutCanvas.fade_in(1.5)
	start_dialogue()


## Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta: float) -> void:
	#pass


func start_dialogue():
	if dialogue_active or dialogue_triggered:
		return

	dialogue_active = true
	dialogue_triggered = true

	if player and player.has_method("freeze_player"):
		player.freeze_player()

	if interact_label:
		interact_label.visible = false

	var dialogue_box = preload("res://scenes/UI/DialogueManager.tscn").instantiate()
	get_tree().current_scene.add_child(dialogue_box)

	dialogue_box.load_dialogue(dialogue_file_path, npc_id)
	dialogue_box.dialogue_finished.connect(_on_dialogue_finished)

func _on_dialogue_finished():
	dialogue_active = false
	if player and player.has_method("unfreeze_player"):
		player.unfreeze_player()
	FadeOutCanvas.fade_out(1)
	get_tree().change_scene_to_file("res://scenes/Chapter3/Straight/Scene2/Chapter3Scene2.tscn")
		
