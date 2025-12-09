# CustomDeleteDialog.gd
# Attach this script to a Panel node in your scene tree

extends Panel

signal confirmed(profile: Dictionary)
signal cancelled

@onready var profile_name_label: Label = $MarginContainer/VBoxContainer/ProfileNameLabel
@onready var warning_label: Label = $MarginContainer/VBoxContainer/WarningLabel
@onready var delete_button: Button = $MarginContainer/VBoxContainer/HBoxContainer/DeleteButton
@onready var cancel_button: Button = $MarginContainer/VBoxContainer/HBoxContainer/CancelButton

var current_profile: Dictionary = {}

func _ready():
	hide()
	delete_button.pressed.connect(_on_delete_pressed)
	cancel_button.pressed.connect(_on_cancel_pressed)
	
	# Style buttons
	delete_button.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))
	delete_button.add_theme_color_override("font_hover_color", Color(1.0, 0.5, 0.5))
	
	# Center the dialog
	#set_anchors_preset(Control.PRESET_CENTER)
	#size = Vector2(400, 250)

func show_dialog(profile: Dictionary):
	current_profile = profile
	profile_name_label.text = "Delete Profile: " + profile.player_name
	warning_label.text = "⚠ This will permanently delete all save data for this profile.\n\nThis action cannot be undone."
	
	# Reset button state
	delete_button.disabled = false
	delete_button.text = "Delete Profile"
	
	show()
	modulate.a = 0.0
	
	# Animate in
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.2)
	tween.tween_property(self, "scale", Vector2.ONE, 0.2).from(Vector2(0.9, 0.9))

func _on_delete_pressed():
	# Visual feedback during deletion
	delete_button.disabled = true
	delete_button.text = "Deleting..."
	cancel_button.disabled = true
	
	# Small delay for visual feedback
	await get_tree().create_timer(0.3).timeout
	
	confirmed.emit(current_profile)
	hide_dialog()

func _on_cancel_pressed():
	cancelled.emit()
	hide_dialog()

func hide_dialog():
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.15)
	tween.tween_property(self, "scale", Vector2(0.9, 0.9), 0.15)
	tween.tween_callback(hide)
	tween.tween_callback(_reset_state)

func _reset_state():
	delete_button.disabled = false
	delete_button.text = "Delete Profile"
	cancel_button.disabled = false
	scale = Vector2.ONE
