extends Control

signal dialogue_finished

@onready var text_label: Label = $Panel/TextLabel
@onready var next_button: Button = $Panel/NextButton
@onready var auto_button: Button = $Panel/AutoButton
@onready var options_container: VBoxContainer = $Panel/OptionsContainer
@onready var auto_timer: Timer = Timer.new()

var dialogue_lines: Array = []
var current_line: int = 0
var player: Node = null
var auto_mode: bool = false
var is_branching: bool = false

# Typewriter effect
var typewriter_speed: float = 0.03
var is_typing: bool = false

func _ready():
	add_child(auto_timer)
	auto_timer.one_shot = true
	auto_timer.timeout.connect(_on_auto_timer_timeout)

	if next_button:
		next_button.pressed.connect(_on_next_pressed)
	if auto_button:
		auto_button.pressed.connect(_on_auto_pressed)
		auto_button.text = "Auto: OFF"

# ========================
# Linear dialogue
# ========================
func start_dialogue(lines: Array, player_node: Node):
	dialogue_lines = lines
	current_line = 0
	player = player_node
	is_branching = false
	visible = true
	if player and "can_move" in player:
		player.can_move = false
	_clear_options()
	show_line()

func show_line():
	if current_line < dialogue_lines.size():
		await _typewriter_effect(dialogue_lines[current_line])
		if auto_mode:
			auto_timer.start(3.0)
	else:
		end_dialogue()

func next_line():
	current_line += 1
	show_line()

func _on_auto_timer_timeout():
	next_line()

func _on_next_pressed():
	if is_typing:
		# Skip typing and show full line
		if current_line < dialogue_lines.size():
			text_label.text = dialogue_lines[current_line]
			is_typing = false
	else:
		if not auto_mode and not is_branching:
			next_line()

func _on_auto_pressed():
	auto_mode = !auto_mode
	if auto_mode:
		auto_button.text = "Auto: ON"
		auto_timer.start(3.0)
	else:
		auto_button.text = "Auto: OFF"
		auto_timer.stop()
	if auto_mode and not is_branching:
		auto_timer.start(3.0)
	else:
		auto_timer.stop()

# ========================
# Branching dialogue
# ========================
func start_branching_dialogue(speaker: String, text: String, options: Array, player_node: Node = null):
	visible = true
	player = player_node
	is_branching = true
	_clear_options()
	if player and "can_move" in player:
		player.can_move = false

	# Show main text with typewriter
	await _typewriter_effect(speaker + ": " + text)

	for option_dict in options:
		var btn = Button.new()
		btn.text = option_dict["text"]
		btn.pressed.connect(func(opt = option_dict):
			_show_response_and_finish(speaker, opt["response"]))
		options_container.add_child(btn)

func _show_response_and_finish(speaker: String, response: String) -> void:
	await _typewriter_effect(speaker + ": " + response)
	_clear_options()
	await get_tree().create_timer(1.0).timeout
	end_dialogue()

# ========================
# Typewriter effect helper
# ========================
func _typewriter_effect(full_text: String) -> void:
	is_typing = true
	text_label.text = ""
	for i in full_text.length():
		if not is_typing:
			text_label.text = full_text
			break
		text_label.text += full_text[i]
		await get_tree().create_timer(typewriter_speed).timeout
	is_typing = false

# ========================
# Helper to clear options safely
# ========================
func _clear_options() -> void:
	if not options_container:
		push_error("OptionsContainer not found!")
		return
	for child in options_container.get_children():
		child.queue_free()

# ========================
# End dialogue
# ========================
func end_dialogue() -> void:
	visible = false
	if player and "can_move" in player:
		player.can_move = true
	emit_signal("dialogue_finished")
	queue_free()
