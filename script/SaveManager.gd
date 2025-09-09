extends Node

# Path to the SQLite database file
const DB_PATH: String = "user://game_data.db"

# Game data structure
var game_data: Dictionary = {
	"player_name": "Player",
	"current_scene": "",
	"player_position": {"x": 0.0, "y": 0.0, "z": 0.0},
	"player_direction": "down",
	"has_save": false
}

# SQLite database object
var db: SQLite

func _ready() -> void:
	print("📂 SaveManager ready")

	# Create SQLite instance
	db = SQLite.new()
	db.path = DB_PATH
	db.open_db()

	# Ensure save table exists
	db.query("""
		CREATE TABLE IF NOT EXISTS save_data (
			id INTEGER PRIMARY KEY AUTOINCREMENT,
			player_name TEXT,
			current_scene TEXT,
			pos_x REAL,
			pos_y REAL,
			pos_z REAL,
			direction TEXT,
			has_save INTEGER
		);
	""")

# ---------------- SAVE ----------------
func save_game() -> bool:
	var player := get_tree().get_first_node_in_group("player")
	if player:
		game_data["player_position"] = {
			"x": player.position.x,
			"y": player.position.y,
			"z": player.position.z if "position" in player else 0.0
		}
		if "last_direction" in player:
			game_data["player_direction"] = str(player.last_direction)

	var scene = get_tree().current_scene
	game_data["current_scene"] = scene.scene_file_path if scene else ""

	game_data["has_save"] = true

	var ok = bool(db.query_with_bindings("""
		INSERT INTO save_data (
			player_name, current_scene, pos_x, pos_y, pos_z, direction, has_save
		) VALUES (?, ?, ?, ?, ?, ?, ?);
	""", [
		game_data["player_name"],
		game_data["current_scene"],
		game_data["player_position"]["x"],
		game_data["player_position"]["y"],
		game_data["player_position"]["z"],
		game_data["player_direction"],
		int(game_data["has_save"])
	]))

	if ok:
		print("💾 Game saved into SQLite")
		debug_print_saves()
	else:
		print("⚠️ Failed to save game")

	return ok

# ---------------- LOAD ----------------
func has_save_file() -> bool:
	if db:  # make sure DB is open
		var result: Array = db.select_rows(
			"save_data",
			"player_name, current_scene, pos_x, pos_y, pos_z, direction, has_save",
			[]
		)
	return false


# Coroutine-safe load_game
func load_game() -> bool:
	var result: Array = db.select_rows(
		"save_data",
		"player_name, current_scene, pos_x, pos_y, pos_z, direction, has_save",
		[]
	)

	if result.size() > 0:
		var row: Dictionary = result[result.size() - 1] # last inserted row
		game_data = {
			"player_name": row["player_name"],
			"current_scene": row["current_scene"],
			"player_position": {
				"x": row["pos_x"],
				"y": row["pos_y"],
				"z": row["pos_z"]
			},
			"player_direction": row["direction"],
			"has_save": bool(row["has_save"])
		}
		print("📂 Loaded game: ", game_data)
		return true

	print("⚠️ No save data found")
	return false

# ---------------- CONTINUE ----------------
# Coroutine-safe continue
func continue_game() -> void:
	if not await load_game():
		print("⚠️ No save file to continue from.")
		return

	if game_data.has("current_scene") and game_data["current_scene"] != "":
		var scene_path = game_data["current_scene"]
		print("➡️ Continuing game from scene: ", scene_path)

		# Load the scene asynchronously
		await get_tree().change_scene_to_file(scene_path)

		# Wait one frame to ensure nodes are ready
		await get_tree().process_frame

		# Restore player state
		var player = get_tree().get_first_node_in_group("player")
		if player:
			player.position = Vector3(
				game_data["player_position"]["x"],
				game_data["player_position"]["y"],
				game_data["player_position"]["z"]
			)
			if "last_direction" in player:
				player.last_direction = game_data["player_direction"]

			# Reset velocity if exists
			if "velocity" in player:
				player.velocity = Vector3.ZERO

		print("✅ Player restored, movement should work now")
	else:
		print("⚠️ Save file has no scene path.")

# ---------------- NEW GAME ----------------
func start_new_game() -> void:
	print("🆕 Starting new game - clearing save data")
	game_data = {
		"player_name": "Player",
		"current_scene": "",
		"player_position": {"x": 0.0, "y": 0.0, "z": 0.0},
		"player_direction": "down",
		"has_save": false
	}
	var ok: bool = db.query("DELETE FROM save_data;")
	if ok:
		print("🗑️ Cleared all saves from DB")
	else:
		print("⚠️ Failed to clear saves")

# ---------------- GETTERS ----------------
func get_saved_player_position() -> Vector3:
	if game_data.has("player_position"):
		var pos: Dictionary = game_data["player_position"]
		return Vector3(pos["x"], pos["y"], pos["z"])
	return Vector3.ZERO

func get_saved_player_direction() -> String:
	if game_data.has("player_direction"):
		return str(game_data["player_direction"])
	return "down"

# ---------------- DEBUG ----------------
func debug_print_saves() -> void:
	var result: Array = db.select_rows(
		"save_data",
		"id, player_name, current_scene, pos_x, pos_y, pos_z, direction, has_save",
		[]
	)
	for row in result:
		print("📝 Save row: ", row)
		
		
# Returns number of save entries in the database
func get_save_count() -> int:
	if db:  # make sure the database is initialized
		var result: Array = db.select_rows("save_data", "id", [])
		return result.size()
	return 0
