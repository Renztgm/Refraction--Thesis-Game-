extends Control

signal closed   # Signal to notify PauseMenu

# --- UI References ---
@onready var apply_button: Button = $SettingsPanel/VBox/HBoxContainer/ApplyButton
@onready var cancel_button: Button = $SettingsPanel/VBox/HBoxContainer/CancelButton
@onready var reset_button: Button = $SettingsPanel/VBox/HBoxContainer/ResetButton

@onready var music_slider: HSlider = $SettingsPanel/VBox/AudioSection/MusicVolume/MusicSlider
@onready var volume_label: Label = $SettingsPanel/VBox/AudioSection/MusicVolume/VolumeLabel
@onready var music_check_box: CheckBox = $SettingsPanel/VBox/AudioSection/MusicVolume/MusicEnabled/MusicCheckBox

@onready var brightness_slider: HSlider = $SettingsPanel/VBox/VideoSection/Brightness/BrightnessSlider
@onready var brightness_label: Label = $SettingsPanel/VBox/VideoSection/Brightness/BrightnessLabel
@onready var fullscreen_check_box: CheckBox = $SettingsPanel/VBox/VideoSection/Fullscreen/FullscreenCheckBox
@onready var v_sync_check_box: CheckBox = $SettingsPanel/VBox/VideoSection/VSync/VSyncCheckBox

var original_settings: Dictionary

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS   # UI works while game paused

	original_settings = SettingsManager.settings.duplicate()
	load_current_settings()
	connect_ui_signals()
	
	# Debug: Check slider ranges
	print("=== SLIDER SETUP DEBUG ===")
	print("Music slider - Min: ", music_slider.min_value, ", Max: ", music_slider.max_value, ", Current: ", music_slider.value)
	print("Brightness slider - Min: ", brightness_slider.min_value, ", Max: ", brightness_slider.max_value, ", Current: ", brightness_slider.value)

func connect_ui_signals():
	music_slider.value_changed.connect(_on_music_volume_changed)
	music_check_box.toggled.connect(_on_music_enabled_toggled)
	brightness_slider.value_changed.connect(_on_brightness_changed)
	fullscreen_check_box.toggled.connect(_on_fullscreen_toggled)
	v_sync_check_box.toggled.connect(_on_vsync_toggled)

	apply_button.pressed.connect(_on_apply_pressed)
	cancel_button.pressed.connect(_on_cancel_pressed)
	reset_button.pressed.connect(_on_reset_pressed)

func load_current_settings():
	# Audio - Convert 0-1 to 0-100 for display
	var display_value = SettingsManager.get_music_volume() * 100.0
	music_slider.value = display_value
	volume_label.text = str(int(display_value)) + "%"
	music_check_box.button_pressed = SettingsManager.is_music_enabled()
	music_slider.editable = music_check_box.button_pressed
	var alpha = 1.0 if music_check_box.button_pressed else 0.5
	music_slider.modulate.a = alpha
	volume_label.modulate.a = alpha

	# Video - Fixed brightness calculation
	brightness_slider.value = SettingsManager.get_brightness()
	var pct = int((SettingsManager.get_brightness() - 1.0) * 100)
	brightness_label.text = ("+" if pct >= 0 else "") + str(pct) + "%"

	fullscreen_check_box.button_pressed = SettingsManager.is_fullscreen()
	v_sync_check_box.button_pressed = SettingsManager.is_vsync_enabled()

# -------------------------
# Signal Handlers
# -------------------------
func _on_music_volume_changed(value: float):
	# Convert from 0-100 range to 0-1 range
	var normalized_value = value / 100.0
	SettingsManager.set_music_volume(normalized_value)
	volume_label.text = str(int(value)) + "%"
	
	# Debug output
	print("=== MUSIC VOLUME CHANGED ===")
	print("Slider value: ", value)
	print("Normalized value: ", normalized_value)
	print("Stored value: ", SettingsManager.get_music_volume())

func _on_music_enabled_toggled(enabled: bool):
	SettingsManager.set_music_enabled(enabled)
	music_slider.editable = enabled
	var alpha = 1.0 if enabled else 0.5
	music_slider.modulate.a = alpha
	volume_label.modulate.a = alpha
	
	print("Music enabled: ", enabled)

func _on_brightness_changed(value: float):
	SettingsManager.set_brightness(value)
	# Fixed brightness percentage calculation
	var pct = int((value - 1.0) * 100)
	brightness_label.text = ("+" if pct >= 0 else "") + str(pct) + "%"
	print("Brightness set to: ", value, " (", pct, "%)")

func _on_fullscreen_toggled(enabled: bool):
	SettingsManager.set_fullscreen(enabled)
	print("Fullscreen: ", enabled)

func _on_vsync_toggled(enabled: bool):
	SettingsManager.set_vsync_enabled(enabled)
	print("VSync: ", enabled)

func _on_apply_pressed():
	print("Applying settings...")
	SettingsManager.save_settings()
	emit_signal("closed")
	queue_free()

func _on_cancel_pressed():
	print("Cancelling settings...")
	SettingsManager.settings = original_settings.duplicate()
	SettingsManager.apply_all_settings()
	emit_signal("closed")
	queue_free()

func _on_reset_pressed():
	var confirm_dialog = ConfirmationDialog.new()
	confirm_dialog.dialog_text = "Reset all settings to default values?"
	confirm_dialog.title = "Reset Settings"
	confirm_dialog.confirmed.connect(_on_reset_confirmed.bind(confirm_dialog))
	confirm_dialog.canceled.connect(_on_reset_cancelled.bind(confirm_dialog))
	add_child(confirm_dialog)
	confirm_dialog.popup_centered()

func _on_reset_confirmed(dialog: ConfirmationDialog):
	print("Resetting settings to defaults...")
	SettingsManager.reset_to_defaults()
	load_current_settings()
	dialog.queue_free()

func _on_reset_cancelled(dialog: ConfirmationDialog):
	dialog.queue_free()

# Close settings with ESC key
func _input(event):
	if event.is_action_pressed("ui_cancel"):
		_on_cancel_pressed()
