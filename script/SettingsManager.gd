# SettingsManager.gd
extends Node

var settings: Dictionary = {
	"music_volume": 0.8,
	"music_enabled": true,
	"brightness": 1.0,
	"fullscreen": false,
	"vsync": true,
}

# Audio bus indices (you may need to adjust these based on your audio setup)
var master_bus_index: int
var music_bus_index: int

# Brightness overlay node
var brightness_overlay: ColorRect

func _ready():
	# Debug: Print all available buses
	print("=== AUDIO BUSES DEBUG ===")
	for i in AudioServer.bus_count:
		print("Bus ", i, ": ", AudioServer.get_bus_name(i))
	
	# Get audio bus indices
	master_bus_index = AudioServer.get_bus_index("Master")
	music_bus_index = AudioServer.get_bus_index("Music")
	
	print("Master bus index: ", master_bus_index)
	print("Music bus index: ", music_bus_index)
	
	# Rest of your existing code...



func create_brightness_overlay():
	# Create a CanvasLayer for brightness overlay
	var canvas_layer = CanvasLayer.new()
	canvas_layer.layer = 100  # High layer to be on top
	get_tree().root.add_child(canvas_layer)
	
	# Create ColorRect for brightness adjustment
	brightness_overlay = ColorRect.new()
	brightness_overlay.color = Color.BLACK
	brightness_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE  # Don't block input
	brightness_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	canvas_layer.add_child(brightness_overlay)

# Audio Functions
func get_music_volume() -> float:
	return settings["music_volume"]

func set_music_volume(value: float) -> void:
	settings["music_volume"] = clamp(value, 0.0, 1.0)
	apply_music_volume()

func apply_music_volume():
	print("=== APPLYING MUSIC VOLUME ===")
	print("Music enabled: ", settings["music_enabled"])
	print("Music volume: ", settings["music_volume"])
	
	if settings["music_enabled"] and settings["music_volume"] > 0:
		var db = linear_to_db(settings["music_volume"])
		print("Setting volume to: ", db, " dB")
		AudioServer.set_bus_volume_db(music_bus_index, db)
		AudioServer.set_bus_mute(music_bus_index, false)
		print("Bus muted: ", AudioServer.is_bus_mute(music_bus_index))
	else:
		print("Muting bus")
		AudioServer.set_bus_mute(music_bus_index, true)

func is_music_enabled() -> bool:
	return settings["music_enabled"]

func set_music_enabled(enabled: bool) -> void:
	settings["music_enabled"] = enabled
	apply_music_volume()  # Apply the change immediately

# Video Functions
func get_brightness() -> float:
	return settings["brightness"]

func set_brightness(value: float) -> void:
	settings["brightness"] = clamp(value, 0.5, 2.0)
	apply_brightness()

func apply_brightness():
	if brightness_overlay:
		var brightness_value = settings["brightness"]
		if brightness_value < 1.0:
			# Darker: increase black overlay opacity
			var darkness = 1.0 - brightness_value
			brightness_overlay.color = Color(0, 0, 0, darkness * 0.8)  # Max 80% darkness
		else:
			# Brighter: reduce overlay opacity to 0 (no darkening effect)
			brightness_overlay.color = Color(0, 0, 0, 0)

func is_fullscreen() -> bool:
	return settings["fullscreen"]

func set_fullscreen(enabled: bool) -> void:
	settings["fullscreen"] = enabled
	apply_fullscreen()

func apply_fullscreen():
	DisplayServer.window_set_mode(
		DisplayServer.WINDOW_MODE_FULLSCREEN if settings["fullscreen"] else DisplayServer.WINDOW_MODE_WINDOWED
	)

func is_vsync_enabled() -> bool:
	return settings["vsync"]

func set_vsync_enabled(enabled: bool) -> void:
	settings["vsync"] = enabled
	apply_vsync()

func apply_vsync():
	DisplayServer.window_set_vsync_mode(
		DisplayServer.VSYNC_ENABLED if settings["vsync"] else DisplayServer.VSYNC_DISABLED
	)

# File Operations
func save_settings() -> void:
	var file = FileAccess.open("user://settings.cfg", FileAccess.WRITE)
	if file:
		file.store_var(settings)
		file.close()
		print("Settings saved successfully")
	else:
		print("Failed to save settings")

func load_settings() -> void:
	if FileAccess.file_exists("user://settings.cfg"):
		var file = FileAccess.open("user://settings.cfg", FileAccess.READ)
		if file:
			settings = file.get_var()
			file.close()
			apply_all_settings()
			print("Settings loaded successfully")
		else:
			print("Failed to load settings file")
	else:
		print("No settings file found, using defaults")
		apply_all_settings()

func reset_to_defaults() -> void:
	settings = {
		"music_volume": 0.8,
		"music_enabled": true,
		"brightness": 1.0,
		"fullscreen": false,
		"vsync": true,
	}
	apply_all_settings()

func apply_all_settings() -> void:
	apply_music_volume()
	apply_brightness()
	apply_fullscreen()
	apply_vsync()
