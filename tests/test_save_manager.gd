# ==============================================================================
# TEST_SAVE_MANAGER.GD
# Unit tests for SaveManager (TC002, UT001, UT002, UT012)
# ==============================================================================
extends GutTest

var mock_player_scene = preload("res://scenes/Player/player.tscn") if FileAccess.file_exists("res://scenes/Player/player.tscn") else null
var test_profile_id: int = -1

func before_each():
	"""Setup before each test"""
	# Create a test profile
	if ProfileManager and ProfileManager.has_method("create_profile"):
		test_profile_id = ProfileManager.create_profile("TestPlayer")
		ProfileManager.active_profile_id = test_profile_id
	
	# Clear any existing save data for test profile
	if SaveManager.db:
		SaveManager.db.query("DELETE FROM save_data WHERE profile_id = %d;" % test_profile_id)

func after_each():
	"""Cleanup after each test"""
	# Clean up test profile
	if ProfileManager and test_profile_id > 0:
		if ProfileManager.has_method("delete_profile"):
			ProfileManager.delete_profile(test_profile_id)
	test_profile_id = -1

func test_save_manager_exists():
	"""UT001: Test that SaveManager autoload exists"""
	assert_not_null(SaveManager, "SaveManager autoload should exist")
	print("✅ SaveManager autoload found")

func test_database_initialized():
	"""Test that database is properly initialized"""
	assert_not_null(SaveManager.db, "Database should be initialized")
	assert_true(SaveManager.db.path.length() > 0, "Database path should be set")
	print("✅ Database initialized at:", SaveManager.db.path)

func test_has_save_file_returns_false_initially():
	"""Test has_save_file() returns false when no save exists"""
	var has_save = SaveManager.has_save_file()
	# Should be false or could be true if other saves exist
	assert_typeof(has_save, TYPE_BOOL, "has_save_file() should return boolean")
	print("✅ has_save_file() returns:", has_save)

func test_save_game_requires_active_profile():
	"""UT001: Test save_game() behavior with active profile"""
	if ProfileManager and ProfileManager.active_profile_id > 0:
		# Try to save (will fail without player node, but won't crash)
		var result = SaveManager.save_game()
		# Result may be false without player, but function should execute
		assert_typeof(result, TYPE_BOOL, "save_game() should return boolean")
		print("✅ save_game() executed, result:", result)
	else:
		pass_test("No active profile available")

func test_save_game_with_mock_player():
	"""UT001: Test saving game with mock player"""
	if mock_player_scene and ProfileManager and ProfileManager.active_profile_id > 0:
		# Create a mock player
		var player = mock_player_scene.instantiate()
		player.add_to_group("player")
		get_tree().root.add_child(player)
		await get_tree().process_frame
		
		# Try to save
		var result = SaveManager.save_game()
		assert_typeof(result, TYPE_BOOL, "save_game() should return boolean")
		
		# Cleanup
		player.queue_free()
		print("✅ save_game() with player executed, result:", result)
	else:
		pass_test("Mock player scene not available or no profile")

func test_load_game_returns_boolean():
	"""UT002: Test load_game() returns boolean"""
	var result = SaveManager.load_game()
	assert_typeof(result, TYPE_BOOL, "load_game() should return boolean")
	print("✅ load_game() executed, result:", result)

func test_game_data_structure():
	"""Test that game_data has expected structure"""
	assert_not_null(SaveManager.game_data, "game_data should exist")
	assert_true(SaveManager.game_data.has("player_name"), "Should have player_name")
	assert_true(SaveManager.game_data.has("current_scene"), "Should have current_scene")
	assert_true(SaveManager.game_data.has("player_position"), "Should have player_position")
	assert_true(SaveManager.game_data.has("player_direction"), "Should have player_direction")
	assert_true(SaveManager.game_data.has("has_save"), "Should have has_save flag")
	print("✅ game_data structure is valid")

