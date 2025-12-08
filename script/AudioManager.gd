extends Node

var pool: Array[AudioStreamPlayer] = []
@export var pool_size := 10

func _ready():
	# Pre-create some stream players
	for i in range(pool_size):
		var p = AudioStreamPlayer.new()
		p.bus = "SFX"
		add_child(p)
		pool.append(p)


# ----------------------------------------------------------
# Public: Play UI sound by filepath OR AudioStream
# ----------------------------------------------------------
func play_ui_sound(sound):
	var stream := _get_stream(sound)
	if stream:
		_play_sound(stream)


# ----------------------------------------------------------
# Internal helpers
# ----------------------------------------------------------
func _get_stream(sound) -> AudioStream:
	if sound is AudioStream:
		return sound
	if sound is String:
		return load(sound)
	push_warning("Invalid sound: expected String path or AudioStream")
	return null

func _play_sound(stream: AudioStream):
	var p := _get_free_player()
	p.stream = stream
	p.play()

func _get_free_player() -> AudioStreamPlayer:
	for p in pool:
		if !p.playing:
			return p

	# None available → create new one
	var np = AudioStreamPlayer.new()
	np.bus = "SFX"
	add_child(np)
	pool.append(np)
	return np
