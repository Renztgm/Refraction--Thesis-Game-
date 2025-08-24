# MainMenu.gd
# Attach this to your main menu scene
extends Control

@onready var continue_button: Button = $MarginContainer/HBoxContainer/VBoxContainer/ContinueButton
@onready var new_game_button: Button = $MarginContainer/HBoxContainer/VBoxContainer/NewGameButton
@onready var quit_button: Button = $MarginContainer/HBoxContainer/VBoxContainer/QuitButton

func _ready():
	# Connect button signals
	continue_button.pressed.connect(_on_continue_pressed)
	new_game_button.pressed.connect(_on_new_game_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	
	# Enable/disable continue button based on save file
	continue_button.disabled = not SaveManager.has_save_file()

func _on_continue_pressed():
	if SaveManager.continue_game():
		print("Continuing game...")
	else:
		print("Failed to load save file!")

func _on_new_game_pressed():
	# Change this to your first game scene
	get_tree().change_scene_to_file("res://scenes/main.tscn")

func _on_quit_pressed():
	get_tree().quit()
