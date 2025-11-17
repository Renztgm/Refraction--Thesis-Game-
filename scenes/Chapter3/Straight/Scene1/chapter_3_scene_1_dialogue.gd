extends Node3D

@export var dialogue_manager_scene: PackedScene
@export var dialogue_file: String = "res://dialogues/EchoBeast.json"
@export var npc_id: String = "EchoBeast"
var next_scene_path: String = "res://scenes/Chapter3/Straight/Scene1/Chapter3Scene1.tscn"

@onready var dialogue_manager: Control = $DialogueManager

func _ready():
	# Instance the DialogueManager scene
	start_dialogue()
	
func start_dialogue():
	var dialogue_manager = get_tree().root.get_node("Chapter3Scene1Dialogue/DialogueManager")

	# Now dialogue_manager really has those functions
	dialogue_manager.load_dialogue(dialogue_file, npc_id)
	dialogue_manager.show_node("start")
	dialogue_manager.show()

	if not dialogue_manager.is_connected("dialogue_finished", Callable(self, "_on_dialogue_finished")):
		dialogue_manager.connect("dialogue_finished", Callable(self, "_on_dialogue_finished"))
		
func _on_dialogue_finished():
	FadeOutCanvas.fade_out(3.0)

	var t := Timer.new()
	t.wait_time = 3.0
	t.one_shot = true
	add_child(t)
	t.timeout.connect(func():
		get_tree().change_scene_to_file(next_scene_path)
	)
	t.start()

	
