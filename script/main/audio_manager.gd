extends Node

# --------------------
# Audio Stream Players (scene nodes)
# --------------------
@onready var BackgroundMusicPlayer: AudioStreamPlayer = $BackgroundMusic
@onready var UISoundPlayer: AudioStreamPlayer = $UISounds
@onready var WaterPlayer: AudioStreamPlayer = $WaterPlayer
@onready var WindPlayer: AudioStreamPlayer = $WindPlayer

# --------------------
# Preloaded audio
# --------------------
var wind_sound: AudioStream = preload("res://assets/audio/ambient/Wind Sound SOUND EFFECT - No Copyright[Download Free].mp3")
var water_sound: AudioStream = preload("res://assets/audio/ambient/BirdChirping.mp3")
var click_sound: AudioStream = preload("res://assets/audio/ui/Click_sound.wav")
var background_music: AudioStream = preload("res://assets/audio/music/time_for_adventure.mp3")

func _ready():
	print("📂 AudioManager ready")
	setup_ambient_sounds()
	start_background_music()

# --------------------
# Ambient Sounds
# --------------------
func setup_ambient_sounds():
	WindPlayer.stream = wind_sound
	WindPlayer.volume_db = -8
	WindPlayer.play()  # loops automatically if audio file is imported with loop enabled

	WaterPlayer.stream = water_sound
	WaterPlayer.volume_db = -15
	WaterPlayer.play()  # loops automatically

# --------------------
# Background Music
# --------------------
func start_background_music():
	BackgroundMusicPlayer.stream = background_music
	BackgroundMusicPlayer.volume_db = -10
	BackgroundMusicPlayer.play()  # loops automatically if imported with loop enabled

func stop_background_music():
	BackgroundMusicPlayer.stop()

# --------------------
# UI Sounds
# --------------------
func play_ui_sound():
	if UISoundPlayer:
		UISoundPlayer.stop()  # optional: stop previous sound
		UISoundPlayer.stream = click_sound
		UISoundPlayer.play()

# --------------------
# Stop All Music
# --------------------
func stop_all_music():
	WindPlayer.stop()
	WaterPlayer.stop()
	BackgroundMusicPlayer.stop()
