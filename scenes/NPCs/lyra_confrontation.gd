extends CharacterBody3D   # or Node2D/Area2D depending on your setup

@export var dialogue_file_path: String = "res://dialogues/lyra_confrontation.json"
@export var npc_id: String = "Lyra"
var scene_log = "res://scenes/Chapter3/Straight/Scene2/Chapter3Scene2A.tscn"
@export var next_scene_path: String = "res://scenes/UI/endchapterscene.tscn"
var dialogue_active: bool = false
var dialogue_triggered: bool = false
var player: Node = null

func _ready():
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0]

func start_dialogue():
	if dialogue_active or dialogue_triggered:
		return

	dialogue_active = true
	dialogue_triggered = true

	if player and player.has_method("freeze_player"):
		player.freeze_player()

	var dialogue_box = preload("res://scenes/UI/DialogueManager.tscn").instantiate()
	get_tree().current_scene.add_child(dialogue_box)

	dialogue_box.load_dialogue(dialogue_file_path, npc_id)
	dialogue_box.dialogue_finished.connect(_on_dialogue_finished)

func _on_dialogue_finished():
	dialogue_active = false
	if player and player.has_method("unfreeze_player"):
		player.unfreeze_player()
		ItemPopUp.show_message("Saving...")
		# ✅ Save current game state (player position, scene, etc.)
		if SaveManager:
			var saved := SaveManager.save_game()
			if saved:
				print("💾 Game state saved successfully")
			else:
				print("❌ Failed to save game state")

		# ✅ Log scene completion for branching system
		if SaveManager:
			var scene_path = scene_log
			var branch_id = "chapter_3_scene_2"
			var logged := SaveManager.log_scene_completion(scene_path, branch_id)
			if logged:
				print("logged:", scene_path)
			else:
				print(scene_log, " already logged or failed to log.")

			# ✅ Set chapter info for next scene
			SaveManager.set_current_chapter(3)
			SaveManager.set_next_scene_path("res://scenes/Chapter4/Scene1/Chapter4Scene1.tscn")
			

			# Load end chapter scene
			get_tree().change_scene_to_file("res://scenes/UI/endchapterscene.tscn")
func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		start_dialogue()
		print(player)
