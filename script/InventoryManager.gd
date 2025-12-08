extends Node

# ============================================
# Autoload this script as "InventoryManager"
# ============================================

var db: SQLite
var slot_count: int = 20

# -----------------------
# Initialization
# -----------------------
func _ready():
	db = SQLite.new()
	db.path = "user://game_data.db"
	db.open_db()

	# ======================
	# MEMORY SHARDS TABLE
	# ======================
	db.query("""
        CREATE TABLE IF NOT EXISTS memory_shards (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            profile_id INTEGER NOT NULL,
            shard_name TEXT,
            description TEXT,
            icon_path TEXT,
            collected_at TEXT,
            scene_location TEXT,
            FOREIGN KEY(profile_id) REFERENCES profiles(id) ON DELETE CASCADE,
            UNIQUE(profile_id, shard_name)
        );
	""")
	# ======================
	# ITEMS TABLE (definitions, global)
	# ======================
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

	# ======================
	# INVENTORY TABLE (per profile)
	# ======================
	db.query("""
	    CREATE TABLE IF NOT EXISTS inventory (
	        slot_id INT,
	        profile_id INTEGER NOT NULL,
	        item_id INTEGER,
	        quantity INT,
	        FOREIGN KEY(profile_id) REFERENCES profiles(id) ON DELETE CASCADE,
	        UNIQUE(profile_id, slot_id)
	    );
	""")

	print("✅ InventoryManager initialized")


# ============================================
# MEMORY SHARD FUNCTIONS
# ============================================

func save_memory_shard(shard_name: String, description: String, icon_path: String, scene_location: String) -> bool:
	if ProfileManager.active_profile_id == -1:
		push_error("No active profile selected!")
		return false

	var timestamp = Time.get_datetime_string_from_system()
	var res = db.select_rows("memory_shards", "profile_id = %d AND shard_name = '%s'" % [ProfileManager.active_profile_id, shard_name], ["*"])
	if res.size() > 0:
		print("⚠️ Memory shard '%s' already collected for this profile" % shard_name)
		return false

	var ok = db.query_with_bindings("""
        INSERT INTO memory_shards (profile_id, shard_name, description, icon_path, collected_at, scene_location)
        VALUES (?, ?, ?, ?, ?, ?);
	""", [ProfileManager.active_profile_id, shard_name, description, icon_path, timestamp, scene_location])

	if not ok:
		print("❌ Failed to save shard:", db.error_message)
		return false

	print("✅ Memory shard '%s' saved to database for profile %d" % [shard_name, ProfileManager.active_profile_id])
	return true

func get_all_memory_shards() -> Array:
	if ProfileManager.active_profile_id == -1:
		return []
	return db.select_rows("memory_shards", "profile_id = %d" % ProfileManager.active_profile_id, ["*"])

# Returns a single memory shard dictionary for the active profile
func get_memory_shard(shard_name: String) -> Dictionary:
	if ProfileManager.active_profile_id == -1:
		return {}
	var res = db.select_rows(
		"memory_shards",
		"shard_name = '%s' AND profile_id = %d" % [shard_name, ProfileManager.active_profile_id],
		["*"]
	)
	return res[0] if res.size() > 0 else {}


func has_memory_shard(shard_name: String) -> bool:
	var res = db.select_rows("memory_shards", "profile_id = %d AND shard_name = '%s'" % [ProfileManager.active_profile_id, shard_name], ["*"])
	return res.size() > 0

func get_memory_shard_count() -> int:
	return get_all_memory_shards().size()


# ============================================
# ITEM / INVENTORY FUNCTIONS
# ============================================

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


func add_item(slot_id: int, item_id: int, quantity: int) -> void:
	if ProfileManager.active_profile_id == -1:
		push_error("No active profile selected!")
		return

	db.query("INSERT OR REPLACE INTO inventory (slot_id, profile_id, item_id, quantity) VALUES (%d, %d, %d, %d);" %
		[slot_id, ProfileManager.active_profile_id, item_id, quantity])


func remove_item(slot_id: int) -> void:
	if ProfileManager.active_profile_id == -1:
		push_error("No active profile selected!")
		return
	db.query("DELETE FROM inventory WHERE slot_id = %d AND profile_id = %d;" % [slot_id, ProfileManager.active_profile_id])

func remove_item_id(item_id: int) -> void:
	if ProfileManager.active_profile_id == -1:
		push_error("No active profile selected!")
		return
	db.query("DELETE FROM inventory WHERE item_id = %d AND profile_id = %d;" % [item_id, ProfileManager.active_profile_id])
#kailangan ko maget ung item_id located sa inventory mara magamit sa second line where item_id is needed!


func get_inventory() -> Array:
	if ProfileManager.active_profile_id == -1:
		return []
	return db.select_rows("inventory", "profile_id = %d" % ProfileManager.active_profile_id, ["*"])

# Returns inventory slots for the active profile
func get_all_inventory_slots() -> Array:
	return get_inventory()


func get_item(item_id: int) -> Dictionary:
	var res = db.select_rows("items", "id = %d" % item_id, ["*"])
	return res[0] if res.size() > 0 else {}

# Returns all items in the global items table (item definitions)
func get_all_items() -> Array:
	return db.select_rows("items", "", ["*"])


func has_item(item_id: int) -> bool:
	if ProfileManager.active_profile_id == -1:
		return false
	var res = db.select_rows("inventory", "profile_id = %d AND item_id = %d AND quantity > 0" % [ProfileManager.active_profile_id, item_id], ["*"])
	return res.size() > 0


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
# UTILITY / PROFILE DATA MANAGEMENT
# ============================================

func clear_profile_data(profile_id: int = -1):
	if profile_id == -1:
		profile_id = ProfileManager.active_profile_id
	if profile_id == -1:
		push_error("No active profile selected!")
		return

	db.query("DELETE FROM memory_shards WHERE profile_id = %d;" % profile_id)
	db.query("DELETE FROM inventory WHERE profile_id = %d;" % profile_id)
	print("🧹 Cleared inventory and shards for profile", profile_id)


func clear_all_game_data():
	if ProfileManager.active_profile_id == -1:
		push_error("No active profile selected!")
		return
	clear_profile_data(ProfileManager.active_profile_id)
	print("✅ All inventory and memory shards cleared for active profile")
