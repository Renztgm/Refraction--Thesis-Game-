extends Node

const SAVE_FILE = "user://savegame.save"

# Game data
var game_data = {
	"player_name": "Player",
	"current_scene": "",
	"player_position": {"x": 0, "y": 0, "z": 0},
	"player_direction": "down",  # store as string
	"has_save": false
}

# Prevent multiple dialogs
var is_dialog_open = false

func _ready():
	print("SaveManager ready!")
	print("Save file will be stored at: ", ProjectSettings.globalize_path(SAVE_FILE))
	
	# Prevent immediate quit - we want to show a dialog first
	get_tree().set_auto_accept_quit(false)

func _notification(what):
	match what:
		NOTIFICATION_WM_CLOSE_REQUEST:
			print("❌ Close button (X) pressed - showing save dialog...")
			_show_save_confirmation_dialog()
		NOTIFICATION_WM_GO_BACK_REQUEST:  # Android back button
			print("🔙 Back button pressed - showing save dialog...")
			_show_save_confirmation_dialog()

func _show_save_confirmation_dialog():
	# Prevent multiple dialogs from opening
	if is_dialog_open:
		print("⚠️ Dialog already open - ignoring request")
		return
	
	# Check if we're in gameplay (not in menus)
	var current_scene_name = get_tree().current_scene.scene_file_path
	
	# Add your gameplay scene paths here
	var gameplay_scenes = [
		"res://scenes/main.tscn",
		"res://scenes/level1.tscn",
		"res://scenes/overworld.tscn"
		# Add other gameplay scenes where saving makes sense
	]
	
	if current_scene_name in gameplay_scenes:
		# Set flag to prevent multiple dialogs
		is_dialog_open = true
		
		# Load the custom dialog scene
		var dialog_scene = preload("res://scenes/SaveConfirmDialog.tscn")
		var dialog_instance = dialog_scene.instantiate()
		
		# Connect the signals from the custom dialog
		dialog_instance.save_and_quit_requested.connect(_on_save_and_quit)
		dialog_instance.quit_without_save_requested.connect(_on_quit_without_saving)
		dialog_instance.dialog_cancelled.connect(_on_cancel_quit)
		
		# Connect to tree_exiting to reset flag when dialog is freed
		dialog_instance.tree_exiting.connect(_on_dialog_closed)
		
		# Add dialog to the current scene
		get_tree().current_scene.add_child(dialog_instance)
	else:
		# In menu - just quit without asking
		print("📋 In menu - quitting immediately")
		get_tree().quit()

func _on_dialog_closed():
	# Reset the flag when dialog is closed
	is_dialog_open = false
	print("🔄 Dialog closed - ready for next request")

# Updated signal handlers (no dialog parameter needed)
func _on_save_and_quit():
	print("💾 Player chose to save and quit")
	is_dialog_open = false  # Reset flag before quitting
	save_game()
	get_tree().quit()

func _on_quit_without_saving():
	print("🚪 Player chose to quit without saving")
	is_dialog_open = false  # Reset flag before quitting
	get_tree().quit()

func _on_cancel_quit():
	print("❌ Player cancelled quit - continuing game")
	is_dialog_open = false  # Reset flag when cancelled
	# The SaveConfirmDialog handles its own cleanup

# ---------------- SAVE ----------------
func save_game() -> bool:
	game_data["current_scene"] = get_tree().current_scene.scene_file_path
	
	var player = get_tree().get_first_node_in_group("player")
	if player:
		# Save position
		game_data["player_position"] = {
			"x": player.position.x,
			"y": player.position.y,
			"z": player.position.z
		}
		# Save direction
		if "last_direction" in player:
			game_data["player_direction"] = str(player.last_direction)
		
		# 🔹 Debug output for saved values
		print("💾 Saving player position: ", player.position)
		print("💾 Saving player direction: ", player.last_direction)
	
	game_data["has_save"] = true
	
	var save_file = FileAccess.open(SAVE_FILE, FileAccess.WRITE)
	if save_file:
		save_file.store_string(JSON.stringify(game_data))
		save_file.close()
		print("✅ Game saved successfully at: ", ProjectSettings.globalize_path(SAVE_FILE))
		return true
	return false

# ---------------- LOAD ----------------
func has_save_file() -> bool:
	return FileAccess.file_exists(SAVE_FILE)

func load_game() -> bool:
	if not FileAccess.file_exists(SAVE_FILE):
		print("⚠️ No save file found at: ", ProjectSettings.globalize_path(SAVE_FILE))
		return false
	
	var save_file = FileAccess.open(SAVE_FILE, FileAccess.READ)
	if not save_file:
		print("⚠️ Could not open save file")
		return false
	
	var json_string = save_file.get_as_text()
	save_file.close()
	
	var json = JSON.new()
	var parse_result = json.parse(json_string)
	
	if parse_result != OK:
		print("⚠️ Could not parse save file")
		return false
	
	game_data = json.data
	
	# 🔹 Debug output for loaded values
	if game_data.has("player_position"):
		print("📂 Loaded player position: ", Vector3(
			game_data["player_position"]["x"],
			game_data["player_position"]["y"],
			game_data["player_position"]["z"]
		))
	if game_data.has("player_direction"):
		print("📂 Loaded player direction: ", game_data["player_direction"])
	
	print("✅ Game loaded successfully from: ", ProjectSettings.globalize_path(SAVE_FILE))
	return true

# ---------------- CONTINUE ----------------
func continue_game():
	if not load_game():
		print("⚠️ No save file to continue from.")
		return
	
	if game_data.has("current_scene") and game_data["current_scene"] != "":
		var scene_path = game_data["current_scene"]
		print("➡️ Continuing game from scene: ", scene_path)
		get_tree().change_scene_to_file(scene_path)
	else:
		print("⚠️ Save file has no scene path.")

# ---------------- NEW GAME ----------------
func start_new_game():
	print("🆕 Starting new game - clearing save data")
	
	# Reset game data to defaults
	game_data = {
		"player_name": "Player",
		"current_scene": "",
		"player_position": {"x": 0, "y": 0, "z": 0},
		"player_direction": "down",
		"has_save": false
	}
	
	# Delete the save file if it exists
	if FileAccess.file_exists(SAVE_FILE):
		var dir = DirAccess.open("user://")
		if dir:
			dir.remove("savegame.save")
			print("🗑️ Deleted existing save file")

# ---------------- GETTERS ----------------
func get_saved_player_position() -> Vector3:
	if game_data.has("player_position"):
		var pos = game_data["player_position"]
		return Vector3(pos["x"], pos["y"], pos["z"])
	return Vector3.ZERO

func get_saved_player_direction() -> String:
	if game_data.has("player_direction"):
		return str(game_data["player_direction"])
	return "down"
