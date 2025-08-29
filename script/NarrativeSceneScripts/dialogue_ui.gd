extends Control

@onready var name_label: Label = $NameLabel
@onready var text_label: RichTextLabel = $DialogueText
@onready var next_button: Button = $NextButton

signal dialogue_advanced

var typewriter_speed: float = 0.03  # seconds per character
var is_typing: bool = false
var full_text: String = ""

func _ready():
	next_button.pressed.connect(_on_next_pressed)
	hide()  # Start hidden

func show_dialogue(character_name: String, text: String):
	name_label.text = character_name
	text_label.clear()  # Clear previous text
	full_text = text
	show()
	await _typewriter_text()

func _typewriter_text() -> void:
	is_typing = true
	text_label.clear()
	var display_text := ""
	for i in full_text.length():
		if not is_typing:
			display_text = full_text
			break
		display_text += full_text[i]
		text_label.text = display_text
		await get_tree().create_timer(typewriter_speed).timeout
	is_typing = false

func _on_next_pressed():
	if is_typing:
		# Skip typing and show full text immediately
		text_label.text = full_text
		is_typing = false
	else:
		dialogue_advanced.emit()

func hide_dialogue():
	hide()
