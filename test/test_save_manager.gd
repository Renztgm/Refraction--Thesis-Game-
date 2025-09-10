extends RefCounted
class_name TestSaveManager

var save_manager: Node
var test_db_path: String = "user://test_game_data.db"

func setup():
	print("Setting up TestSaveManager...")
	save_manager = preload("res://script/SaveManager.gd").new()
	save_manager.init_with_db_path(test_db_path)

func teardown():
	print("Tearing down TestSaveManager...")
	if save_manager:
		save_manager.queue_free()
	
	var dir = DirAccess.open("user://")
	if dir and dir.file_exists("test_game_data.db"):
		var result = dir.remove("test_game_data.db")
		if result != OK:
			print("Warning: Failed to remove test database file")

func test_save_and_load_game() -> bool:
	print("Running test_save_and_load_game...")
	
	# Mock game state
	save_manager.game_data["player_name"] = "Tester"
	save_manager.game_data["current_scene"] = "res://scenes/NarativeScenes/Scene1.tscn"
	save_manager.game_data["player_position"] = {"x": 1, "y": 2, "z": 3}
	save_manager.game_data["player_direction"] = "North"
	save_manager.game_data["has_save"] = true
	
	# Save game
	var save_ok = save_manager.save_game()
	if not save_ok:
		print("FAIL: save_game() returned false")
		return false
	
	# Verify file was created
	var dir = DirAccess.open("user://")
	if not dir or not dir.file_exists("test_game_data.db"):
		print("FAIL: Database file was not created")
		return false
	
	# Reset in-memory data
	save_manager.game_data["player_name"] = ""
	save_manager.game_data["current_scene"] = ""
	save_manager.game_data["player_position"] = {"x": 0, "y": 0, "z": 0}
	save_manager.game_data["player_direction"] = ""
	save_manager.game_data["has_save"] = false
	
	# Load game
	var load_ok = save_manager.load_game()
	if not load_ok:
		print("FAIL: load_game() returned false")
		return false
	
	# Check each assertion individually
	if save_manager.game_data["player_name"] != "Tester":
		print("FAIL: player_name mismatch")
		return false
	
	if save_manager.game_data["current_scene"] != "res://scenes/NarativeScenes/Scene1.tscn":
		print("FAIL: current_scene mismatch")
		return false
	
	if save_manager.game_data["player_position"]["x"] != 1:
		print("FAIL: player_position.x mismatch")
		return false
	
	if save_manager.game_data["player_position"]["y"] != 2:
		print("FAIL: player_position.y mismatch")
		return false
	
	if save_manager.game_data["player_position"]["z"] != 3:
		print("FAIL: player_position.z mismatch")
		return false
	
	if save_manager.game_data["player_direction"] != "North":
		print("FAIL: player_direction mismatch")
		return false
	
	if save_manager.game_data["has_save"] != true:
		print("FAIL: has_save mismatch")
		return false
	
	print("PASS: test_save_and_load_game")
	return true

func test_save_without_init() -> bool:
	print("Running test_save_without_init...")
	
	# Test saving without proper initialization
	var uninit_manager = preload("res://script/SaveManager.gd").new()
	var result = uninit_manager.save_game()
	
	if result:
		print("FAIL: save_game() should fail without initialization")
		return false
	
	print("PASS: test_save_without_init")
	return true

func test_load_nonexistent_save() -> bool:
	print("Running test_load_nonexistent_save...")
	
	# Ensure no save file exists
	var dir = DirAccess.open("user://")
	if dir and dir.file_exists("test_game_data.db"):
		dir.remove("test_game_data.db")
	
	var result = save_manager.load_game()
	
	if result:
		print("FAIL: load_game() should fail when no save file exists")
		return false
	
	print("PASS: test_load_nonexistent_save")
	return true

func run_all_tests() -> bool:
	print("=" + "=".repeat(49))
	print("Starting SaveManager Tests")
	print("=" + "=".repeat(49))
	
	var test_methods = [
		"test_save_and_load_game",
		"test_save_without_init",
		"test_load_nonexistent_save"
	]
	
	var passed = 0
	var total = test_methods.size()
	
	for test_method_name in test_methods:
		setup()
		var result = call(test_method_name)
		teardown()
		
		if result:
			passed += 1
		
		print("-" + "-".repeat(29))
	
	print("=" + "=".repeat(49))
	print("Test Results: %d/%d passed" % [passed, total])
	print("=" + "=".repeat(49))
	
	return passed == total
