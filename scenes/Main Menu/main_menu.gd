extends Control

@onready var continue_button: Button = $MarginContainer/HBoxContainer/VBoxContainer/ContinueButton
@onready var new_game_button: Button = $MarginContainer/HBoxContainer/VBoxContainer/NewGameButton
@onready var quit_button: Button = $MarginContainer/HBoxContainer/VBoxContainer/QuitButton

func _ready() -> void:
	# Connect button signals
	continue_button.pressed.connect(_on_continue_pressed)
	new_game_button.pressed.connect(_on_new_game_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	
	# Check save file
	var count = SaveManager.get_save_count()
	print("📂 Save entries found: ", count)
	
	# Enable/disable continue button
	continue_button.disabled = (count == 0)

# --------------------
# Button handlers
# --------------------
func _on_continue_pressed() -> void:
	AudioMgr.play_ui_sound()
	print("MainMenu: Continue pressed")
	if not await SaveManager.continue_game():
		print("⚠️ No save found. Starting new game...")
		_on_new_game_pressed()

func _on_new_game_pressed() -> void:
	AudioMgr.play_ui_sound()
	print("MainMenu: New Game pressed")
	SaveManager.start_new_game()
	get_tree().change_scene_to_file("res://scenes/NarativeScenes/Scene1.tscn")

func _on_quit_pressed() -> void:
	AudioMgr.play_ui_sound()
	print("MainMenu: Quit pressed")
	get_tree().quit()
