extends Node

var db: SQLite
var settings: Dictionary = {
	"music_volume": 0.8,
	"music_enabled": true,
	"brightness": 1.0,
	"fullscreen": false,
	"vsync": true,
}

# Audio bus indices
var master_bus_index: int
var music_bus_index: int

# Brightness overlay node
var brightness_overlay: ColorRect

func _ready():
	print("=== SETTINGS MANAGER INITIALIZING ===")
	
	# Initialize database
	db = SQLite.new()
	db.path = "user://game_data.db"
	var opened = db.open_db()
	print("📂 Database opened:", opened)
	
	# Create table if not exists
	_create_table()
	
	# Load saved settings
	load_settings()
	
	# Audio bus info
	for i in range(AudioServer.bus_count):
		print("Bus ", i, ": ", AudioServer.get_bus_name(i))
	master_bus_index = AudioServer.get_bus_index("Master")
	music_bus_index = AudioServer.get_bus_index("Music")
	print("Master bus index:", master_bus_index)
	print("Music bus index:", music_bus_index)
	
	# Brightness overlay
	create_brightness_overlay()


# =========================
# DATABASE INITIALIZATION
# =========================
func _create_table() -> void:
	var sql = """
	CREATE TABLE IF NOT EXISTS settings (
		key TEXT PRIMARY KEY,
		value TEXT
	);
	"""
	var success = db.query(sql)
	print("🔧 Table creation result:", success)


# =========================
# BRIGHTNESS OVERLAY
# =========================
func create_brightness_overlay():
	var canvas_layer = CanvasLayer.new()
	canvas_layer.layer = 100
	get_tree().root.add_child(canvas_layer)

	brightness_overlay = ColorRect.new()
	brightness_overlay.color = Color.BLACK
	brightness_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	brightness_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	canvas_layer.add_child(brightness_overlay)


# =========================
# AUDIO
# =========================
func set_music_volume(value: float) -> void:
	settings["music_volume"] = clamp(value, 0.0, 1.0)
	apply_music_volume()

func apply_music_volume():
	if settings["music_enabled"] and settings["music_volume"] > 0.0:
		var db_value = linear_to_db(settings["music_volume"])
		AudioServer.set_bus_volume_db(music_bus_index, db_value)
		AudioServer.set_bus_mute(music_bus_index, false)
	else:
		AudioServer.set_bus_mute(music_bus_index, true)

func set_music_enabled(enabled: bool) -> void:
	settings["music_enabled"] = enabled
	apply_music_volume()


# =========================
# VIDEO
# =========================
func set_brightness(value: float) -> void:
	settings["brightness"] = clamp(value, 0.5, 2.0)
	apply_brightness()

func apply_brightness():
	if brightness_overlay:
		var brightness_value = settings["brightness"]
		if brightness_value < 1.0:
			var darkness = 1.0 - brightness_value
			brightness_overlay.color = Color(0, 0, 0, darkness * 0.8)
		else:
			brightness_overlay.color = Color(0, 0, 0, 0)

func set_fullscreen(enabled: bool) -> void:
	settings["fullscreen"] = enabled
	apply_fullscreen()

func apply_fullscreen():
	DisplayServer.window_set_mode(
		DisplayServer.WINDOW_MODE_FULLSCREEN if settings["fullscreen"] else DisplayServer.WINDOW_MODE_WINDOWED
	)

func set_vsync_enabled(enabled: bool) -> void:
	settings["vsync"] = enabled
	apply_vsync()

func apply_vsync():
	DisplayServer.window_set_vsync_mode(
		DisplayServer.VSYNC_ENABLED if settings["vsync"] else DisplayServer.VSYNC_DISABLED
	)


# =========================
# SAVE / LOAD FROM DATABASE
# =========================
func save_settings() -> void:
	for key in settings.keys():
		var value = str(settings[key])
		var sql = "INSERT OR REPLACE INTO settings (key, value) VALUES (?, ?);"
		db.query_with_bindings(sql, [key, value])
	print("💾 Settings saved to database.")

func load_settings() -> void:
	var rows = db.query("SELECT key, value FROM settings;")
	if typeof(rows) == TYPE_ARRAY and rows.size() > 0:
		for row in rows:
			if row.has("key") and row.has("value"):
				var key = row["key"]
				var value = _parse_value(row["value"])
				if key in settings:
					settings[key] = value
		print("✅ Settings loaded from database.")
	else:
		print("⚠️ No saved settings found, using defaults.")
		save_settings()
	apply_all_settings()

func _parse_value(value_str: String):
	if value_str == "true":
		return true
	if value_str == "false":
		return false
	if value_str.is_valid_float():
		return float(value_str)
	return value_str


# =========================
# DEFAULTS / APPLY
# =========================
func reset_to_defaults() -> void:
	settings = {
		"music_volume": 0.8,
		"music_enabled": true,
		"brightness": 1.0,
		"fullscreen": false,
		"vsync": true,
	}
	save_settings()
	apply_all_settings()
	print("🔄 Settings reset to defaults.")

func apply_all_settings() -> void:
	apply_music_volume()
	apply_brightness()
	apply_fullscreen()
	apply_vsync()


# =========================
# GETTERS for SettingsUI.gd
# =========================
func get_music_volume() -> float:
	return settings.get("music_volume", 0.8)

func is_music_enabled() -> bool:
	return settings.get("music_enabled", true)

func get_brightness() -> float:
	return settings.get("brightness", 1.0)

func is_fullscreen() -> bool:
	return settings.get("fullscreen", false)

func is_vsync_enabled() -> bool:
	return settings.get("vsync", true)
