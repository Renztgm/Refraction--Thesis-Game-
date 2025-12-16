# ==============================================================================
# TEST_INVENTORY_MANAGER.GD
# Unit tests for InventoryManager (TC005, UT003, UT004, UT010)
# ==============================================================================
extends GutTest

var test_profile_id: int = -1

func before_each():
	"""Setup before each test"""
	# Create test profile
	if ProfileManager and ProfileManager.has_method("create_profile"):
		test_profile_id = ProfileManager.create_profile("InventoryTest")
		ProfileManager.active_profile_id = test_profile_id
	
	# Clear inventory for test profile
	if InventoryManager and InventoryManager.has_method("clear_profile_data"):
		InventoryManager.clear_profile_data(test_profile_id)

func after_each():
	"""Cleanup after each test"""
	# Clean up test data
	if InventoryManager and test_profile_id > 0:
		InventoryManager.clear_profile_data(test_profile_id)
	
	# Delete test profile
	if ProfileManager and test_profile_id > 0:
		if ProfileManager.has_method("delete_profile"):
			ProfileManager.delete_profile(test_profile_id)
	test_profile_id = -1

func test_inventory_manager_exists():
	"""Test that InventoryManager autoload exists"""
	assert_not_null(InventoryManager, "InventoryManager autoload should exist")
	print("✅ InventoryManager autoload found")

func test_database_initialized():
	"""Test that InventoryManager database is initialized"""
	assert_not_null(InventoryManager.db, "Database should be initialized")
	assert_true(InventoryManager.db.path.length() > 0, "Database path should be set")
	print("✅ InventoryManager database initialized")

func test_slot_count_defined():
	"""Test that slot_count is properly defined"""
	assert_typeof(InventoryManager.slot_count, TYPE_INT, "slot_count should be integer")
	assert_eq(InventoryManager.slot_count, 20, "slot_count should be 20")
	print("✅ Inventory slot count:", InventoryManager.slot_count)

# ==============================================================================
# MEMORY SHARD TESTS
# ==============================================================================

func test_save_memory_shard():
	"""TC005: Test saving a memory shard"""
	if not ProfileManager or ProfileManager.active_profile_id <= 0:
		pass_test("No active profile")
		return
	
	var shard_name = "test_red_shard"
	var description = "A crimson memory from the past"
	var icon_path = "res://assets/shards/red.png"
	var scene_location = "res://scenes/chapter1/scene1.tscn"
	
	var result = InventoryManager.save_memory_shard(shard_name, description, icon_path, scene_location)
	assert_true(result, "save_memory_shard() should return true")
	print("✅ Memory shard saved successfully")

func test_save_duplicate_memory_shard_fails():
	"""Test that saving duplicate shard returns false"""
	if not ProfileManager or ProfileManager.active_profile_id <= 0:
		pass_test("No active profile")
		return
	
	var shard_name = "duplicate_shard"
	var description = "Test shard"
	var icon_path = "res://test.png"
	var scene_location = "res://test.tscn"
	
	# Save first time
	var first_save = InventoryManager.save_memory_shard(shard_name, description, icon_path, scene_location)
	assert_true(first_save, "First save should succeed")
	
	# Try to save again
	var second_save = InventoryManager.save_memory_shard(shard_name, description, icon_path, scene_location)
	assert_false(second_save, "Duplicate save should return false")
	print("✅ Duplicate shard prevention works")

func test_get_all_memory_shards():
	"""Test retrieving all memory shards"""
	if not ProfileManager or ProfileManager.active_profile_id <= 0:
		pass_test("No active profile")
		return
	
	# Save multiple shards
	InventoryManager.save_memory_shard("shard1", "First", "icon1.png", "scene1.tscn")
	InventoryManager.save_memory_shard("shard2", "Second", "icon2.png", "scene2.tscn")
	InventoryManager.save_memory_shard("shard3", "Third", "icon3.png", "scene3.tscn")
	
	var shards = InventoryManager.get_all_memory_shards()
	assert_not_null(shards, "get_all_memory_shards() should return array")
	assert_true(shards is Array, "Should return Array type")
	assert_eq(shards.size(), 3, "Should have 3 shards")
	print("✅ Retrieved all memory shards, count:", shards.size())

