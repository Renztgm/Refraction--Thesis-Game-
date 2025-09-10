extends Node

var db_path: String = "user://game_data.db"
var db: SQLite

var game_data: Dictionary = {
	"player_name": "Player",
	"current_scene": "",
	"player_position": {"x": 0.0, "y": 0.0, "z": 0.0},
	"player_direction": "down",
	"has_save": false
}

# -----------------------
# Initialization
# -----------------------
func _ready() -> void:
	init_db()

func init_db() -> bool:
	db = SQLite.new()
	db.path = db_path
	print("🔧 Initializing database at: ", ProjectSettings.globalize_path(db.path))

	if not db.open_db():
		push_error("❌ Failed to open database")
		return false

	print("✅ Database opened successfully")

	var create_result: bool = db.query("""
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
	print("🔧 Table creation result: ", create_result)
	return create_result

# -----------------------
# Save helpers
# -----------------------
func has_save_file() -> bool:
	if db == null:
		return false
	db.query("SELECT COUNT(*) as cnt FROM save_data;")
	if db.query_result.size() > 0:
		return db.query_result[0]["cnt"] > 0
	return false

# -----------------------
# Save game
# -----------------------
func save_game() -> bool:
	print("🔧 Starting save_game()...")

	if db == null:
		if not init_db():
			return false

	# Gather player & scene
	var player := get_tree().get_first_node_in_group("player")
	if player:
		if player is Node3D:
			game_data["player_position"] = {"x": player.position.x, "y": player.position.y, "z": player.position.z}
		elif player is Node2D:
			game_data["player_position"] = {"x": player.position.x, "y": player.position.y, "z": 0.0}
		if "last_direction" in player:
			game_data["player_direction"] = str(player.last_direction)

	var scene = get_tree().current_scene
	game_data["current_scene"] = scene.scene_file_path if scene else ""
	game_data["has_save"] = true

	print("🔧 Data to save: ", game_data)

	# Clear old saves
	db.query("DELETE FROM save_data;")

	# Insert new save
	var insert_sql := """
		INSERT INTO save_data (
			player_name, current_scene, pos_x, pos_y, pos_z, direction, has_save
		) VALUES (?, ?, ?, ?, ?, ?, ?);
	"""
	var params: Array = [
		game_data["player_name"],
		game_data["current_scene"],
		game_data["player_position"]["x"],
		game_data["player_position"]["y"],
		game_data["player_position"]["z"],
		game_data["player_direction"],
		1
	]

	print("📦 Executing SQL:\n", insert_sql)
	print("📦 With params: ", params)

	var insert_ok: bool = db.query_with_bindings(insert_sql, params)
	print("🔧 Insert result: ", insert_ok)

	# Verify immediately
	db.query("SELECT * FROM save_data;")
	print("🔍 Verification query executed")
	print("🔧 Verification rows: ", db.query_result)

	if db.query_result.size() == 0:
		print("⚠️ Save failed - no rows after insert")
		return false

	print("✅ Save successful")
	return true

# -----------------------
# Load game
# -----------------------
func load_game() -> bool:
	if db == null:
		if not init_db():
			return false

	print("🔧 Running load_game()...")
	db.query("SELECT * FROM save_data;")
	print("📊 Rows returned: ", db.query_result)

	if db.query_result.size() == 0:
		print("⚠️ No save data found")
		return false

	var row: Dictionary = db.query_result[0]
	game_data = {
		"player_name": row["player_name"],
		"current_scene": row["current_scene"],
		"player_position": {"x": row["pos_x"], "y": row["pos_y"], "z": row["pos_z"]},
		"player_direction": row["direction"],
		"has_save": bool(row["has_save"])
	}
	print("📂 Loaded game: ", game_data)
	return true

# -----------------------
# Continue
# -----------------------
func continue_game() -> bool:
	if not load_game():
		return false
	if game_data["current_scene"] == "":
		return false

	get_tree().change_scene_to_file(game_data["current_scene"])

	# Delay until scene is ready
	await get_tree().process_frame  

	var player := get_tree().get_first_node_in_group("player")
	if player:
		if player is Node3D:
			player.position = Vector3(
				game_data["player_position"]["x"],
				game_data["player_position"]["y"],
				game_data["player_position"]["z"]
			)
		elif player is Node2D:
			player.position = Vector2(
				game_data["player_position"]["x"],
				game_data["player_position"]["y"]
			)

		if "last_direction" in player:
			player.last_direction = game_data["player_direction"]

	return true

# -----------------------
# Start new game
# -----------------------
func start_new_game() -> void:
	game_data = {
		"player_name": "Player",
		"current_scene": "",
		"player_position": {"x": 0.0, "y": 0.0, "z": 0.0},
		"player_direction": "down",
		"has_save": false
	}
	if db:
		db.query("DELETE FROM save_data;")
		print("🗑️ Cleared all saves from DB")

# -----------------------
# Getters
# -----------------------

func get_saved_player_position() -> Vector3:
	if not game_data.has("player_position"):
		return Vector3.ZERO
	var pos = game_data["player_position"]
	return Vector3(pos["x"], pos["y"], pos["z"])

func get_saved_scene() -> String:
	return game_data.get("current_scene", "")

func get_saved_player_direction() -> String:
	return game_data.get("player_direction", "down")

func has_save_data() -> bool:
	return game_data.get("has_save", false)
