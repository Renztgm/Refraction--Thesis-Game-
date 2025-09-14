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

	# Parse JSON (Godot 4)
	var all_dialogues: Dictionary = {}
	
	# parse_string returns Variant directly
	var json_data = JSON.parse_string(content)
	if typeof(json_data) != TYPE_DICTIONARY:
		push_error("Failed to parse JSON. Make sure the file is valid!")
		return

	all_dialogues = json_data as Dictionary

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

	# Show options only if node has them
	var opts = node.get("options", [])
	for option in opts:
		var btn = Button.new()
		btn.text = option["text"]
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.pressed.connect(func(): _on_option_selected(option["next"], option["text"]))
		options_container.add_child(btn)

	if sentences.size() > 0:
		_start_sentence()
	elif opts.size() > 0:
		options_container.visible = true
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
		next_button.visible = true  # Next remains visible after typing

# --- Next button pressed ---
func _on_next_pressed():
	if is_typing:
		# Finish typing immediately
		typing_timer.stop()
		dialogue_label.text = full_text
		is_typing = false
		return

	# Move to next sentence in the current node
	if current_sentence < sentences.size() - 1:
		current_sentence += 1
		_start_sentence()
		return

	# If MC text is pending, type it now
	if pending_mc_text != "":
		full_text = "You: " + pending_mc_text
		pending_mc_text = ""
		visible_text = ""
		char_index = 0
		is_typing = true
		dialogue_label.text = ""
		next_button.visible = false
		typing_timer.start()
		return

	# Otherwise, move to next node
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
func _on_option_selected(next_node: String, option_text: String):
	_clear_options()
	options_container.visible = false

	# Store the MC text to be typed
	pending_mc_text = option_text
	pending_next_node = next_node

	# Start typing player text immediately
	full_text = "You: " + pending_mc_text
	pending_mc_text = ""  # clear after storing
	visible_text = ""
	char_index = 0
	is_typing = true
	dialogue_label.text = ""
	next_button.visible = true  # keep visible so player can click Next after typing
	typing_timer.start()

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
