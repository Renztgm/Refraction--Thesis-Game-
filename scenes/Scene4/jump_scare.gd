extends Area3D

@export var jumpscare_duration: float = 3.0  # How long to show the jumpscare
@export var music_fade_duration: float = 1.5  # How long the fade out takes
@onready var jumpscare_camera: Camera3D = $"../JumpscareCamera"  # Camera positioned in front of NPC
@onready var dialogue_manager: Control = $"../DialogueManager"
@onready var background_music: AudioStreamPlayer = $"../AudioManager/BackgroundMusic"

var player_camera: Camera3D
var player: Node3D
var is_jumpscaring: bool = false
var jumpscare_timer: float = 0.0
var jumpscare_sound = AudioStreamPlayer.new()
var music_tween: Tween

func _ready():
	body_entered.connect(_on_body_entered)
	if jumpscare_camera:
		jumpscare_camera.current = false
	add_child(jumpscare_sound)
	jumpscare_sound.stream = load("res://assets/audio/ambient/Eerrie_Sound.mp3")

func _on_body_entered(body):
	# Check if the player entered
	if body.is_in_group("player") and not is_jumpscaring:
		player = body
		
		player_camera = find_camera_in_node(player)
		
		if player_camera and jumpscare_camera:
			fade_out_music()  # Add fade out here
			trigger_jumpscare()
			
			await get_tree().create_timer(3).timeout
			dialogue_manager.load_dialogue("res://dialogues/what_is_that.json", "what_is_that")
		else:
			if not player_camera:
				push_error("No Camera3D found in player!")
			if not jumpscare_camera:
				push_error("JumpscareCamera not found! Make sure it exists in the scene.")

func fade_out_music():
	if background_music and background_music.playing:
		# Kill previous tween if it exists
		if music_tween:
			music_tween.kill()
		
		# Create new tween
		music_tween = create_tween()
		music_tween.tween_property(background_music, "volume_db", -80, music_fade_duration)
		music_tween.tween_callback(background_music.stop)

func find_camera_in_node(node: Node) -> Camera3D:
	# Check if this node is a camera
	if node is Camera3D:
		return node
	
	# Search through children
	for child in node.get_children():
		var result = find_camera_in_node(child)
		if result:
			return result
	
	return null

func trigger_jumpscare():
	is_jumpscaring = true
	jumpscare_timer = 0.0
	jumpscare_sound.play() 
	# Switch to jumpscare camera
	jumpscare_camera.current = true
	
	# Disable player input (optional - add this method to your player script)
	if player.has_method("disable_input"):
		player.disable_input()

func _process(delta):
	if is_jumpscaring:
		jumpscare_timer += delta
		
		if jumpscare_timer >= jumpscare_duration:
			# Switch back to player camera
			player_camera.current = true
			
			# Re-enable player input
			if player and player.has_method("enable_input"):
				player.enable_input()
			
			is_jumpscaring = false
			
			# Optional: disable this area so it doesn't trigger again
			queue_free()
