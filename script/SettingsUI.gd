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
	mouse_filter = Control.MOUSE_FILTER_PASS
	z_index = 9999
	# Debug: Check all node references
	print("=== SETTINGS UI NODE CHECK ===")
	print("apply_button: ", apply_button)
	print("cancel_button: ", cancel_button)
	print("reset_button: ", reset_button)
	print("music_slider: ", music_slider)
	print("volume_label: ", volume_label)
	print("music_check_box: ", music_check_box)
	print("brightness_slider: ", brightness_slider)
	print("brightness_label: ", brightness_label)
	print("fullscreen_check_box: ", fullscreen_check_box)
	print("v_sync_check_box: ", v_sync_check_box)
	
	# Try to find missing nodes manually
	find_missing_nodes()
	move_to_front()
	
	if SettingsManager:
		original_settings = SettingsManager.settings.duplicate()
		load_current_settings()
	else:
		print("❌ SettingsManager not found!")
	
	connect_ui_signals()
	
	# Debug: Check slider ranges
	if music_slider and brightness_slider:
		print("=== SLIDER SETUP DEBUG ===")
		print("Music slider - Min: ", music_slider.min_value, ", Max: ", music_slider.max_value, ", Current: ", music_slider.value)
		print("Brightness slider - Min: ", brightness_slider.min_value, ", Max: ", brightness_slider.max_value, ", Current: ", brightness_slider.value)

func find_missing_nodes():
	"""Try to find missing nodes using find_child"""
	if not apply_button:
		apply_button = find_child("ApplyButton", true, false)
		print("Found ApplyButton manually: ", apply_button)
	
	if not cancel_button:
		cancel_button = find_child("CancelButton", true, false)
		print("Found CancelButton manually: ", cancel_button)
	
	if not reset_button:
		reset_button = find_child("ResetButton", true, false)
		print("Found ResetButton manually: ", reset_button)
	
	if not music_slider:
		music_slider = find_child("MusicSlider", true, false)
		print("Found MusicSlider manually: ", music_slider)
	
	if not volume_label:
		volume_label = find_child("VolumeLabel", true, false)
		print("Found VolumeLabel manually: ", volume_label)
	
	if not music_check_box:
		music_check_box = find_child("MusicCheckBox", true, false)
		print("Found MusicCheckBox manually: ", music_check_box)
	
	if not brightness_slider:
		brightness_slider = find_child("BrightnessSlider", true, false)
		print("Found BrightnessSlider manually: ", brightness_slider)
	
	if not brightness_label:
		brightness_label = find_child("BrightnessLabel", true, false)
		print("Found BrightnessLabel manually: ", brightness_label)
	
	if not fullscreen_check_box:
		fullscreen_check_box = find_child("FullscreenCheckBox", true, false)
		print("Found FullscreenCheckBox manually: ", fullscreen_check_box)
	
	if not v_sync_check_box:
		v_sync_check_box = find_child("VSyncCheckBox", true, false)
		print("Found VSyncCheckBox manually: ", v_sync_check_box)

func connect_ui_signals():
	# Safe signal connections with null checks
	if music_slider:
		music_slider.value_changed.connect(_on_music_volume_changed)
		music_slider.mouse_filter = Control.MOUSE_FILTER_STOP
	
	if music_check_box:
		music_check_box.toggled.connect(_on_music_enabled_toggled)
		music_check_box.mouse_filter = Control.MOUSE_FILTER_STOP
	
	if brightness_slider:
		brightness_slider.value_changed.connect(_on_brightness_changed)
		brightness_slider.mouse_filter = Control.MOUSE_FILTER_STOP
	
	if fullscreen_check_box:
		fullscreen_check_box.toggled.connect(_on_fullscreen_toggled)
		fullscreen_check_box.mouse_filter = Control.MOUSE_FILTER_STOP
	
	if v_sync_check_box:
		v_sync_check_box.toggled.connect(_on_vsync_toggled)
		v_sync_check_box.mouse_filter = Control.MOUSE_FILTER_STOP

	if apply_button:
		apply_button.pressed.connect(_on_apply_pressed)
		apply_button.mouse_filter = Control.MOUSE_FILTER_STOP
		print("✅ Apply button connected and configured")
	else:
		print("❌ Apply button not found - cannot connect signal")
	
	if cancel_button:
		cancel_button.pressed.connect(_on_cancel_pressed)
		cancel_button.mouse_filter = Control.MOUSE_FILTER_STOP
		print("✅ Cancel button connected and configured")
	else:
		print("❌ Cancel button not found - cannot connect signal")
	
	if reset_button:
		reset_button.pressed.connect(_on_reset_pressed)
		reset_button.mouse_filter = Control.MOUSE_FILTER_STOP
		print("✅ Reset button connected and configured")
	else:
		print("❌ Reset button not found - cannot connect signal")

