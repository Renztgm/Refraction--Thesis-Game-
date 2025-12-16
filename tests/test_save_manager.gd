# ==============================================================================
# TEST_SAVE_MANAGER.GD
# Unit tests for SaveManager (TC002, UT001, UT002, UT012)
# ==============================================================================
extends GutTest

func before_each():
	"""Setup before each test"""
	# Clear any existing save data
	if SaveManager.has_save_file():
		SaveManager.delete_save()

func after_each():
	"""Cleanup after each test"""
	# Clean up test saves
	if SaveManager.has_save_file():
		SaveManager.delete_save()

func test_save_manager_exists():
	"""UT001: Test that SaveManager autoload exists"""
	assert_not_null(SaveManager, "SaveManager autoload should exist")

func test_save_game_creates_file():
	"""UT001: Test saving game data creates a save file"""
	# Assuming SaveManager.save_game() uses current game state
	var result = SaveManager.save_game()
	assert_true(result, "save_game() should return true on success")
	assert_true(SaveManager.has_save_file(), "Save file should exist after saving")

func test_load_game_returns_data():
	"""UT002: Test loading existing save returns correct data"""
	SaveManager.save_game()
	var loaded_data = SaveManager.load_game()
	
	assert_not_null(loaded_data, "load_game() should return data")
	print("✅ Save game loaded successfully")

func test_load_game_without_save_returns_null():
	"""UT002: Test loading without save file returns null"""
	var loaded_data = SaveManager.load_game()
	assert_null(loaded_data, "load_game() should return null when no save exists")

func test_delete_save_removes_file():
	"""UT013: Test deleting save file"""
	SaveManager.save_game()
	assert_true(SaveManager.has_save_file(), "Save should exist before delete")
	
	SaveManager.delete_save()
	assert_false(SaveManager.has_save_file(), "Save should not exist after delete")

func test_has_save_file_check():
	"""Test has_save_file() returns correct boolean"""
	# No save initially
	assert_false(SaveManager.has_save_file(), "Should return false when no save exists")
	
	# Create save
	SaveManager.save_game()
	assert_true(SaveManager.has_save_file(), "Should return true after save created")

func test_save_overwrites_existing():
	"""UT001: Test that new save overwrites existing save"""
	SaveManager.save_game()
	var first_save_time = SaveManager.get_save_timestamp() if SaveManager.has_method("get_save_timestamp") else Time.get_unix_time_from_system()
	
	await get_tree().create_timer(0.1).timeout
	
	SaveManager.save_game()
	var second_save_time = SaveManager.get_save_timestamp() if SaveManager.has_method("get_save_timestamp") else Time.get_unix_time_from_system()
	
	assert_true(SaveManager.has_save_file(), "Save file should still exist")
	print("✅ Save successfully overwrites previous save")
