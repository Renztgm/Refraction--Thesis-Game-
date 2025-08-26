extends CharacterBody3D

@onready var animated_sprite = $CompanionSprite
@onready var interact_area: Area3D = $Area3D
@onready var interact_label: Label3D = $InteractLabel3D
@onready var hum_player: AudioStreamPlayer3D = $hum_player

var current_facing = "down"
var player_in_range: bool = false
var dialogue_active: bool = false
var can_move: bool = true

# ==============================
# Scene 2 Dialogue Data
# ==============================
var scene2_dialogue = [
	{
		"speaker": "Companion",
		"text": "You finally woke up. I was starting to think you were just another echo.",
		"options": [
			{"text": "Who are you?", "response": "Same question to you."},
			{"text": "Where... am I?", "response": "Somewhere between what was and what isn’t."},
			{"text": "(Stay silent)", "response": "Silent type. That’s okay. This place prefers quiet."}
		]
	}
]

func _ready():
	# Initialize humming sound
	hum_player.stream = preload("res://assets/audio/ambient/humming.mp3")
	hum_player.stream.loop = true
	hum_player.attenuation_model = AudioStreamPlayer3D.ATTENUATION_DISABLED
	hum_player.unit_size = 5.0
	hum_player.max_distance = 50.0
	hum_player.volume_db = -6
	hum_player.play()

	# Connect interaction signals
	interact_area.body_entered.connect(_on_body_entered)
	interact_area.body_exited.connect(_on_body_exited)

	if interact_label:
		interact_label.visible = false

func _unhandled_input(event: InputEvent) -> void:
	if player_in_range and not dialogue_active and event.is_action_pressed("interact"):
		start_scene2()

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		player_in_range = true
		if interact_label and not dialogue_active:
			interact_label.visible = true

func _on_body_exited(body: Node) -> void:
	if body.is_in_group("player"):
		player_in_range = false
		if interact_label:
			interact_label.visible = false

# ==============================
# Scene 2 Dialogue Handling
# ==============================
func start_scene2():
	if dialogue_active:
		return

	dialogue_active = true
	can_move = false
	if interact_label:
		interact_label.visible = false

	var dialogue_box = preload("res://scenes/DialogueBox.tscn").instantiate()
	get_tree().current_scene.add_child(dialogue_box)

	# Show dialogue lines with branching options
	var entry = scene2_dialogue[0]
	dialogue_box.start_branching_dialogue(entry["speaker"], entry["text"], entry["options"])

	# Reset state when dialogue finishes
	dialogue_box.dialogue_finished.connect(func():
		dialogue_active = false
		can_move = true
		if player_in_range and interact_label:
			interact_label.visible = true
	)

# ==============================
# Animation Helper
# ==============================
func play_directional_animation(anim_type: String):
	var animation_name = anim_type.capitalize() + "_" + current_facing
	if animated_sprite.sprite_frames.has_animation(animation_name):
		animated_sprite.play(animation_name)
	else:
		var fallback = anim_type.capitalize() + "_down"
		if animated_sprite.sprite_frames.has_animation(fallback):
			animated_sprite.play(fallback)
