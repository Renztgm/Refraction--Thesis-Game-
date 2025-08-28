extends Control


func _create_option_button(text: String) -> Button:
	var btn = Button.new()
	btn.text = text
	
	# Make button fill horizontally
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	# Add padding (margins)
	btn.add_theme_constant_override("hseparation", 10)
	btn.add_theme_constant_override("vseparation", 6)
	
	# Font size override (bigger for readability)
	btn.add_theme_font_size_override("font_size", 24)

	# Style: Backgrounds for normal/hover/pressed
	var style_normal = StyleBoxFlat.new()
	style_normal.bg_color = Color(0.15, 0.15, 0.15, 0.8)
	style_normal.corner_radius_all = 12
	btn.add_theme_stylebox_override("normal", style_normal)

	var style_hover = StyleBoxFlat.new()
	style_hover.bg_color = Color(0.25, 0.25, 0.25, 0.9)
	style_hover.corner_radius_all = 12
	btn.add_theme_stylebox_override("hover", style_hover)

	var style_pressed = StyleBoxFlat.new()
	style_pressed.bg_color = Color(0.35, 0.35, 0.35, 1)
	style_pressed.corner_radius_all = 12
	btn.add_theme_stylebox_override("pressed", style_pressed)

	return btn
