extends Control

# -----------------------
# NODES
# -----------------------
@onready var fade_overlay: ColorRect = $FadeOverlay
@onready var wake_up_text: RichTextLabel = $UILayer/WakeupText
@onready var voice_text: RichTextLabel = $UILayer/VoiceText
@onready var mc_thought_text: RichTextLabel = $UILayer/MCThoughtText
@onready var shard_text: RichTextLabel = $UILayer/ShardText

@onready var hospital_bed: TextureRect = $FlashContainer/HospitalBed
@onready var hallway: TextureRect = $FlashContainer/Hallway
@onready var calendar: TextureRect = $FlashContainer/Calendar
@onready var shard_memory: TextureRect = $FlashContainer/ShardMemory
@onready var mc_reflection: TextureRect = $FlashContainer/MCReflection

# -----------------------
# AUDIO
# -----------------------
@onready var static_player: AudioStreamPlayer = $StaticPlayer
@onready var whispers_player: AudioStreamPlayer = $WhisperPlayer
@onready var heartbeat_player: AudioStreamPlayer = $HeartbeatPlayer
@onready var voice_player: AudioStreamPlayer = $VoicePlayer
@onready var tinnitus_player: AudioStreamPlayer = $tinnitusPlayer
@onready var footsteps_player: AudioStreamPlayer = $footstepPlayer

var static_audio: AudioStream = preload("res://assets/audio/ambient/Static_Sound.mp3")
@export var whispers_audio: AudioStream
@export var voice_audio: AudioStream
@export var heartbeat_audio: AudioStream
@export var tinnitus_audio: AudioStream
@export var footsteps_audio: AudioStream

# -----------------------
# STATE
# -----------------------
var scene_phase := 0
var phase_timer := 0.0
var is_scene_active := false
var phase_started := false

# Phase durations (in seconds)
var PHASE_TIMES := [
	2.0, # Phase 0: Static Flicker
	3.0, # Phase 1: Hospital Bed flash
	3.0, # Phase 2: Hallway flash
	3.0, # Phase 3: Calendar flash
	5.0, # Phase 4: MC Reflection
	5.0, # Phase 5: Wake Up text
	5.0, # Phase 6: Voice line
	5.0, # Phase 7: MC Thought
	9999.0 # Phase 8: Memory Shard (final, waits → fade out)
]

signal sequence_completed

# -----------------------
# SETUP
# -----------------------
func _ready():
	setup_simple_scene()
	trigger_sequence()
	
func setup_simple_scene():
	if fade_overlay:
		fade_overlay.color = Color(0, 0, 0, 1)

	if wake_up_text:
		wake_up_text.text = ""
		wake_up_text.visible = false
	if voice_text:
		voice_text.text = ""
		voice_text.visible = false
	if mc_thought_text:
		mc_thought_text.text = ""
		mc_thought_text.visible = false
	if shard_text:
		shard_text.text = ""
		shard_text.visible = false
	
	if hospital_bed: hospital_bed.visible = false
	if hallway: hallway.visible = false
	if calendar: calendar.visible = false
	if shard_memory: shard_memory.visible = false
	if mc_reflection: mc_reflection.visible = false

func trigger_sequence():
	start_memory_room()

func start_memory_room():
	if is_scene_active:
		return
		
	is_scene_active = true
	scene_phase = 0
	phase_timer = 0.0
	phase_started = false
	
	print("🎬 Starting Memory Room sequence...")

	if static_player and static_audio:
		static_player.stream = static_audio
		static_player.volume_db = -20.0
		static_player.play()
		print("🎵 Static playing:", static_audio)

	if whispers_player and whispers_audio:
		whispers_player.stream = whispers_audio
		whispers_player.volume_db = -6.0
		whispers_player.play()
		print("🎵 Whispers playing:", whispers_audio)

func _process(delta):
	if not is_scene_active:
		return
		
	phase_timer += delta

	match scene_phase:
		0: phase_static_flicker()
		1: phase_hospital_flash()
		2: phase_hallway_flash()
		3: phase_calendar_flash()
		4: phase_mc_reflection()
		5: phase_wake_up_text()
		6: phase_voice_line()
		7: phase_mc_thought()
		8: complete_sequence()
	
	# Advance only if NOT the shard phase
	if scene_phase < PHASE_TIMES.size() - 1 and phase_timer >= PHASE_TIMES[scene_phase]:
		advance_phase()

