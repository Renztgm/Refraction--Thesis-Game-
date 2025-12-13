extends Node3D

@onready var color_rect: Panel = $CanvasLayer/ColorRect
@onready var canvas_layer: CanvasLayer = $CanvasLayer
@onready var countdown_label: Label = $CanvasLayer/countdown
@onready var sound_player: AudioStreamPlayer = $echo_sound # Add this
@onready var sound_timer: Timer = $Timer  # Add this


func _ready() -> void:
	FadeOutCanvas.fade_in(1)
	sprint_notif()
	
	sound_timer.wait_time = 15
	sound_timer.one_shot = false  # Repeats automatically
	sound_timer.timeout.connect(_on_sound_timer_timeout)
	sound_timer.start()

func _process(delta: float) -> void:
	pass

func _on_sound_timer_timeout() -> void:
	# Play sound every 30 seconds
	sound_player.play()

func sprint_notif():
	get_tree().paused = true
	var tween := create_tween()
	tween.tween_property(canvas_layer, "modulate:a", 0.0, 0.0)
	var countdown = ["5", "4", "3", "2", "1", "Run!"]
	for text in countdown:
		countdown_label.text = text
		await get_tree().create_timer(1.0).timeout
	remove_canvas()

func remove_canvas():
	get_tree().paused = false
	canvas_layer.queue_free()
