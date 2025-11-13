extends CanvasLayer

@onready var panel: Control = $Panel
@onready var message_label: Label = $Panel/MessageLabel

func _ready() -> void:
	if message_label == null or panel == null:
		push_error("❌ Itempopup missing Panel/MessageLabel. Check node names.")
		return
	visible = false
	print("✅ Itempopup ready")

func show_message(text: String, duration: float = 2.0, color: Color = Color.WHITE) -> void:
	if message_label == null or panel == null:
		push_error("❌ Cannot show message — Panel/MessageLabel is missing.")
		return

	message_label.text = text
	message_label.add_theme_color_override("font_color", color)

	# Reset alpha in case it was faded before
	panel.modulate.a = 1.0
	visible = true

	var timer := Timer.new()
	timer.wait_time = duration
	timer.one_shot = true
	add_child(timer)
	timer.timeout.connect(_auto_hide)
	timer.start()

func _auto_hide() -> void:
	# Fade out the Panel over 0.5 seconds, then hide the CanvasLayer
	var tween := create_tween()
	tween.tween_property(panel, "modulate:a", 0.0, 0.5)
	tween.finished.connect(_after_fade)

func _after_fade() -> void:
	hide()
	# Reset alpha so next message starts visible
	panel.modulate.a = 1.0
