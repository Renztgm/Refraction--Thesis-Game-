extends Node

# ═══════════════════════════════════════════════════════════════════
# NARRATIVE PROGRESSION SYSTEM
# Tracks story choices, remembered facts, and branching paths
# ═══════════════════════════════════════════════════════════════════

signal memory_unlocked(key: String)
signal memory_lost(key: String)
signal story_flag_changed(flag: String, value: Variant)
signal ending_unlocked(ending_id: String)

# ────────────────────────────────────────────────────────────────────
# MEMORY TRACKING
# ────────────────────────────────────────────────────────────────────

var remembered_facts: Dictionary = {
	# "hospital": true/false
	# "accident": true/false
	# "coma": true/false
}

var failed_memories: Array[String] = []
var unlocked_memories: Array[String] = []

# ────────────────────────────────────────────────────────────────────
# STORY FLAGS (for general branching)
# ────────────────────────────────────────────────────────────────────

var story_flags: Dictionary = {
	# "met_lyra": true
	# "chose_truth": false
	# "mirror_shattered": true
}

# ────────────────────────────────────────────────────────────────────
# CHAPTER PROGRESS
# ────────────────────────────────────────────────────────────────────

var current_chapter: int = 1
var chapter_completion: Dictionary = {}

# ────────────────────────────────────────────────────────────────────
# ENDINGS
# ────────────────────────────────────────────────────────────────────

var available_endings: Array[String] = []
var achieved_ending: String = ""

# ═══════════════════════════════════════════════════════════════════
# MEMORY MANAGEMENT
# ═══════════════════════════════════════════════════════════════════

func remember_fact(fact_key: String) -> void:
	"""Mark a memory/fact as successfully remembered"""
	fact_key = fact_key.to_upper()
	remembered_facts[fact_key] = true
	
	if fact_key not in unlocked_memories:
		unlocked_memories.append(fact_key)
	
	# Remove from failed if it was there
	if fact_key in failed_memories:
		failed_memories.erase(fact_key)
	
	memory_unlocked.emit(fact_key)
	print("✅ Remembered:", fact_key)

func forget_fact(fact_key: String) -> void:
	"""Mark a memory/fact as failed/forgotten"""
	fact_key = fact_key.to_upper()
	remembered_facts[fact_key] = false
	
	if fact_key not in failed_memories:
		failed_memories.append(fact_key)
	
	# ⚠️ CRITICAL: Remove from unlocked_memories if it was there
	if fact_key in unlocked_memories:
		unlocked_memories.erase(fact_key)
	
	memory_lost.emit(fact_key)
	print("❌ Forgot:", fact_key)
	print("Currently remembered:", unlocked_memories)
	print("Currently forgotten:", failed_memories)

func is_remembered(fact_key: String) -> bool:
	"""Check if a specific fact was remembered"""
	return remembered_facts.get(fact_key.to_upper(), false)

func is_forgotten(fact_key: String) -> bool:
	"""Check if a specific fact was forgotten"""
	return fact_key.to_upper() in failed_memories

func get_memory_completion() -> float:
	"""Returns percentage of memories unlocked (0.0 to 1.0)"""
	if remembered_facts.is_empty():
		return 0.0
	var total = remembered_facts.size()
	var remembered = remembered_facts.values().count(true)
	return float(remembered) / float(total)

func get_forgotten_facts() -> Array[String]:
	"""Get list of all forgotten facts"""
	return failed_memories.duplicate()

func get_remembered_facts() -> Array[String]:
	"""Get list of all remembered facts"""
	return unlocked_memories.duplicate()

func get_remembered_count() -> int:
	"""Get count of remembered facts"""
	return unlocked_memories.size()

func get_forgotten_count() -> int:
	"""Get count of forgotten facts"""
	return failed_memories.size()

# ═══════════════════════════════════════════════════════════════════
# STORY FLAGS
# ═══════════════════════════════════════════════════════════════════

func set_flag(flag_name: String, value: Variant) -> void:
	"""Set a story flag (can be bool, int, string, etc.)"""
	story_flags[flag_name] = value
	story_flag_changed.emit(flag_name, value)
	print("🚩 Flag set:", flag_name, "=", value)

func get_flag(flag_name: String, default_value: Variant = null) -> Variant:
	"""Get a story flag value"""
	return story_flags.get(flag_name, default_value)

func has_flag(flag_name: String) -> bool:
	"""Check if a flag exists"""
	return flag_name in story_flags

func clear_flag(flag_name: String) -> void:
	"""Remove a story flag"""
	if flag_name in story_flags:
		story_flags.erase(flag_name)

# ═══════════════════════════════════════════════════════════════════
# CHAPTER MANAGEMENT
# ═══════════════════════════════════════════════════════════════════

func set_chapter(chapter_num: int) -> void:
	"""Set current chapter"""
	current_chapter = chapter_num
	print("📖 Chapter:", chapter_num)

func complete_chapter(chapter_num: int, completion_data: Dictionary = {}) -> void:
	"""Mark a chapter as completed with optional data"""
	chapter_completion[chapter_num] = completion_data
	print("✓ Chapter", chapter_num, "completed")

