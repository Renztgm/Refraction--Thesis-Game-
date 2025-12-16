extends Control

@export var dialogue_path: String = "res://dialogues/EndingA.json"
@export var npc_id: String = "awaken"
@export var ending_text: String = "The war has just begun."
@onready var label: Label = $EndingText/Label
var tween: Tween

func _ready():
	FadeOutCanvas.fade_in(0.3)
	label.modulate.a = 0.0
	start_dialogue()
	
func start_dialogue():
	var dialogue_box = preload("res://scenes/UI/DialogueManager.tscn").instantiate()
	get_tree().current_scene.add_child(dialogue_box)

	dialogue_box.load_dialogue(dialogue_path, npc_id)
	dialogue_box.dialogue_finished.connect(_on_dialogue_finished)

func _on_dialogue_finished():
	FadeOutCanvas.fade_out_white(1.5)
	await get_tree().create_timer(2).timeout
	ending_text_label()

func ending_text_label():
	label.text = ending_text
	tween = create_tween()
	tween.tween_property(label, "modulate:a", 1.0, 1.5)
	await get_tree().create_timer(5).timeout
	ending_text_close()

func ending_text_close():
	tween = create_tween()
	tween.tween_property(label, "modulate:a",0.0, 1.5)
	await get_tree().create_timer(5).timeout
	go_to_end_chapter()
	
	

func go_to_end_chapter():
	if SaveManager:
		var saved := SaveManager.save_game()
		if saved:
			print("💾 Game state saved successfully")
		else:
			print("❌ Failed to save game state")

	if SaveManager:
		var scene_path = get_tree().current_scene.scene_file_path
		var branch_id = "awakening"  # Or any meaningful branch ID
		var logged := SaveManager.log_scene_completion(scene_path, branch_id)
		if logged:
			print("📌 Scene logged to game_path:", scene_path)
		else:
			print("ℹ️ Scene already logged or failed to log.")

		# ✅ Set chapter info for next scene
		SaveManager.set_current_chapter(5)
		#SaveManager.set_next_scene_path("")

	FadeOutCanvas.fade_in_white(0)
	get_tree().change_scene_to_file("res://scenes/UI/endchapterscene.tscn")
