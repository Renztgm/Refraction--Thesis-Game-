extends Control

@onready var slot_container: VBoxContainer = $MarginContainer/MarginContainer/VScrollBar/VBoxContainer
@onready var custom_dialog: Panel = $CustomDeleteDialog  # Your custom dialog node

var profile_to_delete: Dictionary = {}

func _ready():
	FadeOutCanvas.fade_in(0.3)
	load_profile_slots()
	
	# Connect custom dialog signals
	custom_dialog.confirmed.connect(_on_delete_confirmed)
	custom_dialog.cancelled.connect(_on_delete_cancelled)

func load_profile_slots():
	for c in slot_container.get_children():
		c.queue_free()
	
	var profiles = ProfileManager.get_profiles()
	for p in profiles:
		var slot = preload("res://scenes/Main Menu/Load Slot/ProfileSlot.tscn").instantiate()
		slot_container.add_child(slot)
		slot.call_deferred("set_profile", p)
		slot.load_pressed.connect(_select_profile)
		slot.delete_pressed.connect(_ask_delete_profile)

func _ask_delete_profile(profile: Dictionary):
	profile_to_delete = profile
	custom_dialog.show_dialog(profile)

func _on_delete_confirmed(profile: Dictionary):
	if ProfileManager.delete_profile(profile.id):
		print("✅ Deleted profile:", profile.id)
		
		# Visual feedback
		_show_success_notification("Profile deleted successfully")
	else:
		push_error("❌ Failed to delete profile: %s" % profile.id)
		_show_error_notification("Failed to delete profile")
	
	profile_to_delete = {}
	load_profile_slots()

func _on_delete_cancelled():
	profile_to_delete = {}
	print("Deletion cancelled")

func _show_success_notification(message: String):
	var notification = Label.new()
	notification.text = message
	notification.add_theme_color_override("font_color", Color(0.3, 1.0, 0.3))
	notification.position = Vector2(get_viewport_rect().size.x / 2 - 100, 50)
	add_child(notification)
	
	var tween = create_tween()
	tween.tween_property(notification, "modulate:a", 0.0, 1.0).set_delay(2.0)
	tween.tween_callback(notification.queue_free)

func _show_error_notification(message: String):
	var notification = Label.new()
	notification.text = message
	notification.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))
	notification.position = Vector2(get_viewport_rect().size.x / 2 - 100, 50)
	add_child(notification)
	
	var tween = create_tween()
	tween.tween_property(notification, "modulate:a", 0.0, 1.0).set_delay(2.0)
	tween.tween_callback(notification.queue_free)

func _select_profile(profile: Dictionary):
	print("Selected:", profile)
	ProfileManager.set_active_profile(profile.id)
	
	if await SaveManager.continue_game():
		print("Loading profile", profile.id)
	else:
		print("No save for this profile — starting new")
		SaveManager.start_new_game()
		get_tree().change_scene_to_file("res://scenes/Scene1/Prologue/Prologue.tscn")

func _on_button_pressed() -> void:
	FadeOutCanvas.fade_out(0.3)
	get_tree().change_scene_to_file("res://scenes/Main Menu/main_menu.tscn")
