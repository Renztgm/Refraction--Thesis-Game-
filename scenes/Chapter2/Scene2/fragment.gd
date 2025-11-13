extends Sprite2D

var is_dragging: bool = false
var correct_position: Vector2
var snap_threshold: float = 20.0

func _ready():
	# Save the correct position from the editor
	correct_position = position

func _input(event):
	# Check PuzzleManager lock before allowing drag
	var manager = get_parent().get_parent().get_node("PuzzleManager")
	if manager.puzzle_locked:
		return

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed and get_rect().has_point(to_local(event.position)):
			is_dragging = true
		elif not event.pressed and is_dragging:
			is_dragging = false
			try_snap()

	elif event is InputEventMouseMotion and is_dragging:
		position += event.relative

func try_snap():
	if position.distance_to(correct_position) < snap_threshold:
		position = correct_position
