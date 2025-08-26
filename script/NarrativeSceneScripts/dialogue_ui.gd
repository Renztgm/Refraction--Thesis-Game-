# dialogue_ui.gd
extends Control

#@onready var name_label = $Panel/NameLabel
#@onready var text_label: RichTextLabel = $DialogueText
#@onready var next_button: Button = $NextButton
@onready var name_label: Label = $NameLabel
@onready var text_label: RichTextLabel = $DialogueText
@onready var next_button: Button = $NextButton


signal dialogue_advanced

func _ready():
	next_button.pressed.connect(_on_next_pressed)
	hide()  # Start hidden

func show_dialogue(character_name: String, text: String):
	name_label.text = character_name
	text_label.text = text
	show()

func _on_next_pressed():
	dialogue_advanced.emit()

func hide_dialogue():
	hide()
