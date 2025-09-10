extends Area3D

@onready var dialogue_label: RichTextLabel = $"../CanvasLayer/DialogueLabel"

var notebook_message: String = "I used to come here. Someone read to me here... but who?"
var has_triggered: bool = false

func _ready():
	# Connect the signal for detecting the player entering the Area3D
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	if has_triggered:
		return
	if body.is_in_group("player"):
		has_triggered = true
		# Debug message
		print("DEBUG: Player entered the notebook area.")
		_show_text()

func _show_text() -> void:
	dialogue_label.text = notebook_message
