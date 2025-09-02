extends Control

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

func _ready():
	hide()

	typing_timer = Timer.new()
	typing_timer.wait_time = typing_speed
	typing_timer.one_shot = false
	add_child(typing_timer)
	typing_timer.timeout.connect(_on_typing_step)

	next_button.pressed.connect(_on_NextButton_pressed)
	

# --- Public API ---
func load_dialogue(file_path: String, npc_id: String):
	var file = FileAccess.open(file_path, FileAccess.READ)
	if file:
		var content = file.get_as_text()
		var all_dialogues = JSON.parse_string(content)

		if typeof(all_dialogues) != TYPE_DICTIONARY:
			push_error("Invalid dialogue file: " + file_path)
			return

		if not all_dialogues.has(npc_id):
			push_error("No dialogue for NPC: " + npc_id)
			return

		dialogue = all_dialogues[npc_id]
		current_node = "start"
		show()

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
		btn.pressed.connect(func(): _on_option_selected(option["next"]))
		options_container.add_child(btn)

	if sentences.size() > 0:
		_start_sentence()
	else:
		if opts.size() > 0:
			options_container.visible = true
		else:
			# no text and no options, close directly
			_close_dialogue()

# --- Internals ---
func _start_sentence():
	full_text = sentences[current_sentence]
	visible_text = ""
	char_index = 0
	dialogue_label.text = ""
	next_button.visible = false
	typing_timer.start()

func _on_typing_step():
	if char_index < full_text.length():
		visible_text += full_text[char_index]
		dialogue_label.text = visible_text
		char_index += 1
	else:
		typing_timer.stop()
		# show correct button state
		if current_sentence < sentences.size() - 1:
			next_button.text = "➤"
			next_button.visible = true
		else:
			var node = dialogue[current_node]
			var opts: Array = node.get("options", [])
			if opts.size() > 0:
				options_container.visible = true
				next_button.visible = false
			else:
				# last sentence & no options → show Finish instead of auto-closing
				next_button.text = "Finish ✔"
				next_button.visible = true

func _on_NextButton_pressed():
	if not typing_timer.is_stopped():
		typing_timer.stop()
		dialogue_label.text = full_text
		return

	if current_sentence < sentences.size() - 1:
		current_sentence += 1
		_start_sentence()
	else:
		var node = dialogue[current_node]
		var opts: Array = node.get("options", [])
		if opts.size() > 0:
			options_container.visible = true
			next_button.visible = false
		else:
			# "Finish" button pressed
			_close_dialogue()

func _on_option_selected(next_node: String):
	if next_node == "end":
		_close_dialogue()
	else:
		show_node(next_node)

func _clear_options():
	for c in options_container.get_children():
		c.queue_free()

func _close_dialogue():
	if typing_timer and not typing_timer.is_stopped():
		typing_timer.stop()
	dialogue_label.text = ""
	_clear_options()
	options_container.visible = false
	next_button.visible = false
	hide()
