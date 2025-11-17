extends Control

@onready var button: Button = $restartButton

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	button.connect("pressed", Callable(self, "_on_button_pressed"))

func show_death_screen():
	visible = true
	get_tree().paused = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _on_restart_pressed() -> void:
	pass

func _on_restart_button_pressed() -> void:
	print("Restart button pressed!")
	get_tree().paused = false
	visible = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

	var player = get_tree().current_scene.get_node("Player3d")  # adjust name
	if player:
		player.reload()
	else:
		push_warning("⚠️ Player node not found")
