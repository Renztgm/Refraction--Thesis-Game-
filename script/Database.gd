extends Node

var db: SQLite

func _ready():
	db = SQLite.new()
	db.path = "user://refraction.db"  # save inside user folder
	db.open_db()

	# Create table if it doesn’t exist
	var query = """
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
	"""
	db.query(query)

# ---------------- SAVE ----------------
func save_game(player_name: String, current_scene: String, pos: Vector3, direction: String) -> void:
	var query = "INSERT INTO save_data (player_name, current_scene, pos_x, pos_y, pos_z, direction, has_save) VALUES (?, ?, ?, ?, ?, ?, ?);"
	db.query_with_bindings(query, [
		player_name,
		current_scene,
		pos.x, pos.y, pos.z,
		direction,
		1
	])
	print("✅ Game saved to SQLite at: ", db.path)

# ---------------- LOAD ----------------
func load_last_save() -> Dictionary:
	var query = "SELECT player_name, current_scene, pos_x, pos_y, pos_z, direction, has_save FROM save_data ORDER BY id DESC LIMIT 1;"
	db.query(query)
	if db.next_row():
		return {
			"player_name": db.get_column_data(0),
			"current_scene": db.get_column_data(1),
			"player_position": {
				"x": db.get_column_data(2),
				"y": db.get_column_data(3),
				"z": db.get_column_data(4),
			},
			"player_direction": db.get_column_data(5),
			"has_save": bool(db.get_column_data(6))
		}
	return {}
