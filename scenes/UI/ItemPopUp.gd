extends CanvasLayer

@onready var message_label: Label = $Panel/MessageLabel

func _ready() -> void:
	if message_label == null:
		push_error("❌ MessageLabel not found. Check node names and structure.")
	else:
		print("✅ MessageLabel found:", message_label)

func show_message(text: String, duration := 2.0) -> void:
	if message_label == null:
		push_error("❌ Cannot show message — MessageLabel is missing.")
		return

	message_label.text = text
	visible = true
	create_timer(duration).timeout.connect(hide)

func create_timer(seconds: float) -> Timer:
	var timer = Timer.new()
	timer.wait_time = seconds
	timer.one_shot = true
	add_child(timer)
	timer.start()
	return timer
