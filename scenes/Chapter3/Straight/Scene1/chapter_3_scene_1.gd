extends Node3D

@onready var color_rect: Panel = $CanvasLayer/ColorRect
@onready var canvas_layer: CanvasLayer = $CanvasLayer
@onready var countdown_label: Label = $CanvasLayer/countdown

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	FadeOutCanvas.fade_in(1)
	sprint_notif()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

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

#func _on_panel_gui_input(event: InputEvent) -> void:
	#if event is InputEventMouseButton: 
		#if event.pressed and event.button_index == MouseButton.MOUSE_BUTTON_LEFT:
			#remove_canvas()