func test_get_memory_shard():
	"""Test retrieving a specific memory shard"""
	if not ProfileManager or ProfileManager.active_profile_id <= 0:
		pass_test("No active profile")
		return
	
	var shard_name = "specific_shard"
	InventoryManager.save_memory_shard(shard_name, "Test", "icon.png", "scene.tscn")
	
	var shard = InventoryManager.get_memory_shard(shard_name)
	assert_not_null(shard, "get_memory_shard() should return dictionary")
	assert_true(shard is Dictionary, "Should return Dictionary")
	assert_eq(shard.get("shard_name", ""), shard_name, "Shard name should match")
	print("✅ Retrieved specific memory shard:", shard_name)

func test_has_memory_shard():
	"""Test checking if memory shard exists"""
	if not ProfileManager or ProfileManager.active_profile_id <= 0:
		pass_test("No active profile")
		return
	
	var shard_name = "check_shard"
	
	# Should not exist initially
	var exists_before = InventoryManager.has_memory_shard(shard_name)
	assert_false(exists_before, "Shard should not exist initially")
	
	# Save shard
	InventoryManager.save_memory_shard(shard_name, "Test", "icon.png", "scene.tscn")
	
	# Should exist now
	var exists_after = InventoryManager.has_memory_shard(shard_name)
	assert_true(exists_after, "Shard should exist after saving")
	print("✅ has_memory_shard() works correctly")

func test_get_memory_shard_count():
	"""Test getting memory shard count"""
	if not ProfileManager or ProfileManager.active_profile_id <= 0:
		pass_test("No active profile")
		return
	
	var initial_count = InventoryManager.get_memory_shard_count()
	assert_typeof(initial_count, TYPE_INT, "Count should be integer")
	
	# Add shards
	InventoryManager.save_memory_shard("count1", "Test1", "icon1.png", "scene1.tscn")
	InventoryManager.save_memory_shard("count2", "Test2", "icon2.png", "scene2.tscn")
	
	var new_count = InventoryManager.get_memory_shard_count()
	assert_eq(new_count, initial_count + 2, "Count should increase by 2")
	print("✅ Memory shard count:", new_count)

# ==============================================================================
# ITEM TESTS
# ==============================================================================

func test_save_item_to_items_table():
	"""Test saving item definition to items table"""
	var item = {
		"id": 1,
		"name": "Health Potion",
		"description": "Restores 50 HP",
		"icon_path": "res://assets/items/health_potion.png",
		"stack_size": 10,
		"is_completed": false
	}
	
	InventoryManager.save_item_to_items_table(item)
	
	# Verify item was saved
	var retrieved = InventoryManager.get_item(1)
	assert_not_null(retrieved, "Item should be retrievable")
	assert_eq(retrieved.get("name", ""), "Health Potion", "Item name should match")
	print("✅ Item saved to items table")

func test_add_item_to_inventory():
	"""UT003: Test adding item to inventory"""
	if not ProfileManager or ProfileManager.active_profile_id <= 0:
		pass_test("No active profile")
		return
	
	# First, create item definition
	var item = {
		"id": 100,
		"name": "Test Sword",
		"description": "A test weapon",
		"stack_size": 1
	}
	InventoryManager.save_item_to_items_table(item)
	
	# Add to inventory
	var slot_id = 0
	var item_id = 100
	var quantity = 1
	InventoryManager.add_item(slot_id, item_id, quantity)
	
	# Verify
	var inventory = InventoryManager.get_inventory()
	assert_gt(inventory.size(), 0, "Inventory should have items")
	print("✅ Item added to inventory")

func test_remove_item_from_inventory():
	"""UT004: Test removing item from inventory by slot"""
	if not ProfileManager or ProfileManager.active_profile_id <= 0:
		pass_test("No active profile")
		return
	
	# Add item first
	var item = {"id": 101, "name": "Test Item", "description": "Test", "stack_size": 1}
	InventoryManager.save_item_to_items_table(item)
	InventoryManager.add_item(0, 101, 1)
	
	var before = InventoryManager.get_inventory().size()
	
	# Remove item
	InventoryManager.remove_item(0)
	
	var after = InventoryManager.get_inventory().size()
	assert_lt(after, before, "Inventory size should decrease")
	print("✅ Item removed from inventory by slot")

