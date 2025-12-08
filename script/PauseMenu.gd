extends Control

@onready var resume_button: Button = $VBoxContainer/ResumeButton
@onready var settings_button: Button = $VBoxContainer/SettingsButton
@onready var save_button: Button = $VBoxContainer/SaveButton
@onready var main_menu_button: Button = $VBoxContainer/MainMenuButton
@onready var saved_label: Label = $VBoxContainer/SavedLabel

var is_paused = false

func _ready():
	
	
	mouse_filter = Control.MOUSE_FILTER_STOP
	z_index = 100
	process_mode = Node.PROCESS_MODE_ALWAYS   # Interactive while paused
	
	# Connect button signals
	resume_button.pressed.connect(_on_resume_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	save_button.pressed.connect(_on_save_pressed)
	main_menu_button.pressed.connect(_on_main_menu_pressed)

# Helper method for the autoload to focus the resume button
func focus_resume_button():
	if resume_button:
		resume_button.grab_focus()

func toggle_pause():
	print("able to call the togglepause from pausemenu")
	AudioMgr.play_ui_sound("res://assets/audio/ui/Click_sound.wav")
	is_paused = not is_paused
	
	if is_paused:
		show()
		get_tree().paused = true
		resume_button.grab_focus()
		await get_tree().process_frame
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	else:
		_on_resume_pressed()
		
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		
		
func _on_resume_pressed():
	AudioMgr.play_ui_sound("res://assets/audio/ui/Click_sound.wav")
	is_paused = false
	hide()
	get_tree().paused = false

func _on_settings_pressed():
	AudioMgr.play_ui_sound("res://assets/audio/ui/Click_sound.wav")
	var settings = load("res://scenes/UI/SettingsUI.tscn").instantiate()
	
	# Connect to signal for when Settings closes
	settings.closed.connect(func():
		show()
		resume_button.grab_focus()
	)
	
	get_tree().root.add_child(settings)
	hide()

func _on_save_pressed():
	AudioMgr.play_ui_sound("res://assets/audio/ui/Click_sound.wav")
	print("PauseMenu: Save button pressed")
	
	var ok := false
	var error_message := ""
	
	# Check if SaveManager exists and try to save
	if not SaveManager:
		error_message = "❌ SaveManager is missing"
	else:
		ok = SaveManager.save_game()
		if not ok:
			error_message = "❌ SaveManager.save_game() returned false"
	
	if ok:
		show_saved_message("✅ Game Saved!")
		print("✅ Save succeeded")
	else:
		show_saved_message("⚠️ Save Failed!")
		print("⚠️ Save failed")
		if error_message != "":
			print(error_message)
		
		# Extra debug: check if DB exists and if SaveManager has data
		if SaveManager and SaveManager.game_data:
			print("📦 Current game_data: ", SaveManager.game_data)
		else:
			print("⚠️ SaveManager.game_data missing or empty")

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
	AudioMgr.play_ui_sound("res://assets/audio/ui/Click_sound.wav")
	get_tree().paused = false
	is_paused = false
	hide()
	get_tree().change_scene_to_file("res://scenes/Main Menu/main_menu.tscn")


func _on_help_pressed() -> void:
	AudioMgr.play_ui_sound("res://assets/audio/ui/Click_sound.wav")
	var help = load("res://scenes/UI/help.tscn").instantiate()
	
	# Connect to signal for when Settings closes
	help.closed.connect(func():
		show()
		resume_button.grab_focus()
	)
	
	get_tree().root.add_child(help)
	hide()  # hide Pause Menu while Settings is open
