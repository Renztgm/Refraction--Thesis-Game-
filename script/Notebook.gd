extends Area3D

@onready var dialogue_label: RichTextLabel = $"../CanvasLayer/Panel/DialogueLabel"
@onready var flash_screen: ColorRect = $"../CanvasLayer/FlashScreen"
@onready var next_button: Button = $"../CanvasLayer/NextButton"
@onready var panel: Panel = $"../CanvasLayer/Panel"

# Memory Shard UI references
@onready var memory_shard_layer: CanvasLayer = $"../MemoryShard"
@onready var shard_panel: Panel = $"../MemoryShard/ShardPanel"
@onready var shard_image: TextureRect = $"../MemoryShard/ShardPanel/ShardImage"
@onready var shard_description: Label = $"../MemoryShard/ShardPanel/ShardDescription"
@onready var shard_close_button: Button = $"../MemoryShard/ShardPanel/CloseButton"

# Dialogue text
var notebook_message: String = "I used to come here. Someone read to me here... but who?"
var mc_line: String = "It's... still a little fuzzy."
var companion_line: String = "Companion: Careful. Touching pieces like that… it might hurt. Or help. Depends on what you've forgotten."

# Memory Shard data
var shard_texture: Texture2D = preload("res://addons/pngs/shard.png")
var shard_text: String = "This shard contains a memory of warmth and a forgotten voice..."
var shard_name: String = "Memory_shard_1"  # Unique identifier for this shard
var shard_scene_location: String = "Library Notebook Area"

# Dialogue state
enum DialogueState { NONE, NOTEBOOK, MC, COMPANION, SHARD }
var dialogue_state: DialogueState = DialogueState.NONE

# Player + state flags
var has_triggered: bool = false
var player_ref: Node = null
var text_is_showing: bool = false

# Reference to InventoryManager
var inventory_manager: Node = null


func _ready():
	body_entered.connect(_on_body_entered)
	
	# Get InventoryManager reference
	inventory_manager = get_node_or_null("/root/InventoryManager")
	if not inventory_manager:
		print("ERROR: InventoryManager autoload not found!")
	else:
		print("DEBUG: InventoryManager successfully loaded")

	if next_button:
		print("DEBUG: Button found and connecting signal")
		next_button.pressed.connect(_on_next_button_pressed)
		next_button.visible = false
		next_button.disabled = false
	else:
		print("ERROR: next_button not found!")

	if panel:
		panel.visible = false

	if flash_screen:
		flash_screen.modulate.a = 0.0
		flash_screen.visible = false

	# Setup MemoryShard
	if memory_shard_layer:
		memory_shard_layer.visible = false
	if shard_close_button:
		shard_close_button.pressed.connect(_on_shard_close_pressed)


# When player presses Next
func _on_next_button_pressed():
	match dialogue_state:
		DialogueState.NOTEBOOK:
			# Show MC dialogue
			dialogue_label.text = mc_line
			dialogue_state = DialogueState.MC

		DialogueState.MC:
			# Show Companion dialogue
			dialogue_label.text = companion_line
			dialogue_state = DialogueState.COMPANION

		DialogueState.COMPANION:
			# End dialogue, show MemoryShard UI and save to database
			hide_text()
			if memory_shard_layer:
				shard_image.texture = shard_texture
				shard_description.text = shard_text
				memory_shard_layer.visible = true
				
				# Save memory shard to database
				save_memory_shard_to_db()
			
			dialogue_state = DialogueState.SHARD

		_:
			hide_text()


# Save the memory shard to database
func save_memory_shard_to_db():
	if not inventory_manager:
		print("ERROR: Cannot save memory shard - InventoryManager not available")
		return
	
	var icon_path = shard_texture.resource_path if shard_texture else ""
	var success = inventory_manager.save_memory_shard(
		shard_name,
		shard_text,
		icon_path,
		shard_scene_location
	)
	
	if success:
		print("Memory shard '%s' successfully saved!" % shard_name)
	else:
		print("Memory shard '%s' was already collected" % shard_name)