func test_remove_item_by_id():
	"""UT004: Test removing item from inventory by item_id"""
	if not ProfileManager or ProfileManager.active_profile_id <= 0:
		pass_test("No active profile")
		return
	
	# Add item
	var item = {"id": 102, "name": "Remove Test", "description": "Test", "stack_size": 1}
	InventoryManager.save_item_to_items_table(item)
	InventoryManager.add_item(0, 102, 1)
	
	var before = InventoryManager.get_inventory().size()
	
	# Remove by item_id
	InventoryManager.remove_item_id(102)
	
	var after = InventoryManager.get_inventory().size()
	assert_lt(after, before, "Inventory should have fewer items")
	print("✅ Item removed by item_id")

func test_get_inventory():
	"""Test retrieving inventory for active profile"""
	if not ProfileManager or ProfileManager.active_profile_id <= 0:
		pass_test("No active profile")
		return
	
	var inventory = InventoryManager.get_inventory()
	assert_not_null(inventory, "get_inventory() should return array")
	assert_true(inventory is Array, "Should return Array")
	print("✅ get_inventory() returns array, size:", inventory.size())

func test_get_all_inventory_slots():
	"""Test getting all inventory slots"""
	if not ProfileManager or ProfileManager.active_profile_id <= 0:
		pass_test("No active profile")
		return
	
	var slots = InventoryManager.get_all_inventory_slots()
	assert_not_null(slots, "get_all_inventory_slots() should return array")
	assert_true(slots is Array, "Should return Array")
	print("✅ All inventory slots retrieved")

func test_get_item():
	"""Test getting item definition by ID"""
	# Create item
	var item = {
		"id": 200,
		"name": "Magic Staff",
		"description": "A powerful magical weapon",
		"stack_size": 1
	}
	InventoryManager.save_item_to_items_table(item)
	
	# Retrieve item
	var retrieved = InventoryManager.get_item(200)
	assert_not_null(retrieved, "get_item() should return dictionary")
	assert_eq(retrieved.get("name", ""), "Magic Staff", "Item name should match")
	print("✅ Item definition retrieved")

func test_get_all_items():
	"""Test getting all item definitions"""
	# Create multiple items
	var items = [
		{"id": 301, "name": "Item1", "description": "Test1", "stack_size": 1},
		{"id": 302, "name": "Item2", "description": "Test2", "stack_size": 5},
		{"id": 303, "name": "Item3", "description": "Test3", "stack_size": 10}
	]
	
	for item in items:
		InventoryManager.save_item_to_items_table(item)
	
	var all_items = InventoryManager.get_all_items()
	assert_not_null(all_items, "get_all_items() should return array")
	assert_gte(all_items.size(), 3, "Should have at least 3 items")
	print("✅ All item definitions retrieved, count:", all_items.size())

func test_has_item():
	"""UT010: Test checking if player has item"""
	if not ProfileManager or ProfileManager.active_profile_id <= 0:
		pass_test("No active profile")
		return
	
	var item_id = 400
	
	# Should not have item initially
	var has_before = InventoryManager.has_item(item_id)
	assert_false(has_before, "Should not have item initially")
	
	# Add item
	var item = {"id": item_id, "name": "Check Item", "description": "Test", "stack_size": 1}
	InventoryManager.save_item_to_items_table(item)
	InventoryManager.add_item(0, item_id, 1)
	
	# Should have item now
	var has_after = InventoryManager.has_item(item_id)
	assert_true(has_after, "Should have item after adding")
	print("✅ has_item() works correctly")

func test_get_next_available_slot():
	"""Test finding next available inventory slot"""
	if not ProfileManager or ProfileManager.active_profile_id <= 0:
		pass_test("No active profile")
		return
	
	var next_slot = InventoryManager.get_next_available_slot()
	assert_typeof(next_slot, TYPE_INT, "Should return integer")
	assert_gte(next_slot, 0, "Slot should be >= 0")
	print("✅ Next available slot:", next_slot)

# ==============================================================================
# UTILITY TESTS
# ==============================================================================

