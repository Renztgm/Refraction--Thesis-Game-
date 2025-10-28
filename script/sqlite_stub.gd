extends Object
class_name SQLiteStub

var path: String
var query_result: Array = []

func open_db() -> bool:
	return false

func query(sql: String) -> bool:
	query_result = []
	return false

func query_with_bindings(sql: String, bindings: Array) -> bool:
	query_result = []
	return false

func select_rows(table: String, where_clause: String, columns: Array) -> Array:
	return []