func is_chapter_completed(chapter_num: int) -> bool:
	"""Check if a chapter was completed"""
	return chapter_num in chapter_completion

func get_chapter_data(chapter_num: int) -> Dictionary:
	"""Get completion data for a chapter"""
	return chapter_completion.get(chapter_num, {})

# ═══════════════════════════════════════════════════════════════════
# ENDING MANAGEMENT
# ═══════════════════════════════════════════════════════════════════

func unlock_ending(ending_id: String) -> void:
	"""Unlock an ending as available"""
	if ending_id not in available_endings:
		available_endings.append(ending_id)
		ending_unlocked.emit(ending_id)
		print("🎬 Ending unlocked:", ending_id)

func set_achieved_ending(ending_id: String) -> void:
	"""Set the ending the player achieved"""
	achieved_ending = ending_id
	print("🏆 Ending achieved:", ending_id)

func get_achieved_ending() -> String:
	"""Get the ending the player achieved"""
	return achieved_ending

# ═══════════════════════════════════════════════════════════════════
# BRANCHING LOGIC
# ═══════════════════════════════════════════════════════════════════

func determine_scene_path(base_path: String, branch_rules: Dictionary) -> String:
	"""
	Determine which scene to load based on story state
	
	Example usage:
	var next_scene = NarrativeProgression.determine_scene_path(
		"res://scenes/Chapter3/default.tscn",
		{
			"forgot_hospital": "res://scenes/Chapter3/hospital_forgotten.tscn",
			"forgot_accident": "res://scenes/Chapter3/accident_forgotten.tscn",
			"all_remembered": "res://scenes/Chapter3/true_path.tscn"
		}
	)
	"""
	
	# Check custom conditions
	for condition in branch_rules:
		if evaluate_condition(condition):
			return branch_rules[condition]
	
	# Return default
	return base_path

func evaluate_condition(condition: String) -> bool:
	"""Evaluate a branching condition"""
	match condition:
		"forgot_hospital":
			return is_forgotten("HOSPITAL")
		"forgot_accident":
			return is_forgotten("ACCIDENT")
		"forgot_coma":
			return is_forgotten("COMA")
		"all_remembered":
			return failed_memories.is_empty() and unlocked_memories.size() >= 3
		"incomplete_memory":
			return not failed_memories.is_empty()
		_:
			# Check if it's a flag
			return get_flag(condition, false)

func get_narrative_summary() -> Dictionary:
	"""Get a summary of the entire narrative state"""
	return {
		"chapter": current_chapter,
		"remembered": unlocked_memories,
		"forgotten": failed_memories,
		"memory_completion": get_memory_completion(),
		"flags": story_flags.duplicate(),
		"ending": achieved_ending,
		"available_endings": available_endings.duplicate()
	}

# ═══════════════════════════════════════════════════════════════════
# SAVE/LOAD
# ═══════════════════════════════════════════════════════════════════

func get_save_data() -> Dictionary:
	"""Get all data needed for saving"""
	return {
		"remembered_facts": remembered_facts,
		"failed_memories": failed_memories,
		"unlocked_memories": unlocked_memories,
		"story_flags": story_flags,
		"current_chapter": current_chapter,
		"chapter_completion": chapter_completion,
		"available_endings": available_endings,
		"achieved_ending": achieved_ending
	}

func load_save_data(data: Dictionary) -> void:
	"""Restore from save data"""
	remembered_facts = data.get("remembered_facts", {})
	failed_memories = data.get("failed_memories", [])
	unlocked_memories = data.get("unlocked_memories", [])
	story_flags = data.get("story_flags", {})
	current_chapter = data.get("current_chapter", 1)
	chapter_completion = data.get("chapter_completion", {})
	available_endings = data.get("available_endings", [])
	achieved_ending = data.get("achieved_ending", "")
	print("📂 Narrative state loaded")

func reset_all() -> void:
	"""Reset all narrative progress (new game)"""
	remembered_facts.clear()
	failed_memories.clear()
	unlocked_memories.clear()
	story_flags.clear()
	current_chapter = 1
	chapter_completion.clear()
	available_endings.clear()
	achieved_ending = ""
	print("🔄 Narrative progression reset")

func reset_memories_only() -> void:
	"""Reset only memory tracking (useful for replaying a chapter)"""
	remembered_facts.clear()
	failed_memories.clear()
	unlocked_memories.clear()
	print("🔄 Memory state reset")

# ═══════════════════════════════════════════════════════════════════
# DEBUG HELPERS
# ═══════════════════════════════════════════════════════════════════

func print_status() -> void:
	"""Print current narrative state (for debugging)"""
	print("NARRATIVE PROGRESSION STATUS")
	print("Chapter:", current_chapter)
	print("Remembered:", unlocked_memories)
	print("Forgotten:", failed_memories)
	print("Memory completion:", "%.0f%%" % (get_memory_completion() * 100))
	print("Active flags:", story_flags)
	print("Achieved ending:", achieved_ending if achieved_ending else "None")
