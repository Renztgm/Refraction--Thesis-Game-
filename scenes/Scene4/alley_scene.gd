extends Node3D

@onready var dialogue_manager: Control = $DialogueManager
@onready var player: CharacterBody3D = $Player3d

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	FadeOutCanvas.fade_in(1.0)
	start_dialogue()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func start_dialogue():
	if player.has_method("freeze_player"):
		player.freeze_player()
	else: 
		push_error("player doesnt have the freeze-player method")
	
	dialogue_manager.load_dialogue("res://dialogues/to_the_safehouse.json", "Companion")
	await dialogue_manager.dialogue_finished
	dialogue_finished()
func dialogue_finished():
	if player.has_method("unfreeze_player"):
		player.unfreeze_player()
	else: 
		push_error("player doesnt have the unfreeze-player method")
