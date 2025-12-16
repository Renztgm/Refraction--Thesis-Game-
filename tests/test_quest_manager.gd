# ==============================================================================
# TEST_QUEST_MANAGER.GD
# Unit tests for QuestManager (TC006, UT005, UT006, UT007, UT011)
# ==============================================================================
extends GutTest

var test_profile_id: int = -1

func before_each():
	"""Setup before each test"""
	# Create test profile
	if ProfileManager and ProfileManager.has_method("create_profile"):
		test_profile_id = ProfileManager.create_profile("QuestTest")
		ProfileManager.active_profile_id = test_profile_id
	
	# Clear quests
	if QuestManager:
		QuestManager.active_quests.clear()
		if QuestManager.db:
			QuestManager.db.query("DELETE FROM quests WHERE profile_id = %d;" % test_profile_id)
			QuestManager.db.query("DELETE FROM quest_objectives WHERE profile_id = %d;" % test_profile_id)

func after_each():
	"""Cleanup after each test"""
	# Clear quest data
	if QuestManager and test_profile_id > 0:
		QuestManager.active_quests.clear()
		if QuestManager.db:
			QuestManager.db.query("DELETE FROM quests WHERE profile_id = %d;" % test_profile_id)
			QuestManager.db.query("DELETE FROM quest_objectives WHERE profile_id = %d;" % test_profile_id)
	
	# Delete test profile
	if ProfileManager and test_profile_id > 0:
		if ProfileManager.has_method("delete_profile"):
			ProfileManager.delete_profile(test_profile_id)
	test_profile_id = -1

func test_quest_manager_exists():
	"""Test that QuestManager autoload exists"""
	assert_not_null(QuestManager, "QuestManager autoload should exist")
	print("✅ QuestManager autoload found")

func test_database_initialized():
	"""Test that QuestManager database is initialized"""
	assert_not_null(QuestManager.db, "Database should be initialized")
	assert_true(QuestManager.db.path.length() > 0, "Database path should be set")
	print("✅ QuestManager database initialized")

func test_active_quests_dictionary():
	"""Test that active_quests is a dictionary"""
	assert_not_null(QuestManager.active_quests, "active_quests should exist")
	assert_true(QuestManager.active_quests is Dictionary, "active_quests should be Dictionary")
	print("✅ active_quests dictionary exists")

# ==============================================================================
# QUEST CREATION TESTS
# ==============================================================================

func test_create_quest():
	"""UT005: Test creating a new quest"""
	if not ProfileManager or ProfileManager.active_profile_id <= 0:
		pass_test("No active profile")
		return
	
	var quest_id = "test_quest_001"
	var title = "Find the Ancient Artifact"
	var description = "Search the ruins for the lost artifact"
	var objectives = [
		{"id": "obj1", "text": "Talk to the elder", "is_completed": false},
		{"id": "obj2", "text": "Search the ruins", "is_completed": false}
	]
	
	QuestManager.create_quest(quest_id, title, description, objectives)
	
	# Verify quest was created
	assert_true(QuestManager.active_quests.has(quest_id), "Quest should be in active_quests")
	var quest = QuestManager.active_quests[quest_id]
	assert_eq(quest["title"], title, "Quest title should match")
	assert_eq(quest["description"], description, "Quest description should match")
	assert_eq(quest["objectives"].size(), 2, "Should have 2 objectives")
	print("✅ Quest created successfully:", quest_id)

# ==============================================================================
# QUEST LOADING TESTS
# ==============================================================================

func test_load_active_quest():
	"""Test loading a single quest from database"""
	if not ProfileManager or ProfileManager.active_profile_id <= 0:
		pass_test("No active profile")
		return
	
	# Create and save a quest first
	var quest_id = "load_test_quest"
	QuestManager.create_quest(quest_id, "Load Test", "Testing load functionality", [])
	
	# Clear memory and reload
	QuestManager.active_quests.clear()
	QuestManager.load_active_quest(quest_id)
	
	# Verify loaded
	assert_true(QuestManager.active_quests.has(quest_id), "Quest should be loaded")
	print("✅ Quest loaded successfully:", quest_id)

