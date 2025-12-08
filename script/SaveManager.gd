extends Node

var db_path: String = "user://game_data.db"
var db: SQLite

var current_chapter: int = 1
var next_chapter_scene_path: String = ""

var active_profile_id: int:
	get: return ProfileManager.active_profile_id


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

	if not db.open_db():
		push_error("❌ Failed to open database")
		return false

	db.query("PRAGMA foreign_keys = ON;")

	# 1. Profiles
	var create_profiles_table := db.query("""
		CREATE TABLE IF NOT EXISTS profiles (
			id INTEGER PRIMARY KEY AUTOINCREMENT,
			player_name TEXT NOT NULL,
			created_at TEXT,
			last_played TEXT
		);
	""")
	print("Profiles table:", create_profiles_table)

	# 2. Save Data
	var create_save_table := db.query("""
		CREATE TABLE IF NOT EXISTS save_data (
			id INTEGER PRIMARY KEY AUTOINCREMENT,
			profile_id INTEGER NOT NULL,
			player_name TEXT,
			current_scene TEXT,
			pos_x REAL,
			pos_y REAL,
			pos_z REAL,
			direction TEXT,
			has_save INTEGER,
			FOREIGN KEY(profile_id) REFERENCES profiles(id) ON DELETE CASCADE
		);
	""")
	print("Save table:", create_save_table)

	# 3. Quests
	var create_quests_table := db.query("""
		CREATE TABLE IF NOT EXISTS quests (
			id TEXT,
			profile_id INTEGER NOT NULL,
			title TEXT,
			description TEXT,
			is_completed INTEGER,
			objectives TEXT,
			PRIMARY KEY (id, profile_id),
			FOREIGN KEY(profile_id) REFERENCES profiles(id) ON DELETE CASCADE
		);
	""")
	print("Quests table:", create_quests_table)

	# 4. Game Path
	var create_game_path_table := db.query("""
		CREATE TABLE IF NOT EXISTS game_path (
			id INTEGER PRIMARY KEY AUTOINCREMENT,
			profile_id INTEGER NOT NULL,
			scene_path TEXT,
			branch_id TEXT,
			timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
			FOREIGN KEY(profile_id) REFERENCES profiles(id) ON DELETE CASCADE
		);
	""")
	print("Game path table:", create_game_path_table)

	return create_profiles_table and create_save_table and create_quests_table and create_game_path_table


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

#func save_all_quests():
	#if db == null:
		#if not init_db():
			#return
#
	#db.query("DELETE FROM quests;")  # Clear old data
#
	#for quest in QuestManager.active_quests.values():
		#var objectives_json = JSON.stringify(quest.objectives)
		#var completed = 1 if quest.is_completed else 0  # ✅ Valid
#
#
		#db.query_with_bindings("""
			#INSERT INTO quests (id, title, description, is_completed, objectives)
			#VALUES (?, ?, ?, ?, ?);
		#""", [quest.id, quest.title, quest.description, completed, objectives_json])
		#print("💾 Saving objectives for", quest.id, ":", objectives_json)




func save_game() -> bool:
	print("🔧 Starting save_game()...")

	if db == null:
		if not init_db():
			return false

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

	db.query("DELETE FROM save_data WHERE profile_id = %d;" % active_profile_id)

	var insert_sql := """
		INSERT INTO save_data 
		(profile_id, player_name, current_scene, pos_x, pos_y, pos_z, direction, has_save)
		VALUES (?, ?, ?, ?, ?, ?, ?, ?)
	"""
	var params: Array = [
		active_profile_id,
		game_data["player_name"],
		game_data["current_scene"],
		game_data["player_position"]["x"],
		game_data["player_position"]["y"],
		game_data["player_position"]["z"],
		game_data["player_direction"],
		1
	]

	var insert_ok: bool = db.query_with_bindings(insert_sql, params)
	print("🔧 Insert result: ", insert_ok)

	db.query("SELECT * FROM save_data;")
	print("🔧 Verification rows: ", db.query_result)

	if db.query_result.size() == 0:
		print("⚠️ Save failed - no rows after insert")
		return false

	# ✅ Log scene completion for branching
	log_scene_completion(game_data["current_scene"], "auto")
	#save_all_quests()
	
	print("✅ Save successful")
	return true

# -----------------------
# Load game
# -----------------------
#func load_all_quests():
	#if db.query_with_bindings("SELECT * FROM quests", []):
		#for row in db.query_result:
			#var objectives: Array = []
#
			#var quest := QuestResource.new()
			#quest.id = row["id"]
			#quest.title = row["title"]
			#quest.description = row.get("description", "")
			#quest.is_completed = row["is_completed"] == 1
			#quest.objectives = objectives
#
			#QuestManager.active_quests[quest.id] = {
				#"id": quest.id,
				#"title": quest.title,
				#"description": quest.description,
				#"is_completed": quest.is_completed,
				#"objectives": quest.objectives
			#}
#
			#print("📝 Description for", quest.id, ":", quest.description)
			#print("📦 Loaded quest:", quest.id, "Objectives:", objectives)
	#else:
		#push_error("❌ Failed to query quests table.")

