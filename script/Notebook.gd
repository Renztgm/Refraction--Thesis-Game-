extends Area3D

@onready var dialogue_label: RichTextLabel = $"../CanvasLayer/DialogueLabel"
@onready var flash_screen: ColorRect = $"../CanvasLayer/FlashScreen"
var notebook_message: String = "I used to come here. Someone read to me here... but who?"
var has_triggered: bool = false

func _ready():
	# Connect the signal for detecting the player entering the Area3D
	body_entered.connect(_on_body_entered)
	
	# Make sure flash screen is initially invisible
	if flash_screen:
		flash_screen.modulate.a = 0.0
		flash_screen.visible = false

func _on_body_entered(body: Node) -> void:
	if has_triggered:
		return
	if body.is_in_group("player"):
		has_triggered = true
		# Debug message
		print("DEBUG: Player entered the notebook area.")
		flash_effect()
		show_text()

func flash_effect() -> void:
	if not flash_screen:
		return
	
	flash_screen.visible = true
	var tween = create_tween()
	
	# First flash - strong
	tween.tween_method(set_flash_alpha, 0.0, 0.7, 0.05)
	tween.tween_method(set_flash_alpha, 0.7, 0.0, 0.1)
	tween.tween_interval(0.1)
	
	# Second flash - medium
	tween.tween_method(set_flash_alpha, 0.0, 0.5, 0.05)
	tween.tween_method(set_flash_alpha, 0.5, 0.0, 0.1)
	tween.tween_interval(0.15)
	
	# Third flash - weaker
	tween.tween_method(set_flash_alpha, 0.0, 0.3, 0.05)
	tween.tween_method(set_flash_alpha, 0.3, 0.0, 0.15)
	
	tween.tween_callback(func(): flash_screen.visible = false)

func set_flash_alpha(alpha: float) -> void:
	flash_screen.modulate.a = alpha

func show_text() -> void:
	dialogue_label.text = notebook_message
