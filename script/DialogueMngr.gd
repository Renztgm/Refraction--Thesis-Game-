extends Control

signal dialogue_finished

@onready var npc_name_label = $NPCName
@onready var dialogue_label = $DialogueLabel
@onready var next_button = $NextButton
@onready var options_container = $Options

var dialogue: Dictionary = {}
var current_node: String = "start"

var sentences: Array = []
var current_sentence: int = 0
var full_text: String = ""
var visible_text: String = ""
var char_index: int = 0
var typing_speed: float = 0.03
var typing_timer: Timer

var is_typing: bool = false
var pending_next_node: String = ""
var pending_mc_text: String = ""

func _ready():
	hide()

	typing_timer = Timer.new()
	typing_timer.wait_time = typing_speed
	typing_timer.one_shot = false
	add_child(typing_timer)
	typing_timer.timeout.connect(_on_typing_step)

	next_button.pressed.connect(_on_next_pressed)

# --- Load dialogue from JSON file ---
func load_dialogue(file_path: String, npc_id: String):
	var file = FileAccess.open(file_path, FileAccess.READ)
	if not file:
		push_error("Cannot open file: " + file_path)
		return

	var content = file.get_as_text()
	file.close()

	var json_data = JSON.parse_string(content)
	if typeof(json_data) != TYPE_DICTIONARY:
		push_error("Failed to parse JSON. Make sure the file is valid!")
		return

	var all_dialogues: Dictionary = json_data

	if not all_dialogues.has(npc_id):
		push_error("No dialogue for NPC: " + npc_id)
		return

	dialogue = all_dialogues[npc_id] as Dictionary

	if not dialogue.has("start"):
		push_error("Dialogue missing 'start' node for NPC: " + npc_id)
		return

	current_node = "start"
	show_node(current_node)
	show()

# --- Show a dialogue node ---
func show_node(node_name: String):
	if node_name == "end":
		_close_dialogue()
		return

	if not dialogue.has(node_name):
		push_error("Dialogue node not found: " + node_name)
		return

	current_node = node_name
	var node = dialogue[node_name]

	npc_name_label.text = node.get("name", "Unknown")

	sentences = node.get("sentences", [])
	current_sentence = 0

	_clear_options()
	options_container.visible = false
	next_button.visible = false

	var opts = node.get("options", [])
	for option in opts:
		var btn = Button.new()
		btn.text = option["text"]
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.pressed.connect(func(): _on_option_selected(option))
		options_container.add_child(btn)

	# Store auto-next if provided
	pending_next_node = node.get("next", "")

	if sentences.size() > 0:
		_start_sentence()
	elif opts.size() > 0:
		options_container.visible = true
	elif pending_next_node != "":
		# No sentences or options → jump to next node
		show_node(pending_next_node)
	else:
		_close_dialogue()

# --- Start typing a sentence ---
func _start_sentence():
	full_text = sentences[current_sentence]
	visible_text = ""
	char_index = 0
	is_typing = true
	dialogue_label.text = ""
	next_button.visible = false
	typing_timer.start()

# --- Typing effect ---
func _on_typing_step():
	if char_index < full_text.length():
		visible_text += full_text[char_index]
		dialogue_label.text = visible_text
		char_index += 1
	else:
		typing_timer.stop()
		is_typing = false

		# Distinguish between NPC lines and MC lines
		if npc_name_label.text != "You":
			# NPC speaking
			var node = dialogue.get(current_node, {})
			var opts = node.get("options", [])
			if current_sentence >= sentences.size() - 1 and opts.size() > 0 and pending_mc_text == "":
				# Last NPC line → show options immediately
				options_container.visible = true
				next_button.visible = false
			else:
				# NPC mid-line or no options → Next button
				next_button.visible = true
		else:
			# MC speaking → always Next after line finishes
			next_button.visible = true

# --- Next button pressed ---
func _on_next_pressed():
	if is_typing:
		typing_timer.stop()
		dialogue_label.text = full_text
		is_typing = false
		next_button.visible = true
		return

	# Move to next sentence in the current node
	if current_sentence < sentences.size() - 1:
		current_sentence += 1
		_start_sentence()
		return

	# If MC text is pending, type it now
	if pending_mc_text != "":
		full_text = pending_mc_text
		pending_mc_text = ""
		visible_text = ""
		char_index = 0
		is_typing = true

		# Show player as the speaker
		npc_name_label.text = "You"

		dialogue_label.text = ""
		next_button.visible = false
		typing_timer.start()
		return

	# Otherwise, move to next node if defined
	if pending_next_node != "":
		var next_node = pending_next_node
		pending_next_node = ""
		show_node(next_node)
		return

	# No more sentences or options → close dialogue
	var node = dialogue[current_node]
	if node.get("options", []).size() > 0:
		options_container.visible = true
		next_button.visible = false
	else:
		_close_dialogue()

# --- Player selects an option ---
func _on_option_selected(option_data: Dictionary):
	print("🧪 Option selected:", option_data)
	


	_clear_options()
	options_container.visible = false

	var mc_text = option_data.get("full_text", option_data.get("text", "…"))

	# Handle quest triggers
	if option_data.has("start_quest"):
		var quest_path = option_data["start_quest"]
		var quest = load(quest_path)
		print("📦 Loaded quest:", quest)
		
		var quest_manager = QuestManager
		print("🧠 QuestManager reference:", quest_manager)

		if quest == null:
			push_error("❌ Failed to load quest from: " + quest_path)
		else:
			if QuestManager and QuestManager.has_method("add_quest"):
				QuestManager.add_quest(quest)
				print("🧩 Quest started:", quest.id)
			else:
				push_error("❌ QuestManager not found or missing 'add_quest' method.")

	if option_data.has("complete_objective"):
		var quest_id = option_data["quest_id"]
		var objective = option_data["complete_objective"]
		QuestManager.complete_objective(quest_id, objective)

	if option_data.has("set_flag"):
		var flag_name = option_data["set_flag"]
		get_node("/root/NarrativeState").set_flag(flag_name, true)

	var next_node = option_data.get("next", "end")
	if not dialogue.has(next_node):
		next_node = "end"

	pending_mc_text = mc_text
	pending_next_node = next_node

	_on_next_pressed()

# --- Clear all options ---
func _clear_options():
	for c in options_container.get_children():
		c.queue_free()

# --- Close dialogue ---
func _close_dialogue():
	if typing_timer and not typing_timer.is_stopped():
		typing_timer.stop()
	dialogue_label.text = ""
	_clear_options()
	options_container.visible = false
	next_button.visible = false
	hide()
	emit_signal("dialogue_finished")
