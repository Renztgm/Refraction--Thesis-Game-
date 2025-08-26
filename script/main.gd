extends Node3D

@onready var audio_manager = $AudioManager

func _ready():
	# Start background music when scene loads
	audio_manager.play_background_music()
	audio_manager.play_ambient_sounds()