# -----------------------
# PHASES
# -----------------------
func phase_static_flicker():
	if not phase_started:
		print("➡ Phase 0: Static Flicker")
		phase_started = true

	var flicker = randf()
	if flicker > 0.5:
		fade_overlay.color = Color(0, 0, 0, 0.7)
	else:
		fade_overlay.color = Color(0, 0, 0, 0.0)


func phase_hospital_flash():
	if not phase_started:
		print("➡ Phase 1: Hospital Bed Flash")
		_show_background(hospital_bed)
		phase_started = true
	hospital_bed.visible = randf() > 0.5
	if heartbeat_player and heartbeat_audio:
		heartbeat_player.stream = heartbeat_audio
		heartbeat_player.volume_db = -6.0
		heartbeat_player.play()
		print("🎵 Whispers playing:", heartbeat_audio)

func phase_hallway_flash():
	if not phase_started:
		print("➡ Phase 2: Hallway Flash")
		_show_background(hallway)
		phase_started = true
	hallway.visible = randf() > 0.5

func phase_calendar_flash():
	if not phase_started:
		print("➡ Phase 3: Calendar Flash")
		_show_background(calendar)
		phase_started = true
	calendar.visible = randf() > 0.5

func phase_mc_reflection():
	if not phase_started:
		print("➡ Phase 4: MC Reflection")
		_show_background(mc_reflection)
		mc_reflection.visible = true
		phase_started = true
	mc_reflection.visible = randf() > 0.5
	if phase_timer >= PHASE_TIMES[4] - 0.1 and fade_overlay:
		fade_overlay.color = Color(0, 0, 0, 1)

func phase_wake_up_text():
	if not phase_started:
		print("➡ Phase 5: Wake Up Text")
		wake_up_text.text = "Wake up."
		wake_up_text.visible = true
		phase_started = true

func phase_voice_line():
	if not phase_started:
		print("➡ Phase 6: Voice Line")
		if voice_player and voice_audio:
			voice_player.stream = voice_audio
			voice_player.play()
		voice_text.text = "You don't belong here."
		voice_text.visible = true
		phase_started = true

func phase_mc_thought():
	if not phase_started:
		print("➡ Phase 7: MC Thought")
		mc_thought_text.text = "What... was that voice?"
		mc_thought_text.visible = true
		phase_started = true

#func phase_memory_fragment():
	#if not phase_started:
		#print("➡ Phase 8: Memory Shard Appears (final)")
		#_show_background(shard_memory)
#
		## Fade in shard + text
		#shard_memory.visible = true
		#shard_memory.modulate.a = 0.0
		#shard_text.text = "A broken shard of memory surfaces..."
		#shard_text.visible = true
		#shard_text.modulate.a = 0.0
#
		#if fade_overlay:
			#fade_overlay.color = Color(0, 0, 0, 0)
#
		#var tween = create_tween()
#
		## Fade IN
		#tween.parallel().tween_property(shard_memory, "modulate:a", 1.0, 2.0)
		#tween.parallel().tween_property(shard_text,  "modulate:a", 1.0, 2.0)
#
		## Wait 1 second
		#tween.tween_interval(1.0)
#
		## Fade OUT
		#tween.parallel().tween_property(shard_memory, "modulate:a", 0.0, 2.0)
		#tween.parallel().tween_property(shard_text,  "modulate:a", 0.0, 2.0)
#
		#phase_started = true
#
		## Save the memory shard to the database
		#var saved = InventoryManager.save_memory_shard(
			#"Memory Shard 2",
			#"A broken shard of memory surfaces...",
			#"res://icons/memory_shard.png",
			#"Get while sleeping..."
		#)
		#if saved:
			#print("✓ Memory shard saved")
#
		## Optionally add a reward item to inventory
		#InventoryManager.add_item(2, 1, 1)  # slot_id = 2, item_id = 1 (Potion), quantity = 1
		#print("✓ Reward item added to inventory")
#
		## After showing for a while, fade out
		#await get_tree().create_timer(3.0).timeout
		#_fade_out_shard()
#
#
#func _fade_out_shard():
	#print("✨ Fading shard out, preparing scene transition...")
#
	#var tween = create_tween()
	#if shard_memory:
		#tween.tween_property(shard_memory, "modulate:a", 0.0, 2.0)
	#if shard_text:
		#tween.tween_property(shard_text, "modulate:a", 0.0, 2.0)
	#if fade_overlay:
		#tween.tween_property(fade_overlay, "color", Color(0, 0, 0, 1), 2.0)
