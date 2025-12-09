extends Sprite2D

@export var bob_amplitude : float = 10.0   # how far it moves up/down
@export var bob_speed : float = 2.0        # how fast it bobs

var base_position : Vector2

func _ready() -> void:
	# store the starting position so bobbing happens around it
	base_position = position

func _physics_process(delta: float) -> void:
	# use sine wave to offset the Y position
	var offset_y = sin(Time.get_ticks_msec() / 1000.0 * bob_speed) * bob_amplitude
	position = base_position + Vector2(0, offset_y)
