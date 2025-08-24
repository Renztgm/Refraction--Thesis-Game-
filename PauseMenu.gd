extends Control

@onready var save_button: Button = $VBoxContainer/SaveButton
@onready var main_menu_button: Button = $VBoxContainer/MainMenuButton
@onready var resume_button: Button = $VBoxContainer/ResumeButton
@onready var settings_button: Button = $VBoxContainer/SettingsButton
@onready var saved_label: Label = $VBoxContainer/SavedLabel

var is_paused = false

func _ready():
	print("PauseMenu ready - controlled by Player")
	
	# Add to group so Player can find it easily
	add_to_group("pause_menu")
	
	# Make the pause menu fill the entire screen
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	
	# Set up the VBoxContainer to be centered
	var vbox = $VBoxContainer
	if vbox:
		vbox.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
		vbox.custom_minimum_size = Vector2(200, 300)
	
	# Connect buttons
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
	
	# Hide initially and make sure saved label is hidden
	hide()
	if saved_label:
		saved_label.hide()
	
	# Allow updates while paused
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED


# Draw a background so we can see the pause menu
func _draw():
	if visible:
		draw_rect(get_rect(), Color(0, 0, 0, 0.7))


# ✅ Toggle pause from Player
func toggle_pause():
	is_paused = not is_paused
	print("PauseMenu: Toggle called. New state: ", is_paused)
	
	if is_paused:
		show()
		get_tree().paused = true
		queue_redraw()
		if resume_button:
			resume_button.grab_focus()
	else:
		hide()
		get_tree().paused = false


# ✅ Save button functionality
func _on_save_pressed():
	print("Save button pressed")
	if SaveManager.save_game():
		print("Game saved successfully!")
		show_saved_message()
	else:
		print("Save failed!")


# Show a "Game Saved" label that fades out
func show_saved_message():
	if saved_label:
		saved_label.show()
		saved_label.text = "Game Saved!"
		saved_label.modulate = Color.WHITE
		var tween = create_tween()
		tween.tween_interval(1.0) # wait 1 second
		tween.tween_property(saved_label, "modulate", Color.TRANSPARENT, 1.0)
		tween.tween_callback(func(): saved_label.hide())


# ✅ Main Menu button functionality
func _on_main_menu_pressed():
	print("Main menu button pressed")
	get_tree().paused = false
	is_paused = false
	hide()
	
	# Optional: confirm before leaving
	# (Replace this with a dialog if you want)
	print("Returning to Main Menu...")
	get_tree().change_scene_to_file("res://scenes/Main Menu/main_menu.tscn")


# ✅ Resume button functionality
func _on_resume_pressed():
	print("Resume button pressed")
	toggle_pause()


# ✅ Settings button functionality
func _on_settings_pressed():
	print("Settings button pressed")
	
	# Example: Open a settings scene
	# You can make a SettingsMenu.tscn and instance it here
	var settings_scene = load("res://SettingsMenu.tscn").instantiate()
	get_tree().root.add_child(settings_scene)
	
	# OR if you don’t have a SettingsMenu yet:
	# Just print a placeholder
	# print("Settings pressed - not implemented yet")
