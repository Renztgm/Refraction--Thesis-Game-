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

# Quest message with yellow/gold color
func quest_show_message(text: String, duration: float = 3.0) -> void:
	var quest_color := Color(1.0, 0.84, 0.0)  # Gold color
	show_message("🎯 New Quest! " + text, duration, quest_color)

# Item obtained with green color
func item_obtained_message(item_name: String, duration: float = 2.5) -> void:
	var item_color := Color(0.4, 1.0, 0.4)  # Light green
	show_message("✨ Obtained: " + item_name, duration, item_color)

# Shard obtained with cyan/blue color
func shard_obtained_message(shard_count: int, duration: float = 2.5) -> void:
	var shard_color := Color(0.3, 0.8, 1.0)  # Cyan blue
	show_message("💎 +" + str(shard_count) + " Shard(s)", duration, shard_color)

func _auto_hide() -> void:
	# Fade out the Panel over 0.5 seconds, then hide the CanvasLayer
	var tween := create_tween()
	tween.tween_property(panel, "modulate:a", 0.0, 0.5)
	tween.finished.connect(_after_fade)

func _after_fade() -> void:
	hide()
	# Reset alpha so next message starts visible
	panel.modulate.a = 1.0
