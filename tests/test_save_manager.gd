extends GutTest

const SaveManager = preload("res://script/SaveManager.gd")
const TEST_SCENE = preload("res://scenes/TestingScenes/TestingGrounds.tscn")

# --- Test: Save writes TestingGrounds scene to DB ---
func test_save_game_writes_testinggrounds():
	var save_manager = SaveManager.new()
	add_child_autofree(save_manager)

	# Ensure DB is initialized
	assert_true(save_manager.init_db(), "Database should initialize without errors")

	# Load the TestingGrounds scene so get_tree().current_scene is set
	var test_scene = TEST_SCENE.instantiate()
	get_tree().root.add_child(test_scene)
	get_tree().current_scene = test_scene
	await get_tree().process_frame

	# Set the player's last_direction to "right" to control the saved value
	# Use the group instead of a hardcoded path
	# Look in the scene tree, not the node
	var player = get_tree().get_first_node_in_group("player")
	assert_not_null(player, "Player node must exist in the 'player' group")
	player.last_direction = "right"



	# Update game data with test payload (other fields)
	save_manager.game_data["player_name"] = "UnitTestHero"
	save_manager.game_data["player_position"] = {"x": 10.0, "y": 5.0, "z": 0.0}
	save_manager.game_data["has_save"] = true

	# Save game to DB
	var save_ok = save_manager.save_game()
	assert_true(save_ok, "save_game() should return true on success")

	# Immediately check DB contents
	save_manager.db.query("SELECT * FROM save_data;")
	var rows = save_manager.db.query_result

	assert_gt(rows.size(), 0, "There should be at least one row after saving")
	assert_eq(rows[0]["player_name"], "UnitTestHero", "Player name should match what we saved")
	assert_eq(rows[0]["current_scene"], "res://scenes/TestingScenes/TestingGrounds.tscn", "Scene path should match TestingGrounds")
	assert_eq(rows[0]["direction"], "right", "Direction should match what we forced on the player")
	assert_eq(rows[0]["has_save"], 1, "Has_save flag should be stored as 1")
