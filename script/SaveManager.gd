# File: scripts/SaveManager.gd
extends Node

# ---------------- CONFIG ----------------
# Default database path, can be overridden for testing
var db_path: String = "user://game_data.db"

# ---------------- GAME DATA ----------------
var game_data: Dictionary = {
	"player_name": "Player",
	"current_scene": "",
	"player_position": {"x": 0.0, "y": 0.0, "z": 0.0},
	"player_direction": "down",
	"has_save": false
}

# ---------------- DATABASE ----------------
var db: SQLite

# ---------------- INITIALIZATION ----------------
func _ready() -> void:
	_init_db()

func init_with_db_path(path: String) -> void:
	# Override DB path (useful for tests)
	db_path = path
	_init_db()

func _init_db() -> void:
	db = SQLite.new()
	db.path = db_path
	db.open_db()
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
	# Optional player node
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
	else:
		print("⚠️ Failed to save game")

	return ok

# ---------------- LOAD ----------------
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

# ---------------- NEW GAME ----------------
func start_new_game() -> void:
	game_data = {
		"player_name": "Player",
		"current_scene": "",
		"player_position": {"x": 0.0, "y": 0.0, "z": 0.0},
		"player_direction": "down",
		"has_save": false
	}
	db.query("DELETE FROM save_data;")
	print("🗑️ Cleared all saves from DB")

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

func get_save_count() -> int:
	if db:
		var result: Array = db.select_rows("save_data", "id", [])
		return result.size()
	return 0
