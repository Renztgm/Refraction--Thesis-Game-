extends Node

var db : SQLite
var slot_count : int = 20

func _ready():
	db = SQLite.new()
	db.path = "user://inventory.db"
	db.open_db()

	# Create tables if they don't exist
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