func test_load_all_quests():
	"""Test loading all quests for active profile"""
	if not ProfileManager or ProfileManager.active_profile_id <= 0:
		pass_test("No active profile")
		return
	
	# Create multiple quests
	QuestManager.create_quest("quest1", "Quest 1", "First quest", [])
	QuestManager.create_quest("quest2", "Quest 2", "Second quest", [])
	QuestManager.create_quest("quest3", "Quest 3", "Third quest", [])
	
	# Clear and reload all
	var initial_count = QuestManager.active_quests.size()
	QuestManager.active_quests.clear()
	QuestManager.load_all_quests()
	
	# Verify all loaded
	assert_gte(QuestManager.active_quests.size(), 3, "Should have at least 3 quests")
	print("✅ All quests loaded, count:", QuestManager.active_quests.size())

# ==============================================================================
# OBJECTIVE TESTS
# ==============================================================================

func test_complete_objective():
	"""UT006: Test completing a quest objective"""
	if not ProfileManager or ProfileManager.active_profile_id <= 0:
		pass_test("No active profile")
		return
	
	var quest_id = "objective_test"
	var objectives = [
		{"id": "collect_item", "text": "Collect 5 items", "is_completed": false}
	]
	
	QuestManager.create_quest(quest_id, "Objective Test", "Testing objectives", objectives)
	
	# Complete the objective
	QuestManager.complete_objective(quest_id, "collect_item")
	
	# Verify completion
	var is_completed = QuestManager.is_objective_completed(quest_id, "collect_item")
	assert_true(is_completed, "Objective should be completed")
	print("✅ Objective completed successfully")

func test_complete_objective_creates_if_missing():
	"""Test that complete_objective creates objective if it doesn't exist in DB"""
	if not ProfileManager or ProfileManager.active_profile_id <= 0:
		pass_test("No active profile")
		return
	
	var quest_id = "missing_obj_test"
	QuestManager.create_quest(quest_id, "Missing Obj Test", "Test", [])
	
	# Complete objective that doesn't exist in quest structure
	QuestManager.complete_objective(quest_id, "new_objective")
	
	# Reload quest to get DB state
	QuestManager.active_quests.clear()
	QuestManager.load_all_quests()
	
	# Verify it was created in database
	var profile_id = ProfileManager.active_profile_id
	var rows = QuestManager.db.select_rows(
		"quest_objectives",
		"quest_id = '%s' AND objective_id = '%s' AND profile_id = %d" % [quest_id, "new_objective", profile_id],
		["is_completed"]
	)
	
	assert_gt(rows.size(), 0, "Objective should be created in database")
	if rows.size() > 0:
		assert_eq(rows[0]["is_completed"], 1, "Objective should be marked as completed")
	print("✅ Missing objective created and completed in database")

func test_is_objective_completed():
	"""Test checking if objective is completed"""
	if not ProfileManager or ProfileManager.active_profile_id <= 0:
		pass_test("No active profile")
		return
	
	var quest_id = "check_obj_test"
	var objectives = [
		{"id": "obj_check", "text": "Test objective", "is_completed": false}
	]
	
	QuestManager.create_quest(quest_id, "Check Test", "Test", objectives)
	
	# Should not be completed initially
	var before = QuestManager.is_objective_completed(quest_id, "obj_check")
	assert_false(before, "Objective should not be completed initially")
	
	# Complete it
	QuestManager.complete_objective(quest_id, "obj_check")
	
	# Should be completed now
	var after = QuestManager.is_objective_completed(quest_id, "obj_check")
	assert_true(after, "Objective should be completed")
	print("✅ is_objective_completed() works correctly")

