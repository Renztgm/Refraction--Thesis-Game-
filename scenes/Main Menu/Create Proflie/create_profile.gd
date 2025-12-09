extends Control
@onready var name_input: LineEdit = $MarginContainer/VBoxContainer/NameInput
@onready var confirm_button: Button = $MarginContainer/VBoxContainer/ConfirmButton

func _ready() -> void:
	FadeOutCanvas.fade_in(0.3)
	confirm_button.pressed.connect(_on_confirm_pressed)

func _on_confirm_pressed() -> void:
	var player_name: String = name_input.text.strip_edges()
	if player_name.is_empty():
		player_name = "Player" + str(randi() % 1000)

	var new_id: int = ProfileManager.create_profile(player_name)
	print("Created profile id=%d name=%s" % [new_id, player_name])

	get_tree().change_scene_to_file("res://scenes/Main Menu/Load Slot/load_slot.tscn")
	
func _on_button_pressed() -> void:
	FadeOutCanvas.fade_out(0.3)
	get_tree().change_scene_to_file("res://scenes/Main Menu/main_menu.tscn")
