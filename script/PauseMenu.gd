extends Control

@onready var resume_button: Button = $VBoxContainer/ResumeButton
@onready var settings_button: Button = $VBoxContainer/SettingsButton
@onready var save_button: Button = $VBoxContainer/SaveButton
@onready var main_menu_button: Button = $VBoxContainer/MainMenuButton
@onready var saved_label: Label = $VBoxContainer/SavedLabel

var is_paused = false

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS   # Interactive while paused

	resume_button.pressed.connect(_on_resume_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	save_button.pressed.connect(_on_save_pressed)
	main_menu_button.pressed.connect(_on_main_menu_pressed)

	hide()

func toggle_pause():
	AudioMgr.play_ui_sound()
	is_paused = not is_paused
	if is_paused:
		show()
		get_tree().paused = true
		resume_button.grab_focus()
	else:
		_on_resume_pressed()

func _on_resume_pressed():
	AudioMgr.play_ui_sound()
	is_paused = false
	hide()
	get_tree().paused = false

func _on_settings_pressed():
	AudioMgr.play_ui_sound()
	var settings = load("res://scenes/SettingsUI.tscn").instantiate()

	# Connect to signal for when Settings closes
	settings.closed.connect(func():
		show()
		resume_button.grab_focus()
	)

	get_tree().root.add_child(settings)
	hide()  # hide Pause Menu while Settings is open

func _on_save_pressed():
	AudioMgr.play_ui_sound()
	print("PauseMenu: Save button pressed")

	var ok := false
	var error_message := ""

	# Wrap in a try/catch style to prevent crash
	# (Godot GDScript doesn't have real try/catch, so we check manually)
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
	AudioMgr.play_ui_sound()
	
	get_tree().paused = false
	is_paused = false
	hide()
	get_tree().change_scene_to_file("res://scenes/Main Menu/main_menu.tscn")
