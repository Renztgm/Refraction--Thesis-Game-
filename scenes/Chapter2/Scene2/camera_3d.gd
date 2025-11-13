extends Camera3D

var rotate_speed: float = 0.3
var dragging: bool = false
var last_mouse_pos: Vector2 = Vector2.ZERO

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			dragging = event.pressed
			last_mouse_pos = event.position

	if event is InputEventMouseMotion and dragging:
		var delta: Vector2 = event.relative
		rotation_degrees.x = clamp(rotation_degrees.x - delta.y * rotate_speed, -80, 80)
		rotation_degrees.y -= delta.x * rotate_speed
