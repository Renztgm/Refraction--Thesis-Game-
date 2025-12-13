extends CanvasLayer
@onready var label: Label = $AspectRatioContainer/VBoxContainer/Label

# Correct 4-digit code
const CORRECT_PASSWORD := "1019"

@onready var digits := [
$AspectRatioContainer/VBoxContainer/MarginContainer/HBoxContainer/Digit1, $AspectRatioContainer/VBoxContainer/MarginContainer/HBoxContainer/Digit2, $AspectRatioContainer/VBoxContainer/MarginContainer/HBoxContainer/Digit3, $AspectRatioContainer/VBoxContainer/MarginContainer/HBoxContainer/Digit4
]
@onready var submit_button: Button = $AspectRatioContainer/VBoxContainer/MarginContainer/HBoxContainer/SubmitButton


func _ready():
	submit_button.pressed.connect(_on_submit_pressed)
	for digit in digits:
		digit.max_length = 1           # one character per box
		digit.secret = false            # hide digits like a password
		digit.text = ""
		digit.focus_mode = Control.FOCUS_CLICK

		# Optional: auto-jump to next box
		digit.text_changed.connect(func(new_text: String, d=digit):
			if new_text.length() == 1:
				_focus_next(d))

# Jump focus to next box
func _focus_next(current_box: LineEdit):
	var idx = digits.find(current_box)
	if idx < digits.size() - 1:
		digits[idx + 1].grab_focus()

# When Submit button pressed
func _on_submit_pressed():
	var input_code = ""
	for digit in digits:
		if digit.text == "" or not digit.text.is_valid_int():
			show_message("Enter a number in all boxes!")
			label.text = "Enter a number in all boxes!"
			return
		input_code += digit.text

	if input_code == CORRECT_PASSWORD:
		show_message("ACCESS GRANTED!")
		label.text = "ACCESS GRANTED!"
		_turn_boxes_green()
		unlock_system()
	else:
		show_message("Incorrect code!")
		label.text = "Incorrect code!"
		clear_digits()
		_reset_boxes_color()

func clear_digits():
	for digit in digits:
		digit.text = ""
	digits[0].grab_focus()

# Turn all boxes green
func _turn_boxes_green():
	for digit in digits:
		digit.add_theme_color_override("background_color", Color(0.2, 1, 0.2))  # bright green

# Reset boxes to default color
func _reset_boxes_color():
	for digit in digits:
		digit.add_theme_color_override("background_color", Color(1, 1, 1))  # white


func show_message(msg: String):
	print(msg)  # Replace with UI Label, Popup, etc.

func unlock_system():
	FadeOutCanvas.fade_out(1.0)
	label.text = "System Unlocked!"
	get_tree().paused = false
	
	
	var scene_log = "res://scenes/Chapter4/Scene1/Chapter4Scene1.tscn"
	if SaveManager:
		var saved := SaveManager.save_game()
		if saved:
			print("💾 Game state saved successfully")
		else:
			print("❌ Failed to save game state")

	# ✅ Log scene completion for branching system
	if SaveManager:
		var scene_path = scene_log
		var branch_id = "chapter_3_scene_2"
		var logged := SaveManager.log_scene_completion(scene_path, branch_id)
		if logged:
			print("logged:", scene_path)
		else:
			print(scene_log, " already logged or failed to log.")

		# ✅ Set chapter info for next scene
		SaveManager.set_current_chapter(3)
		SaveManager.set_next_scene_path("res://scenes/Chapter4/Scene1/Chapter4Scene1.tscn")
		#AudioMgr.play_ui_sound("res://assets/audio/ambient/main menu.wav")
	await get_tree().create_timer(2).timeout	
	get_tree().change_scene_to_file("res://scenes/Chapter4/Scene1/Chapter4Scene1PasswordUnlocked.tscn")
	queue_free()



func _on_close_button_pressed() -> void:
	queue_free()
	get_tree().paused = false
