extends Node3D

@onready var hint = $ControlHint
var has_faded_out := false

func _ready():
	hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hint.visible = true
	hint.modulate.a = 1.0
	await get_tree().create_timer(20.0).timeout
	if not has_faded_out:
		_start_fade_out()

func _process(delta):
	if has_faded_out:
		return

	if Input.is_physical_key_pressed(KEY_W) \
	or Input.is_physical_key_pressed(KEY_A) \
	or Input.is_physical_key_pressed(KEY_S) \
	or Input.is_physical_key_pressed(KEY_D):
		_start_fade_out()

func _start_fade_out():
	has_faded_out = true
	var tween := create_tween()
	tween.tween_property(hint, "modulate:a", 0.0, 1.0)
	tween.tween_callback(func(): hint.hide())  # Correct usage
