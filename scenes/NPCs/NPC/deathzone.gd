extends Area3D

# Signal will fire when something enters the area
func _ready():
	connect("body_entered", Callable(self, "_on_body_entered"))

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):  # safer than checking node name
		body.die()  # Call a custom function on the player
