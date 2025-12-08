extends CanvasLayer

@export var chosen_word : String = "DEFAULT"
@export var what_pedestal : String = "DEFAULT_PEDESTAL"
@export var hint: String = "DEFAULT"
var quest_id: String = "reconstruction"
var max_attempts: int = 6
var current_attempt: int = 0
var word_states: Array[String] = []

@onready var status_label: Label = $StatusLabel
@onready var guesses_container: VBoxContainer = $VBoxContainer
@onready var input_field: LineEdit = $LineEdit
@onready var hint_label: Label = $Hint

func _ready() -> void:
	word_states.clear()
	current_attempt = 0
	start_new_game()
	input_field.text = ""
	input_field.grab_focus()
	process_mode = Node.PROCESS_MODE_ALWAYS

func start_new_game() -> void:
	current_attempt = 0
	status_label.text = "Guess the word!"
	hint_label.text = hint
	input_field.text = ""
	input_field.editable = true

	print("\n=== Starting new game for:", chosen_word, "===")

	for child in guesses_container.get_children():
		child.queue_free()

	for attempt in range(max_attempts):
		var row = HBoxContainer.new()
		row.alignment = BoxContainer.ALIGNMENT_CENTER
		for i in range(chosen_word.length()):
			var panel = Panel.new()
			panel.custom_minimum_size = Vector2(64, 64)

			var style = StyleBoxFlat.new()
			style.bg_color = Color(0.1, 0.1, 0.1)
			style.border_color = Color(1, 1, 1)
			style.border_width_left = 2
			style.border_width_right = 2
			style.border_width_top = 2
			style.border_width_bottom = 2
			panel.add_theme_stylebox_override("panel", style)

			var margin = MarginContainer.new()
			margin.add_theme_constant_override("margin_left", 5)
			margin.add_theme_constant_override("margin_right", 5)
			margin.add_theme_constant_override("margin_top", 5)
			margin.add_theme_constant_override("margin_bottom", 5)

			var cell = Label.new()
			cell.text = ""
			cell.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			cell.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			cell.add_theme_font_size_override("font_size", 24)
			cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			cell.size_flags_vertical = Control.SIZE_EXPAND_FILL
			cell.custom_minimum_size = Vector2(64, 64)
			cell.add_theme_color_override("font_color", Color.WHITE)

			margin.add_child(cell)
			panel.add_child(margin)
			row.add_child(panel)
		guesses_container.add_child(row)

	for g in word_states:
		render_guess(g, true)

func render_guess(guess: String, restore: bool = false) -> void:
	if guess.length() != chosen_word.length():
		print("⚠️ Skipping guess due to length mismatch:", guess)
		return

	if current_attempt >= guesses_container.get_child_count():
		print("⚠️ No row available for attempt", current_attempt)
		return

	var row = guesses_container.get_child(current_attempt)
	print("Rendering guess:", guess, "at row", current_attempt, "restore =", restore)

	for i in range(guess.length()):
		var panel = row.get_child(i) as Panel
		var margin = panel.get_child(0) as MarginContainer
		var cell = margin.get_child(0) as Label
		cell.text = guess[i]

		if guess[i] == chosen_word[i]:
			panel.modulate = Color.GREEN
			cell.add_theme_color_override("font_color", Color.WHITE)
		elif chosen_word.find(guess[i]) != -1:
			panel.modulate = Color.YELLOW
			cell.add_theme_color_override("font_color", Color.WHITE)
		else:
			panel.modulate = Color.DIM_GRAY
			cell.add_theme_color_override("font_color", Color.WHITE)

	if not restore:
		current_attempt += 1

func submit_guess(guess: String) -> void:
	guess = guess.to_upper()
	if guess.length() != chosen_word.length():
		status_label.text = "Word must be %d letters!" % chosen_word.length()
		return

	word_states.append(guess)
	render_guess(guess)

	if guess == chosen_word:
		status_label.text = "You Win! Word: %s" % chosen_word
		input_field.editable = false
		
		# 🎯 Track successful memory recovery
		NarrativeProgression.remember_fact(chosen_word)
		
		QuestManager.complete_objective("reconstruction", what_pedestal)
		await get_tree().create_timer(3.0).timeout
		is_quest_finished()
		
	elif current_attempt >= max_attempts:
		status_label.text = "Game Over! The word was: %s" % chosen_word
		input_field.editable = false
		
		# 🎯 Track failed memory
		NarrativeProgression.forget_fact(chosen_word)
		
		# ⚠️ IMPORTANT: Still complete the objective so the quest continues
		# but the failure is tracked in NarrativeProgression
		QuestManager.complete_objective("reconstruction", what_pedestal)
		await get_tree().create_timer(3.0).timeout
		is_quest_finished()

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ENTER and input_field.editable:
			submit_guess(input_field.text)
			input_field.text = ""
			
func is_quest_finished():
	var is_quest_completed = QuestManager.is_quest_completed(quest_id)
	if is_quest_completed:
		FadeOutCanvas.fade_in(1)
		
		# 🌳 Simple branching: 2+ words guessed = good path, less = alternate path
		var remembered_count = NarrativeProgression.get_remembered_facts().size()
		var next_scene: String
		
		if remembered_count >= 2:
			# Good path - remembered at least 2 words
			next_scene = "res://scenes/Chapter3/Straight/Scene2/Mirror Hall/Chapter3Scene2CylinderStructure_Lyra_Confrontation.tscn"
			print("✅ Good ending path - Remembered:", remembered_count, "words")
		else:
			# Bad path - remembered 0 or 1 word
			next_scene = "res://scenes/Chapter3/Straight/Scene2/Alternate/IncompleteMemory.tscn"
			print("❌ Alternate path - Only remembered:", remembered_count, "words")
		
		get_tree().change_scene_to_file(next_scene)
	
	queue_free()
	get_tree().paused = false
	print("closing...")