func test_clear_profile_data():
	"""Test clearing profile inventory and shards"""
	if not ProfileManager or ProfileManager.active_profile_id <= 0:
		pass_test("No active profile")
		return
	
	# Add some data
	InventoryManager.save_memory_shard("clear_test", "Test", "icon.png", "scene.tscn")
	var item = {"id": 500, "name": "Clear Test", "description": "Test", "stack_size": 1}
	InventoryManager.save_item_to_items_table(item)
	InventoryManager.add_item(0, 500, 1)
	
	# Clear data
	InventoryManager.clear_profile_data(test_profile_id)
	
	# Verify cleared
	var shards = InventoryManager.get_all_memory_shards()
	var inventory = InventoryManager.get_inventory()
	assert_eq(shards.size(), 0, "Shards should be cleared")
	assert_eq(inventory.size(), 0, "Inventory should be cleared")
	print("✅ Profile data cleared successfully")

func test_clear_all_game_data():
	"""Test clearing all game data for active profile"""
	if not ProfileManager or ProfileManager.active_profile_id <= 0:
		pass_test("No active profile")
		return
	
	# Add data
	InventoryManager.save_memory_shard("game_data_test", "Test", "icon.png", "scene.tscn")
	
	# Clear all
	InventoryManager.clear_all_game_data()
	
	# Verify
	var count = InventoryManager.get_memory_shard_count()
	assert_eq(count, 0, "All game data should be cleared")
	print("✅ All game data cleared for active profile")

# ==============================================================================
# PROFILE ISOLATION TESTS
# ==============================================================================

func test_inventory_profile_isolation():
	"""Test that different profiles have separate inventories"""
	if not ProfileManager or not ProfileManager.has_method("create_profile"):
		pass_test("ProfileManager not available")
		return
	
	# Create two profiles
	var profile1 = ProfileManager.create_profile("InvProfile1")
	var profile2 = ProfileManager.create_profile("InvProfile2")
	
	# Add item to profile1
	ProfileManager.active_profile_id = profile1
	var item = {"id": 600, "name": "Profile1 Item", "description": "Test", "stack_size": 1}
	InventoryManager.save_item_to_items_table(item)
	InventoryManager.add_item(0, 600, 1)
	var profile1_inventory = InventoryManager.get_inventory()
	
	# Switch to profile2
	ProfileManager.active_profile_id = profile2
	var profile2_inventory = InventoryManager.get_inventory()
	
	# Verify isolation
	assert_gt(profile1_inventory.size(), 0, "Profile1 should have items")
	assert_eq(profile2_inventory.size(), 0, "Profile2 should be empty")
	print("✅ Inventory profile isolation works")
	
	# Cleanup
	ProfileManager.active_profile_id = profile1
	InventoryManager.clear_profile_data(profile1)
	InventoryManager.clear_profile_data(profile2)
	if ProfileManager.has_method("delete_profile"):
		ProfileManager.delete_profile(profile1)
		ProfileManager.delete_profile(profile2)

func test_memory_shard_profile_isolation():
	"""Test that memory shards are isolated per profile"""
	if not ProfileManager or not ProfileManager.has_method("create_profile"):
		pass_test("ProfileManager not available")
		return
	
	# Create two profiles
	var profile1 = ProfileManager.create_profile("ShardProfile1")
	var profile2 = ProfileManager.create_profile("ShardProfile2")
	
	# Add shard to profile1
	ProfileManager.active_profile_id = profile1
	InventoryManager.save_memory_shard("profile1_shard", "Test1", "icon1.png", "scene1.tscn")
	var profile1_count = InventoryManager.get_memory_shard_count()
	
	# Switch to profile2
	ProfileManager.active_profile_id = profile2
	var profile2_count = InventoryManager.get_memory_shard_count()
	
	# Verify isolation
	assert_eq(profile1_count, 1, "Profile1 should have 1 shard")
	assert_eq(profile2_count, 0, "Profile2 should have 0 shards")
	print("✅ Memory shard profile isolation works")
	
	# Cleanup
	ProfileManager.active_profile_id = profile1
	InventoryManager.clear_profile_data(profile1)
	InventoryManager.clear_profile_data(profile2)
	if ProfileManager.has_method("delete_profile"):
		ProfileManager.delete_profile(profile1)
		ProfileManager.delete_profile(profile2)
