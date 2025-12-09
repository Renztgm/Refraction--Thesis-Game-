extends Control

# References to child nodes - Fixed paths!
@onready var canvas_layer: CanvasLayer = $CanvasPause  # The CanvasLayer child
@onready var pause_menu: Control = $CanvasPause/PauseMenu
@onready var settings_ui: Control = $CanvasPause/SettingsUI

var naka_pause := false

func _ready():
	print("🔍 CanvasPause Debug:")
	print("  - Children count: ", get_children().size())
	
	# If no children exist, try to load them from scene files
	if get_children().size() == 0:
		print("  ⚠️ NO CHILDREN FOUND! Creating structure programmatically...")
		create_ui_structure()
	else:
		setup_existing_structure()

func create_ui_structure():
	# Create the CanvasLayer
	canvas_layer = CanvasLayer.new()
	canvas_layer.name = "CanvasPause"
	canvas_layer.layer = 50
	canvas_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(canvas_layer)
	
	# Try to load and instantiate PauseMenu
	var pause_menu_scene = load("res://scenes/UI/PauseMenu.tscn")  # Adjust path as needed
	if pause_menu_scene:
		pause_menu = pause_menu_scene.instantiate()
		canvas_layer.add_child(pause_menu)
		pause_menu.hide()
		pause_menu.set_anchors_preset(Control.PRESET_FULL_RECT)
		print("  ✅ PauseMenu created from scene file")
	else:
		print("  ❌ Could not load PauseMenu scene - check the path")
	
	# Try to load and instantiate SettingsUI
	var settings_ui_scene = load("res://scenes/UI/SettingsUI.tscn")  # Adjust path as needed
	if settings_ui_scene:
		settings_ui = settings_ui_scene.instantiate()
		canvas_layer.add_child(settings_ui)
		settings_ui.hide()
		settings_ui.set_anchors_preset(Control.PRESET_FULL_RECT)
		print("  ✅ SettingsUI created from scene file")
	else:
		print("  ❌ Could not load SettingsUI scene - check the path")

func setup_existing_structure():
	# Try to find nodes using the original paths
	canvas_layer = find_child("CanvasPause", true, false)
	pause_menu = find_child("PauseMenu", true, false)
	settings_ui = find_child("SettingsUI", true, false)
	
	print("  - canvas_layer: ", canvas_layer)
	print("  - pause_menu: ", pause_menu)
	print("  - settings_ui: ", settings_ui)
	
	# Configure found nodes
	if pause_menu:
		pause_menu.hide()
		pause_menu.set_anchors_preset(Control.PRESET_FULL_RECT)
		print("  ✅ PauseMenu configured")
	
	if settings_ui:
		settings_ui.hide()
		settings_ui.set_anchors_preset(Control.PRESET_FULL_RECT)
	
	if canvas_layer:
		canvas_layer.layer = 50
		canvas_layer.process_mode = Node.PROCESS_MODE_ALWAYS
		print("  ✅ CanvasLayer configured")
	
	# Itago ang UI sa simula
	if pause_menu:
		pause_menu.hide()
		pause_menu.set_anchors_preset(Control.PRESET_FULL_RECT)
		print("  ✅ PauseMenu hidden and configured")
	else:
		print("  ❌ PauseMenu not found!")
		
	if settings_ui:
		settings_ui.hide()
		settings_ui.set_anchors_preset(Control.PRESET_FULL_RECT)
	
	# Settings ng CanvasLayer
	if canvas_layer:
		canvas_layer.layer = 50
		canvas_layer.process_mode = Node.PROCESS_MODE_ALWAYS
		print("  ✅ CanvasLayer configured")
	else:
		print("  ❌ CanvasLayer not found!")

# -------------------------------
# Public API
# -------------------------------
func get_settings_ui() -> Control:
	return settings_ui

func ipakita_pause_menu():
	print("Pumunta sa ipakita_pause_menu")

	if pause_menu:
		push_warning("PauseMenu visible before show(): ", pause_menu.visible)

		# 1️⃣ Show UI immediately
		pause_menu.show()
		naka_pause = true
		
		# 2️⃣ Ensure mouse is visible right now
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

		# 3️⃣ Wait one frame before pausing → stops black flash & mouse disappearing
		await get_tree().process_frame

		# 4️⃣ NOW pause the tree (no black screen)
		get_tree().paused = true

		# 5️⃣ Force cursor visible again
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

		# 6️⃣ Focus resume button if available
		if pause_menu.has_method("focus_resume_button"):
			pause_menu.focus_resume_button()
		elif pause_menu.get("resume_button"):
			pause_menu.resume_button.grab_focus()

func toggle_pause_menu():
	print("Pumunta sa toggle_pause_menu")
	#if naka_pause:
		#itago_pause_menu()
	#else:
	ipakita_pause_menu()