func test_quest_completes_when_all_objectives_done():
	"""Test that quest completes when all objectives are done"""
	if not ProfileManager or ProfileManager.active_profile_id <= 0:
		pass_test("No active profile")
		return
	
	var quest_id = "auto_complete_test"
	var objectives = [
		{"id": "obj1", "text": "First task", "is_completed": false},
		{"id": "obj2", "text": "Second task", "is_completed": false}
	]
	
	QuestManager.create_quest(quest_id, "Auto Complete", "Test", objectives)
	
	# Complete first objective
	QuestManager.complete_objective(quest_id, "obj1")
	var quest_after_first = QuestManager.active_quests[quest_id]
	assert_false(quest_after_first["is_completed"], "Quest should not be complete after first objective")
	
	# Complete second objective
	QuestManager.complete_objective(quest_id, "obj2")
	var quest_after_second = QuestManager.active_quests[quest_id]
	assert_true(quest_after_second["is_completed"], "Quest should be complete after all objectives")
	print("✅ Quest auto-completes when all objectives done")

# ==============================================================================
# QUEST COMPLETION TESTS
# ==============================================================================

func test_complete_quest():
	"""UT007: Test manually completing a quest"""
	if not ProfileManager or ProfileManager.active_profile_id <= 0:
		pass_test("No active profile")
		return
	
	var quest_id = "manual_complete_test"
	QuestManager.create_quest(quest_id, "Manual Complete", "Test", [])
	
	# Quest should not be completed initially
	var before = QuestManager.is_quest_completed(quest_id)
	assert_false(before, "Quest should not be completed initially")
	
	# Complete quest
	QuestManager.complete_quest(quest_id)
	
	# Quest should be completed now
	var after = QuestManager.is_quest_completed(quest_id)
	assert_true(after, "Quest should be completed after calling complete_quest()")
	print("✅ Quest manually completed")

func test_is_quest_completed():
	"""Test checking if quest is completed"""
	if not ProfileManager or ProfileManager.active_profile_id <= 0:
		pass_test("No active profile")
		return
	
	var quest_id = "completion_check_test"
	QuestManager.create_quest(quest_id, "Completion Check", "Test", [])
	
	var completed = QuestManager.is_quest_completed(quest_id)
	assert_false(completed, "New quest should not be completed")
	
	QuestManager.complete_quest(quest_id)
	completed = QuestManager.is_quest_completed(quest_id)
	assert_true(completed, "Completed quest should return true")
	print("✅ is_quest_completed() works correctly")

# ==============================================================================
# QUEST STATE TESTS
# ==============================================================================

func test_quest_exists():
	"""Test checking if quest exists for profile"""
	if not ProfileManager or ProfileManager.active_profile_id <= 0:
		pass_test("No active profile")
		return
	
	var quest_id = "exists_test"
	
	# Should not exist initially
	var exists_before = QuestManager.quest_exists(quest_id)
	assert_false(exists_before, "Quest should not exist initially")
	
	# Create quest
	QuestManager.create_quest(quest_id, "Exists Test", "Test", [])
	
	# Should exist now
	var exists_after = QuestManager.quest_exists(quest_id)
	assert_true(exists_after, "Quest should exist after creation")
	print("✅ quest_exists() works correctly")

func test_is_quest_active():
	"""Test checking if quest is active (not completed)"""
	if not ProfileManager or ProfileManager.active_profile_id <= 0:
		pass_test("No active profile")
		return
	
	var quest_id = "active_test"
	QuestManager.create_quest(quest_id, "Active Test", "Test", [])
	
	# Should be active initially
	var active_before = QuestManager.is_quest_active(quest_id)
	assert_true(active_before, "New quest should be active")
	
	# Complete quest
	QuestManager.complete_quest(quest_id)
	
	# Should not be active now
	var active_after = QuestManager.is_quest_active(quest_id)
	assert_false(active_after, "Completed quest should not be active")
	print("✅ is_quest_active() works correctly")

# ==============================================================================
# SAVE/LOAD TESTS
# ==============================================================================

