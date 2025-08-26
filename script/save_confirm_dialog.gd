# SaveConfirmDialog.gd
# Attach this script to a Control node in your dialog scene
extends Control

# Signals to communicate with SaveManager
signal save_and_quit_requested
signal quit_without_save_requested
signal dialog_cancelled

@onready var dialog_panel: Panel = $Control/DialogPanel
@onready var save_button: Button = $Control/DialogPanel/VBoxContainer/ButtonContainer/SaveButton
@onready var dont_save_button: Button = $Control/DialogPanel/VBoxContainer/ButtonContainer/DontSaveButton
@onready var cancel_button: Button = $Control/DialogPanel/VBoxContainer/ButtonContainer/CancelButton


func _ready():
	# Connect button signals
	save_button.pressed.connect(_on_save_button_pressed)
	dont_save_button.pressed.connect(_on_dont_save_button_pressed)
	cancel_button.pressed.connect(_on_cancel_button_pressed)
	
	# Pause the game when dialog opens
	get_tree().paused = true
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	

func _on_save_button_pressed():
	print("Save & Quit button pressed")
	save_and_quit_requested.emit()
	_close_dialog()

func _on_dont_save_button_pressed():
	print("Don't Save button pressed")
	quit_without_save_requested.emit()
	_close_dialog()

func _on_cancel_button_pressed():
	print("Cancel button pressed")
	dialog_cancelled.emit()
	_close_dialog()

func _close_dialog():
	# Unpause game
	get_tree().paused = false
	
	queue_free()

 #Optional: Close dialog with ESC key
func _input(event):
	if event.is_action_pressed("ui_cancel"):  # ESC key
		_on_cancel_button_pressed()
