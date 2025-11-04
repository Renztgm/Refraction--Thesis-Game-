extends Node

var db := SQLite.new()
var db_path := "user://game_data.db"

func _ready():
	db.db_path = db_path  # ✅ Set path directly on the db object
	db.open_db()          # ✅ Now call open_db() with no arguments

func select_rows(table: String, conditions: Dictionary) -> Array:
	var where_clause := []
	for key in conditions.keys():
		where_clause.append("%s = '%s'" % [key, str(conditions[key])])
	var query := "SELECT * FROM %s WHERE %s;" % [table, " AND ".join(where_clause)]
	db.query(query)
	return db.query_result