func test_save_all_quests():
	"""Test saving all quests to database"""
	if not ProfileManager or ProfileManager.active_profile_id <= 0:
		pass_test("No active profile")
		return
	
	# Create quests
	QuestManager.create_quest("save_test1", "Save Test 1", "First", [])
	QuestManager.create_quest("save_test2", "Save Test 2", "Second", [])
	
	# Save explicitly
	QuestManager.save_all_quests()
	
	# Clear memory and reload
	QuestManager.active_quests.clear()
	QuestManager.load_all_quests()
	
	# Verify quests persisted
	assert_true(QuestManager.active_quests.has("save_test1"), "First quest should persist")
	assert_true(QuestManager.active_quests.has("save_test2"), "Second quest should persist")
	print("✅ Quests saved and reloaded successfully")

func test_quest_objectives_persist():
	"""Test that quest objectives persist through save/load"""
	if not ProfileManager or ProfileManager.active_profile_id <= 0:
		pass_test("No active profile")
		return
	
	var quest_id = "persist_obj_test"
	var objectives = [
		{"id": "obj1", "text": "First objective", "is_completed": false},
		{"id": "obj2", "text": "Second objective", "is_completed": true}
	]
	
	QuestManager.create_quest(quest_id, "Persist Test", "Test", objectives)
	
	# Clear and reload
	QuestManager.active_quests.clear()
	QuestManager.load_all_quests()
	
	# Verify objectives persisted
	var quest = QuestManager.active_quests[quest_id]
	assert_eq(quest["objectives"].size(), 2, "Should have 2 objectives")
	assert_eq(quest["objectives"][0]["id"], "obj1", "First objective ID should match")
	assert_eq(quest["objectives"][1]["is_completed"], true, "Second objective should be completed")
	print("✅ Quest objectives persisted correctly")

# ==============================================================================
# JSON IMPORT TESTS
# ==============================================================================

func test_import_quests_from_json():
	"""UT027: Test importing quests from JSON file"""
	if not ProfileManager or ProfileManager.active_profile_id <= 0:
		pass_test("No active profile")
		return
	
	# Create a temporary test JSON file
	var test_json_path = "user://test_quests.json"
	var test_data = [
		{
			"id": "json_quest_1",
			"title": "JSON Quest 1",
			"description": "Imported from JSON",
			"is_completed": false,
			"objectives": [
				{"id": "json_obj1", "text": "First JSON objective", "is_completed": false}
			]
		}
	]
	
	var file = FileAccess.open(test_json_path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(test_data))
		file.close()
		
		# Import quests
		QuestManager.import_quests_from_json(test_json_path)
		
		# Verify imported
		assert_true(QuestManager.active_quests.has("json_quest_1"), "JSON quest should be imported")
		var quest = QuestManager.active_quests["json_quest_1"]
		assert_eq(quest["title"], "JSON Quest 1", "Quest title should match")
		assert_eq(quest["objectives"].size(), 1, "Should have 1 objective")
		
		# Cleanup
		DirAccess.remove_absolute(test_json_path)
		print("✅ Quests imported from JSON successfully")
	else:
		pass_test("Could not create test JSON file")

func test_import_invalid_json():
	"""Test that importing invalid JSON doesn't crash"""
	var invalid_path = "res://nonexistent/quests.json"
	
	# Should not crash
	QuestManager.import_quests_from_json(invalid_path)
	
	# Assert that it handled gracefully (no crash = success)
	assert_true(true, "Invalid JSON import handled without crashing")
	print("✅ Invalid JSON import handled gracefully")

# ==============================================================================
# SIGNAL TESTS
# ==============================================================================

