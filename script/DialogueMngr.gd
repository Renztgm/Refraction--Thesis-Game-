extends Control

signal dialogue_finished

@onready var npc_name_label = $NPCName
@onready var dialogue_label = $DialogueLabel
@onready var next_button = $NextButton
@onready var options_container = $Options

@export var camera: Camera3D
@export var player: Node3D
@export var companion: Node3D
@export var monster: Node3D

# Character voice sound paths
@export var companion_voice_sfx: String = "res://assets/sounds/Companion_Dialogue_short.wav"
@export var player_voice_sfx: String = "res://assets/sounds/MC_dialogue_short.wav"
@export var guardian_voice_sfx: String = ""
@export var stranger_voice_sfx: String = ""
@export var hollow_voice_sfx: String = ""

var dialogue: Dictionary = {}
var current_node: String = "start"

var sentences: Array = []
var current_sentence: int = 0
var full_text: String = ""
var visible_text: String = ""
var char_index: int = 0
var typing_speed: float = 0.03
var typing_timer: Timer

var is_typing: bool = false
var pending_next_node: String = ""
var pending_mc_text: String = ""

var character_voice_player: AudioStreamPlayer


func _ready():
	hide()
	typing_timer = Timer.new()
	typing_timer.wait_time = typing_speed
	typing_timer.one_shot = false
	add_child(typing_timer)
	typing_timer.timeout.connect(_on_typing_step)

	next_button.pressed.connect(_on_next_pressed)
	
	self.gui_input.connect(_on_dialogue_gui_input)
	mouse_filter = Control.MOUSE_FILTER_STOP
	
	# Setup voice player
	character_voice_player = AudioStreamPlayer.new()
	add_child(character_voice_player)

# --- Load dialogue from JSON file ---
func load_dialogue(file_path: String, npc_id: String):
	var file = FileAccess.open(file_path, FileAccess.READ)
	if not file:
		push_error("Cannot open file: " + file_path)
		return

	var content = file.get_as_text()
	file.close()

	var json_data = JSON.parse_string(content)
	if typeof(json_data) != TYPE_DICTIONARY:
		push_error("Failed to parse JSON. Make sure the file is valid!")
		return

	var all_dialogues: Dictionary = json_data

	if not all_dialogues.has(npc_id):
		push_error("No dialogue for NPC: " + npc_id)
		return

	dialogue = all_dialogues[npc_id] as Dictionary

	if not dialogue.has("start"):
		push_error("Dialogue missing 'start' node for NPC: " + npc_id)
		return

	current_node = "start"
	show_node(current_node)
	show()

# --- Show a dialogue node ---
func show_node(node_name: String):
	if node_name == "end":
		_close_dialogue()
		return
		
	if not dialogue.has(node_name):
		push_error("Dialogue node not found: " + node_name)
		return
	
	current_node = node_name
	var node: Dictionary = dialogue[node_name]
	
	# --- Play sound if defined ---
	play_node_sfx(node)
	
	if node.has("start_quest"):
		_start_quest_from_path(node["start_quest"])
	
	# --- Speaker name ---
	npc_name_label.text = node.get("name", "Unknown")

	# --- Sentences ---
	sentences = node.get("sentences", [])
	current_sentence = 0

	# --- Reset UI ---
	_clear_options()
	options_container.visible = false
	next_button.visible = false

	# --- Options ---
	var opts: Array = node.get("options", [])
	for option in opts:
		var btn := Button.new()
		btn.text = option["text"]
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.pressed.connect(func(): _on_option_selected(option))
		options_container.add_child(btn)
	
	# --- Store auto-next if provided ---
	pending_next_node = node.get("next", "")
	
	# --- Cinematic extensions ---
	if node.has("focus"):
		match node["focus"]:
			"Player":
				if player and camera:
					camera.look_at(player.global_transform.origin, Vector3.UP)
			"Companion":
				if companion and camera:
					camera.look_at(companion.global_transform.origin, Vector3.UP)
			"Monster":
				if monster and camera:
					camera.look_at(monster.global_transform.origin, Vector3.UP)

	if node.has("animation"):
		var anim_name: String = node["animation"]
		if npc_name_label.text == "EchoBeast" and monster and monster.has_method("play"):
			monster.play(anim_name)

	# --- Dialogue flow ---
	if sentences.size() > 0:
		_start_sentence()
	elif opts.size() > 0:
		options_container.visible = true
	elif pending_next_node != "":
		show_node(pending_next_node)
	else:
		_close_dialogue()

