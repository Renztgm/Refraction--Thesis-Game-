# res://scripts/ProfileManager.gd
extends Node

var db: SQLite
var active_profile_id: int = -1

func _ready():
	db = SQLite.new()

	var user_path = ProjectSettings.globalize_path("user://game_data.db")
	var res_path = ProjectSettings.globalize_path("res://game_data.db")

	# Copy only if DB does not already exist
	if not FileAccess.file_exists(user_path) and FileAccess.file_exists(res_path):
		DirAccess.copy_absolute(res_path, user_path)

	db.path = "user://game_data.db"

	var ok = db.open_db()
	print("Opening DB at:", db.path, " resolved → ", ProjectSettings.globalize_path(db.path))

func get_profiles() -> Array:

	if db == null:
		SaveManager.init_db()

	var success := db.query("SELECT id, player_name, created_at, last_played FROM profiles")
	var profiles: Array = []

	if success and db.query_result.size() > 0:
		for row in db.query_result:
			profiles.append({
				"id": int(row["id"]),
				"player_name": String(row["player_name"]),
				"created_at": String(row["created_at"]),
				"last_played": String(row["last_played"])
			})
	else:
		print("⚠️ No profiles found")

	#print("get_profiles() result: ", profiles)
	return profiles

func create_profile(player_name: String) -> int:
	# Insert new profile
	db.query("INSERT INTO profiles (player_name, created_at, last_played) VALUES ('%s', datetime('now'), datetime('now'))" % player_name)

	# Get the last inserted id directly
	var new_id: int = db.last_insert_rowid

	# Set active and return
	if new_id != -1:
		set_active_profile(new_id)
	return new_id

func set_active_profile(profile_id: int) -> void:
	active_profile_id = profile_id
	db.query("UPDATE profiles SET last_played = datetime('now') WHERE id = %d" % profile_id)

func save_game_from_state(state: Dictionary) -> void:
	if active_profile_id == -1:
		push_error("No active profile selected!")
		return

	# Items
	db.query("DELETE FROM items WHERE profile_id = %d" % active_profile_id)
	for item in state.get("items", []):
		var name := String(item.get("name", ""))
		var count := int(item.get("count", 0))
		db.query("INSERT INTO items (profile_id, item_name, item_count) VALUES (%d, '%s', %d)" % [active_profile_id, name, count])

	# Memory shards
	db.query("DELETE FROM memoryshards WHERE profile_id = %d" % active_profile_id)
	for shard in state.get("shards", []):
		var t := String(shard.get("type", ""))
		var v := int(shard.get("value", 0))
		db.query("INSERT INTO memoryshards (profile_id, shard_type, shard_value) VALUES (%d, '%s', %d)" % [active_profile_id, t, v])

	# Game path
	db.query("DELETE FROM game_path WHERE profile_id = %d" % active_profile_id)
	for p in state.get("paths", []):
		db.query("INSERT INTO game_path (profile_id, path) VALUES (%d, '%s')" % [active_profile_id, String(p)])

	db.query("UPDATE profiles SET last_played = datetime('now') WHERE id = %d" % active_profile_id)

func load_game_state() -> Dictionary:
	if active_profile_id == -1:
		push_error("No active profile selected!")
		return {}

	var state: Dictionary = {}

	db.query("SELECT item_name, item_count FROM items WHERE profile_id = %d" % active_profile_id)
	state["items"] = _fetch_rows_as_dicts(["item_name", "item_count"])

	db.query("SELECT shard_type, shard_value FROM memoryshards WHERE profile_id = %d" % active_profile_id)
	state["shards"] = _fetch_rows_as_dicts(["shard_type", "shard_value"])

	db.query("SELECT path FROM game_path WHERE profile_id = %d" % active_profile_id)
	state["paths"] = _fetch_single_column("path")

	return state

# Adapt these helpers to your addon’s fetch API (get_result, fetch_array, etc.)
func _fetch_rows_as_dicts(columns: Array) -> Array:
	var rows := []
	# Example fallback: if your addon provides fetch_array() returning [[...], ...]
	if db.has_method("fetch_array"):
		var raw: Array = db.fetch_array()

		for r in raw:
			var d := {}
			for i in range(columns.size()):
				d[columns[i]] = r[i]
			rows.append(d)
	return rows

func _fetch_single_column(column_name: String) -> Array:
	var values := []
	if db.has_method("fetch_array"):
		var raw: Array = db.fetch_array()

		for r in raw:
			values.append(r[0])
	return values
	
	
func save_game() -> void:
	if active_profile_id == -1:
		push_error("No active profile selected!")
		return

	# Example: clear old items for this profile
	db.query("DELETE FROM items WHERE profile_id = %d" % active_profile_id)

	# Example: save new items (replace with your actual game state arrays)
	for item in GameState.items: # assume GameState holds runtime data
		db.query("INSERT INTO items (profile_id, item_name, item_count) VALUES (%d, '%s', %d)" % [
			active_profile_id,
			item.name,
			item.count
		])

	# Example: save memory shards
	db.query("DELETE FROM memoryshards WHERE profile_id = %d" % active_profile_id)
	for shard in GameState.shards:
		db.query("INSERT INTO memoryshards (profile_id, shard_type, shard_value) VALUES (%d, '%s', %d)" % [
			active_profile_id,
			shard.type,
			shard.value
		])

	# Update last_played timestamp
	db.query("UPDATE profiles SET last_played = datetime('now') WHERE id = %d" % active_profile_id)
	
func delete_profile(profile_id: int) -> bool:
	if db == null:
		db = SQLite.new()
		db.path = "user://game_data.db"
		if not db.open_db():
			push_error("❌ Cannot open DB")
			return false
	db.query("PRAGMA foreign_keys = ON;")


	var success = db.query_with_bindings("DELETE FROM profiles WHERE id = ?", [profile_id])
	if success:
		print("✅ Profile deleted:", profile_id)
	else:
		print("❌ Failed to delete profile:", profile_id)
	return success
