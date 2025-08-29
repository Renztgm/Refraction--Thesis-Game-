extends Node

@onready var narrative_controller: Node = $NarrativeController
@onready var companion_sprite: Sprite2D = $Companion/CompanionSprite

func _ready():
	# Make sure the narrative controller exists
	if not narrative_controller:
		push_error("NarrativeController node not found in the scene!")
		return
	
	# Connect signals safely
	if narrative_controller.has_signal("narrative_finished"):
		narrative_controller.narrative_finished.connect(_on_narrative_finished)
	else:
		push_error("narrative_finished signal missing in NarrativeController")
	
	if narrative_controller.has_signal("choice_made"):
		narrative_controller.choice_made.connect(_on_choice_made)
	else:
		push_error("choice_made signal missing in NarrativeController")
	
	# Start the companion scene
	start_companion_scene()

func start_companion_scene() -> void:
	# Fade in companion sprite
	companion_sprite.modulate.a = 0.0
	var tween = create_tween()
	tween.tween_property(companion_sprite, "modulate:a", 1.0, 1.5)
	
	await tween.finished
	await get_tree().create_timer(0.5).timeout
	
	# Define opening dialogue
	var companion_dialogue = [
		narrative_controller.create_simple_dialogue(
			"Companion", 
			"You finally woke up. I was starting to think you were just another echo."
		),
		narrative_controller.create_simple_dialogue(
			"", 
			"How do you respond?", 
			["Who are you?", "Where... am I?", "(Stay silent)"]
		)
	]
	
	narrative_controller.start_dialogue_sequence(companion_dialogue)

func _on_choice_made(choice_text: String) -> void:
	print("Player chose: ", choice_text)
	
	var follow_up_dialogue := []
	
	match choice_text:
		"Who are you?":
			follow_up_dialogue = [
				narrative_controller.create_simple_dialogue("Companion", "Same question to you."),
				narrative_controller.create_simple_dialogue("Companion", "Though I suppose names don't mean much here."),
				narrative_controller.create_simple_dialogue("Companion", "You can call me... well, whatever feels right.")
			]
		
		"Where... am I?":
			follow_up_dialogue = [
				narrative_controller.create_simple_dialogue("Companion", "Somewhere between what was and what isn't."),
				narrative_controller.create_simple_dialogue("Companion", "This place exists in the spaces between memories."),
				narrative_controller.create_simple_dialogue("Companion", "Don't try to understand it all at once.")
			]
		
		"(Stay silent)":
			follow_up_dialogue = [
				narrative_controller.create_simple_dialogue("Companion", "Silent type. That's okay. This place prefers quiet."),
				narrative_controller.create_simple_dialogue("Companion", "Sometimes words just... complicate things."),
				narrative_controller.create_simple_dialogue("Companion", "You'll speak when you're ready.")
			]
	
	if follow_up_dialogue.size() > 0:
		narrative_controller.start_dialogue_sequence(follow_up_dialogue)

func _on_narrative_finished() -> void:
	print("Companion conversation finished!")
	
	# Final dialogue
	var final_dialogue = [
		narrative_controller.create_simple_dialogue("Companion", "Well then... shall we explore this place together?"),
		narrative_controller.create_simple_dialogue("Companion", "I have a feeling you're going to need a guide.")
	]
	
	narrative_controller.start_dialogue_sequence(final_dialogue)
	
	# Wait for final dialogue to finish before moving on
	await narrative_controller.narrative_finished
	transition_to_next_scene()

func transition_to_next_scene() -> void:
	print("Ready to move to next scene!")
	# Example: change scene
	get_tree().change_scene_to_file("res://scenes/NarativeScenes/Scene3.tscn")
