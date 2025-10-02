# SimpleMemoryRoom.gd
# Simplified version for easier testing
extends Control

# Manual node assignment - drag from scene dock
@export var fade_overlay: ColorRect
@export var wake_up_text: RichTextLabel
@export var voice_text: RichTextLabel
@export var mc_thought_text: RichTextLabel

# Audio players
@export var static_player: AudioStreamPlayer
@export var whispers_player: AudioStreamPlayer
@export var voice_player: AudioStreamPlayer
@export var heartbeat_player: AudioStreamPlayer

# Audio streams
@export var static_audio: AudioStream
@export var whispers_audio: AudioStream
@export var voice_audio: AudioStream
@export var heartbeat_audio: AudioStream

var scene_phase = 0
var phase_timer = 0.0
var is_scene_active = false

# Simplified phase timing
var PHASE_TIMES = [2.0, 1.5, 2.0, 1.5, 2.0, 3.0]

func _ready():
	setup_simple_scene()

func setup_simple_scene():
	# Ensure we have the basic elements
	if not fade_overlay:
		push_error("Please assign fade_overlay in the inspector!")
		return
		
	# Initial setup
	fade_overlay.color = Color.BLACK
	fade_overlay.modulate.a = 0.0
	
	# Setup text elements if available
	if wake_up_text:
		wake_up_text.add_theme_color_override("default_color", Color.WHITE)
		wake_up_text.add_theme_font_size_override("normal_font_size", 48)
		wake_up_text.text = "[center]Wake up.[/center]"
		wake_up_text.modulate.a = 0.0
	
	if voice_text:
		voice_text.add_theme_color_override("default_color", Color(0.9, 0.8, 0.8))
		voice_text.add_theme_font_size_override("normal_font_size", 36)
		voice_text.modulate.a = 0.0
	
	if mc_thought_text:
		mc_thought_text.add_theme_color_override("default_color", Color(0.8, 0.9, 1.0))
		mc_thought_text.add_theme_font_size_override("normal_font_size", 28)
		mc_thought_text.modulate.a = 0.0

func start_memory_room():
	if is_scene_active:
		return
		
	is_scene_active = true
	scene_phase = 0
	phase_timer = 0.0
	
	print("Starting Memory Room sequence...")
	
	# Start basic audio
	if static_player and static_audio:
		static_player.stream = static_audio
		static_player.volume_db = -10.0
		static_player.play()

func _process(delta):
	if not is_scene_active:
		return
		
	phase_timer += delta
	
	# Handle current phase
	match scene_phase:
		0: phase_fade_in()
		1: phase_wake_up_text()
		2: phase_voice_line()
		3: phase_mc_thought()
		4: phase_heartbeat()
		5: phase_complete()
	
	# Check for phase advancement
	if scene_phase < PHASE_TIMES.size() and phase_timer >= PHASE_TIMES[scene_phase]:
		advance_phase()

func phase_fade_in():
	var progress = phase_timer / PHASE_TIMES[0]
	if fade_overlay:
		fade_overlay.modulate.a = progress * 0.8

func phase_wake_up_text():
	if wake_up_text:
		var flicker = sin(phase_timer * 20.0) * 0.3 + 0.7
		wake_up_text.modulate.a = flicker

func phase_voice_line():
	var progress = (phase_timer - PHASE_TIMES[1]) / PHASE_TIMES[2]
	
	if progress < 0.1 and voice_player and voice_audio:
		voice_player.stream = voice_audio
		voice_player.volume_db = -5.0
		voice_player.pitch_scale = 0.8
		voice_player.play()
		
		if voice_text:
			voice_text.text = "[center]You don't belong here.[/center]"
			var tween = create_tween()
			tween.tween_property(voice_text, "modulate:a", 1.0, 0.5)

func phase_mc_thought():
	var progress = (phase_timer - PHASE_TIMES[1] - PHASE_TIMES[2]) / PHASE_TIMES[3]
	
	if progress < 0.2 and mc_thought_text:
		mc_thought_text.text = "[center][i]What... was that voice?[/i][/center]"
		var tween = create_tween()
		tween.tween_property(mc_thought_text, "modulate:a", 1.0, 0.3)

func phase_heartbeat():
	var total_time = PHASE_TIMES[0] + PHASE_TIMES[1] + PHASE_TIMES[2] + PHASE_TIMES[3]
	var progress = (phase_timer - total_time) / PHASE_TIMES[4]
	
	if progress < 0.1 and heartbeat_player and heartbeat_audio:
		if static_player:
			static_player.stop()
		
		heartbeat_player.stream = heartbeat_audio
		heartbeat_player.volume_db = -8.0
		heartbeat_player.play()
	
	# Visual heartbeat pulse
	if fade_overlay:
		var pulse = sin(phase_timer * 2.0) * 0.2 + 0.8
		fade_overlay.modulate = Color(pulse * 0.1, 0, 0, 0.9)

func phase_complete():
	complete_sequence()

func advance_phase():
	scene_phase += 1
	print("Advancing to phase: ", scene_phase)

func complete_sequence():
	is_scene_active = false
	print("Memory Room sequence complete!")
	sequence_completed.emit()

# Public method to start
func trigger_sequence():
	start_memory_room()

signal sequence_completed
