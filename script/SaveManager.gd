# SaveManager.gd
# Autoload singleton
extends Node

const SAVE_FILE = "user://savegame.save"

# Data stored in the save file
var game_data = {
	"player_name": "Player",
	"current_scene": "",
	"player_position": {"x": 0.0, "y": 0.0, "z": 0.0},
	"player_direction": "down",
	"has_save": false
}

func _ready():
	print("SaveManager ready!")

# Save the current game state
func save_game() -> bool:
	# Save current scene path
	game_data["current_scene"] = get_tree().current_scene.scene_file_path
	
	# Save player data
	var player = get_tree().get_first_node_in_group("player")
	if player:
		var pos: Vector3 = player.global_position
		game_data["player_position"] = {"x": pos.x, "y": pos.y, "z": pos.z}
		
		if player.has_method("get_last_direction"):
			game_data["player_direction"] = player.get_last_direction()
	
	# Mark save as valid
	game_data["has_save"] = true
	
	# Write JSON file
	var file = FileAccess.open(SAVE_FILE, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(game_data))
		file.close()
		print("Game saved successfully!")
		return true
	else:
		push_error("SaveManager: Could not save game!")
		return false

# Load the saved game
func load_game() -> bool:
	if not FileAccess.file_exists(SAVE_FILE):
		print("No save file found")
		return false
	
	var file = FileAccess.open(SAVE_FILE, FileAccess.READ)
	if not file:
		print("Error: Could not open save file")
		return false
	
	var json_string = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	if json.parse(json_string) != OK:
		print("Error: Could not parse save file")
		return false
	
	game_data = json.data
	print("Game loaded successfully!")
	return true

# Check if save exists
func has_save_file() -> bool:
	return FileAccess.file_exists(SAVE_FILE) and game_data.get("has_save", false)

# Continue from save
func continue_game() -> bool:
	if load_game():
		if game_data.has("current_scene") and game_data["current_scene"] != "":
			get_tree().change_scene_to_file(game_data["current_scene"])
			return true
	return false

# --- Accessors for Player.gd ---
func get_saved_player_position() -> Vector3:
	if game_data.has("player_position"):
		var pos = game_data["player_position"]
		return Vector3(pos.get("x", 0.0), pos.get("y", 0.0), pos.get("z", 0.0))
	return Vector3.ZERO

func get_saved_player_direction() -> String:
	return game_data.get("player_direction", "down")
