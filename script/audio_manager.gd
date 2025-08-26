extends Node
class_name AudioManager

@onready var background_music = $BackgroundMusic
@onready var ambient_sounds = $AmbientSounds
@onready var ui_sounds = $UISounds

func _ready():
	# Configure audio settings
	setup_audio_streams()

func setup_audio_streams():
	# Background music setup
	background_music.stream = preload("res://assets/audio/music/time_for_adventure.mp3")
	background_music.volume_db = -10
	background_music.autoplay = false
	
	# Ambient sounds setup
	ambient_sounds.stream = preload("res://assets/audio/ambient/Wind Sound SOUND EFFECT - No Copyright[Download Free].mp3")
	ambient_sounds.volume_db = -15
	ambient_sounds.autoplay = false

func play_background_music():
	if not background_music.playing:
		background_music.play()

func play_ambient_sounds():
	if not ambient_sounds.playing:
		ambient_sounds.play()

func play_ui_sound():
	ui_sounds.stream = preload("res://assets/audio/ui/Click_sound.wav")
	ui_sounds.play()

func stop_all_music():
	background_music.stop()
	ambient_sounds.stop()
