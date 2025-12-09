extends Control

@onready var inventory_ui: Control = $UI/InventoryUI

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	FadeOutCanvas.fade_in(1.0)


func _on_branches_pressed() -> void:
	AudioMgr.play_ui_sound()
	var branch_map = load("res://scenes/branch selection/BranchMapViewer.tscn").instantiate()
	branch_map.set_meta("previous_scene", self)
	self.visible = false
	get_tree().root.add_child(branch_map)


func _on_inventory_pressed() -> void:
	AudioMgr.play_ui_sound()
	if inventory_ui:
		inventory_ui.visible = not inventory_ui.visible
		print("Inventory toggled:", inventory_ui.visible)
	else:
		push_error("Inventory UI node not found!")


func _on_main_menu_pressed() -> void:
	AudioMgr.play_ui_sound()
	hide()
	get_tree().change_scene_to_file("res://scenes/Main Menu/main_menu.tscn")
