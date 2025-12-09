extends CanvasLayer

@onready var white: ColorRect = $White
@onready var fade_rect: ColorRect = $ColorRect
var tween: Tween

func _ready():
	white.modulate.a = 0.0
	fade_rect.modulate.a = 0.0
	visible = false

func fade_out(duration: float = 1.0, callback: Callable = Callable()):
	visible = true
	tween = create_tween()
	tween.tween_property(fade_rect, "modulate:a", 1.0, duration)
	if callback.is_valid():
		tween.tween_callback(callback)

func fade_in(duration: float = 1.0):
	visible = true
	fade_rect.modulate.a = 1.0
	tween = create_tween()
	tween.tween_property(fade_rect, "modulate:a", 0.0, duration)
	tween.tween_callback(func(): visible = false)
	
func fade_out_white(duration: float = 1.0, callback: Callable = Callable()):
	visible = true
	tween = create_tween()
	tween.tween_property(white, "modulate:a", 1.0, duration)
	if callback.is_valid():
		tween.tween_callback(callback)

func fade_in_white(duration: float = 1.0):
	visible = true
	white.modulate.a = 1.0
	tween = create_tween()
	tween.tween_property(white, "modulate:a", 0.0, duration)
	tween.tween_callback(func(): visible = false)
