extends Control

@onready var continue_button: Button = $MarginContainer/HBoxContainer/VBoxContainer/ContinueButton
@onready var new_game_button: Button = $MarginContainer/HBoxContainer/VBoxContainer/NewGameButton
@onready var quit_button: Button = $MarginContainer/HBoxContainer/VBoxContainer/QuitButton

func _ready():
	# Connect button signals
	continue_button.pressed.connect(_on_continue_pressed)
	new_game_button.pressed.connect(_on_new_game_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	
	# Enable/disable continue button based on whether a save exists
	continue_button.disabled = not SaveManager.has_save_file()

func _on_continue_pressed():
	print("MainMenu: Continue pressed")
	SaveManager.continue_game()

func _on_new_game_pressed():
	print("MainMenu: New Game pressed")
	
	# Clear any existing save data for a fresh start
	SaveManager.start_new_game()
	
	# Load the main gameplay scene
	get_tree().change_scene_to_file("res://scenes/NarativeScenes/Scene1.tscn")

func _on_quit_pressed():
	print("MainMenu: Quit pressed")
	get_tree().quit()
