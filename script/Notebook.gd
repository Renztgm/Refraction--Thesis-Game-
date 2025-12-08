extends Area3D

@onready var dialogue_label: RichTextLabel = $"../CanvasLayer/Panel/DialogueLabel"
@onready var flash_screen: ColorRect = $"../CanvasLayer/FlashScreen"
@onready var next_button: Button = $"../CanvasLayer/NextButton"
@onready var panel: Panel = $"../CanvasLayer/Panel"

var notebook_message: String = "I used to come here. Someone read to me here... but who?"
var mc_line: String = "It's... still a little fuzzy."
var companion_line: String = "Companion: Careful. Touching pieces like that… it might hurt. Or help. Depends on what you've forgotten."

enum DialogueState { NONE, NOTEBOOK, MC, COMPANION, END }
var dialogue_state: DialogueState = DialogueState.NONE

var has_triggered: bool = false
var player_ref: Node = null
var text_is_showing: bool = false

var typewriter_speed: float = 0.03
var typewriter_tween: Tween = null
var full_text: String = ""

func _ready():
	float_object_up()
	body_entered.connect(_on_body_entered)

	if next_button:
		next_button.pressed.connect(_on_next_button_pressed)
		next_button.visible = false
		next_button.disabled = false

	if panel:
		panel.visible = false

	if flash_screen:
		flash_screen.modulate.a = 0.0
		flash_screen.visible = false


func _on_next_button_pressed():
	match dialogue_state:
		DialogueState.NOTEBOOK:
			show_typewriter_text(mc_line)
			dialogue_state = DialogueState.MC

		DialogueState.MC:
			# ✅ On the last line, auto‑advance after typewriter finishes
			show_typewriter_text(companion_line, true)
			dialogue_state = DialogueState.COMPANION

		_:
			hide_text()


func show_typewriter_text(text: String, auto_advance: bool = false) -> void:
	full_text = text
	dialogue_label.text = ""
	if typewriter_tween:
		typewriter_tween.kill()
	typewriter_tween = create_tween()

	for i in range(text.length()):
		var partial = text.substr(0, i + 1)
		typewriter_tween.tween_callback(func(): dialogue_label.text = partial)
		typewriter_tween.tween_interval(typewriter_speed)
		
	if auto_advance:
		typewriter_tween.tween_interval(2.0)
		typewriter_tween.tween_callback(func(): go_to_next_scene())
		
func go_to_next_scene():
	hide_text()
	ItemPopUp.show_message("Saving...")
	if SaveManager:
		var saved := SaveManager.save_game()
		if saved:
			print("💾 Game state saved successfully")
		else:
			print("❌ Failed to save game state")

	# ✅ Log scene completion for branching system
	if SaveManager:
		var scene_path = get_tree().current_scene.scene_file_path
		var branch_id = "awakening"  # Or any meaningful branch ID
		var logged := SaveManager.log_scene_completion(scene_path, branch_id)
		if logged:
			print("📌 Scene logged to game_path:", scene_path)
		else:
			print("ℹ️ Scene already logged or failed to log.")
			
	if player_ref and player_ref.has_method("unfreeze_player"):
		player_ref.unfreeze_player()

	FadeOutCanvas.fade_out(1.0, func():
		get_tree().change_scene_to_file("res://scenes/Scene4/AlleyScene.tscn")
	)


func _on_body_entered(body: Node) -> void:
	if has_triggered:
		return
	if body.is_in_group("player"):
		has_triggered = true
		player_ref = body
		quest_completed()
		if player_ref.has_method("freeze_player"):
			player_ref.freeze_player()
		
		
		glitch_flash_effect()

func quest_completed():
	var is_quest_completed = QuestManager.is_quest_completed("explore_the_bookstore")
	if not is_quest_completed:
		QuestManager.complete_objective("explore_the_bookstore", "explore_the_bookstore_1")
		ItemPopUp.show_message("Quest Completed: Secrets in the Stacks", 0.83)
	else: 
		push_error("Quest Completed Already!")

func glitch_flash_effect() -> void:
	if not flash_screen:
		return

	flash_screen.visible = true
	var tween = create_tween()

	for i in range(8):
		var intensity = randf_range(0.2, 0.9)
		var flash_time = randf_range(0.02, 0.08)
		var pause_time = randf_range(0.01, 0.05)

		tween.tween_method(set_flash_alpha, 0.0, intensity, flash_time)
		tween.tween_method(set_flash_alpha, intensity, 0.0, flash_time * 0.5)
		tween.tween_interval(pause_time)

	tween.tween_interval(0.1)

	for i in range(5):
		var color = get_random_glitch_color()
		var intensity = randf_range(0.3, 0.8)
		tween.tween_callback(func(): flash_screen.color = color)
		tween.tween_method(set_flash_alpha, 0.0, intensity, 0.03)
		tween.tween_method(set_flash_alpha, intensity, 0.0, 0.06)
		tween.tween_interval(randf_range(0.02, 0.08))

	tween.tween_callback(func(): flash_screen.color = Color.WHITE)
	tween.tween_interval(0.15)

	for i in range(12):
		var intensity = randf_range(0.1, 1.0)
		var flash_time = randf_range(0.01, 0.04)
		tween.tween_method(set_flash_alpha, 0.0, intensity, flash_time)
		tween.tween_method(set_flash_alpha, intensity, 0.0, flash_time * 0.3)
		if i < 11:
			tween.tween_interval(randf_range(0.005, 0.03))

	tween.tween_callback(func():
		flash_screen.visible = false
		flash_screen.color = Color.WHITE
		flash_screen.modulate.a = 0.0
		show_text()
	)


func get_random_glitch_color() -> Color:
	var colors = [
		Color.WHITE,
		Color.RED * 0.8,
		Color.CYAN * 0.9,
		Color.MAGENTA * 0.7,
		Color.GREEN * 0.6,
		Color.YELLOW * 0.8,
		Color(0.9, 0.9, 1.0),
		Color(1.0, 0.8, 0.8)
	]
	return colors[randi() % colors.size()]

func set_flash_alpha(alpha: float) -> void:
	flash_screen.modulate.a = alpha

func show_text() -> void:
	show_typewriter_text(notebook_message)
	dialogue_state = DialogueState.NOTEBOOK
	text_is_showing = true
	if next_button:
		next_button.visible = true
	if panel:
		panel.visible = true

func hide_text() -> void:
	dialogue_label.text = ""
	text_is_showing = false
	if next_button:
		next_button.visible = false
	if panel:
		panel.visible = false


func float_object_up():
	var tween = create_tween()
	tween.tween_property(self, "position", position + Vector3(0,1,0), 1)
	tween.tween_callback(float_object_down)

func float_object_down(): 
	var tween = create_tween()
	tween.tween_property(self, "position", position + Vector3(0,-1,0), 1)
	tween.tween_callback(float_object_up)
