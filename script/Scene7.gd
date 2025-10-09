extends Node3D


@onready var fade_overlay: ColorRect = $Fade/FadeOverlay # make sure you add a ColorRect node called FadeOverlay that covers the whole screen

func _ready():
	# Start scene fully black
	if fade_overlay:
		fade_overlay.color = Color(0, 0, 0, 1)
		# Tween fade to transparent (reveal scene)
		var tween = create_tween()
		tween.tween_property(fade_overlay, "color", Color(0, 0, 0, 0), 2.0)
