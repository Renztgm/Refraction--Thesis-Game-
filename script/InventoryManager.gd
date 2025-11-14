extends Node

# ============================================
# Autoload this script as "InventoryManager"
# ============================================

var db : SQLite
var slot_count : int = 20

func _ready():
	db = SQLite.new()
	db.path = "user://game_data.db"
	db.open_db()

	# Create memory_shards table
	db.query("""
        CREATE TABLE IF NOT EXISTS memory_shards (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            shard_name TEXT UNIQUE,
            description TEXT,
            icon_path TEXT,
            collected_at TEXT,
            scene_location TEXT
        );
	""")

	# Create items table with TEXT ID
	db.query("""
	    CREATE TABLE IF NOT EXISTS items (
	        id INTEGER PRIMARY KEY,
	        name TEXT,
	        description TEXT,
	        icon_path TEXT,
	        stack_size INT,
	        is_completed INTEGER DEFAULT 0
	    );
	""")


	# Create inventory table with TEXT item_id
	db.query("""
	    CREATE TABLE IF NOT EXISTS inventory (
	        slot_id INT UNIQUE,
	        item_id INTEGER,
	        quantity INT
	    );
	""")


# ============================================
# MEMORY SHARD FUNCTIONS
# ============================================

func save_memory_shard(shard_name: String, description: String, icon_path: String, scene_location: String) -> bool:
	var timestamp = Time.get_datetime_string_from_system()
	var existing = db.select_rows("memory_shards", "shard_name = '%s'" % shard_name, ["*"])
	if existing.size() > 0:
		print("Memory shard '%s' already collected" % shard_name)
		return false

	var query = """
        INSERT INTO memory_shards (shard_name, description, icon_path, collected_at, scene_location)
        VALUES ('%s', '%s', '%s', '%s', '%s');
	""" % [shard_name, description, icon_path, timestamp, scene_location]

	db.query(query)
	print("Memory shard '%s' saved to database" % shard_name)
	return true

func get_all_memory_shards() -> Array:
	return db.select_rows("memory_shards", "", ["*"])

func get_memory_shard(shard_name: String) -> Dictionary:
	var res = db.select_rows("memory_shards", "shard_name = '%s'" % shard_name, ["*"])
	return res[0] if res.size() > 0 else {}

func has_memory_shard(shard_name: String) -> bool:
	return get_memory_shard(shard_name).size() > 0

func get_memory_shard_count() -> int:
	return get_all_memory_shards().size()

# ============================================
# INVENTORY FUNCTIONS
# ============================================

func get_all_items() -> Array:
	return db.select_rows("items", "", ["*"])
	
func get_all_inventory_slots() -> Array:
	return db.select_rows("inventory", "", ["*"])


func get_inventory() -> Array:
	return db.select_rows("inventory", "", ["*"])

func get_item(item_id: int) -> Dictionary:
	var res = db.select_rows("items", "id = %d" % item_id, ["*"])
	return res[0] if res.size() > 0 else {}

func has_item(item_id: int) -> bool:
	var res = db.select_rows("inventory", "item_id = %d AND quantity > 0" % item_id, ["*"])
	return res.size() > 0

func add_item(slot_id: int, item_id: int, quantity: int) -> void:
	db.query("INSERT OR REPLACE INTO inventory (slot_id, item_id, quantity) VALUES (%d, %d, %d);" % [slot_id, item_id, quantity])


func remove_item(slot_id: int) -> void:
	db.query("DELETE FROM inventory WHERE slot_id = %d;" % slot_id)

func resize_inventory(new_size: int) -> void:
	slot_count = new_size

func save_item_to_items_table(item: Dictionary) -> void:
	if not item.has("id") or not item.has("name") or not item.has("description"):
		push_error("❌ Missing required item fields")
		return

	var icon_path = item.get("icon_path", "")
	var stack_size = item.get("stack_size", 1)
	var is_completed = 1 if item.get("is_completed", false) else 0

	db.query_with_bindings("""
        INSERT OR REPLACE INTO items (id, name, description, icon_path, stack_size, is_completed)
        VALUES (?, ?, ?, ?, ?, ?);
	""", [
		item["id"],
		item["name"],
		item["description"],
		icon_path,
		stack_size,
		is_completed
	])

	print("✅ Saved item to items table:", item["id"])

func get_next_available_slot() -> int:
	var used = []
	var rows = get_inventory()
	for row in rows:
		used.append(row["slot_id"])
	var slot = 0
	while used.has(slot):
		slot += 1
	return slot

# ============================================
# UTILITY FUNCTIONS
# ============================================

func clear_all_data():
	db.query("DELETE FROM memory_shards;")
	db.query("DELETE FROM inventory;")
	print("All game data cleared")

func clear_all_game_data():
	db.query("DELETE FROM memory_shards;")
	db.query("DELETE FROM inventory;")
	print("✓ All memory shards cleared")
	print("✓ All inventory items cleared")
	print("Game data reset for new game")

func reset_to_default_items():
	clear_all_game_data()