func load_current_settings():
	if not SettingsManager:
		return
	
	# Audio - Convert 0-1 to 0-100 for display
	if music_slider and volume_label:
		var display_value = SettingsManager.get_music_volume() * 100.0
		music_slider.value = display_value
		volume_label.text = str(int(display_value)) + "%"
	
	if music_check_box:
		music_check_box.button_pressed = SettingsManager.is_music_enabled()
		if music_slider and volume_label:
			music_slider.editable = music_check_box.button_pressed
			var alpha = 1.0 if music_check_box.button_pressed else 0.5
			music_slider.modulate.a = alpha
			volume_label.modulate.a = alpha

	# Video - Fixed brightness calculation
	if brightness_slider and brightness_label:
		brightness_slider.value = SettingsManager.get_brightness()
		var pct = int((SettingsManager.get_brightness() - 1.0) * 100)
		brightness_label.text = ("+" if pct >= 0 else "") + str(pct) + "%"

	if fullscreen_check_box:
		fullscreen_check_box.button_pressed = SettingsManager.is_fullscreen()
	
	if v_sync_check_box:
		v_sync_check_box.button_pressed = SettingsManager.is_vsync_enabled()

# -------------------------
# Signal Handlers
# -------------------------
func _on_music_volume_changed(value: float):
	if not SettingsManager or not volume_label:
		return
		
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
	if not SettingsManager:
		return
		
	SettingsManager.set_music_enabled(enabled)
	
	if music_slider and volume_label:
		music_slider.editable = enabled
		var alpha = 1.0 if enabled else 0.5
		music_slider.modulate.a = alpha
		volume_label.modulate.a = alpha
	
	print("Music enabled: ", enabled)

func _on_brightness_changed(value: float):
	if not SettingsManager or not brightness_label:
		return
		
	SettingsManager.set_brightness(value)
	# Fixed brightness percentage calculation
	var pct = int((value - 1.0) * 100)
	brightness_label.text = ("+" if pct >= 0 else "") + str(pct) + "%"
	print("Brightness set to: ", value, " (", pct, "%)")

func _on_fullscreen_toggled(enabled: bool):
	if not SettingsManager:
		return
		
	SettingsManager.set_fullscreen(enabled)
	print("Fullscreen: ", enabled)

func _on_vsync_toggled(enabled: bool):
	if not SettingsManager:
		return
		
	SettingsManager.set_vsync_enabled(enabled)
	print("VSync: ", enabled)

func _on_apply_pressed():
	print("Applying settings...")
	if SettingsManager:
		SettingsManager.save_settings()
	emit_signal("closed")
	queue_free()

func _on_cancel_pressed():
	print("Cancelling settings...")
	if SettingsManager:
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
	if SettingsManager:
		SettingsManager.reset_to_defaults()
		load_current_settings()
	dialog.queue_free()

func _on_reset_cancelled(dialog: ConfirmationDialog):
	dialog.queue_free()

# Close settings with ESC key
func _input(event):
	if event.is_action_pressed("ui_cancel"):
		_on_cancel_pressed()
