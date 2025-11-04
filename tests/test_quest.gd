extends GutTest

# Path to the QuestManager script
const QUEST_MANAGER_PATH := "res://scenes/quest/script/QuestManager.gd"

var quest_manager: Node

# -----------------------------------------------------
# Setup and teardown
# -----------------------------------------------------

func before_each():
	# Create a new instance before every test
	quest_manager = load(QUEST_MANAGER_PATH).new()
	add_child_autofree(quest_manager)
	await get_tree().process_frame

func after_each():
	# Clean up the test database after each test
	if quest_manager and quest_manager.db:
		quest_manager.db.query("DELETE FROM quests;")
		quest_manager.db.query("DELETE FROM quest_objectives;")
		quest_manager.db.close()

# -----------------------------------------------------
# TEST 1: Quest creation
# -----------------------------------------------------

func test_create_quest():
	var objectives = [
		{"id": "obj1", "text": "Find the book", "is_completed": false},
		{"id": "obj2", "text": "Return to NPC", "is_completed": false}
	]

	var signal_emitted := false
	quest_manager.connect("quest_updated", func(id): signal_emitted = true)

	quest_manager.create_quest("quest_1", "Book Hunt", "Find the ancient tome", objectives)

	#assert_true(signal_emitted, "quest_updated signal should emit after quest creation")
	assert_true("quest_1" in quest_manager.active_quests, "Quest should be stored in active_quests")

	var q = quest_manager.active_quests["quest_1"]
	assert_eq(q["title"], "Book Hunt", "Quest title should match")
	assert_eq(q["objectives"].size(), 2, "Quest should have 2 objectives")

# -----------------------------------------------------
# TEST 2: Completing an objective
# -----------------------------------------------------

func test_complete_objective_marks_done():
	var objectives = [
		{"id": "obj1", "text": "Collect key", "is_completed": false},
		{"id": "obj2", "text": "Unlock door", "is_completed": false}
	]

	quest_manager.create_quest("quest_2", "Key Quest", "Unlock the secret door", objectives)
	quest_manager.complete_objective("quest_2", "obj1")

	assert_true(
		quest_manager.is_objective_completed("quest_2", "obj1"),
		"Objective obj1 should be marked completed"
	)
	assert_false(
		quest_manager.is_objective_completed("quest_2", "obj2"),
		"Objective obj2 should still be incomplete"
	)

# -----------------------------------------------------
# TEST 3: Save and load quests
# -----------------------------------------------------

func test_save_and_load_quests():
	var objectives = [
		{"id": "obj1", "text": "Talk to villager", "is_completed": true}
	]

	quest_manager.create_quest("quest_3", "Village Talk", "Speak with the elder", objectives)
	quest_manager.save_all_quests()

	# Create a new instance to test loading from DB
	var qm2 = load(QUEST_MANAGER_PATH).new()
	add_child_autofree(qm2)
	await get_tree().process_frame
	qm2.load_all_quests()

	assert_true("quest_3" in qm2.active_quests, "Quest should load from database")
	var q = qm2.active_quests["quest_3"]
	assert_eq(q["description"], "Speak with the elder", "Quest description should match after loading")
	assert_true(q["objectives"][0]["is_completed"], "Objective should remain completed after load")

# -----------------------------------------------------
# TEST 4: Importing quests from JSON
# -----------------------------------------------------

func test_import_quests_from_json():
	var json_path := "user://test_quests.json"
	var data := [
		{
			"id": "quest_json",
			"title": "JSON Quest",
			"description": "Loaded from JSON",
			"is_completed": false,
			"objectives": [
				{"id": "obj1", "text": "Step 1", "is_completed": false}
			]
		}
	]

	var file := FileAccess.open(json_path, FileAccess.WRITE)
	file.store_string(JSON.stringify(data))
	file.close()

	quest_manager.import_quests_from_json(json_path)

	assert_true("quest_json" in quest_manager.active_quests, "Quest from JSON should be loaded")
	var q = quest_manager.active_quests["quest_json"]
	assert_eq(q["title"], "JSON Quest", "Loaded quest title should match")
	assert_eq(q["objectives"].size(), 1, "Loaded quest should have one objective")
