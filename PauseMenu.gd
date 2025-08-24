extends Control

@onready var save_button: Button = $VBoxContainer/SaveButton
@onready var main_menu_button: Button = $VBoxContainer/MainMenuButton
@onready var resume_button: Button = $VBoxContainer/ResumeButton
@onready var settings_button: Button = $VBoxContainer/SettingsButton
@onready var saved_label: Label = $VBoxContainer/SavedLabel

var is_paused = false

func _ready():
	print("PauseMenu ready - controlled by Player")
	
	add_to_group("pause_menu")
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	
	var vbox = $VBoxContainer
	if vbox:
		vbox.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
		vbox.custom_minimum_size = Vector2(200, 300)
	
	if save_button:
		save_button.pressed.connect(_on_save_pressed)
		save_button.custom_minimum_size = Vector2(150, 40)
	if main_menu_button:
		main_menu_button.pressed.connect(_on_main_menu_pressed)
		main_menu_button.custom_minimum_size = Vector2(150, 40)
	if resume_button:
		resume_button.pressed.connect(_on_resume_pressed)
		resume_button.custom_minimum_size = Vector2(150, 40)
	if settings_button:
		settings_button.pressed.connect(_on_settings_pressed)
		settings_button.custom_minimum_size = Vector2(150, 40)
	
	hide()
	if saved_label:
		saved_label.hide()
	
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED


func _draw():
	if visible:
		draw_rect(get_rect(), Color(0, 0, 0, 0.7))


func toggle_pause():
	is_paused = not is_paused
	if is_paused:
		show()
		get_tree().paused = true
		if resume_button:
			resume_button.grab_focus()
	else:
		hide()
		get_tree().paused = false


# ✅ Save button → call SaveManager + show fading label
func _on_save_pressed():
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


# ✅ Go back to Main Menu safely
func _on_main_menu_pressed():
	print("PauseMenu: Main menu button pressed")
	get_tree().paused = false
	is_paused = false
	hide()
	get_tree().change_scene_to_file("res://scenes/Main Menu/main_menu.tscn")


# ✅ Resume game
func _on_resume_pressed():
	print("PauseMenu: Resume button pressed")
	toggle_pause()


# ✅ Settings → placeholder or open SettingsMenu
func _on_settings_pressed():
	print("PauseMenu: Settings button pressed")
	# If you have SettingsMenu.tscn:
	# var settings = load("res://SettingsMenu.tscn").instantiate()
	# get_tree().root.add_child(settings)
	print("Settings pressed - not implemented yet")