func load_game() -> bool:
	if db == null:
		if not init_db():
			return false

	db.query("SELECT * FROM save_data WHERE profile_id = %d LIMIT 1;" % active_profile_id)
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
			
	#load_all_quests()

	return true

# -----------------------
# Start new game
# -----------------------
func start_new_game() -> void:
	if ProfileManager == null or ProfileManager.active_profile_id == 0:
		push_error("❌ No active profile found. Cannot start new game.")
		return

	var active_id = ProfileManager.active_profile_id

	# Reset local game_data for this profile
	game_data = {
		"profile_id": active_id,
		"player_name": "Player",
		"current_scene": "",
		"player_position": {"x": 0.0, "y": 0.0, "z": 0.0},
		"player_direction": "down",
		"has_save": false
	}

	if db:
		var tables_to_clear := [
			"save_data",
			"quests",
			"quest_objectives",
			"game_path",
			"inventory",
			"memory_shards"
		]

		for table_name in tables_to_clear:
			var result := db.query("DELETE FROM %s WHERE profile_id = %d;" % [table_name, active_id])
			if result:
				print("🧹 Cleared table for profile_id %d: %s" % [active_id, table_name])
			else:
				push_error("❌ Failed to clear table %s for profile_id %d" % [table_name, active_id])
				
	if QuestManager:
		QuestManager.active_quests.clear()
# -----------------------
# Branching Progress
# -----------------------
# SaveManager.gd
func log_scene_completion(scene_path: String, branch_id: String = "", profile_id: int = -1) -> bool:
	# If caller didn't pass a profile_id, use the active profile
	if profile_id == -1:
		if ProfileManager == null:
			push_error("❌ ProfileManager not available; cannot log scene.")
			return false
		profile_id = ProfileManager.active_profile_id

	if profile_id == -1 or profile_id == 0:
		push_error("❌ No active profile selected; cannot log scene.")
		return false

	if db == null:
		if not init_db():
			return false

	# Check if this scene is already logged for THIS profile only
	var check := db.query_with_bindings(
		"SELECT COUNT(*) AS count FROM game_path WHERE scene_path = ? AND profile_id = ?;",
		[scene_path, profile_id]
	)

	if not check:
		push_error("❌ Failed to query game_path for duplicates.")
		return false

	if db.query_result.size() > 0 and int(db.query_result[0]["count"]) > 0:
		print("ℹ️ Scene already logged for profile:", profile_id, " scene:", scene_path)
		return false

	# Insert new scene entry for this profile
	var insert := db.query_with_bindings(
		"INSERT INTO game_path (scene_path, branch_id, profile_id) VALUES (?, ?, ?);",
		[scene_path, branch_id, profile_id]
	)

	if insert:
		print("📌 Scene logged:", scene_path, "Profile:", profile_id, "Branch:", branch_id)
		return true
	else:
		push_error("❌ Failed to insert scene log")
		return false


func get_visited_scene_paths() -> Array:
	if db == null:
		if not init_db():
			return []
	var profile_id = ProfileManager.active_profile_id
	if profile_id <= 0:
		return []

	var success := db.query_with_bindings(
		"SELECT scene_path FROM game_path WHERE profile_id = ?;",
		[profile_id]
	)
	if success and db.query_result.size() > 0:
		var paths: Array = []
		for row in db.query_result:
			paths.append(row["scene_path"])
		return paths
	return []

func get_last_scene_path() -> String:
	if db == null:
		if not init_db():
			return ""
	var profile_id = ProfileManager.active_profile_id
	if profile_id <= 0:
		return ""
	var success := db.query_with_bindings(
		"SELECT scene_path FROM game_path WHERE profile_id = ? ORDER BY timestamp DESC LIMIT 1;",
		[profile_id]
	)
	if success and db.query_result.size() > 0:
		return db.query_result[0]["scene_path"]
	return ""



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

func get_memory_shard_count() -> int:
	if db == null:
		if not init_db():
			return 0

	var profile_id = ProfileManager.active_profile_id
	if profile_id == 0:
		push_error("❌ No active profile found.")
		return 0

	# Count memory shards only for this profile
	var success := db.query_with_bindings(
		"SELECT COUNT(*) AS count FROM memory_shards WHERE profile_id = ?;",
		[profile_id]
	)

	if success and db.query_result.size() > 0:
		return int(db.query_result[0]["count"])
	else:
		push_error("❌ Failed to query memory_shards count or table is empty for profile_id %d." % profile_id)
		return 0


func set_current_chapter(chapter: int) -> void:
	current_chapter = chapter

func get_current_chapter() -> int:
	return current_chapter

func set_next_scene_path(path: String) -> void:
	next_chapter_scene_path = path

func get_next_scene_path() -> String:
	return next_chapter_scene_path

func is_quest_completed(quest_id: String) -> bool:
	if db == null:
		if not init_db():
			return false

	var success := db.query_with_bindings("SELECT is_completed FROM quests WHERE id = ?", [quest_id])
	if not success or db.query_result.size() == 0:
		print("⚠️ Quest not found or query failed:", quest_id)
		return false

	return int(db.query_result[0]["is_completed"]) == 1
	
func get_profile_id() -> int:
	return ProfileManager.active_profile_id
