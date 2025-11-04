extends Node

signal quest_updated(quest_id: String)

var db: SQLite
var active_quests: Dictionary = {}

func _ready():
	db = SQLite.new()
	db.path = "user://game_data.db"
	db.open_db()

	# Create quests table
	db.query("""
        CREATE TABLE IF NOT EXISTS quests (
            id TEXT PRIMARY KEY,
            title TEXT,
            description TEXT,
            is_completed INTEGER
        );
	""")

	# Create objectives table
	db.query("""
        CREATE TABLE IF NOT EXISTS quest_objectives (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            quest_id TEXT,
            objective_id TEXT,
            text TEXT,
            is_completed INTEGER
        );
	""")

	load_all_quests()

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
	

# -----------------------------
# Complete an objective
# -----------------------------
func complete_objective(quest_id: String, objective_id: String) -> void:
	var quest = active_quests.get(quest_id)
	if not quest:
		return

	for obj in quest["objectives"]:
		if obj.get("id", "") == objective_id and not obj.get("is_completed", false):
			obj["is_completed"] = true
			db.query("UPDATE quest_objectives SET is_completed = 1 WHERE quest_id = '%s' AND objective_id = '%s';" % [quest_id, objective_id])

			if quest["objectives"].all(func(o): return o.get("is_completed", false)):
				quest["is_completed"] = true
				db.query("UPDATE quests SET is_completed = 1 WHERE id = '%s';" % quest_id)

			emit_signal("quest_updated", quest_id)
			break


# ----------------------------------------------
# When the Objective is been finished handler
# ----------------------------------------------

func is_objective_completed(quest_id: String, objective_id: String) -> bool:
	var quest = active_quests.get(quest_id)
	if not quest:
		return false
	for obj in quest["objectives"]:
		if obj.get("id", "") == objective_id:
			return obj.get("is_completed", false)
	return false


# -----------------------------
# Save all quests to database
# -----------------------------
func save_all_quests() -> void:
	print("🧠 Saving quests to database...")
	db.query("DELETE FROM quests;")
	db.query("DELETE FROM quest_objectives;")

	for quest in active_quests.values():
		print("📦 Saving quest:", quest["id"])
		db.query_with_bindings("""
		    INSERT INTO quests (id, title, description, is_completed)
		    VALUES (?, ?, ?, ?);
		""", [
			quest["id"],
			quest["title"],
			quest["description"],
			(1 if quest["is_completed"] else 0)
		])




		for obj in quest["objectives"]:
			print("   ↪ Objective:", obj["id"], "-", obj["text"])
			db.query("""
                INSERT INTO quest_objectives (quest_id, objective_id, text, is_completed)
                VALUES ('%s', '%s', '%s', %d);
			""" % [
				quest["id"],
				obj["id"],
				obj["text"],
				(1 if obj["is_completed"] else 0)
			])

# -----------------------------
# Load all quests from database
# -----------------------------
func load_all_quests() -> void:
	print("🔄 Loading quests from database...")
	active_quests.clear()

	var quest_rows = db.select_rows("quests", "", ["*"])
	for row in quest_rows:
		var quest = {
			"id": row["id"],
			"title": row["title"],
			"description": row["description"],
			"is_completed": row["is_completed"] == 1,
			"objectives": load_objectives_for_quest(row["id"])
		}
		active_quests[row["id"]] = quest
		print("✅ Loaded quest:", row["id"])
		emit_signal("quest_updated", row["id"])

func load_objectives_for_quest(quest_id: String) -> Array:
	var rows = db.select_rows("quest_objectives", "quest_id = '%s'" % quest_id, ["*"])
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
