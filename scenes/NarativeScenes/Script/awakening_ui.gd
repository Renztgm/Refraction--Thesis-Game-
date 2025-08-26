# awakening_ui.gd - Attach to UILayer (CanvasLayer)
extends CanvasLayer

@onready var dialogue_box = $DialogueBox
@onready var subtitle_text = $SubtitleText
@onready var interaction_prompts = $InteractionPrompts

func _ready():
	setup_ui_styles()

func setup_ui_styles():
	# Style the dialogue box for the mysterious atmosphere
	style_dialogue_box()
	style_subtitle_text()

func style_dialogue_box():
	if dialogue_box and dialogue_box.has_node("Panel"):
		var panel = dialogue_box.get_node("Panel")
		
		# Create a dark, atmospheric style
		var style_box = StyleBoxFlat.new()
		style_box.bg_color = Color(0.1, 0.1, 0.1, 0.8)  # Dark transparent
		style_box.border_width_left = 2
		style_box.border_width_right = 2  
		style_box.border_width_top = 2
		style_box.border_width_bottom = 2
		style_box.border_color = Color(0.3, 0.6, 0.4)  # Emerald border
		style_box.corner_radius_top_left = 10
		style_box.corner_radius_top_right = 10
		style_box.corner_radius_bottom_left = 10
		style_box.corner_radius_bottom_right = 10
		
		panel.add_theme_stylebox_override("panel", style_box)

func style_subtitle_text():
	if subtitle_text:
		subtitle_text.add_theme_color_override("font_color", Color.WHITE)
		subtitle_text.add_theme_color_override("font_shadow_color", Color.BLACK)
		subtitle_text.add_theme_constant_override("shadow_offset_x", 2)
		subtitle_text.add_theme_constant_override("shadow_offset_y", 2)

func create_atmospheric_ui():
	# Add some atmospheric UI elements
	create_vignette_effect()
	
func create_vignette_effect():
	# Create a subtle vignette to enhance the mysterious mood
	var vignette = ColorRect.new()
	vignette.name = "Vignette"
	vignette.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	
	# Create gradient for vignette effect
	var gradient = Gradient.new()
	gradient.add_point(0.0, Color.TRANSPARENT)
	gradient.add_point(0.7, Color.TRANSPARENT)  
	gradient.add_point(1.0, Color(0, 0, 0, 0.3))  # Dark edges
	
	var gradient_texture = GradientTexture2D.new()
	gradient_texture.gradient = gradient
	gradient_texture.fill_from = Vector2(0.5, 0.5)  # Center
	gradient_texture.fill_to = Vector2(1.0, 0.5)    # Edge
	gradient_texture.fill = GradientTexture2D.FILL_RADIAL
	
	vignette.texture = gradient_texture
	add_child(vignette)
	
	# Send to back
	move_child(vignette, 0)
