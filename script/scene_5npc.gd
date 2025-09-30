extends CharacterBody3D

@onready var animated_sprite = $CompanionSprite
@onready var interact_area: Area3D = $Area3D
@onready var interact_label: Label3D = $InteractLabel3D
@onready var hum_player: AudioStreamPlayer3D = $hum_player

var current_facing = "down"
var dialogue_active: bool = false
var can_move: bool = true
var dialogue_triggered: bool = false  # Prevent retriggering

# Dialogue settings
var dialogue_file_path: String = "res://dialogues/Scene5Dialogue.json"  # Path to your dialogue JSON
var npc_id: String = "Scene5Dialogue"  # ID of this NPC in the dialogue file
var next_scene_path: String = "res://scenes/Scene6/Scene6.tscn"  # Path to next scene
var player_node: Node = null

func _ready():
	# Find player node
	player_node = get_tree().get_first_node_in_group("player")
	
	# Initialize humming sound
	hum_player.stream = preload("res://assets/audio/ambient/humming.mp3")
	hum_player.stream.loop = true
	hum_player.attenuation_model = AudioStreamPlayer3D.ATTENUATION_DISABLED
	hum_player.unit_size = 5.0
	hum_player.max_distance = 150.0
	hum_player.volume_db = -6
	hum_player.play()
	
	# Connect interaction signals
	interact_area.body_entered.connect(_on_body_entered)
	interact_area.body_exited.connect(_on_body_exited)
	
	# Hide interact label since we're using trigger mode
	if interact_label:
		interact_label.visible = false

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player") and not dialogue_triggered:
		# Automatically start dialogue when player enters trigger area
		start_dialogue()

func _on_body_exited(body: Node) -> void:
	# Optional: You can add any cleanup here if needed
	pass

# ==============================
# Dialogue Handling
# ==============================
func start_dialogue():
	if dialogue_active or dialogue_triggered:
		return
	
	dialogue_active = true
	dialogue_triggered = true  # Prevent retriggering
	can_move = false
	
	# Freeze the player
	freeze_player()
	
	# Hide interact label during dialogue
	if interact_label:
		interact_label.visible = false
	
	# Create and setup dialogue manager
	var dialogue_box = preload("res://scenes/UI/DialogueManager.tscn").instantiate()
	get_tree().current_scene.add_child(dialogue_box)
	
	# Load dialogue from JSON file
	dialogue_box.load_dialogue(dialogue_file_path, npc_id)
	
	# Connect to dialogue finished signal
	dialogue_box.dialogue_finished.connect(_on_dialogue_finished)

func _on_dialogue_finished():
	dialogue_active = false
	can_move = true
	# Note: dialogue_triggered remains true to prevent retriggering
	
	# Start fade out and transition to next scene
	fade_to_sleep()

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

# ==============================
# Player Control Functions
# ==============================
func freeze_player():
	if player_node and player_node.has_method("freeze_player"):
		player_node.freeze_player()

func unfreeze_player():
	if player_node and player_node.has_method("unfreeze_player"):
		player_node.unfreeze_player()

# ==============================
# Fade and Scene Transition
# ==============================
func fade_to_sleep():
	# Create fade overlay
	var fade_overlay = ColorRect.new()
	fade_overlay.color = Color.BLACK
	fade_overlay.color.a = 0.0  # Start transparent
	fade_overlay.z_index = 100  # Make sure it's on top
	fade_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	
	# Add to scene
	get_tree().current_scene.add_child(fade_overlay)
	
	# Create tween for fade effect
	var tween = create_tween()
	tween.tween_property(fade_overlay, "color:a", 1.0, 2.0)  # Fade to black over 2 seconds
	
	# Wait a moment in black, then change scene
	tween.tween_callback(func(): 
		await get_tree().create_timer(1.0).timeout  # Stay in black for 1 second
		change_to_next_scene()
	)

func change_to_next_scene():
	# Change to next scene
	get_tree().change_scene_to_file(next_scene_path)
# ==============================
# Optional: Reset trigger for testing
# ==============================
func reset_trigger():
	"""Call this function if you want to allow the dialogue to trigger again"""
	dialogue_triggered = false
