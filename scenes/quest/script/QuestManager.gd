extends Node

signal quest_updated(quest_id: String)

var db: SQLite
var active_quests: Dictionary = {}

func _ready():
	db = SQLite.new()
	db.path = "user://game_data.db"
	db.open_db()

	# ------------------------
	# Create profile-aware tables
	# ------------------------
	db.query("""
		CREATE TABLE IF NOT EXISTS quests (
			id TEXT,
			profile_id INTEGER NOT NULL,
			title TEXT,
			description TEXT,
			is_completed INTEGER,
			PRIMARY KEY(id, profile_id),
			FOREIGN KEY(profile_id) REFERENCES profiles(id) ON DELETE CASCADE
		);
	""")

	db.query("""
		CREATE TABLE IF NOT EXISTS quest_objectives (
			id INTEGER PRIMARY KEY AUTOINCREMENT,
			quest_id TEXT,
			profile_id INTEGER NOT NULL,
			objective_id TEXT,
			text TEXT,
			is_completed INTEGER,
			FOREIGN KEY(profile_id) REFERENCES profiles(id) ON DELETE CASCADE
		);
	""")

	load_all_quests()

# -----------------------------
# Helper to get current profile
# -----------------------------
func _profile_id() -> int:
	if ProfileManager:
		return ProfileManager.active_profile_id
	push_error("❌ ProfileManager not available!")
	return -1

# -----------------------------
# Create a new quest in code
# -----------------------------
func create_quest(id: String, title: String, description: String, objectives: Array) -> void:
	var quest = {
		"id": id,
		"title": title,
		"description": description,
		"is_completed": false,
		"objectives": objectives
	}
	active_quests[id] = quest
	save_all_quests()
	emit_signal("quest_updated", id)



func load_active_quest(quest_id: String) -> void:
	var profile_id = _profile_id()
	var rows = db.select_rows("quests", "id = '%s' AND profile_id = %d" % [quest_id, profile_id], ["*"])
	if rows.size() == 0:
		push_warning("⚠️ Quest not found in DB: " + quest_id)
		return

	var row = rows[0]
	var quest = {
		"id": row["id"],
		"title": row["title"],
		"description": row["description"],
		"is_completed": row["is_completed"] == 1,
		"objectives": load_objectives_for_quest(row["id"], profile_id)
	}
	active_quests[row["id"]] = quest
	emit_signal("quest_updated", row["id"])
	print("📦 Loaded single quest:", row["id"])

# -----------------------------
# Complete an objective
# -----------------------------
func complete_objective(quest_id: String, objective_id: String) -> void:
	var profile_id = _profile_id()
	var quest = active_quests.get(quest_id)
	# ----------------------
	# 1. Check if objective exists in DB
	# ----------------------
	var rows = db.select_rows(
		"quest_objectives",
		"quest_id = '%s' AND objective_id = '%s' AND profile_id = %d" % [
			quest_id, objective_id, profile_id
		],
		["id"]
	)
	
	if rows.size() == 0:
		# Objective row missing → create it
		var obj_text = "Collected " + objective_id
		db.query_with_bindings("""
		    INSERT INTO quest_objectives (quest_id, profile_id, objective_id, text, is_completed)
		    VALUES (?, ?, ?, ?, 1)
		""", [quest_id, profile_id, objective_id, obj_text])

	else:
		# Objective exists → update it
		db.query_with_bindings("""
			UPDATE quest_objectives
			SET is_completed = 1
			WHERE quest_id = ? AND profile_id = ? AND objective_id = ?
		""", [quest_id, profile_id, objective_id])

	# ----------------------
	# 2. Update in-memory quest if loaded
	# ----------------------
	if quest:
		quest = active_quests.get(quest_id)
		for obj in quest["objectives"]:
			if obj.get("id", "") == objective_id:
				obj["is_completed"] = true
				break

		# If all objectives completed → complete quest
		if quest["objectives"].all(func(o): return o.get("is_completed", false)):
			quest["is_completed"] = true
			db.query_with_bindings("""
				UPDATE quests
				SET is_completed = 1
				WHERE id = ? AND profile_id = ?
			""", [quest_id, profile_id])

		emit_signal("quest_updated", quest_id)

# -----------------------------
# Check if objective is completed
# -----------------------------
func is_objective_completed(quest_id: String, objective_id: String) -> bool:
	var quest = active_quests.get(quest_id)
	if not quest:
		return false
	for obj in quest["objectives"]:
		if obj.get("id", "") == objective_id:
			return obj.get("is_completed", false)
	return false

