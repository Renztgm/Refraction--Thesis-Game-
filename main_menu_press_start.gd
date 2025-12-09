extends Control

@onready var icon: TextureRect = $Button/icon

func _ready() -> void:
	# Start transparent
	icon.modulate.a = 0.0

func _on_button_mouse_entered() -> void:
	var tween = create_tween()
	tween.tween_property(icon, "modulate:a", 1.0, 0.3) # fade in

func _on_button_mouse_exited() -> void:
	var tween = create_tween()
	tween.tween_property(icon, "modulate:a", 0.0, 0.3) # fade out



func _on_button_pressed() -> void:
	FadeOutCanvas.fade_out(0.3)
	await get_tree().create_timer(0.3).timeout
	get_tree().change_scene_to_file("res://scenes/Main Menu/main_menu.tscn")
