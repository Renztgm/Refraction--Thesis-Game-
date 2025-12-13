extends Control

@onready var continue_button: Button = $MarginContainer/HBoxContainer/VBoxContainer/ContinueButton
@onready var new_game_button: Button = $MarginContainer/HBoxContainer/VBoxContainer/NewGameButton
@onready var name_input: LineEdit = $MarginContainer/HBoxContainer/VBoxContainer/NameInput
@onready var quit_button: Button = $MarginContainer/HBoxContainer/VBoxContainer/QuitButton
@onready var settings_button: Button = $MarginContainer/HBoxContainer/VBoxContainer/SettingsButton

func _ready() -> void:
	FadeOutCanvas.fade_in(0.3)
	# Connect button signals
	continue_button.pressed.connect(_on_continue_pressed)
	new_game_button.pressed.connect(_on_new_game_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	var profiles = ProfileManager.get_profiles()
	continue_button.disabled = profiles.size() < 1
	
	if continue_button.disabled:
		$MarginContainer/HBoxContainer/VBoxContainer/ContinueButton.visible = false


# --------------------
# Button handlers
# --------------------
func _on_continue_pressed() -> void:
	AudioMgr.play_ui_sound("res://assets/audio/ui/Click_sound.wav")
	print("MainMenu: Continue pressed")
	get_tree().change_scene_to_file("res://scenes/Main Menu/Load Slot/load_slot.tscn")
	if  continue_button.disabled:
		print("Continue button is disabled")
		return


func _on_new_game_pressed() -> void:
	AudioMgr.play_ui_sound("res://assets/audio/ui/Click_sound.wav")
	get_tree().change_scene_to_file("res://scenes/Main Menu/Create Proflie/CreateProfile.tscn")

func _on_settings_pressed() -> void:
	AudioMgr.play_ui_sound("res://assets/audio/ui/Click_sound.wav")
	FadeOutCanvas.fade_in(0.3)
	var settings = preload("res://scenes/UI/SettingsUI.tscn").instantiate()
	add_child(settings)

func _on_quit_pressed() -> void:
	AudioMgr.play_ui_sound("res://assets/audio/ui/Click_sound.wav")
	print("MainMenu: Quit pressed")
	await get_tree().create_timer(1).timeout
	get_tree().quit()