func _start_quest_from_path(quest_path: String):
	print("📦 Auto-starting quest:", quest_path)

	if not FileAccess.file_exists(quest_path):
		push_error("❌ Quest file not found at: " + quest_path)
		return

	var file = FileAccess.open(quest_path, FileAccess.READ)
	var content = file.get_as_text()
	file.close()

	var quest_data = JSON.parse_string(content)
	if typeof(quest_data) != TYPE_ARRAY:
		push_error("❌ Invalid quest JSON structure in " + quest_path)
		return

	if QuestManager and QuestManager.has_method("import_quests_from_json"):
		QuestManager.import_quests_from_json(quest_path)
		QuestManager.load_all_quests()
		QuestManager.save_all_quests()

		for q in quest_data:
			var quest_id = q.get("id", "unknown")
			var quest_title = q.get("title", quest_id)
			print("🧩 Quest auto-started:", quest_id)
			ItemPopUp.show_message("🧭 New Quest Started: " + quest_title, 3.0, Color.CYAN)
	else:
		push_error("❌ QuestManager missing or import method unavailable!")


# --- Start typing a sentence ---
func _start_sentence():
	full_text = sentences[current_sentence]
	visible_text = ""
	char_index = 0
	is_typing = true
	dialogue_label.text = ""
	next_button.visible = false
	
	# Play character voice when starting new sentence
	play_character_voice()
	
	typing_timer.start()

# --- NEW: Play voice based on who's speaking ---
func play_character_voice():
	var speaker_name = npc_name_label.text
	var voice_path = ""
	var volume_db = 0.0  # Default volume
	
	# Check speaker and assign appropriate voice + volume
	if speaker_name == "You":
		voice_path = player_voice_sfx
		volume_db = -5.0  
	elif speaker_name == "Lyra" or speaker_name == "Companion":
		voice_path = companion_voice_sfx
		volume_db = -15.0  
	elif speaker_name == "Guardian":
		voice_path = guardian_voice_sfx
		volume_db = 0.0 
	elif speaker_name == "Hollow":
		voice_path = hollow_voice_sfx
		volume_db = 0.0 
	elif speaker_name == "Stranger":
		voice_path = stranger_voice_sfx
		volume_db = 0.0 
	
	#checking if sound_player have correct variables.
	if voice_path != "" and ResourceLoader.exists(voice_path):
		var audio_stream: AudioStream = load(voice_path)
		if audio_stream:
			character_voice_player.stream = audio_stream
			character_voice_player.volume_db = volume_db  # Set volume
			character_voice_player.play()
	elif voice_path != "":
		push_warning("Character voice not found: " + voice_path)

# --- Typing effect ---
func _on_typing_step():
	if char_index < full_text.length():
		visible_text += full_text[char_index]
		dialogue_label.text = visible_text
		char_index += 1
	else:
		typing_timer.stop()
		is_typing = false

		# Distinguish between NPC lines and MC lines
		if npc_name_label.text != "You":
			# NPC speaking
			var node = dialogue.get(current_node, {})
			var opts = node.get("options", [])
			if current_sentence >= sentences.size() - 1 and opts.size() > 0 and pending_mc_text == "":
				# Last NPC line → show options immediately
				options_container.visible = true
				next_button.visible = false
			else:
				# NPC mid-line or no options → Next button
				next_button.visible = true
		else:
			# MC speaking → always Next after line finishes
			next_button.visible = true

# --- Next button pressed ---
func _on_next_pressed():
	if is_typing:
		typing_timer.stop()
		dialogue_label.text = full_text
		is_typing = false
		next_button.visible = true
		return

	# Move to next sentence in the current node
	if current_sentence < sentences.size() - 1:
		current_sentence += 1
		_start_sentence()
		return

	# If MC text is pending, type it now
	if pending_mc_text != "":
		full_text = pending_mc_text
		pending_mc_text = ""
		visible_text = ""
		char_index = 0
		is_typing = true

		# Show player as the speaker
		npc_name_label.text = "You"

		dialogue_label.text = ""
		next_button.visible = false
		
		# Play player voice
		play_character_voice()
		
		typing_timer.start()
		return

	# Otherwise, move to next node if defined
	if pending_next_node != "":
		var next_node = pending_next_node
		pending_next_node = ""
		show_node(next_node)
		return

	# No more sentences or options → close dialogue
	var node = dialogue[current_node]
	if node.get("options", []).size() > 0:
		options_container.visible = true
		next_button.visible = false
	else:
		_close_dialogue()

