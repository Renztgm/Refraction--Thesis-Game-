extends Node3D

@export var npc_id: String = "Companion"
@export var dialogue_file: String = "res://dialogues/CompanionScene2.json"
@onready var hum_player: AudioStreamPlayer3D = $hum_player

var player_in_range = false
var dialogue_started = false
var player_ref: Node = null  # store reference to player

func _ready():
	hum_player.stream = preload("res://assets/audio/ambient/humming.mp3")
	hum_player.stream.loop = true
	hum_player.attenuation_model = AudioStreamPlayer3D.ATTENUATION_DISABLED
	hum_player.unit_size = 5.0
	hum_player.max_distance = 100.0
	hum_player.volume_db = -6
	hum_player.play()
	
	$Area3D.body_entered.connect(_on_body_entered)
	$Area3D.body_exited.connect(_on_body_exited)

func _on_body_entered(body):
	if body.is_in_group("player"):
		player_in_range = true
		player_ref = body

		# Automatically start dialogue when entering area (only once)
		if not dialogue_started:
			dialogue_started = true

			# freeze the player before starting dialogue
			if player_ref.has_method("freeze_player"):
				player_ref.freeze_player()

			start_dialogue()

func _on_body_exited(body):
	if body.is_in_group("player"):
		player_in_range = false

func _input(event):
	if player_in_range and event.is_action_pressed("interact") and not dialogue_started:
		dialogue_started = true

		# freeze the player before starting dialogue
		if player_ref and player_ref.has_method("freeze_player"):
			player_ref.freeze_player()

		start_dialogue()
		
func _on_dialogue_finished():
		# ✅ Log scene completion for branching system
	if SaveManager:
		var scene_path = get_tree().current_scene.scene_file_path
		var branch_id = "First_Exploration"  # You can use a meaningful ID like the BranchNode title or event name
		var logged := SaveManager.log_scene_completion(scene_path, branch_id)
		if logged:
			print("📌 Scene logged to game_path:", scene_path)
			ItemPopUp.show_message("Saving...")
		else:
			print("ℹ️ Scene already logged or failed to log.")
			
			
	var fade_layer = get_tree().root.get_node("NarrativeScene3d/FadeLayer")
	fade_layer.start_transition("res://scenes/Scene3/Scene3.tscn")

func start_dialogue():
	var dialogue_manager = get_tree().root.get_node("NarrativeScene3d/CanvasLayer/DialogueManager")
	dialogue_manager.load_dialogue(dialogue_file, npc_id)
	dialogue_manager.show_node("start")
	dialogue_manager.show()
	
	# connect signal if not already connected
	if not dialogue_manager.is_connected("dialogue_finished", Callable(self, "_on_dialogue_finished")):
		dialogue_manager.connect("dialogue_finished", Callable(self, "_on_dialogue_finished"))