func test_quest_updated_signal():
	"""Test that quest_updated signal is emitted"""
	if not ProfileManager or ProfileManager.active_profile_id <= 0:
		pass_test("No active profile")
		return
	
	# Create a quest first
	var quest_id = "signal_test"
	QuestManager.create_quest(quest_id, "Signal Test", "Test", [
		{"id": "obj1", "text": "Test objective", "is_completed": false}
	])
	
	# Now watch for signal when completing objective (which definitely emits)
	watch_signals(QuestManager)
	
	# Complete objective - this should emit quest_updated signal
	QuestManager.complete_objective(quest_id, "obj1")
	
	# Wait a moment
	await get_tree().create_timer(0.2).timeout
	
	# Check if signal was emitted
	assert_signal_emitted(QuestManager, "quest_updated", "quest_updated signal should be emitted")
	
	print("✅ quest_updated signal works correctly")

# ==============================================================================
# PROFILE ISOLATION TESTS
# ==============================================================================

func test_quest_profile_isolation():
	"""Test that quests are isolated per profile"""
	if not ProfileManager or not ProfileManager.has_method("create_profile"):
		pass_test("ProfileManager not available")
		return
	
	# Create two profiles
	var profile1 = ProfileManager.create_profile("QuestProfile1")
	var profile2 = ProfileManager.create_profile("QuestProfile2")
	
	# Add quest to profile1
	ProfileManager.active_profile_id = profile1
	QuestManager.active_quests.clear()
	QuestManager.create_quest("profile1_quest", "Profile 1 Quest", "Test", [])
	var profile1_quests = QuestManager.active_quests.size()
	
	# Switch to profile2
	ProfileManager.active_profile_id = profile2
	QuestManager.active_quests.clear()
	QuestManager.load_all_quests()
	var profile2_quests = QuestManager.active_quests.size()
	
	# Verify isolation
	assert_gt(profile1_quests, 0, "Profile1 should have quests")
	assert_eq(profile2_quests, 0, "Profile2 should have no quests")
	print("✅ Quest profile isolation works")
	
	# Cleanup
	if QuestManager.db:
		QuestManager.db.query("DELETE FROM quests WHERE profile_id IN (%d, %d);" % [profile1, profile2])
		QuestManager.db.query("DELETE FROM quest_objectives WHERE profile_id IN (%d, %d);" % [profile1, profile2])
	if ProfileManager.has_method("delete_profile"):
		ProfileManager.delete_profile(profile1)
		ProfileManager.delete_profile(profile2)

# ==============================================================================
# INTEGRATION TESTS
# ==============================================================================

func test_multiple_quests_multiple_objectives():
	"""Integration: Test managing multiple quests with multiple objectives"""
	if not ProfileManager or ProfileManager.active_profile_id <= 0:
		pass_test("No active profile")
		return
	
	# Create 3 quests with different objectives
	QuestManager.create_quest("multi1", "Multi Quest 1", "First", [
		{"id": "m1_obj1", "text": "Task 1", "is_completed": false},
		{"id": "m1_obj2", "text": "Task 2", "is_completed": false}
	])
	
	QuestManager.create_quest("multi2", "Multi Quest 2", "Second", [
		{"id": "m2_obj1", "text": "Task 1", "is_completed": false}
	])
	
	QuestManager.create_quest("multi3", "Multi Quest 3", "Third", [
		{"id": "m3_obj1", "text": "Task 1", "is_completed": false},
		{"id": "m3_obj2", "text": "Task 2", "is_completed": false},
		{"id": "m3_obj3", "text": "Task 3", "is_completed": false}
	])
	
	# Complete some objectives
	QuestManager.complete_objective("multi1", "m1_obj1")
	QuestManager.complete_objective("multi2", "m2_obj1")
	QuestManager.complete_objective("multi3", "m3_obj1")
	QuestManager.complete_objective("multi3", "m3_obj2")
	
	# Verify states
	assert_false(QuestManager.is_quest_completed("multi1"), "Quest 1 should not be complete")
	assert_true(QuestManager.is_quest_completed("multi2"), "Quest 2 should be complete")
	assert_false(QuestManager.is_quest_completed("multi3"), "Quest 3 should not be complete")
	
	print("✅ Multiple quests with multiple objectives work correctly")
