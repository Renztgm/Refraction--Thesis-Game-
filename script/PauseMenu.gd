extends Control

@onready var resume_button: Button = $VBoxContainer/ResumeButton
@onready var settings_button: Button = $VBoxContainer/SettingsButton
@onready var save_button: Button = $VBoxContainer/SaveButton
@onready var main_menu_button: Button = $VBoxContainer/MainMenuButton
@onready var saved_label: Label = $VBoxContainer/SavedLabel

@onready var audio_manager = get_node("/root/Main/AudioManager")

var is_paused = false

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS   # Interactive while paused

	resume_button.pressed.connect(_on_resume_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	save_button.pressed.connect(_on_save_pressed)
	main_menu_button.pressed.connect(_on_main_menu_pressed)

	hide()


func toggle_pause():
	audio_manager.play_ui_sound()
	is_paused = not is_paused
	if is_paused:
		show()
		get_tree().paused = true
		resume_button.grab_focus()
	else:
		_on_resume_pressed()


func _on_resume_pressed():
	audio_manager.play_ui_sound()
	is_paused = false
	hide()
	get_tree().paused = false


func _on_settings_pressed():
	audio_manager.play_ui_sound()
	var settings = load("res://scenes/SettingsUI.tscn").instantiate()

	# Connect to signal for when Settings closes
	settings.closed.connect(func():
		show()
		resume_button.grab_focus()
	)

	get_tree().root.add_child(settings)
	hide()  # hide Pause Menu while Settings is open


func _on_save_pressed():
	audio_manager.play_ui_sound()
	print("PauseMenu: Save button pressed")
	if SaveManager.save_game():
		show_saved_message("Game Saved!")
	else:
		show_saved_message("Save Failed!")

func show_saved_message(msg: String):
	if saved_label:
		saved_label.text = msg
		saved_label.show()
		saved_label.modulate = Color.WHITE
		var tween = create_tween()
		tween.tween_interval(1.0)
		tween.tween_property(saved_label, "modulate", Color.TRANSPARENT, 1.0)
		tween.tween_callback(func(): saved_label.hide())

func _on_main_menu_pressed():
	audio_manager.play_ui_sound()
	
	get_tree().paused = false
	is_paused = false
	hide()
	get_tree().change_scene_to_file("res://scenes/Main Menu/main_menu.tscn")
