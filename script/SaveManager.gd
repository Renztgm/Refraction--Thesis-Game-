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

func _ready():
	print("SaveManager ready!")
	print("Save file will be stored at: ", ProjectSettings.globalize_path(SAVE_FILE))

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
		get_tree().change_scene_to_file(scene_path)  # Fixed typo: was "change_scene_to_fiale"
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
