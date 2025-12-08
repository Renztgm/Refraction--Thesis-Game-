extends Button

@export var texture: TextureRect
@export var target_button: Button


func _ready() -> void:
	target_button.mouse_entered.connect(_on_button_mouse_entered)
	target_button.mouse_exited.connect(_on_button_mouse_exited)
	target_button.pressed.connect(_on_button_pressed)
	texture.modulate.a = 0.0

func _on_button_mouse_entered() -> void:
	push_warning("hoverred! ", target_button)
	var tween = create_tween()
	tween.tween_property(texture, "modulate:a", 1.0, 0.3) # fade in

func _on_button_mouse_exited() -> void:
	var tween = create_tween()
	tween.tween_property(texture, "modulate:a", 0.0, 0.3) # fade out



func _on_button_pressed() -> void:
	FadeOutCanvas.fade_out(0.3)
