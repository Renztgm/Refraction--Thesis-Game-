# narrative_controller.gd
extends Node

@onready var camera_controller = get_parent().get_node("Camera/CameraController")
@onready var dialogue_ui = get_parent().get_node("UILayer/DialogueBox")
@onready var audio_manager = get_parent().get_node("AudioManager")
@onready var characters = get_parent().get_node("Characters")

var dialogue_data = [
	{"character": "Character1", "text": "Hello there! Welcome to our world.", "camera_shot": "close_char1"},
	{"character": "Character2", "text": "Indeed! It's great to see you here.", "camera_shot": "close_char2"},
	{"character": "Character1", "text": "What brings you to this place?", "camera_shot": "wide"}
]

var current_dialogue_index = 0

func _ready():
	dialogue_ui.dialogue_advanced.connect(_on_dialogue_advanced)
	start_narrative()

func start_narrative():
	show_current_dialogue()

func show_current_dialogue():
	if current_dialogue_index < dialogue_data.size():
		var dialogue = dialogue_data[current_dialogue_index]
		
		# Move camera
		camera_controller.move_to_shot(dialogue.camera_shot)
		
		# Show dialogue
		dialogue_ui.show_dialogue(dialogue.character, dialogue.text)
		
		# Highlight speaking character
		highlight_speaking_character(dialogue.character)
	else:
		end_narrative()

func _on_dialogue_advanced():
	current_dialogue_index += 1
	show_current_dialogue()

func highlight_speaking_character(speaking_character_name: String):
	# Reset all characters to dim
	for child in characters.get_children():
		if child is Node3D and child.name != speaking_character_name:
			set_character_material_color(child, Color.GRAY, 0.3)
	
	# Highlight speaking character
	var speaking_char = characters.get_node_or_null(speaking_character_name)
	if speaking_char:
		set_character_material_color(speaking_char, Color.WHITE, 0.3)

func set_character_material_color(character: Node3D, color: Color, duration: float):
	var mesh_instance = character.get_node_or_null("MeshInstance3D")
	if not mesh_instance:
		print("Warning: No MeshInstance3D found in ", character.name)
		return
	
	# Get or create material
	var material = mesh_instance.get_surface_override_material(0)
	if not material:
		material = StandardMaterial3D.new()
		mesh_instance.set_surface_override_material(0, material)
	
	# Tween to new color
	var tween = create_tween()
	tween.tween_property(material, "albedo_color", color, duration)

func end_narrative():
	dialogue_ui.hide_dialogue()
	# Reset all characters to normal
	for child in characters.get_children():
		if child is Node3D:
			set_character_material_color(child, Color.WHITE, 0.5)
	print("Narrative completed!")
