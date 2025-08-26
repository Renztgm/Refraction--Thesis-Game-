extends CharacterBody3D

@onready var hum_player: AudioStreamPlayer3D = $hum_player

func _ready():
	hum_player.stream = preload("res://assets/audio/ambient/humming.mp3")
	hum_player.stream.loop = true
	hum_player.play()

	# How far sound carries
	hum_player.unit_size = 5.0
	hum_player.max_distance = 50.0
	hum_player.attenuation_model = AudioStreamPlayer3D.ATTENUATION_DISABLED
	hum_player.volume_db = -6
	hum_player.play()