# --- Player selects an option ---
func _on_option_selected(option_data: Dictionary):
	print("🧪 Option selected:", option_data)
	_clear_options()
	options_container.visible = false

	var mc_text = option_data.get("full_text", option_data.get("text", "…"))

	# Handle quest triggers
	if option_data.has("start_quest"):
		var quest_path = option_data["start_quest"]
		print("📦 Starting quest from:", quest_path)

		if FileAccess.file_exists(quest_path):
			var file = FileAccess.open(quest_path, FileAccess.READ)
			var content = file.get_as_text()
			file.close()

			var quest_data = JSON.parse_string(content)
			if typeof(quest_data) == TYPE_ARRAY:
				# ✅ Import the quest(s) properly
				if QuestManager and QuestManager.has_method("import_quests_from_json"):
					QuestManager.import_quests_from_json(quest_path)
					QuestManager.load_all_quests()
					QuestManager.save_all_quests()

					var started_quests = quest_data
					for q in started_quests:
						var quest_id = q.get("id", "unknown")
						var quest_title = q.get("title", quest_id)
						print("🧩 Quest started:", quest_id)
						ItemPopUp.show_message("🧭 New Quest Started: " + quest_title, 3.0, Color.CYAN)
				else:
					push_error("❌ QuestManager missing or import method unavailable!")
			else:
				push_error("❌ Invalid quest JSON structure in " + quest_path)
		else:
			push_error("❌ Quest file not found at: " + quest_path)

	if option_data.has("complete_objective"):
		var quest_id = option_data["quest_id"]
		var objective = option_data["complete_objective"]
		QuestManager.complete_objective(quest_id, objective)

	if option_data.has("set_flag"):
		var flag_name = option_data["set_flag"]
		get_node("/root/NarrativeState").set_flag(flag_name, true)

	var next_node = option_data.get("next", "end")
	if not dialogue.has(next_node):
		next_node = "end"

	pending_mc_text = mc_text
	pending_next_node = next_node

	_on_next_pressed()

# --- Clear all options ---
func _clear_options():
	for c in options_container.get_children():
		c.queue_free()

func _on_dialogue_gui_input(event: InputEvent):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.double_click:
			_skip_sentence()

func _skip_sentence():
	if is_typing:
		typing_timer.stop()
		dialogue_label.text = full_text
		is_typing = false
		next_button.visible = true

# --- Close dialogue ---
func _close_dialogue():
	if typing_timer and not typing_timer.is_stopped():
		typing_timer.stop()
	if character_voice_player and character_voice_player.playing:
		character_voice_player.stop()
	dialogue_label.text = ""
	_clear_options()
	options_container.visible = false
	next_button.visible = false
	hide()
	emit_signal("dialogue_finished")
	
# Helper function to play a sound from a dialogue node
func play_node_sfx(node: Dictionary):
	if not node.has("sound"):
		return
	
	var sound_path: String = node["sound"]
	if not ResourceLoader.exists(sound_path):
		push_error("Dialogue SFX not found: " + sound_path)
		return
	
	var audio_stream: AudioStream = load(sound_path)
	if not audio_stream:
		push_error("Failed to load audio: " + sound_path)
		return
	
	# Create player
	var sfx_player := AudioStreamPlayer.new()
	add_child(sfx_player)
	sfx_player.stream = audio_stream
	sfx_player.play()
	
	# Determine duration (fallback if unknown)
	var duration := 3.0
	if audio_stream.has_method("get_length"):
		duration = audio_stream.get_length()
	
	# Queue free player after it finishes
	var t := Timer.new()
	t.one_shot = true
	t.wait_time = duration
	add_child(t)
	t.start()
	t.timeout.connect(Callable(sfx_player, "queue_free"))
