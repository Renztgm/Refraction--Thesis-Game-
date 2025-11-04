extends Control

# Nodes
@onready var quote_label: Label = $CanvasLayer/MarginContainer/VBoxContainer/QuoteLabel
@onready var loading_label: Label = $CanvasLayer/MarginContainer/VBoxContainer/LoadingLabel

# Quotes
var messages: Array = []
var message_index: int = -1   # -1 means no quote chosen yet

# Fade variables
var alpha: float = 0.0
var fade_in: bool = true
var fade_speed: float = 0.5       # Fade speed per second
var display_timer: float = 0.0
var display_duration: float = 8.0 # Time quote stays fully visible

# Loading dots
var dot_timer: float = 0.0
var dot_count: int = 0

func _ready():
	randomize() # Seed random number generator

	# Load JSON quotes
	var file := FileAccess.open("res://dialogues/qoutes.json", FileAccess.READ)
	if file:
		var text: String = file.get_as_text()
		file.close()

		# Parse JSON explicitly as Array
		var data: Array = JSON.parse_string(text)

		if typeof(data) == TYPE_ARRAY:
			messages = data
		else:
			push_error("quotes.json does not contain a top-level array")
	else:
		push_error("Could not open quotes.json")

	# Debug print to confirm loading
	print("Loaded messages: ", messages)

	# Initialize first quote
	if messages.size() > 0:
		_pick_new_quote()
		quote_label.modulate.a = 0.0
		alpha = 0.0
		fade_in = true
		display_timer = 0.0
	else:
		# If no quotes loaded, show a placeholder
		quote_label.text = "No quotes found."
		quote_label.modulate.a = 1.0

func _process(delta: float) -> void:
	# -------------------------------
	# Handle quote fade in/out
	# -------------------------------
	if messages.size() > 0:
		if fade_in:
			alpha += fade_speed * delta
			if alpha >= 1.0:
				alpha = 1.0
				fade_in = false
				display_timer = 0.0
		else:
			display_timer += delta
			if display_timer >= display_duration:
				alpha -= fade_speed * delta
				if alpha <= 0.0:
					alpha = 0.0
					# Pick a new random quote
					_pick_new_quote()
					fade_in = true
					display_timer = 0.0

		quote_label.modulate.a = alpha

	# -------------------------------
	# Animate "Loading..." dots
	# -------------------------------
	dot_timer += delta
	if dot_timer >= 0.5:
		dot_timer = 0.0
		dot_count = (dot_count + 1) % 4
		loading_label.text = "Loading" + ".".repeat(dot_count)

# -------------------------------
# Helper: Pick new random quote (no immediate repeats)
# -------------------------------
func _pick_new_quote() -> void:
	if messages.size() == 0:
		return

	var new_index := message_index
	while new_index == message_index and messages.size() > 1:
		new_index = randi() % messages.size()

	message_index = new_index
	quote_label.text = messages[message_index]

func update_progress(value: float) -> void:
	# Optional: connect to a ProgressBar node
	# $ProgressBar.value = value * 100.0

	# Or just log it for now
	print("Loading progress: ", value * 100)