# -----------------------------
# Save all quests for active profile
# -----------------------------
func save_all_quests() -> void:
	var profile_id = _profile_id()
	print("🧠 Saving quests for profile:", profile_id)

	# Delete only quests/objectives for this profile
	db.query_with_bindings("DELETE FROM quests WHERE profile_id = ?", [profile_id])
	db.query_with_bindings("DELETE FROM quest_objectives WHERE profile_id = ?", [profile_id])

	for quest in active_quests.values():
		db.query_with_bindings("""
			INSERT INTO quests (id, profile_id, title, description, is_completed)
			VALUES (?, ?, ?, ?, ?)
		""", [
			quest["id"],
			profile_id,
			quest["title"],
			quest["description"],
			(1 if quest["is_completed"] else 0)
		])

		for obj in quest["objectives"]:
			db.query_with_bindings("""
				INSERT INTO quest_objectives (quest_id, profile_id, objective_id, text, is_completed)
				VALUES (?, ?, ?, ?, ?)
			""", [
				quest["id"],
				profile_id,
				obj["id"],
				obj["text"],
				(1 if obj["is_completed"] else 0)
			])

# -----------------------------
# Load all quests for active profile
# -----------------------------
func load_all_quests() -> void:
	var profile_id = _profile_id()
	active_quests.clear()

	var quest_rows = db.select_rows("quests", "profile_id = %d" % profile_id, ["*"])
	for row in quest_rows:
		var quest = {
			"id": row["id"],
			"title": row["title"],
			"description": row["description"],
			"is_completed": row["is_completed"] == 1,
			"objectives": load_objectives_for_quest(row["id"], profile_id)
		}
		active_quests[row["id"]] = quest
		emit_signal("quest_updated", row["id"])
		print("✅ Loaded quest for profile", profile_id, ":", row["id"])

func load_objectives_for_quest(quest_id: String, profile_id: int) -> Array:
	var rows = db.select_rows("quest_objectives", "quest_id = '%s' AND profile_id = %d" % [quest_id, profile_id], ["*"])
	var objectives = []
	for row in rows:
		objectives.append({
			"id": row["objective_id"],
			"text": row["text"],
			"is_completed": row["is_completed"] == 1
		})
	return objectives

# -----------------------------
# Import quests from JSON file
# -----------------------------
func import_quests_from_json(path: String) -> void:
	print("📥 Importing quests from JSON:", path)

	var file := FileAccess.open(path, FileAccess.READ)
	if not file:
		push_error("❌ Failed to open JSON file: " + path)
		return

	var content := file.get_as_text()
	var data: Array = JSON.parse_string(content)
	if typeof(data) != TYPE_ARRAY:
		push_error("❌ Invalid JSON format.")
		return

	for quest_data in data:
		var id = quest_data.get("id", "")
		var title = quest_data.get("title", "")
		var description = quest_data.get("description", "")
		var is_completed = quest_data.get("is_completed", false)
		var objectives = quest_data.get("objectives", [])

		print("📄 Found quest in JSON:", id)
		for obj in objectives:
			print("   ↪ Objective:", obj.get("id", ""), "-", obj.get("text", ""))

		var quest = {
			"id": id,
			"title": title,
			"description": description,
			"is_completed": is_completed,
			"objectives": objectives
		}

		active_quests[id] = quest
		

	save_all_quests()
	load_all_quests()



# -----------------------------
# Check if quest is completed
# -----------------------------
func is_quest_completed(quest_id: String) -> bool:
	var profile_id = _profile_id()
	var res = db.select_rows("quests", "id = '%s' AND profile_id = %d AND is_completed = 1" % [quest_id, profile_id], ["*"])
	return res.size() > 0

# -----------------------------
# Complete a quest manually
# -----------------------------
func complete_quest(quest_id: String) -> void:
	var profile_id = _profile_id()

	# Update memory
	if active_quests.has(quest_id):
		active_quests[quest_id]["is_completed"] = true

	# Update database
	db.query_with_bindings("""
		UPDATE quests SET is_completed = 1
		WHERE id = ? AND profile_id = ?
	""", [quest_id, profile_id])

	print("✅ Quest completed for profile", profile_id, ":", quest_id)
	emit_signal("quest_updated", quest_id)


# -----------------------------
# Check if quest exists for profile
# -----------------------------
func quest_exists(quest_id: String) -> bool:
	var profile_id = _profile_id()
	var res = db.select_rows("quests", "id = '%s' AND profile_id = %d" % [quest_id, profile_id], ["id"])
	return res.size() > 0


func is_quest_active(quest_id: String) -> bool:
	var quest = active_quests.get(quest_id)
	if not quest:
		return false
	return not quest.get("is_completed", false)
