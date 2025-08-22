extends Control

signal dialogue_finished

@onready var text_label: Label = $Panel/TextLabel
@onready var next_button: Button = $Panel/NextButton
@onready var auto_button: Button = $Panel/AutoButton
@onready var auto_timer: Timer = Timer.new()

var dialogue_lines: Array = []

var current_line: int = 0
var player: Node = null
var auto_mode: bool = false  # ✅ Player can toggle this

func _ready():
	# Add auto timer
	auto_timer.one_shot = true
	add_child(auto_timer)
	auto_timer.timeout.connect(_on_auto_timer_timeout)

	# ✅ Only connect buttons if they exist
	if next_button:
		next_button.pressed.connect(_on_next_pressed)
	else:
		push_error("❌ NextButton not found in DialogueBox scene!")

	if auto_button:
		auto_button.pressed.connect(_on_auto_pressed)
		auto_button.text = "Auto: OFF"
	else:
		push_error("❌ AutoButton not found in DialogueBox scene!")

func start_dialogue(lines: Array, player_node: Node):
	dialogue_lines = lines
	current_line = 0
	visible = true
	player = player_node
	if player and "can_move" in player:
		player.can_move = false
	show_line()

func show_line():
	if current_line < dialogue_lines.size():
		text_label.text = dialogue_lines[current_line]

		if auto_mode:
			auto_timer.start(3.0)  # auto advance after 3s
	else:
		end_dialogue()

func _on_auto_timer_timeout():
	next_line()

func _on_next_pressed():
	if not auto_mode:
		next_line()

func _on_auto_pressed():
	auto_mode = !auto_mode
	if auto_mode:
		auto_button.text = "Auto: ON"
		auto_timer.start(3.0)
	else:
		auto_button.text = "Auto: OFF"
		auto_timer.stop()

func next_line():
	current_line += 1
	show_line()

func end_dialogue():
	visible = false
	if player and "can_move" in player:
		player.can_move = true
	dialogue_finished.emit()
	queue_free()