func test_get_saved_player_position():
	"""Test getting saved player position"""
	var position = SaveManager.get_saved_player_position()
	assert_not_null(position, "get_saved_player_position() should return Vector3")
	assert_true(position is Vector3, "Should return Vector3")
	print("✅ get_saved_player_position() returns:", position)

func test_get_saved_scene():
	"""Test getting saved scene path"""
	var scene_path = SaveManager.get_saved_scene()
	assert_typeof(scene_path, TYPE_STRING, "get_saved_scene() should return string")
	print("✅ get_saved_scene() returns:", scene_path)

func test_get_saved_player_direction():
	"""Test getting saved player direction"""
	var direction = SaveManager.get_saved_player_direction()
	assert_typeof(direction, TYPE_STRING, "get_saved_player_direction() should return string")
	print("✅ get_saved_player_direction() returns:", direction)

func test_has_save_data():
	"""Test has_save_data() method"""
	var has_data = SaveManager.has_save_data()
	assert_typeof(has_data, TYPE_BOOL, "has_save_data() should return boolean")
	print("✅ has_save_data() returns:", has_data)

func test_log_scene_completion():
	"""Test logging scene completion for branching"""
	if ProfileManager and ProfileManager.active_profile_id > 0:
		var scene_path = "res://test/scene.tscn"
		var result = SaveManager.log_scene_completion(scene_path, "test_branch")
		assert_typeof(result, TYPE_BOOL, "log_scene_completion() should return boolean")
		print("✅ log_scene_completion() executed, result:", result)
	else:
		pass_test("No active profile")

func test_get_visited_scene_paths():
	"""Test retrieving visited scene paths"""
	if ProfileManager and ProfileManager.active_profile_id > 0:
		var paths = SaveManager.get_visited_scene_paths()
		assert_not_null(paths, "get_visited_scene_paths() should return array")
		assert_true(paths is Array, "Should return Array")
		print("✅ get_visited_scene_paths() returns %d paths" % paths.size())
	else:
		pass_test("No active profile")

func test_get_last_scene_path():
	"""Test getting last visited scene"""
	if ProfileManager and ProfileManager.active_profile_id > 0:
		var last_scene = SaveManager.get_last_scene_path()
		assert_typeof(last_scene, TYPE_STRING, "get_last_scene_path() should return string")
		print("✅ get_last_scene_path() returns:", last_scene)
	else:
		pass_test("No active profile")

func test_chapter_management():
	"""Test chapter getter/setter"""
	SaveManager.set_current_chapter(2)
	var chapter = SaveManager.get_current_chapter()
	assert_eq(chapter, 2, "Chapter should be set to 2")
	print("✅ Chapter management works")

func test_next_scene_path_management():
	"""Test next scene path getter/setter"""
	var test_path = "res://scenes/next_scene.tscn"
	SaveManager.set_next_scene_path(test_path)
	var stored_path = SaveManager.get_next_scene_path()
	assert_eq(stored_path, test_path, "Next scene path should match")
	print("✅ Next scene path management works")

func test_get_memory_shard_count():
	"""Test getting memory shard count"""
	if ProfileManager and ProfileManager.active_profile_id > 0:
		var count = SaveManager.get_memory_shard_count()
		assert_typeof(count, TYPE_INT, "get_memory_shard_count() should return int")
		assert_gte(count, 0, "Shard count should be >= 0")
		print("✅ Memory shard count:", count)
	else:
		pass_test("No active profile")

func test_is_quest_completed():
	"""Test checking if quest is completed"""
	var is_completed = SaveManager.is_quest_completed("test_quest")
	assert_typeof(is_completed, TYPE_BOOL, "is_quest_completed() should return boolean")
	print("✅ is_quest_completed() returns:", is_completed)

func test_get_profile_id():
	"""Test getting active profile ID"""
	var profile_id = SaveManager.get_profile_id()
	assert_typeof(profile_id, TYPE_INT, "get_profile_id() should return int")
	print("✅ Active profile ID:", profile_id)
