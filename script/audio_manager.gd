extends Node
class_name AudioManager

@onready var background_music: AudioStreamPlayer = $BackgroundMusic
@onready var hum_player: AudioStreamPlayer3D = $"../Entities/Npc1/hum_player" # must exist inside NPC
@onready var WindPlayer: AudioStreamPlayer = $WindPlayer
@onready var WaterPlayer: AudioStreamPlayer = $WaterPlayer
@onready var ui_sounds: AudioStreamPlayer = $UISounds

func _ready():
	setup_audio_streams()
	play_ambient_sounds() # 🔹 Start ambience (including humming) immediately

func setup_audio_streams():
	# Ambient sounds
	var hum = preload("res://assets/audio/ambient/humming.mp3")
	var wind = preload("res://assets/audio/ambient/BirdChirping.mp3")
	var water = preload("res://assets/audio/ambient/Wind Sound SOUND EFFECT - No Copyright[Download Free].mp3")

	# Humming (directional, from NPC)
	hum_player.stream = hum
	hum_player.unit_size = 1.0     # how far sound carries (lower = louder nearby)
	hum_player.max_distance = 30.0 # fades out fully at this distance
	hum_player.volume_db = -12
	hum_player.stream.loop = true  # 🔹 Make sure it loops

	# Wind
	WindPlayer.stream = wind
	WindPlayer.volume_db = -8
	WindPlayer.stream.loop = true

	# Water
	WaterPlayer.stream = water
	WaterPlayer.volume_db = -15
	WaterPlayer.stream.loop = true

	# Background music starts after 30 sec
	start_background_music_after_delay(30.0)

func play_ambient_sounds():
	if hum_player and not hum_player.playing:
		hum_player.play()
	if WindPlayer and not WindPlayer.playing:
		WindPlayer.play()
	if WaterPlayer and not WaterPlayer.playing:
		WaterPlayer.play()

func start_background_music_after_delay(delay: float) -> void:
	await get_tree().create_timer(delay).timeout
	play_background_music()

func play_background_music():
	if not background_music.playing:
		background_music.stream = preload("res://assets/audio/music/time_for_adventure.mp3")
		background_music.volume_db = -30
		background_music.play()

func play_ui_sound():
	ui_sounds.stream = preload("res://assets/audio/ui/Click_sound.wav")
	ui_sounds.play()

func stop_all_music():
	background_music.stop()
	hum_player.stop()
	WindPlayer.stop()
	WaterPlayer.stop()
