# awakening_narrative.gd - Main narrative controller for Scene 1
extends Node

@onready var camera_controller = get_parent().get_node("Camera/CameraController")
@onready var dialogue_ui = get_parent().get_node("UILayer/DialogueBox")
@onready var choice_ui = get_parent().get_node("UILayer/ChoiceBox")
@onready var fade_overlay = get_parent().get_node("UILayer/FadeOverlay")
@onready var audio_manager = get_parent().get_node("AudioManager")
@onready var player = get_parent().get_node("Characters/Player")

var scene_state = "black_screen"

# Scene dialogue and choices
var opening_text = "You open your eyes to an emerald sky. Ivy coils around what used to be streetlamps. You don't remember your name. You don't remember anything."

var first_choices = [
	{"text": "(Stand up.)", "id": "stand_up"},
	{"text": "(Stay still and listen to the wind.)", "id": "listen"},
	{"text": "(Look at your hands.)", "id": "look_hands"}
]

var choice_responses = {
	"stand_up": {
		"text": "Your legs shake as you rise. The world tilts, unfamiliar. Everything feels wrong, yet strangely beautiful. The emerald light makes your skin look pale and ghostly.",
		"action": "stand_up_action"
	},
	"listen": {
		"text": "The wind carries whispers of a world you don't recognize. Leaves rustle with secrets. In the distance, something that might have been a car alarm warbles like a broken song.",
		"action": "listen_action"
	},
	"look_hands": {
		"text": "Your hands are your own, but somehow foreign. Dirt under your nails, scratches you don't remember getting. They tremble slightly in the strange green light.",
		"action": "look_hands_action"
	}
}

var realization_text = "The silence stretches endlessly. No voices call your name—because no one knows it. No footsteps approach—because no one is coming. You are completely, utterly alone in this beautiful, broken world."

func _ready():
	setup_ui()
	start_awakening_sequence()

func setup_ui():
	# Create choice UI if it doesn't exist
	if not choice_ui:
		choice_ui = create_choice_ui()
	
	# Create fade overlay if it doesn't exist  
	if not fade_overlay:
		fade_overlay = create_fade_overlay()
	
	dialogue_ui.dialogue_advanced.connect(_on_dialogue_advanced)

func create_choice_ui():
	var choice_box = Control.new()
	choice_box.name = "ChoiceBox"
	choice_box.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	choice_box.size = Vector2(600, 300)
	
	var panel = Panel.new()
	panel.size = choice_box.size
	choice_box.add_child(panel)
	
	var container = VBoxContainer.new()
	container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	container.add_theme_constant_override("separation", 20)
	panel.add_child(container)
	
	get_parent().get_node("UILayer").add_child(choice_box)
	choice_box.hide()
	return choice_box

func create_fade_overlay():
	var overlay = ColorRect.new()
	overlay.name = "FadeOverlay"
	overlay.color = Color.BLACK
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	get_parent().get_node("UILayer").add_child(overlay)
	return overlay

func start_awakening_sequence():
	# Start with black screen
	fade_overlay.color = Color.BLACK
	fade_overlay.modulate.a = 1.0
	
	# Camera starts looking down at player
	camera_controller.position_for_awakening()
	
	await get_tree().create_timer(2.0).timeout
	
	# Fade in from black
	fade_in_from_black()

func fade_in_from_black():
	scene_state = "fading_in"
	audio_manager.fade_in_from_black()
	
	var tween = create_tween()
	tween.tween_property(fade_overlay, "modulate:a", 0.0, 4.0)
	
	await tween.finished
	
	# Show opening text
	show_opening_dialogue()

func show_opening_dialogue():
	scene_state = "opening_dialogue"
	dialogue_ui.show_dialogue("", opening_text)

func _on_dialogue_advanced():
	if scene_state == "opening_dialogue":
		dialogue_ui.hide_dialogue()
		show_first_choices()
	elif scene_state == "choice_response":
		dialogue_ui.hide_dialogue()
		show_realization()
	elif scene_state == "realization":
		end_scene()

func show_first_choices():
	scene_state = "first_choice"
	show_choices(first_choices)

func show_choices(choices: Array):
	choice_ui.show()
	
	# Clear previous choices
	var container = choice_ui.get_node("Panel/VBoxContainer")
	for child in container.get_children():
		child.queue_free()
	
	# Add new choices
	for choice in choices:
		var button = Button.new()
		button.text = choice.text
		button.pressed.connect(_on_choice_selected.bind(choice.id))
		container.add_child(button)

func _on_choice_selected(choice_id: String):
	audio_manager.play_choice_sound()
	choice_ui.hide()
	
	var response = choice_responses[choice_id]
	
	# Perform the action
	match response.action:
		"stand_up_action":
			player.stand_up()
			camera_controller.adjust_for_standing()
		"listen_action":
			camera_controller.focus_on_environment()
		"look_hands_action":
			player.look_at_hands()
			camera_controller.close_up_hands()
	
	# Show response text
	scene_state = "choice_response"
	await get_tree().create_timer(1.0).timeout  # Wait for action
	dialogue_ui.show_dialogue("", response.text)

func show_realization():
	scene_state = "realization"
	audio_manager.play_realization_sound()
	
	# Change camera to emphasize loneliness
	camera_controller.wide_lonely_shot()
	
	dialogue_ui.show_dialogue("", realization_text)

func end_scene():
	print("Scene 1: Awakening completed")
	# Fade to black or transition to next scene
	var tween = create_tween()
	tween.tween_property(fade_overlay, "modulate:a", 1.0, 2.0)
	
	await tween.finished
	
	# Load next scene or return to main menu
	get_tree().change_scene_to_file("res://scenes/NarativeScenes/Scene2.tscn")
