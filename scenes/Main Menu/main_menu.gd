class_name MainMenu
extends Control

@onready var start_button: Button = $MarginContainer/HBoxContainer/VBoxContainer/Start_Button as Button
@onready var exit_button: Button = $MarginContainer/HBoxContainer/VBoxContainer/Exit_Button as Button
@onready var start_level = preload("res://scenes/main.tscn") as PackedScene

# Store original button texts
var start_button_original_text: String
var exit_button_original_text: String

func _ready():
	# Store original texts
	start_button_original_text = start_button.text
	exit_button_original_text = exit_button.text
	
	# Connect button press signals
	start_button.button_down.connect(on_start_pressed)
	exit_button.button_down.connect(on_exit_pressed)
	
	# Connect hover signals for start button
	start_button.mouse_entered.connect(on_start_button_hover_enter)
	start_button.mouse_exited.connect(on_start_button_hover_exit)
	
	# Connect hover signals for exit button
	exit_button.mouse_entered.connect(on_exit_button_hover_enter)
	exit_button.mouse_exited.connect(on_exit_button_hover_exit)

func on_start_pressed() -> void:
	get_tree().change_scene_to_packed(start_level)

func on_exit_pressed() -> void:
	get_tree().quit()

# Hover effects for start button
func on_start_button_hover_enter() -> void:
	start_button.text = "➤ " + start_button_original_text

func on_start_button_hover_exit() -> void:
	start_button.text = start_button_original_text

# Hover effects for exit button
func on_exit_button_hover_enter() -> void:
	exit_button.text = "➤ " + exit_button_original_text

func on_exit_button_hover_exit() -> void:
	exit_button.text = exit_button_original_text
