# ============================================
# FILE 3: InventoryManager.gd (Complete version)
# Set this as an Autoload named "InventoryManager"
# ============================================
extends Node

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
	
	# Create inventory tables
	db.query("""
		CREATE TABLE IF NOT EXISTS items (
			id INTEGER PRIMARY KEY AUTOINCREMENT,
			name TEXT,
			icon_path TEXT,
			stack_size INT
		);
	""")
	
	db.query("""
		CREATE TABLE IF NOT EXISTS inventory (
			slot_id INT UNIQUE,
			item_id INT,
			quantity INT
		);
	""")
	
	# Example data setup (if no data exists)
	var items_exist = db.select_rows("items", "", ["*"])
	if items_exist.size() == 0:
		db.query("INSERT INTO items (name, icon_path, stack_size) VALUES ('Potion', 'res://icons/potion.png', 99);")
		db.query("INSERT INTO items (name, icon_path, stack_size) VALUES ('Sword', 'res://icons/sword.png', 1);")
	
	db.query("INSERT OR REPLACE INTO inventory (slot_id, item_id, quantity) VALUES (0, 1, 1);")
	db.query("INSERT OR REPLACE INTO inventory (slot_id, item_id, quantity) VALUES (1, 2, 1);")

# ============================================
# MEMORY SHARD FUNCTIONS
# ============================================

func save_memory_shard(shard_name: String, description: String, icon_path: String, scene_location: String) -> bool:
	var timestamp = Time.get_datetime_string_from_system()
	
	# Check if shard already exists
	var existing = db.select_rows("memory_shards", "shard_name = '%s'" % shard_name, ["*"])
	if existing.size() > 0:
		print("Memory shard '%s' already collected" % shard_name)
		return false
	
	# Insert new memory shard
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
	var res = db.select_rows("memory_shards", "shard_name = '%s'" % shard_name, ["*"])
	return res.size() > 0

func get_memory_shard_count() -> int:
	var shards = get_all_memory_shards()
	return shards.size()

# ============================================
# INVENTORY FUNCTIONS
# ============================================

func get_inventory() -> Array:
	return db.select_rows("inventory", "", ["*"])

func get_item(item_id: int) -> Dictionary:
	var res = db.select_rows("items", "id = %d" % item_id, ["*"])
	return res[0] if res.size() > 0 else {}

func add_item(slot_id: int, item_id: int, quantity: int):
	db.query("INSERT OR REPLACE INTO inventory (slot_id, item_id, quantity) VALUES (%d, %d, %d);" % [slot_id, item_id, quantity])

func remove_item(slot_id: int):
	db.query("DELETE FROM inventory WHERE slot_id = %d;" % slot_id)

func resize_inventory(new_size: int):
	slot_count = new_size

# ============================================
# UTILITY FUNCTIONS
# ============================================

func clear_all_data():
	db.query("DELETE FROM memory_shards;")
	db.query("DELETE FROM inventory;")
	print("All game data cleared")

func clear_all_game_data():
	"""Clear all memory shards and inventory items for a new game"""
	db.query("DELETE FROM memory_shards;")
	db.query("DELETE FROM inventory;")
	print("✓ All memory shards cleared")
	print("✓ All inventory items cleared")
	print("Game data reset for new game")

# Optional: Reset to default starting items
func reset_to_default_items():
	"""Clear everything and add starting items"""
	clear_all_game_data()
	
	# Add default starting items (customize as needed)
	db.query("INSERT OR REPLACE INTO inventory (slot_id, item_id, quantity) VALUES (0, 1, 1);")
	db.query("INSERT OR REPLACE INTO inventory (slot_id, item_id, quantity) VALUES (1, 2, 1);")
	
	print("✓ Default items restored")
