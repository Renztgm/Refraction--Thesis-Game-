extends HBoxContainer

signal load_pressed(profile)
signal delete_pressed(profile)

var profile: Dictionary

@onready var name_label: Label = $MarginContainer/MarginContainer/VBoxContainer/NameLabel
@onready var last_played_label: Label = $MarginContainer/MarginContainer/VBoxContainer/LastPlayedLabel
@onready var load_button: Button = $MarginContainer/MarginContainer/VBoxContainer2/LoadButton
@onready var delete_button: Button = $MarginContainer/MarginContainer/VBoxContainer2/DeleteButton
@onready var color_rect: Panel = $MarginContainer/ColorRect
@onready var delete_icon: TextureRect = $MarginContainer/MarginContainer/VBoxContainer2/DeleteButton/DeleteIcon

var normal_texture = preload("res://assets/ui/trash_close.png")
var hover_texture = preload("res://assets/ui/trash_open.png")

func _ready():
	delete_icon.texture = normal_texture



func set_profile(p: Dictionary):
	profile = p
	name_label.text = p.player_name
	last_played_label.text = "Last played: %s" % p.last_played

	load_button.pressed.connect(func(): emit_signal("load_pressed", profile))
	delete_button.pressed.connect(func(): emit_signal("delete_pressed", profile))
	
func _on_mouse_entered() -> void:
	var stylebox = StyleBoxFlat.new()
	stylebox.bg_color = Color(0.141, 0.231, 0.153)
	stylebox.shadow_size = 10
	stylebox.shadow_color = Color(1,1,1,1)
	stylebox.border_width_bottom = 15
	stylebox.border_color = Color(0.09, 0.157, 0.098)
	stylebox.border_blend = true
	stylebox.corner_radius_bottom_left = 20
	stylebox.corner_radius_bottom_right = 20
	stylebox.corner_radius_top_right = 20
	stylebox.corner_radius_top_left = 20
	color_rect.add_theme_stylebox_override("panel", stylebox)

func _on_mouse_exited() -> void:
	var stylebox = StyleBoxFlat.new()
	stylebox.bg_color = Color(0.141, 0.231, 0.153)
	stylebox.shadow_size = 0
	stylebox.shadow_color = Color(1,1,1,1)
	stylebox.border_width_bottom = 35
	stylebox.border_color = Color(0.09, 0.157, 0.098)
	stylebox.border_blend = true
	stylebox.corner_radius_bottom_left = 20
	stylebox.corner_radius_bottom_right = 20
	stylebox.corner_radius_top_right = 20
	stylebox.corner_radius_top_left = 20
	color_rect.add_theme_stylebox_override("panel", stylebox)

func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton: 
		if event.pressed and event.button_index == MouseButton.MOUSE_BUTTON_LEFT:
			AudioMgr.play_ui_sound("res://assets/audio/ui/Click_sound.wav")
			emit_signal("load_pressed", profile)


func _on_delete_button_mouse_entered() -> void:
	delete_icon.texture = hover_texture


func _on_delete_button_mouse_exited() -> void:
	delete_icon.texture = normal_texture