#
	#tween.connect("finished", Callable(self, "_on_shard_fade_complete"))
#
#func _on_shard_fade_complete():
	#print("➡ Shard fade complete → load next scene")
	#complete_sequence()

# -----------------------
# SEQUENCE CONTROL
# -----------------------
func advance_phase():
	if wake_up_text: wake_up_text.visible = false
	if voice_text: voice_text.visible = false
	if mc_thought_text: mc_thought_text.visible = false

	scene_phase += 1
	phase_timer = 0.0
	phase_started = false
	print("➡ ADVANCED TO PHASE:", scene_phase)

	if scene_phase >= PHASE_TIMES.size():
		complete_sequence()

func complete_sequence():
	is_scene_active = false
	picture_1()
	picture_2()
	picture_3()
	print("✅ Memory Room sequence complete! → Loading Scene7")
	sequence_completed.emit()
		

	
	# ✅ Save current game state (player position, scene, etc.)
	if SaveManager:
		var saved := SaveManager.save_game()
		if saved:
			print("💾 Game state saved successfully")
		else:
			print("❌ Failed to save game state")

	# ✅ Log scene completion for branching system
	if SaveManager:
		var scene_path = get_tree().current_scene.scene_file_path
		var branch_id = "awakening"  # Or any meaningful branch ID
		var logged := SaveManager.log_scene_completion(scene_path, branch_id)
		if logged:
			print("📌 Scene logged to game_path:", scene_path)
		else:
			print("ℹ️ Scene already logged or failed to log.")

	var next_scene_path = "res://scenes/Scene7/Scene7.tscn"
	if ResourceLoader.exists(next_scene_path):
		get_tree().change_scene_to_file(next_scene_path)
	else:
		push_error("❌ Could not find next scene: " + next_scene_path)
	
	
# -----------------------
# BACKGROUND CONTROL
# -----------------------
func _show_background(bg_node: Node):
	if hospital_bed: hospital_bed.visible = false
	if hallway: hallway.visible = false
	if calendar: calendar.visible = false
	if shard_memory: shard_memory.visible = false
	if mc_reflection: mc_reflection.visible = false
	
	if bg_node:
		bg_node.visible = true

func picture_1():
	var icon_path = "res://assets/images/calendar.png"
	if not ResourceLoader.exists(icon_path):
		icon_path = "res://assets/icons/default.png"

	var item_data = {
		"id": 101,
		"name": "Photo 1",
		"description": "You know the calendar, but you forgotten.",
		"icon_path": icon_path,
		"stack_size": 1,
		"is_completed": true
	}

	InventoryManager.save_item_to_items_table(item_data)

	var slot_id = InventoryManager.get_next_available_slot()
	InventoryManager.add_item(slot_id, 101, 1)

	var ui = get_tree().get_nodes_in_group("inventory_ui")
	if ui.size() > 0 and ui[0].active_tab == "items":
		ui[0].load_inventory()

func picture_2():
	var icon_path = "res://assets/images/hallway.png"
	if not ResourceLoader.exists(icon_path):
		icon_path = "res://assets/icons/default.png"

	var item_data = {
		"id": 102,
		"name": "Photo 2",
		"description": "this hallway seems familiar.",
		"icon_path": icon_path,
		"stack_size": 1,
		"is_completed": true
	}

	InventoryManager.save_item_to_items_table(item_data)

	var slot_id = InventoryManager.get_next_available_slot()
	InventoryManager.add_item(slot_id, 102, 1)

	var ui = get_tree().get_nodes_in_group("inventory_ui")
	if ui.size() > 0 and ui[0].active_tab == "items":
		ui[0].load_inventory()

func picture_3():
	var icon_path = "res://assets/images/hospitalBed.png"
	if not ResourceLoader.exists(icon_path):
		icon_path = "res://assets/icons/default.png"

	var item_data = {
		"id": 103,
		"name": "Photo 3",
		"description": "You can't remember the past.",
		"icon_path": icon_path,
		"stack_size": 1,
		"is_completed": true
	}

	InventoryManager.save_item_to_items_table(item_data)

	var slot_id = InventoryManager.get_next_available_slot()
	InventoryManager.add_item(slot_id, 103, 1)

	var ui = get_tree().get_nodes_in_group("inventory_ui")
	if ui.size() > 0 and ui[0].active_tab == "items":
		ui[0].load_inventory()
