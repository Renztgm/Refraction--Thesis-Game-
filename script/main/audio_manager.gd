extends Node
class_name AudioManager

#@onready var background_music: AudioStreamPlayer = $BackgroundMusic
@onready var WindPlayer: AudioStreamPlayer = $WindPlayer
@onready var WaterPlayer: AudioStreamPlayer = $WaterPlayer
@onready var ui_sounds: AudioStreamPlayer = $UISounds

func _ready():
	setup_audio_streams()

func setup_audio_streams():
	# Ambient sounds
	var wind = preload("res://assets/audio/ambient/BirdChirping.mp3")
	var water = preload("res://assets/audio/ambient/Wind Sound SOUND EFFECT - No Copyright[Download Free].mp3")

	# After 30 seconds, start background music
	#start_background_music_after_delay(30.0)

	# Wind (loop)
	WindPlayer.stream = wind
	WindPlayer.volume_db = -8
	WindPlayer.play()

	# Water (loop)
	WaterPlayer.stream = water
	WaterPlayer.volume_db = -15
	WaterPlayer.play()

#func start_background_music_after_delay(delay: float) -> void:
	#await get_tree().create_timer(delay).timeout
	#play_background_music()

#func play_background_music():
	#if not background_music.playing:
		#background_music.stream = preload("res://assets/audio/music/time_for_adventure.mp3")
		#background_music.volume_db = -10
		#background_music.play()

func play_ui_sound():
	ui_sounds.stream = preload("res://assets/audio/ui/Click_sound.wav")
	ui_sounds.play()

func stop_all_music():
	#background_music.stop()
	WindPlayer.stop()
	WaterPlayer.stop()