# Trigger when player enters the area
func _on_body_entered(body: Node) -> void:
	if has_triggered:
		return
	if body.is_in_group("player"):
		has_triggered = true
		player_ref = body
		print("DEBUG: Player entered the notebook area.")
		
		# Freeze player
		if player_ref.has_method("freeze_player"):
			player_ref.freeze_player()
		
		# Call glitch effect first
		glitch_flash_effect()


# Flash/glitch effect before showing first dialogue
func glitch_flash_effect() -> void:
	if not flash_screen:
		return
	
	flash_screen.visible = true
	var tween = create_tween()
	
	# Rapid stutter flashes
	for i in range(8):
		var intensity = randf_range(0.2, 0.9)
		var flash_time = randf_range(0.02, 0.08)
		var pause_time = randf_range(0.01, 0.05)
		
		tween.tween_method(set_flash_alpha, 0.0, intensity, flash_time)
		tween.tween_method(set_flash_alpha, intensity, 0.0, flash_time * 0.5)
		tween.tween_interval(pause_time)
	
	# Brief pause
	tween.tween_interval(0.1)
	
	# Erratic color shifts with flashes
	for i in range(5):
		var color = get_random_glitch_color()
		var intensity = randf_range(0.3, 0.8)
		tween.tween_callback(func(): flash_screen.color = color)
		tween.tween_method(set_flash_alpha, 0.0, intensity, 0.03)
		tween.tween_method(set_flash_alpha, intensity, 0.0, 0.06)
		tween.tween_interval(randf_range(0.02, 0.08))
	
	# Reset color and final dramatic flash sequence
	tween.tween_callback(func(): flash_screen.color = Color.WHITE)
	tween.tween_interval(0.15)
	
	# Final chaotic burst
	for i in range(12):
		var intensity = randf_range(0.1, 1.0)
		var flash_time = randf_range(0.01, 0.04)
		tween.tween_method(set_flash_alpha, 0.0, intensity, flash_time)
		tween.tween_method(set_flash_alpha, intensity, 0.0, flash_time * 0.3)
		if i < 11:  # Don't add interval after last flash
			tween.tween_interval(randf_range(0.005, 0.03))
	
	# Clean up and show notebook dialogue
	tween.tween_callback(func(): 
		flash_screen.visible = false
		flash_screen.color = Color.WHITE
		flash_screen.modulate.a = 0.0
		
		# Show first dialogue AFTER flashing finishes
		show_text()
	)


# Helpers
func get_random_glitch_color() -> Color:
	var colors = [
		Color.WHITE,
		Color.RED * 0.8,
		Color.CYAN * 0.9,
		Color.MAGENTA * 0.7,
		Color.GREEN * 0.6,
		Color.YELLOW * 0.8,
		Color(0.9, 0.9, 1.0),  # Slight blue tint
		Color(1.0, 0.8, 0.8)   # Slight red tint
	]
	return colors[randi() % colors.size()]


func set_flash_alpha(alpha: float) -> void:
	flash_screen.modulate.a = alpha


func show_text() -> void:
	dialogue_label.text = notebook_message
	dialogue_state = DialogueState.NOTEBOOK
	text_is_showing = true
	if next_button:
		next_button.visible = true
	if panel:
		panel.visible = true


func hide_text() -> void:
	dialogue_label.text = ""
	text_is_showing = false
	if next_button:
		next_button.visible = false
	if panel:
		panel.visible = false


func _on_shard_close_pressed():
	memory_shard_layer.visible = false

	# Resume gameplay
	if player_ref and player_ref.has_method("unfreeze_player"):
		player_ref.unfreeze_player()
		
		get_tree().change_scene_to_file("res://scenes/Scene4/AlleyScene.tscn")
